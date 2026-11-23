/**
 * Trusted Firebase Admin SDK script to approve, reject, revoke, or retry
 * approval email delivery for a mentor application on Firebase Spark / Blaze.
 *
 * Uses the same transactional core (`server/admin_core.mjs`) and real email
 * sender (`server/email_service.mjs`) as the HTTP Admin Backend.
 *
 * Usage (Production):
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
 *     node scripts/review_mentor.mjs --project upridge-rwanda-dev --uid <uid> --decision approve
 *
 * Usage (Retry failed approval email):
 *   node scripts/review_mentor.mjs --project upridge-rwanda-dev --uid <uid> --retry-email
 */

import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  deliverMentorApprovalEmail,
  reviewMentorApplicationTx,
  revokeMentorTx,
  setMentorVisibilityTx,
} from '../server/admin_core.mjs';
import { createEmailSender } from '../server/email_service.mjs';

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
    } catch (_) {}
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
    decision: '',
    reason: '',
    actorEmail: 'authapp05@gmail.com',
    retryEmail: false,
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
    } else if (key === '--decision' && next) {
      args.decision = next.trim().toLowerCase();
      i += 1;
    } else if (key === '--reason' && next) {
      args.reason = next.trim();
      i += 1;
    } else if (key === '--actor-email' && next) {
      args.actorEmail = next.trim().toLowerCase();
      i += 1;
    } else if (key === '--retry-email') {
      args.retryEmail = true;
    }
  }
  return args;
}

const args = parseArgs(process.argv);
if (
  !args.uid ||
  (!args.retryEmail &&
    args.decision !== 'approve' &&
    args.decision !== 'reject' &&
    args.decision !== 'revoke' &&
    args.decision !== 'publish' &&
    args.decision !== 'hide')
) {
  console.error(
    'Usage: node scripts/review_mentor.mjs --uid <uid> (--decision <approve|reject|revoke|publish|hide> [--reason "<text>"] | --retry-email) [--project upridge-rwanda-dev]',
  );
  process.exit(1);
}
if (
  (args.decision === 'reject' || args.decision === 'revoke') &&
  args.reason.length < 5
) {
  console.error(
    `When --decision is ${args.decision}, provide --reason with at least 5 characters.`,
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

let actorUid = 'operator-cli';
try {
  const actorRecord = await auth.getUserByEmail(args.actorEmail);
  actorUid = actorRecord.uid;
} catch (_) {
  // Actor email may not exist in local emulator tests; fall back to operator-cli.
}
const actor = { uid: actorUid, email: args.actorEmail };
const emailSender = createEmailSender(process.env);

if (args.retryEmail) {
  const appSnap = await db.collection('mentorApplications').doc(args.uid).get();
  if (!appSnap.exists) {
    console.error(`Mentor application mentorApplications/${args.uid} not found.`);
    process.exit(1);
  }
  const appData = appSnap.data() || {};
  const userSnap = await db.collection('users').doc(args.uid).get();
  const userData = userSnap.exists ? userSnap.data() || {} : {};
  const delivery = await deliverMentorApprovalEmail({
    db,
    FieldValue,
    applicantUid: args.uid,
    recipientEmail: userData.email || appData.applicantEmail,
    mentorName: appData.applicantName || userData.displayName,
    actorUid: actor.uid,
    actorEmail: actor.email,
    emailSender,
  });
  console.log(JSON.stringify({ ok: delivery.delivered, uid: args.uid, emailDelivery: delivery }));
  process.exit(delivery.delivered ? 0 : 1);
}

if (args.decision === 'revoke') {
  const res = await revokeMentorTx({
    auth,
    db,
    FieldValue,
    actor,
    targetUid: args.uid,
    reason: args.reason,
  });
  console.log(JSON.stringify({ ...res, uid: args.uid }));
} else if (args.decision === 'publish' || args.decision === 'hide') {
  const res = await setMentorVisibilityTx({
    db,
    FieldValue,
    actor,
    mentorUid: args.uid,
    isPublic: args.decision === 'publish',
  });
  console.log(JSON.stringify({ ...res, uid: args.uid }));
} else {
  const res = await reviewMentorApplicationTx({
    auth,
    db,
    FieldValue,
    actor,
    applicantUid: args.uid,
    decision: args.decision === 'approve' ? 'approved' : 'rejected',
    reason: args.reason,
    emailSender,
  });
  console.log(JSON.stringify({ ...res, uid: args.uid }));
}
