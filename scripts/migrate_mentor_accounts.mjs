/**
 * Safe idempotent migration script to repair legacy misclassified mentor
 * accounts (`role: 'student'` with an existing `mentorApplications/{uid}`)
 * and backfill `approvalStatus` and Auth `emailVerified` across `users/{uid}`.
 *
 * Safety guarantees:
 * - Dry-run by default (pass `--apply` to commit writes).
 * - Never converts ordinary Youth accounts without a `mentorApplications/{uid}` doc.
 * - Never auto-approves accounts (`isApproved` never flips from false -> true).
 * - Preserves `rejected` and `revoked` states and clears stale mentor claims.
 *
 * Usage:
 *   node scripts/migrate_mentor_accounts.mjs --project upridge-rwanda-dev [--apply]
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
    apply: false,
  };
  for (let i = 2; i < argv.length; i += 1) {
    const key = argv[i];
    const next = argv[i + 1];
    if (key === '--project' && next) {
      args.project = next.trim();
      i += 1;
    } else if (key === '--apply') {
      args.apply = true;
    }
  }
  return args;
}

export function resolveMigratedAccountPatch({ userData, appData, emailVerified }) {
  const patch = {};
  const warnings = [];

  if (userData.emailVerified !== emailVerified) {
    patch.emailVerified = emailVerified;
  }

  if (userData.role === 'admin') {
    if (userData.approvalStatus !== 'notRequired' && userData.approvalStatus !== 'approved') {
      patch.approvalStatus = 'approved';
    }
    return { patch, warnings, staleMentorClaimRisk: false };
  }

  if (appData != null) {
    const appStatus = String(appData.status || 'pending');
    const existingApproved = userData.isApproved === true;
    const existingApprovalStatus = String(userData.approvalStatus || '');

    let targetApproval;
    if (existingApprovalStatus === 'revoked' || appStatus === 'revoked') {
      targetApproval = 'revoked';
    } else if (appStatus === 'rejected') {
      targetApproval = 'rejected';
    } else if (appStatus === 'approved' && existingApproved) {
      targetApproval = 'approved';
    } else {
      targetApproval = 'pending';
      if (appStatus === 'approved' && !existingApproved) {
        warnings.push(
          'Application status="approved" but users/{uid}.isApproved!=true; keeping pending (never auto-approving).',
        );
      }
    }

    const targetApproved = targetApproval === 'approved';
    if (userData.role !== 'mentor') patch.role = 'mentor';
    if (userData.approvalStatus !== targetApproval) {
      patch.approvalStatus = targetApproval;
    }
    if (Boolean(userData.isApproved) !== targetApproved) {
      patch.isApproved = targetApproved;
    }
    if (userData.onboarded !== true) patch.onboarded = true;
    return {
      patch,
      warnings,
      staleMentorClaimRisk: !targetApproved,
    };
  }

  if (userData.role === 'mentor') {
    const existingApproval = String(userData.approvalStatus || '');
    let targetApproval;
    if (existingApproval === 'revoked') {
      targetApproval = 'revoked';
    } else if (existingApproval === 'rejected') {
      targetApproval = 'rejected';
    } else if (userData.isApproved === true && existingApproval !== 'pending') {
      targetApproval = 'approved';
    } else {
      targetApproval = 'pending';
    }
    const targetApproved = targetApproval === 'approved';
    if (userData.approvalStatus !== targetApproval) {
      patch.approvalStatus = targetApproval;
    }
    if (Boolean(userData.isApproved) !== targetApproved) {
      patch.isApproved = targetApproved;
    }
    return {
      patch,
      warnings,
      staleMentorClaimRisk: !targetApproved,
    };
  }

  if (userData.role === 'student' || userData.role === 'youth') {
    if (userData.approvalStatus !== 'notRequired') {
      patch.approvalStatus = 'notRequired';
    }
    return { patch, warnings, staleMentorClaimRisk: true };
  }

  warnings.push(`Unknown role "${userData.role}" left untouched for manual inspection.`);
  return { patch, warnings, staleMentorClaimRisk: false };
}

export async function runMentorMigration({
  authClient,
  db,
  apply = false,
  logger = console,
}) {
  const [usersSnap, appsSnap] = await Promise.all([
    db.collection('users').get(),
    db.collection('mentorApplications').get(),
  ]);

  const appsByUid = new Map();
  for (const doc of appsSnap.docs) {
    appsByUid.set(doc.id, doc.data());
  }

  const seenUids = new Set();
  let examined = 0;
  let updated = 0;
  let created = 0;
  let claimsCleared = 0;
  let warningCount = 0;
  const now = new Date();

  for (const userDoc of usersSnap.docs) {
    examined += 1;
    const uid = userDoc.id;
    seenUids.add(uid);
    const data = userDoc.data() || {};
    const appData = appsByUid.get(uid) || null;

    let authRecord = null;
    let emailVerified = Boolean(data.emailVerified);
    try {
      authRecord = await authClient.getUser(uid);
      emailVerified = Boolean(authRecord.emailVerified);
    } catch (_) {
      // Auth record missing or deleted; preserve stored verification state.
    }

    const { patch, warnings, staleMentorClaimRisk } = resolveMigratedAccountPatch({
      userData: data,
      appData,
      emailVerified,
    });
    for (const warn of warnings) {
      warningCount += 1;
      logger.warn(`[WARN] users/${uid}: ${warn}`);
    }

    if (
      staleMentorClaimRisk &&
      authRecord?.customClaims?.role === 'mentor'
    ) {
      claimsCleared += 1;
      logger.log(
        `[${apply ? 'CLAIM-STRIP' : 'DRY-RUN'}] Stripping stale { role: 'mentor' } custom claim for users/${uid}`,
      );
      if (apply) {
        const nextClaims = { ...(authRecord.customClaims || {}) };
        delete nextClaims.role;
        await authClient.setCustomUserClaims(uid, nextClaims);
        await authClient.revokeRefreshTokens(uid);
      }
    }

    if (Object.keys(patch).length > 0) {
      updated += 1;
      logger.log(
        `[${apply ? 'UPDATE' : 'DRY-RUN'}] users/${uid}:`,
        JSON.stringify(patch),
      );
      if (apply) {
        await userDoc.ref.set({ ...patch, updatedAt: now }, { merge: true });
      }
    }
  }

  for (const [uid, appData] of appsByUid.entries()) {
    if (seenUids.has(uid)) continue;

    let emailVerified = false;
    let email = String(appData.applicantEmail || '');
    try {
      const authRecord = await authClient.getUser(uid);
      emailVerified = Boolean(authRecord.emailVerified);
      email = authRecord.email || email;
    } catch (_) {}

    const rawAppStatus = String(appData.status || 'pending');
    // Never auto-approve a missing users/{uid} solely from mentorApplications presence.
    const approvalStatus =
      rawAppStatus === 'rejected'
        ? 'rejected'
        : rawAppStatus === 'revoked'
          ? 'revoked'
          : 'pending';
    if (rawAppStatus === 'approved') {
      warningCount += 1;
      logger.warn(
        `[WARN] mentorApplications/${uid} had status="approved" with missing users/${uid}; creating users/${uid} as pending (manual admin review required).`,
      );
    }

    const payload = {
      ownerUid: uid,
      email,
      displayName: appData.applicantName || 'Mentor Applicant',
      phone: '',
      role: 'mentor',
      isApproved: false,
      approvalStatus,
      emailVerified,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      createdAt: appData.createdAt || now,
      updatedAt: now,
    };
    created += 1;
    logger.log(
      `[${apply ? 'CREATE' : 'DRY-RUN'}] users/${uid} from mentorApplications/${uid}:`,
      JSON.stringify({
        role: payload.role,
        approvalStatus: payload.approvalStatus,
        isApproved: payload.isApproved,
        emailVerified: payload.emailVerified,
      }),
    );
    if (apply) {
      await db.collection('users').doc(uid).set(payload);
    }
  }

  return {
    ok: true,
    dryRun: !apply,
    examinedUsers: examined,
    applicationsCount: appsSnap.size,
    usersUpdated: updated,
    usersCreated: created,
    claimsCleared,
    warnings: warningCount,
  };
}

const __isCliEntry =
  process.argv[1] && path.resolve(process.argv[1]) === __filename;

if (__isCliEntry) {
  const args = parseArgs(process.argv);
  const { app, auth, firestore } = loadFirebaseAdmin();
  const usingEmulators = Boolean(
    process.env.FIREBASE_AUTH_EMULATOR_HOST ||
      process.env.FIRESTORE_EMULATOR_HOST,
  );
  const firebaseApp = app.initializeApp(
    usingEmulators
      ? { projectId: args.project }
      : { projectId: args.project, credential: app.applicationDefault() },
  );
  const authClient = auth.getAuth(firebaseApp);
  const db = firestore.getFirestore(firebaseApp);

  runMentorMigration({
    authClient,
    db,
    apply: args.apply,
  })
    .then((summary) => {
      console.log(JSON.stringify(summary));
    })
    .catch((err) => {
      console.error('Migration failed:', err?.message || err);
      process.exit(1);
    });
}
