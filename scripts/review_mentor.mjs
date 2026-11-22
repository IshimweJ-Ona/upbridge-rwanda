/**
 * Trusted Firebase Admin SDK script to approve or reject a mentor application
 * on the Firebase Spark (free) plan without deploying Cloud Functions.
 *
 * Usage (Production):
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
 *     node scripts/review_mentor.mjs --project upridge-rwanda-dev --uid <uid> --decision approve
 *
 * Usage (Reject):
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
 *     node scripts/review_mentor.mjs --project upridge-rwanda-dev --uid <uid> --decision reject --reason "Add more project mentorship examples"
 *
 * Usage (Local Emulators):
 *   $env:FIREBASE_AUTH_EMULATOR_HOST="127.0.0.1:9099"
 *   $env:FIRESTORE_EMULATOR_HOST="127.0.0.1:8080"
 *   node scripts/review_mentor.mjs --project upridge-rwanda-dev --uid <uid> --decision approve
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
    decision: '',
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
    } else if (key === '--decision' && next) {
      args.decision = next.trim().toLowerCase();
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
if (
  !args.uid ||
  (args.decision !== 'approve' &&
    args.decision !== 'reject' &&
    args.decision !== 'revoke')
) {
  console.error(
    'Usage: node scripts/review_mentor.mjs --uid <uid> --decision <approve|reject|revoke> [--reason "<text>"] [--project upridge-rwanda-dev]',
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

const userRecord = await auth.getUser(args.uid);
const appRef = db.collection('mentorApplications').doc(args.uid);
const appSnap = await appRef.get();

const appData = appSnap.exists ? (appSnap.data() ?? {}) : {};
if (args.decision === 'revoke') {
  if (appSnap.exists && appData.status !== 'approved') {
    console.error(
      `Cannot revoke mentorApplications/${args.uid}: current status is "${appData.status}", expected "approved".`,
    );
    process.exit(1);
  }
} else {
  if (!appSnap.exists) {
    console.error(`Mentor application mentorApplications/${args.uid} not found.`);
    process.exit(1);
  }
  if (appData.status !== 'pending') {
    console.error(
      `Cannot review mentorApplications/${args.uid}: current status is "${appData.status}", expected "pending".`,
    );
    process.exit(1);
  }
}

let actorUid = 'operator-cli';
try {
  const actor = await auth.getUserByEmail(args.actorEmail);
  actorUid = actor.uid;
} catch (_) {
  // Actor email may not exist in local emulator tests; fall back to operator-cli.
}

const batch = db.batch();

if (args.decision === 'approve') {
  const existingClaims = userRecord.customClaims ?? {};
  await auth.setCustomUserClaims(args.uid, {
    ...existingClaims,
    role: 'mentor',
  });

  batch.update(appRef, {
    status: 'approved',
    rejectionReason: '',
    reviewedBy: actorUid,
    reviewedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  batch.set(
    db.collection('users').doc(args.uid),
    {
      role: 'mentor',
      isApproved: true,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  batch.set(
    db.collection('profiles').doc(args.uid),
    {
      mentorExpertise: Array.isArray(appData.expertise) ? appData.expertise : [],
      mentorExperienceYears: Number(appData.experienceYears ?? 0),
      mentorAvailability: String(appData.availability ?? ''),
      mentorBio: String(appData.bio ?? ''),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  batch.set(db.collection('notifications').doc(), {
    ownerUid: args.uid,
    title: 'Mentor application approved',
    body: 'Congratulations! Your mentor application has been approved.',
    type: 'mentorApproval',
    route: '/m/home',
    isRead: false,
    readAt: null,
    status: 'unread',
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
} else if (args.decision === 'reject') {
  batch.update(appRef, {
    status: 'rejected',
    rejectionReason: args.reason,
    reviewedBy: actorUid,
    reviewedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  batch.set(db.collection('notifications').doc(), {
    ownerUid: args.uid,
    title: 'Mentor application update',
    body: `Your mentor application was not approved yet: ${args.reason}`,
    type: 'mentorRejection',
    route: '/mentor-apply',
    isRead: false,
    readAt: null,
    status: 'unread',
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
} else {
  const existingClaims = { ...(userRecord.customClaims ?? {}) };
  if (existingClaims.role === 'mentor') {
    existingClaims.role = 'student';
  }
  await auth.setCustomUserClaims(args.uid, existingClaims);
  await auth.revokeRefreshTokens(args.uid);

  if (appSnap.exists) {
    batch.update(appRef, {
      status: 'revoked',
      rejectionReason: args.reason,
      reviewedBy: actorUid,
      reviewedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  batch.set(
    db.collection('users').doc(args.uid),
    {
      role: 'student',
      isApproved: false,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  batch.set(
    db.collection('profiles').doc(args.uid),
    {
      isMentorPublic: false,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  batch.set(db.collection('notifications').doc(), {
    ownerUid: args.uid,
    title: 'Mentor access revoked',
    body: `Your mentor privileges were revoked: ${args.reason}`,
    type: 'mentorRevocation',
    route: '/mentor-apply',
    isRead: false,
    readAt: null,
    status: 'unread',
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

batch.set(db.collection('auditLogs').doc(), {
  ownerUid: actorUid,
  actorUid,
  actorEmail: args.actorEmail,
  action:
    args.decision === 'approve'
      ? 'approveMentorApplication'
      : args.decision === 'reject'
        ? 'rejectMentorApplication'
        : 'revokeMentorRole',
  targetCollection:
    args.decision === 'revoke' ? 'users' : 'mentorApplications',
  targetId: args.uid,
  details: `${args.decision.toUpperCase()} mentor (${appData.applicantEmail ?? userRecord.email ?? args.uid})${args.reason ? `: ${args.reason}` : ''}`,
  status: 'recorded',
  createdAt: FieldValue.serverTimestamp(),
  updatedAt: FieldValue.serverTimestamp(),
});

await batch.commit();

console.log(
  args.decision === 'approve'
    ? `Approved mentor application for ${args.uid} (${args.project}) and granted custom claim { role: 'mentor' }.`
    : args.decision === 'reject'
      ? `Rejected mentor application for ${args.uid} (${args.project}).`
      : `Revoked mentor privileges for ${args.uid} (${args.project}).`,
);
if (args.decision === 'approve') {
  console.log(
    'Note: The promoted user must refresh their ID token (sign out and back in, or trigger token refresh) to receive { role: "mentor" }.',
  );
}
