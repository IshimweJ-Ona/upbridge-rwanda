import assert from 'node:assert/strict';
import test from 'node:test';
import {
  resolveMigratedAccountPatch,
  runMentorMigration,
} from './migrate_mentor_accounts.mjs';

function createMigrationMemoryStore({ users = {}, apps = {}, authUsers = {} }) {
  const userDocs = new Map(
    Object.entries(users).map(([id, data]) => [id, structuredClone(data)]),
  );
  const appDocs = new Map(
    Object.entries(apps).map(([id, data]) => [id, structuredClone(data)]),
  );
  const authMap = new Map(
    Object.entries(authUsers).map(([id, data]) => [id, structuredClone(data)]),
  );
  const claimUpdates = [];
  const tokenRevocations = [];

  const db = {
    collection(name) {
      const store = name === 'users' ? userDocs : appDocs;
      return {
        async get() {
          return {
            size: store.size,
            docs: [...store.entries()].map(([id, data]) => ({
              id,
              data: () => structuredClone(data),
              ref: {
                async set(patch, opts) {
                  if (opts?.merge && store.has(id)) {
                    store.set(id, { ...store.get(id), ...structuredClone(patch) });
                  } else {
                    store.set(id, structuredClone(patch));
                  }
                },
              },
            })),
          };
        },
        doc(id) {
          return {
            async set(data) {
              store.set(id, structuredClone(data));
            },
          };
        },
      };
    },
  };

  const authClient = {
    async getUser(uid) {
      if (!authMap.has(uid)) throw new Error('auth/user-not-found');
      return structuredClone(authMap.get(uid));
    },
    async setCustomUserClaims(uid, claims) {
      claimUpdates.push({ uid, claims });
      const cur = authMap.get(uid) || {};
      authMap.set(uid, { ...cur, customClaims: claims });
    },
    async revokeRefreshTokens(uid) {
      tokenRevocations.push(uid);
    },
  };

  return {
    userDocs,
    appDocs,
    claimUpdates,
    tokenRevocations,
    db,
    authClient,
  };
}

test('resolveMigratedAccountPatch never auto-approves conflicting approved applications or alters youth accounts', () => {
  const youth = resolveMigratedAccountPatch({
    userData: { role: 'student', isApproved: false, emailVerified: true },
    appData: null,
    emailVerified: true,
  });
  assert.deepEqual(youth.patch, { approvalStatus: 'notRequired' });

  const conflict = resolveMigratedAccountPatch({
    userData: { role: 'student', isApproved: false, emailVerified: true },
    appData: { status: 'approved' },
    emailVerified: true,
  });
  assert.equal(conflict.patch.role, 'mentor');
  assert.equal(conflict.patch.isApproved, undefined); // false already matches false
  assert.equal(conflict.patch.approvalStatus, 'pending');
  assert.equal(conflict.warnings.length, 1);
});

test('runMentorMigration supports dry-run default, repairs legacy mentors, preserves youth/rejected/revoked, and is idempotent', async () => {
  const store = createMigrationMemoryStore({
    users: {
      'youth-1': {
        ownerUid: 'youth-1',
        role: 'student',
        isApproved: false,
        emailVerified: true,
        status: 'active',
        onboarded: true,
      },
      'legacy-pending-mentor': {
        ownerUid: 'legacy-pending-mentor',
        role: 'student',
        isApproved: false,
        emailVerified: false,
        status: 'active',
        onboarded: false,
      },
      'revoked-mentor': {
        ownerUid: 'revoked-mentor',
        role: 'mentor',
        isApproved: true,
        approvalStatus: 'revoked',
        emailVerified: true,
        status: 'active',
      },
      'approved-mentor': {
        ownerUid: 'approved-mentor',
        role: 'mentor',
        isApproved: true,
        approvalStatus: 'approved',
        emailVerified: true,
        status: 'active',
        onboarded: true,
      },
    },
    apps: {
      'legacy-pending-mentor': {
        applicantName: 'Kevine',
        applicantEmail: 'kevine@upbridge.rw',
        status: 'pending',
      },
      'revoked-mentor': {
        applicantName: 'Revoked',
        applicantEmail: 'revoked@upbridge.rw',
        status: 'revoked',
      },
      'approved-mentor': {
        applicantName: 'Approved',
        applicantEmail: 'approved@upbridge.rw',
        status: 'approved',
      },
      'orphan-app': {
        applicantName: 'Orphan App',
        applicantEmail: 'orphan@upbridge.rw',
        status: 'approved',
      },
    },
    authUsers: {
      'youth-1': { emailVerified: true, customClaims: {} },
      'legacy-pending-mentor': { emailVerified: true, customClaims: {} },
      'revoked-mentor': { emailVerified: true, customClaims: { role: 'mentor' } },
      'approved-mentor': { emailVerified: true, customClaims: { role: 'mentor' } },
      'orphan-app': { emailVerified: true, email: 'orphan@upbridge.rw', customClaims: {} },
    },
  });

  const noopLogger = { log() {}, warn() {} };

  // 1. Dry run leaves all documents untouched.
  const dry = await runMentorMigration({
    authClient: store.authClient,
    db: store.db,
    apply: false,
    logger: noopLogger,
  });
  assert.equal(dry.dryRun, true);
  assert.equal(dry.usersUpdated, 3); // youth-1, legacy-pending-mentor, revoked-mentor
  assert.equal(dry.usersCreated, 1); // orphan-app
  assert.equal(dry.claimsCleared, 1);
  assert.equal(store.userDocs.get('legacy-pending-mentor').role, 'student');
  assert.equal(store.userDocs.has('orphan-app'), false);

  // 2. Apply repairs legacy pending mentor, strips revoked claim, creates orphan as pending (never auto-approved).
  const applied = await runMentorMigration({
    authClient: store.authClient,
    db: store.db,
    apply: true,
    logger: noopLogger,
  });
  assert.equal(applied.dryRun, false);
  assert.equal(store.userDocs.get('youth-1').role, 'student');
  assert.equal(store.userDocs.get('youth-1').approvalStatus, 'notRequired');
  assert.equal(store.userDocs.get('legacy-pending-mentor').role, 'mentor');
  assert.equal(store.userDocs.get('legacy-pending-mentor').approvalStatus, 'pending');
  assert.equal(store.userDocs.get('legacy-pending-mentor').emailVerified, true);
  assert.equal(store.userDocs.get('legacy-pending-mentor').isApproved, false);
  assert.equal(store.userDocs.get('revoked-mentor').isApproved, false);
  assert.equal(store.userDocs.get('revoked-mentor').approvalStatus, 'revoked');
  assert.equal(store.userDocs.get('approved-mentor').isApproved, true);
  assert.equal(store.userDocs.get('approved-mentor').approvalStatus, 'approved');
  assert.equal(store.userDocs.get('orphan-app').role, 'mentor');
  assert.equal(store.userDocs.get('orphan-app').isApproved, false);
  assert.equal(store.userDocs.get('orphan-app').approvalStatus, 'pending');
  assert.deepEqual(store.tokenRevocations, ['revoked-mentor']);

  // 3. Idempotent rerun performs 0 writes.
  const rerun = await runMentorMigration({
    authClient: store.authClient,
    db: store.db,
    apply: true,
    logger: noopLogger,
  });
  assert.equal(rerun.usersUpdated, 0);
  assert.equal(rerun.usersCreated, 0);
  assert.equal(rerun.claimsCleared, 0);
});
