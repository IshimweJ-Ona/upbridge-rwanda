import assert from 'node:assert/strict';
import http from 'node:http';
import test from 'node:test';
import {
  APPROVAL_EMAIL_SUBJECT,
  buildMentorApprovalEmail,
  createEmailSender,
} from './email_service.mjs';
import {
  HttpAuthError,
  deliverMentorApprovalEmail,
  reviewMentorApplicationTx,
  revokeMentorTx,
  verifyAdminActor,
} from './admin_core.mjs';
import { createAdminServer } from './index.mjs';

function createMemoryFirestore(initial = {}) {
  const cols = new Map();
  let autoId = 1;
  const clone = (val) => (val == null ? val : structuredClone(val));

  function ensureCol(name) {
    if (!cols.has(name)) cols.set(name, new Map());
    return cols.get(name);
  }

  for (const [col, docs] of Object.entries(initial)) {
    const map = ensureCol(col);
    for (const [id, data] of Object.entries(docs)) {
      map.set(id, clone(data));
    }
  }

  function makeRef(colName, docId) {
    return {
      colName,
      id: docId,
      async get() {
        const data = ensureCol(colName).get(docId);
        return {
          exists: data !== undefined,
          id: docId,
          data: () => clone(data),
        };
      },
      async set(data, opts) {
        const col = ensureCol(colName);
        if (opts?.merge && col.has(docId)) {
          col.set(docId, { ...col.get(docId), ...clone(data) });
        } else {
          col.set(docId, clone(data));
        }
      },
      async update(patch) {
        const col = ensureCol(colName);
        if (!col.has(docId)) throw new Error(`Missing ${colName}/${docId}`);
        col.set(docId, { ...col.get(docId), ...clone(patch) });
      },
    };
  }

  let txQueue = Promise.resolve();
  return {
    _cols: cols,
    collection(name) {
      return {
        doc(id) {
          const finalId = id || `auto_${autoId++}`;
          return makeRef(name, finalId);
        },
        async add(data) {
          const id = `auto_${autoId++}`;
          await makeRef(name, id).set(data);
          return { id };
        },
      };
    },
    async runTransaction(fn) {
      const tx = {
        get: (ref) => ref.get(),
        set: (ref, data, opts) => ref.set(data, opts),
        update: (ref, patch) => ref.update(patch),
      };
      const run = txQueue.then(() => fn(tx));
      txQueue = run.catch(() => {});
      return run;
    },
  };
}

const FieldValue = {
  serverTimestamp: () => new Date('2026-11-23T15:20:00Z'),
};

test('buildMentorApprovalEmail produces exact SkillBridge approval subject and copy', () => {
  const email = buildMentorApprovalEmail({ mentorName: 'Claire Mukamana' });
  assert.equal(
    email.subject,
    "You're Approved! Welcome to SkillBridge as a Mentor",
  );
  assert.match(email.text, /^Hello Claire Mukamana,/);
  assert.match(email.text, /Your mentor application has been reviewed and approved\./);
  assert.match(email.text, /Welcome to SkillBridge!/);
  assert.match(email.text, /The SkillBridge Team$/);
  assert.match(email.html, /Claire Mukamana/);
});

test('verifyAdminActor blocks missing tokens, non-admins, unverified admins, and demoted/deactivated admins', async () => {
  const db = createMemoryFirestore({
    users: {
      'admin-ok': { role: 'admin', status: 'active' },
      'admin-demoted': { role: 'student', status: 'active' },
      'admin-disabled': { role: 'admin', status: 'deactivated' },
    },
  });
  const auth = {
    async verifyIdToken(token, checkRevoked) {
      assert.equal(checkRevoked, true);
      if (token === 'student-tok') {
        return { uid: 's1', email_verified: true, role: 'student' };
      }
      if (token === 'unverified-admin') {
        return { uid: 'admin-ok', email_verified: false, role: 'admin' };
      }
      if (token === 'demoted-admin') {
        return { uid: 'admin-demoted', email_verified: true, role: 'admin' };
      }
      if (token === 'disabled-admin') {
        return { uid: 'admin-disabled', email_verified: true, role: 'admin' };
      }
      if (token === 'revoked-tok') {
        throw new Error('Firebase ID token has been revoked.');
      }
      return {
        uid: 'admin-ok',
        email: 'authapp05@gmail.com',
        email_verified: true,
        role: 'admin',
      };
    },
  };

  await assert.rejects(
    verifyAdminActor({ auth, db, idToken: '' }),
    (e) => e instanceof HttpAuthError && e.statusCode === 401,
  );
  await assert.rejects(
    verifyAdminActor({ auth, db, idToken: 'revoked-tok' }),
    (e) => e instanceof HttpAuthError && e.statusCode === 401,
  );
  await assert.rejects(
    verifyAdminActor({ auth, db, idToken: 'student-tok' }),
    (e) => e instanceof HttpAuthError && e.statusCode === 403,
  );
  await assert.rejects(
    verifyAdminActor({ auth, db, idToken: 'unverified-admin' }),
    (e) => e instanceof HttpAuthError && e.statusCode === 403,
  );
  await assert.rejects(
    verifyAdminActor({ auth, db, idToken: 'demoted-admin' }),
    (e) => e instanceof HttpAuthError && e.statusCode === 403,
  );
  await assert.rejects(
    verifyAdminActor({ auth, db, idToken: 'disabled-admin' }),
    (e) => e instanceof HttpAuthError && e.statusCode === 403,
  );

  const ok = await verifyAdminActor({ auth, db, idToken: 'valid-admin' });
  assert.equal(ok.uid, 'admin-ok');
  assert.equal(ok.email, 'authapp05@gmail.com');
});

