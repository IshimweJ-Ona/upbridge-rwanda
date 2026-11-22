// One-time trusted admin provisioning script.
// Usage:
//   node scripts/bootstrap_admin.mjs --email authapp05@gmail.com
// Works against Firebase Auth/Firestore emulators when FIREBASE_AUTH_EMULATOR_HOST
// and FIRESTORE_EMULATOR_HOST are set, or against production using GOOGLE_APPLICATION_CREDENTIALS.

import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

function parseArg(flag, fallback) {
  const idx = process.argv.indexOf(flag);
  if (idx !== -1 && process.argv[idx + 1]) {
    return process.argv[idx + 1];
  }
  return fallback;
}

const projectId =
  parseArg('--project', process.env.GCLOUD_PROJECT || 'upridge-rwanda-dev');
const adminEmail = parseArg('--email', 'authapp05@gmail.com').trim();
const sendVerify = process.argv.includes('--generate-verification-link');

initializeApp({
  projectId,
  ...(process.env.FIREBASE_AUTH_EMULATOR_HOST
    ? {}
    : { credential: applicationDefault() }),
});

const auth = getAuth();
const db = getFirestore();

async function main() {
  const user = await auth.getUserByEmail(adminEmail);
  await auth.setCustomUserClaims(user.uid, {
    ...(user.customClaims ?? {}),
    role: 'admin',
  });

  const now = FieldValue.serverTimestamp();
  await db.collection('users').doc(user.uid).set(
    {
      ownerUid: user.uid,
      email: user.email ?? adminEmail,
      displayName: user.displayName || 'UpBridge Admin',
      phone: user.phoneNumber || '',
      role: 'admin',
      isApproved: true,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      updatedAt: now,
      createdAt: now,
    },
    { merge: true },
  );

  await db.collection('auditLogs').add({
    ownerUid: user.uid,
    actorUid: user.uid,
    actorEmail: user.email ?? adminEmail,
    action: 'bootstrapAdmin',
    targetCollection: 'users',
    targetId: user.uid,
    details: 'Provisioned admin custom claim via trusted bootstrap script.',
    status: 'recorded',
    createdAt: now,
    updatedAt: now,
  });

  console.log(`Admin custom claim granted to ${adminEmail} (uid=${user.uid}).`);
  console.log(`emailVerified=${user.emailVerified}`);

  if (!user.emailVerified && sendVerify) {
    const link = await auth.generateEmailVerificationLink(adminEmail);
    console.log(`Verification link: ${link}`);
  }
}

main().catch((err) => {
  console.error('Bootstrap failed:', err);
  process.exitCode = 1;
});
