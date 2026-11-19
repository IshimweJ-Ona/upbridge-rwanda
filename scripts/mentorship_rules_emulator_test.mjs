// Mentorship rules (mentorSessions, mentorProfiles) against the Auth/Firestore
// emulators. Run with scripts/test_mentorship_rules.ps1. Never point this at
// a real project: it refuses any project ID that does not start with demo-.
import { randomBytes, randomUUID } from 'node:crypto';

const projectId = process.env.UPBRIDGE_FIREBASE_EMULATOR_PROJECT_ID;
const authBase = `http://127.0.0.1:${process.env.UPBRIDGE_AUTH_EMULATOR_PORT ?? '9099'}`;
const firestoreBase = `http://127.0.0.1:${process.env.UPBRIDGE_FIRESTORE_EMULATOR_PORT ?? '8080'}`;
const apiKey = 'emulator-only-key';
const docs = `projects/${projectId}/databases/(default)/documents`;

if (!projectId?.startsWith('demo-')) {
  throw new Error('The mentorship rules test requires a demo-* emulator project ID.');
}

// ── HTTP helpers ──

async function request(url, options = {}) {
  const response = await fetch(url, options);
  const text = await response.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  return { status: response.status, data };
}

const post = (url, body, token) =>
  request(url, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  });

const authCall = (method, payload) =>
  post(`${authBase}/identitytoolkit.googleapis.com/v1/${method}?key=${apiKey}`, payload);

/** Signs up and verifies an email user; returns { uid, token }. */
async function verifiedUser(label) {
  const email = `${label}-${randomUUID()}@example.test`;
  const password = `Emulator-${randomBytes(12).toString('hex')}`;
  const created = await authCall('accounts:signUp', { email, password, returnSecureToken: true });
  ensure(created.status === 200, `signup failed for ${label}`);
  await authCall('accounts:sendOobCode', { requestType: 'VERIFY_EMAIL', idToken: created.data.idToken });
  const codes = await request(`${authBase}/emulator/v1/projects/${projectId}/oobCodes`);
  const code = codes.data?.oobCodes?.find((c) => c.email === email && c.requestType === 'VERIFY_EMAIL')?.oobCode;
  ensure(code, `no verification code for ${label}`);
  await authCall('accounts:update', { oobCode: code });
  const signedIn = await authCall('accounts:signInWithPassword', { email, password, returnSecureToken: true });
  ensure(signedIn.status === 200, `sign-in failed for ${label}`);
  return { uid: created.data.localId, token: signedIn.data.idToken };
}

// ── Firestore value encoding ──

function encode(value) {
  if (value === null) return { nullValue: null };
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value) ? { integerValue: String(value) } : { doubleValue: value };
  }
  if (typeof value === 'string') return { stringValue: value };
  if (Array.isArray(value)) return { arrayValue: { values: value.map(encode) } };
  return { mapValue: { fields: fields(value) } };
}

const fields = (obj) => Object.fromEntries(Object.entries(obj).map(([k, v]) => [k, encode(v)]));

/**
 * One write. `now` lists fields set to the server time (request.time), like
 * FieldValue.serverTimestamp() in the app. `mask` makes it an update.
 */
function write(path, data, { now = [], mask, exists } = {}) {
  return {
    update: { name: `${docs}/${path}`, fields: fields(data) },
    ...(mask ? { updateMask: { fieldPaths: mask.filter((f) => !now.includes(f)) } } : {}),
    ...(now.length ? { updateTransforms: now.map((f) => ({ fieldPath: f, setToServerValue: 'REQUEST_TIME' })) } : {}),
    ...(exists === undefined ? {} : { currentDocument: { exists } }),
  };
}

const commit = (writes, token) => post(`${firestoreBase}/v1/${docs}:commit`, { writes }, token);

/** Admin-style seed that bypasses rules (emulator only). */
const seed = (path, data) => commit([write(path, data)], 'owner');

const create = (path, data, token, now = ['createdAt', 'updatedAt']) =>
  commit([write(path, data, { now, exists: false })], token);

const update = (path, changes, token, now = ['updatedAt']) =>
  commit([write(path, changes, { now, mask: [...Object.keys(changes), ...now], exists: true })], token);

const remove = (path, token) => commit([{ delete: `${docs}/${path}` }], token);

const read = (path, token) =>
  request(`${firestoreBase}/v1/${docs}/${path}`, { headers: { authorization: `Bearer ${token}` } });

const query = (collection, field, value, token) =>
  post(`${firestoreBase}/v1/${docs}:runQuery`, {
    structuredQuery: {
      from: [{ collectionId: collection }],
      where: { fieldFilter: { field: { fieldPath: field }, op: 'EQUAL', value: encode(value) } },
      limit: 200,
    },
  }, token);

// ── Test runner ──