test('approval triggers email once, retry prevents duplicates, and rejection never sends approval email', async () => {
  const db = createMemoryFirestore({
    users: {
      m1: {
        ownerUid: 'm1',
        email: 'claire@skillbridge.rw',
        displayName: 'Claire Mukamana',
        role: 'mentor',
        isApproved: false,
        approvalStatus: 'pending',
        status: 'active',
      },
      m2: {
        ownerUid: 'm2',
        email: 'rejected@skillbridge.rw',
        displayName: 'Rejected User',
        role: 'mentor',
        isApproved: false,
        approvalStatus: 'pending',
        status: 'active',
      },
    },
    mentorApplications: {
      m1: {
        ownerUid: 'm1',
        applicantName: 'Claire Mukamana',
        applicantEmail: 'claire@skillbridge.rw',
        headline: 'Staff Engineer',
        bio: 'Mentoring engineers.',
        expertise: ['Mobile'],
        experienceYears: 6,
        status: 'pending',
      },
      m2: {
        ownerUid: 'm2',
        applicantName: 'Rejected User',
        applicantEmail: 'rejected@skillbridge.rw',
        headline: 'Developer',
        bio: 'Bio text here.',
        expertise: ['Web'],
        experienceYears: 2,
        status: 'pending',
      },
    },
  });

  const claimsSet = [];
  const auth = {
    async getUser() {
      return { customClaims: {} };
    },
    async setCustomUserClaims(uid, claims) {
      claimsSet.push({ uid, claims });
    },
    async revokeRefreshTokens() {},
  };

  const sentEmails = [];
  const failingSender = async () => {
    throw new Error('SMTP connection timeout');
  };
  const succeedingSender = async (msg) => {
    sentEmails.push(msg);
    return {
      configured: true,
      delivered: true,
      provider: 'mock-smtp',
      messageId: 'msg-123',
    };
  };
  const actor = { uid: 'admin-1', email: 'authapp05@gmail.com' };

  // 1. Rejection NEVER triggers approval email.
  const rejectRes = await reviewMentorApplicationTx({
    auth,
    db,
    FieldValue,
    actor,
    applicantUid: 'm2',
    decision: 'rejected',
    reason: 'Needs clearer experience references',
    emailSender: succeedingSender,
  });
  assert.equal(rejectRes.newApprovalStatus, 'rejected');
  assert.equal(sentEmails.length, 0);
  assert.equal(db._cols.get('users').get('m2').role, 'mentor');
  assert.equal(db._cols.get('users').get('m2').approvalStatus, 'rejected');

  // 2. Approval succeeds even if SMTP transport temporarily fails; failure is recorded honestly.
  const firstApprove = await reviewMentorApplicationTx({
    auth,
    db,
    FieldValue,
    actor,
    applicantUid: 'm1',
    decision: 'approved',
    emailSender: failingSender,
  });
  assert.equal(firstApprove.newApprovalStatus, 'approved');
  assert.equal(firstApprove.emailDelivery.status, 'failed');
  assert.equal(firstApprove.emailDelivery.delivered, false);
  assert.equal(db._cols.get('users').get('m1').role, 'mentor');
  assert.equal(db._cols.get('users').get('m1').isApproved, true);
  assert.equal(db._cols.get('users').get('m1').approvalStatus, 'approved');
  assert.equal(db._cols.get('mentorApplications').get('m1').approvalEmailStatus, 'failed');
  assert.equal(claimsSet.length, 1);

  // 3. Safe retry delivers once and marks approvalEmailStatus='sent'.
  const retryOk = await deliverMentorApprovalEmail({
    db,
    FieldValue,
    applicantUid: 'm1',
    recipientEmail: 'claire@skillbridge.rw',
    mentorName: 'Claire Mukamana',
    actorUid: actor.uid,
    actorEmail: actor.email,
    emailSender: succeedingSender,
  });
  assert.equal(retryOk.status, 'sent');
  assert.equal(retryOk.delivered, true);
  assert.equal(sentEmails.length, 1);
  assert.equal(sentEmails[0].to, 'claire@skillbridge.rw');
  assert.equal(sentEmails[0].subject, APPROVAL_EMAIL_SUBJECT);

  // 4. Subsequent retries (or duplicate approve call) NEVER send a duplicate email.
  const retryDup = await deliverMentorApprovalEmail({
    db,
    FieldValue,
    applicantUid: 'm1',
    recipientEmail: 'claire@skillbridge.rw',
    mentorName: 'Claire Mukamana',
    actorUid: actor.uid,
    actorEmail: actor.email,
    emailSender: succeedingSender,
  });
  assert.equal(retryDup.status, 'already_sent');
  assert.equal(sentEmails.length, 1);

  const dupApprove = await reviewMentorApplicationTx({
    auth,
    db,
    FieldValue,
    actor,
    applicantUid: 'm1',
    decision: 'approved',
    emailSender: succeedingSender,
  });
  assert.equal(dupApprove.alreadyApproved, true);
  assert.equal(sentEmails.length, 1);

  // 5. Revocation preserves role='mentor', sets approvalStatus='revoked', hides public profile.
  await revokeMentorTx({
    auth,
    db,
    FieldValue,
    actor,
    targetUid: 'm1',
    reason: 'Policy review hold',
  });
  assert.equal(db._cols.get('users').get('m1').role, 'mentor');
  assert.equal(db._cols.get('users').get('m1').isApproved, false);
  assert.equal(db._cols.get('users').get('m1').approvalStatus, 'revoked');
  assert.equal(db._cols.get('profiles').get('m1').isMentorPublic, false);
});

