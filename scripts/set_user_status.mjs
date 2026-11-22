/**
 * Trusted Firebase Admin SDK script to activate or deactivate a user account
 * (Firebase Auth disabled state + refresh token revocation + Firestore status + audit log)
 * on the Firebase Spark (free) plan without deploying Cloud Functions.
 *
 * Usage (Production):
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
 *     node scripts/set_user_status.mjs --project upridge-rwanda-dev --uid <uid> --status deactivated --reason "Policy violation"
 *
 * Usage (Local Emulators):
 *   $env:FIREBASE_AUTH_EMULATOR_HOST="127.0.0.1:9099"
 *   $env:FIRESTORE_EMULATOR_HOST="127.0.0.1:8080"
 *   node scripts/set_user_status.mjs --project upridge-rwanda-dev --uid <uid> --status active
 */

import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function loadFirebaseAdmin() {
  const roots = [
    createRequire(import.meta.url),
    createRequire(path.resolve(__dirname, '../package.json')),
  ];
  for (const req of roots) {
    try {
      return {
        app: req('firebase-admin/app'),
        auth: req('firebase-admin/auth'),
        firestore: req('firebase-admin/firestore'),
      };
    } catch (_) {
      // Try next resolution root.
    }
  }
  throw new Error(
    'Unable to resolve firebase-admin. Run "npm install" at the repo root.',
  );
}

function parseArgs(argv) {
  const args = {
    project:
      process.env.FIREBASE_PROJECT_ID ||
      process.env.GCLOUD_PROJECT ||
      'upridge-rwanda-dev',
    uid: '',
    status: '',
    reason: '',
    actorEmail: 'authapp05@gmail.com',
  };
  for (let i = 2; i < argv.length; i += 1) {
    const key = argv[i];
    const next = argv[i + 1];
    if (key === '--project' && next) {
      args.project = next.trim();
      i += 1;
    } else if (key === '--uid' && next) {
      args.uid = next.trim();
      i += 1;
    } else if (key === '--status' && next) {
      args.status = next.trim().toLowerCase();
      i += 1;
    } else if (key === '--reason' && next) {
      args.reason = next.trim();
      i += 1;
    } else if (key === '--actor-email' && next) {
      args.actorEmail = next.trim().toLowerCase();
      i += 1;
    }
  }
  return args;
}

const args = parseArgs(process.argv);
if (!args.uid || (args.status !== 'active' && args.status !== 'deactivated')) {
  console.error(
    'Usage: node scripts/set_user_status.mjs --uid <uid> --status <active|deactivated> [--reason "<text>"] [--project upridge-rwanda-dev]',
  );
  process.exit(1);
}

const { app, auth: authPkg, firestore: fsPkg } = loadFirebaseAdmin();
const usingEmulators = Boolean(
  process.env.FIREBASE_AUTH_EMULATOR_HOST ||
    process.env.FIRESTORE_EMULATOR_HOST,
);

app.initializeApp(
  usingEmulators
    ? { projectId: args.project }
    : { projectId: args.project, credential: app.applicationDefault() },
);

const auth = authPkg.getAuth();
const db = fsPkg.getFirestore();
const { FieldValue } = fsPkg;

const userRecord = await auth.getUser(args.uid);
if (userRecord.customClaims?.role === 'admin' && args.status === 'deactivated') {
  console.error('Refusing to deactivate an administrator account.');
  process.exit(1);
}

const deactivate = args.status === 'deactivated';
await auth.updateUser(args.uid, { disabled: deactivate });
if (deactivate) {
  await auth.revokeRefreshTokens(args.uid);
}

let actorUid = 'operator-cli';
try {
  const actor = await auth.getUserByEmail(args.actorEmail);
  actorUid = actor.uid;
} catch (_) {
  // Actor email may not exist in local emulator tests; fall back to operator-cli.
}

const batch = db.batch();
batch.set(
  db.collection('users').doc(args.uid),
  {
    status: args.status,
    updatedAt: FieldValue.serverTimestamp(),
  },
  { merge: true },
);
batch.set(db.collection('auditLogs').doc(), {
  ownerUid: actorUid,
  actorUid,
  actorEmail: args.actorEmail,
  action: deactivate ? 'deactivateUser' : 'reactivateUser',
  targetCollection: 'users',
  targetId: args.uid,
  details: `Set ${userRecord.email ?? args.uid} status=${args.status}${args.reason ? `: ${args.reason}` : ''}`,
  status: 'recorded',
  createdAt: FieldValue.serverTimestamp(),
  updatedAt: FieldValue.serverTimestamp(),
});
await batch.commit();

console.log(
  `Set users/${args.uid} status=${args.status} (Auth disabled=${deactivate}) on ${args.project}.`,
);