function ensure(condition, message) {
  if (!condition) throw new Error(message);
}

const results = [];

async function check(name, action, expected) {
  const { status, data } = await action();
  const ok = status === expected;
  results.push({ name, ok });
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${ok ? '' : `  (expected ${expected}, got ${status}: ${JSON.stringify(data)?.slice(0, 200)})`}`);
}

const allowed = (name, action) => check(name, action, 200);
const denied = (name, action) => check(name, action, 403);

async function main() {
  const youth = await verifiedUser('youth');
  const otherYouth = await verifiedUser('other-youth');
  const mentor = await verifiedUser('mentor');
  const otherMentor = await verifiedUser('other-mentor');
  const unverifiedMentor = await verifiedUser('unverified-mentor');
  const fullMentor = await verifiedUser('full-mentor');

  const profile = (name, extra = {}) => ({
    displayName: name,
    title: 'Data analyst',
    verified: true,
    accepting: true,
    reviewsCount: 12,
    ...extra,
  });
  await seed(`mentorProfiles/${mentor.uid}`, profile('Alice'));
  await seed(`mentorProfiles/${otherMentor.uid}`, profile('Bob'));
  await seed(`mentorProfiles/${unverifiedMentor.uid}`, profile('Carol', { verified: false }));
  await seed(`mentorProfiles/${fullMentor.uid}`, profile('Dan', { accepting: false }));

  const inTwoDays = new Date(Date.now() + 2 * 24 * 3600 * 1000);
  const request_ = (mentorId, extra = {}) => ({
    requesterId: youth.uid,
    requesterName: 'Jean',
    mentorId,
    mentorName: 'Alice',
    topic: 'Career advice',
    note: '',
    startsAt: inTwoDays,
    durationMinutes: 30,
    mode: 'Google Meet',
    status: 'requested',
    ...extra,
  });
  const sid = () => `s-${randomUUID()}`;

  console.log('\nmentorSessions · create');
  const s1 = sid();
  await allowed('youth requests a session with a verified mentor', () => create(`mentorSessions/${s1}`, request_(mentor.uid), youth.token));
  await denied('cannot request as someone else', () => create(`mentorSessions/${sid()}`, request_(mentor.uid, { requesterId: otherYouth.uid }), youth.token));
  await denied('cannot create an already confirmed session', () => create(`mentorSessions/${sid()}`, request_(mentor.uid, { status: 'confirmed' }), youth.token));
  await denied('cannot book an unverified mentor', () => create(`mentorSessions/${sid()}`, request_(unverifiedMentor.uid), youth.token));
  await denied('cannot book a mentor who is not accepting', () => create(`mentorSessions/${sid()}`, request_(fullMentor.uid), youth.token));
  await denied('cannot book a missing mentor', () => create(`mentorSessions/${sid()}`, request_('no-such-mentor'), youth.token));
  await denied('cannot book a time in the past', () => create(`mentorSessions/${sid()}`, request_(mentor.uid, { startsAt: new Date(Date.now() - 3600 * 1000) }), youth.token));
  await denied('cannot add extra fields like a meeting link', () => create(`mentorSessions/${sid()}`, request_(mentor.uid, { meetingLink: 'https://evil.example' }), youth.token));
  await denied('cannot send an empty or long topic', () => create(`mentorSessions/${sid()}`, request_(mentor.uid, { topic: 'x'.repeat(81) }), youth.token));
  await denied('mentor cannot book themselves', () => create(`mentorSessions/${sid()}`, { ...request_(mentor.uid), requesterId: mentor.uid }, mentor.token));
  await denied('signed-out users cannot request', () => create(`mentorSessions/${sid()}`, request_(mentor.uid), undefined));

  console.log('\nmentorSessions · read');
  await allowed('youth reads their session', () => read(`mentorSessions/${s1}`, youth.token));
  await allowed('mentor reads a session booked with them', () => read(`mentorSessions/${s1}`, mentor.token));
  await denied('another youth cannot read it', () => read(`mentorSessions/${s1}`, otherYouth.token));
  await denied('another mentor cannot read it', () => read(`mentorSessions/${s1}`, otherMentor.token));
  await allowed('mentor lists sessions where mentorId is them', () => query('mentorSessions', 'mentorId', mentor.uid, mentor.token));
  await denied('mentor cannot list another mentor\'s sessions', () => query('mentorSessions', 'mentorId', mentor.uid, otherMentor.token));

  console.log('\nmentorSessions · status changes');
  await denied('youth cannot confirm their own request', () => update(`mentorSessions/${s1}`, { status: 'confirmed' }, youth.token));
  await denied('another mentor cannot confirm it', () => update(`mentorSessions/${s1}`, { status: 'confirmed' }, otherMentor.token));
  await denied('mentor cannot skip straight to completed', () => update(`mentorSessions/${s1}`, { status: 'completed' }, mentor.token));
  await denied('mentor cannot change the topic', () => update(`mentorSessions/${s1}`, { status: 'confirmed', topic: 'Something else' }, mentor.token));
  await denied('meeting link must be https', () => update(`mentorSessions/${s1}`, { status: 'confirmed', meetingLink: 'http://meet.example/x' }, mentor.token));
  await allowed('mentor confirms with a meeting link', () => update(`mentorSessions/${s1}`, { status: 'confirmed', meetingLink: 'https://meet.google.com/abc-defg-hij' }, mentor.token));
  await denied('mentor cannot change the link after confirming', () => update(`mentorSessions/${s1}`, { status: 'completed', meetingLink: 'https://other.example' }, mentor.token));
  await denied('youth cannot withdraw a confirmed session', () => remove(`mentorSessions/${s1}`, youth.token));
  await allowed('mentor completes a confirmed session', () => update(`mentorSessions/${s1}`, { status: 'completed' }, mentor.token));
  await denied('a completed session cannot be cancelled', () => update(`mentorSessions/${s1}`, { status: 'cancelled' }, mentor.token));
  await denied('youth cannot cancel a completed session', () => update(`mentorSessions/${s1}`, { status: 'cancelled' }, youth.token));

  const s2 = sid();
  await create(`mentorSessions/${s2}`, request_(mentor.uid), youth.token);
  await allowed('mentor declines a request', () => update(`mentorSessions/${s2}`, { status: 'declined' }, mentor.token));
  await denied('a declined request cannot be confirmed later', () => update(`mentorSessions/${s2}`, { status: 'confirmed' }, mentor.token));

  const s3 = sid();
  await create(`mentorSessions/${s3}`, request_(mentor.uid), youth.token);
  await update(`mentorSessions/${s3}`, { status: 'confirmed' }, mentor.token);
  await denied('youth can only cancel, not complete', () => update(`mentorSessions/${s3}`, { status: 'completed' }, youth.token));
  await allowed('youth cancels a confirmed session', () => update(`mentorSessions/${s3}`, { status: 'cancelled' }, youth.token));

  const s4 = sid();
  await create(`mentorSessions/${s4}`, request_(mentor.uid), youth.token);
  await denied('mentor cannot delete a request', () => remove(`mentorSessions/${s4}`, mentor.token));
  await denied('another youth cannot withdraw it', () => remove(`mentorSessions/${s4}`, otherYouth.token));
  await allowed('youth withdraws a pending request', () => remove(`mentorSessions/${s4}`, youth.token));

  console.log('\nmentorProfiles');
  const editable = {
    accepting: false,
    meetingLink: 'https://meet.google.com/abc-defg-hij',
    menteeLimit: 4,
    availabilityWindows: [{ weekday: 2, startMinutes: 1080, endMinutes: 1200 }],
    availability: 'Tuesday · 18:00–20:00',
    openSlots: [inTwoDays],
  };
  await allowed('anyone signed in can read a mentor profile', () => read(`mentorProfiles/${mentor.uid}`, youth.token));
  await allowed('mentor updates their availability and settings', () => update(`mentorProfiles/${mentor.uid}`, editable, mentor.token));
  await denied('mentor cannot verify themselves', () => update(`mentorProfiles/${unverifiedMentor.uid}`, { verified: true }, unverifiedMentor.token));
  await denied('mentor cannot change their review count', () => update(`mentorProfiles/${mentor.uid}`, { reviewsCount: 999 }, mentor.token));
  await denied('mentor cannot edit another mentor', () => update(`mentorProfiles/${otherMentor.uid}`, editable, mentor.token));
  await denied('youth cannot edit a mentor profile', () => update(`mentorProfiles/${mentor.uid}`, { accepting: true }, youth.token));
  await denied('meeting link must be https', () => update(`mentorProfiles/${mentor.uid}`, { meetingLink: 'meet.google.com/abc' }, mentor.token));
  await denied('mentee limit stays between 1 and 10', () => update(`mentorProfiles/${mentor.uid}`, { menteeLimit: 0 }, mentor.token));
  await denied('updatedAt must be the server time', () => update(`mentorProfiles/${mentor.uid}`, { accepting: true, updatedAt: new Date(0) }, mentor.token, []));
  await denied('a user cannot create their own mentor profile', () => create(`mentorProfiles/${youth.uid}`, profile('Jean'), youth.token, []));

  const failed = results.filter((r) => !r.ok);
  console.log(`\n${results.length - failed.length} passed, ${failed.length} failed`);
  if (failed.length) process.exitCode = 1;
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    // Remove this run's data from the disposable emulator project.
    await request(`${firestoreBase}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: 'DELETE' });
    await request(`${authBase}/emulator/v1/projects/${projectId}/accounts`, { method: 'DELETE' });
  });