test('createEmailSender never fakes delivery when unconfigured and calls Resend API with real credentials', async () => {
  const unconfigured = createEmailSender({});
  const unconfRes = await unconfigured({
    to: 'm@skillbridge.rw',
    subject: 'Test',
    text: 'Body',
    html: '<p>Body</p>',
  });
  assert.equal(unconfRes.configured, false);
  assert.equal(unconfRes.delivered, false);

  let called = null;
  const resendSender = createEmailSender(
    {
      RESEND_API_KEY: 're_test_123',
      MAIL_FROM: 'SkillBridge <mentors@skillbridge.rw>',
    },
    async (url, opts) => {
      called = { url, opts };
      return {
        ok: true,
        status: 200,
        async json() {
          return { id: 'resend_id_42' };
        },
      };
    },
  );
  const sent = await resendSender({
    to: 'm@skillbridge.rw',
    subject: APPROVAL_EMAIL_SUBJECT,
    text: 'Hello',
    html: '<p>Hello</p>',
  });
  assert.equal(sent.delivered, true);
  assert.equal(sent.messageId, 'resend_id_42');
  assert.equal(called.url, 'https://api.resend.com/emails');
});

test('HTTP Admin server rejects non-admin requests and serves authorized approvals', async () => {
  const db = createMemoryFirestore({
    users: {
      'admin-1': { role: 'admin', status: 'active' },
      'm-http': {
        ownerUid: 'm-http',
        email: 'mhttp@skillbridge.rw',
        displayName: 'Jean Bosco',
        role: 'mentor',
        isApproved: false,
        approvalStatus: 'pending',
        status: 'active',
      },
    },
    mentorApplications: {
      'm-http': {
        ownerUid: 'm-http',
        applicantName: 'Jean Bosco',
        applicantEmail: 'mhttp@skillbridge.rw',
        headline: 'Data Engineer',
        bio: 'Mentoring youth on SQL and Python.',
        expertise: ['Data'],
        experienceYears: 5,
        status: 'pending',
      },
    },
  });
  const auth = {
    async verifyIdToken(token) {
      if (token === 'admin-jwt') {
        return { uid: 'admin-1', email: 'authapp05@gmail.com', email_verified: true, role: 'admin' };
      }
      return { uid: 's1', email_verified: true, role: 'student' };
    },
    async getUser() {
      return { customClaims: {} };
    },
    async setCustomUserClaims() {},
  };

  const delivered = [];
  const server = createAdminServer({
    auth,
    db,
    FieldValue,
    emailSender: async (msg) => {
      delivered.push(msg);
      return { configured: true, delivered: true, provider: 'test', messageId: 'http-1' };
    },
  });

  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    const addr = server.address();
    const baseUrl = `http://127.0.0.1:${addr.port}`;

    const nonAdminResp = await fetch(`${baseUrl}/admin/review-mentor-application`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer student-jwt',
      },
      body: JSON.stringify({ applicantUid: 'm-http', decision: 'approved' }),
    });
    assert.equal(nonAdminResp.status, 403);
    assert.equal(delivered.length, 0);

    const adminResp = await fetch(`${baseUrl}/admin/review-mentor-application`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer admin-jwt',
      },
      body: JSON.stringify({ applicantUid: 'm-http', decision: 'approved' }),
    });
    assert.equal(adminResp.status, 200);
    const json = await adminResp.json();
    assert.equal(json.newApprovalStatus, 'approved');
    assert.equal(json.emailDelivery.status, 'sent');
    assert.equal(delivered.length, 1);

    const badJsonResp = await fetch(`${baseUrl}/admin/review-mentor-application`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer admin-jwt',
      },
      body: '{invalid-json',
    });
    assert.equal(badJsonResp.status, 400);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

test('concurrent email retries never send duplicate emails, revocation clears approvalEmailStatus, and admins cannot be converted to mentors', async () => {
  const db = createMemoryFirestore({
    users: {
      'm-conc': {
        ownerUid: 'm-conc',
        email: 'conc@skillbridge.rw',
        displayName: 'Concurrent Mentor',
        role: 'mentor',
        isApproved: true,
        approvalStatus: 'approved',
        status: 'active',
      },
      'admin-target': {
        ownerUid: 'admin-target',
        email: 'admin2@skillbridge.rw',
        displayName: 'Other Admin',
        role: 'admin',
        isApproved: true,
        approvalStatus: 'approved',
        status: 'active',
      },
    },
    mentorApplications: {
      'm-conc': {
        ownerUid: 'm-conc',
        applicantName: 'Concurrent Mentor',
        applicantEmail: 'conc@skillbridge.rw',
        status: 'approved',
      },
      'admin-target': {
        ownerUid: 'admin-target',
        applicantName: 'Other Admin',
        applicantEmail: 'admin2@skillbridge.rw',
        status: 'pending',
      },
    },
    profiles: {
      'm-conc': { ownerUid: 'm-conc', isMentorPublic: true },
    },
  });
  const auth = {
    async getUser() {
      return { customClaims: { role: 'mentor' } };
    },
    async setCustomUserClaims() {},
    async revokeRefreshTokens() {},
  };
  const actor = { uid: 'admin-1', email: 'authapp05@gmail.com' };

  let sendCount = 0;
  const slowSender = async () => {
    sendCount += 1;
    await new Promise((r) => setTimeout(r, 25));
    return { configured: true, delivered: true, provider: 'resend', messageId: 'conc-1' };
  };

  const [r1, r2] = await Promise.all([
    deliverMentorApprovalEmail({
      db,
      FieldValue,
      applicantUid: 'm-conc',
      recipientEmail: 'conc@skillbridge.rw',
      mentorName: 'Concurrent Mentor',
      actorUid: actor.uid,
      actorEmail: actor.email,
      emailSender: slowSender,
    }),
    deliverMentorApprovalEmail({
      db,
      FieldValue,
      applicantUid: 'm-conc',
      recipientEmail: 'conc@skillbridge.rw',
      mentorName: 'Concurrent Mentor',
      actorUid: actor.uid,
      actorEmail: actor.email,
      emailSender: slowSender,
    }),
  ]);
  assert.equal(sendCount, 1);
  assert.ok([r1.status, r2.status].includes('sent'));
  assert.ok([r1.status, r2.status].includes('in_progress'));

  // Revocation resets approvalEmailStatus so future re-approval can deliver a fresh email.
  await revokeMentorTx({
    auth,
    db,
    FieldValue,
    actor,
    targetUid: 'm-conc',
    reason: 'Temporary compliance hold',
  });
  assert.equal(db._cols.get('mentorApplications').get('m-conc').status, 'revoked');
  assert.equal(db._cols.get('mentorApplications').get('m-conc').approvalEmailStatus, '');

  // Administrator accounts cannot be converted to mentor.
  await assert.rejects(
    reviewMentorApplicationTx({
      auth,
      db,
      FieldValue,
      actor,
      applicantUid: 'admin-target',
      decision: 'approved',
      emailSender: slowSender,
    }),
    (e) => e instanceof HttpAuthError && e.statusCode === 409,
  );
  assert.equal(db._cols.get('users').get('admin-target').role, 'admin');
});
