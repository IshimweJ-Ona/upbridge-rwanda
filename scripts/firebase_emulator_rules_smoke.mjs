// Exercises real Firestore rules against disposable Auth/Firestore emulators.
import { randomBytes, randomUUID } from 'node:crypto';

const projectId = process.env.UPBRIDGE_FIREBASE_EMULATOR_PROJECT_ID;
const authBase = `http://127.0.0.1:${process.env.UPBRIDGE_AUTH_EMULATOR_PORT ?? '9099'}`;
const firestoreBase = `http://127.0.0.1:${process.env.UPBRIDGE_FIRESTORE_EMULATOR_PORT ?? '8080'}`;
const apiKey = process.env.UPBRIDGE_FIREBASE_API_KEY ?? 'emulator-only-key';

if (!projectId?.startsWith('demo-')) {
  throw new Error('The rules smoke test requires a demo-* emulator project ID.');
}

async function request(url, options = {}) {
  const response = await fetch(url, options);
  const body = await response.text();
  let data;
  try {
    data = body ? JSON.parse(body) : null;
  } catch {
    data = body;
  }
  return { status: response.status, data };
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

async function authCall(method, payload) {
  return request(
    `${authBase}/identitytoolkit.googleapis.com/v1/${method}?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(payload),
    },
  );
}

async function firestoreCall(path, { token, method = 'GET', body } = {}) {
  return request(`${firestoreBase}/v1/projects/${projectId}/databases/(default)/documents/${path}`, {
    method,
    headers: {
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'content-type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
}

async function firestoreCommit(writes, token) {
  return request(
    `${firestoreBase}/v1/projects/${projectId}/databases/(default)/documents:commit`,
    {
      method: 'POST',
      headers: {
        authorization: `Bearer ${token}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({ writes }),
    },
  );
}

async function main() {
  const runId = randomUUID();
  const email = `jonathan-rules-${runId}@example.test`;
  const password = `Emulator-${randomBytes(18).toString('hex')}`;
  let localId;
  try {
    const created = await authCall('accounts:signUp', {
      email,
      password,
      returnSecureToken: true,
    });
    assert(created.status === 200, `Auth emulator signup failed: ${JSON.stringify(created.data)}`);
    localId = created.data.localId;

    const unverifiedWrite = await firestoreCall(`users/${localId}`, {
      token: created.data.idToken,
      method: 'PATCH',
      body: {
        fields: {
          role: { stringValue: 'youth' },
          accountStatus: { stringValue: 'active' },
        },
      },
    });
    assert(unverifiedWrite.status === 403, 'Unverified user unexpectedly wrote a profile.');

    const verificationRequest = await authCall('accounts:sendOobCode', {
      requestType: 'VERIFY_EMAIL',
      idToken: created.data.idToken,
    });
    assert(verificationRequest.status === 200, `Verification request failed: ${JSON.stringify(verificationRequest.data)}`);
    const pendingCodes = await request(`${authBase}/emulator/v1/projects/${projectId}/oobCodes`);
    const verificationCode = pendingCodes.data?.oobCodes?.find(
      (entry) => entry.email === email && entry.requestType === 'VERIFY_EMAIL',
    )?.oobCode;
    assert(verificationCode, 'Auth Emulator did not expose its verification code.');
    const verified = await authCall('accounts:update', { oobCode: verificationCode });
    assert(verified.status === 200, `Email verification failed: ${JSON.stringify(verified.data)}`);
    const signedIn = await authCall('accounts:signInWithPassword', {
      email,
      password,
      returnSecureToken: true,
    });
    assert(signedIn.status === 200, `Verified account sign-in failed: ${JSON.stringify(signedIn.data)}`);
    const tokenClaims = JSON.parse(Buffer.from(signedIn.data.idToken.split('.')[1], 'base64url'));
    assert(tokenClaims.email_verified === true, 'Auth Emulator did not issue a verified token.');

    const ownWrite = await firestoreCall(`users/${localId}`, {
      token: signedIn.data.idToken,
      method: 'PATCH',
      body: {
        fields: {
          role: { stringValue: 'youth' },
          accountStatus: { stringValue: 'active' },
        },
      },
    });
    assert(ownWrite.status === 200, `Verified owner write denied: ${JSON.stringify(ownWrite.data)}`);

    const monthKey = new Date().toISOString().slice(0, 7);
    const checkInId = `${localId}_${monthKey}`;
    const checkInName = `projects/${projectId}/databases/(default)/documents/checkIns/${checkInId}`;
    const checkInFields = {
      userId: { stringValue: localId },
      monthKey: { stringValue: monthKey },
      usefulness: { integerValue: '5' },
      applied: { booleanValue: true },
      changeNote: { stringValue: 'Applied the feedback to my project.' },
    };
    const validCheckIn = await firestoreCommit([
      {
        update: { name: checkInName, fields: checkInFields },
        updateTransforms: [
          { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
        ],
      },
    ], signedIn.data.idToken);
    assert(
      validCheckIn.status === 200,
      `Valid check-in denied: ${JSON.stringify(validCheckIn.data)}`,
    );

    const savedCheckIn = await firestoreCall(`checkIns/${checkInId}`, {
      token: signedIn.data.idToken,
    });
    assert(savedCheckIn.status === 200, 'Owner could not read their check-in.');
    assert(
      savedCheckIn.data.fields?.userId?.stringValue === localId,
      'Check-in owner was not persisted.',
    );

    const duplicateCheckIn = await firestoreCommit([
      {
        update: { name: checkInName, fields: checkInFields },
        updateTransforms: [
          { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
        ],
      },
    ], signedIn.data.idToken);
    assert(duplicateCheckIn.status === 403, 'User unexpectedly replaced a submitted check-in.');

    const editedCheckIn = await firestoreCall(`checkIns/${checkInId}`, {
      token: signedIn.data.idToken,
      method: 'PATCH',
      body: { fields: { usefulness: { integerValue: '1' } } },
    });
    assert(editedCheckIn.status === 403, 'User unexpectedly edited a submitted check-in.');

    const invalidCheckIn = await firestoreCommit([
      {
        update: {
          name: `projects/${projectId}/databases/(default)/documents/checkIns/${localId}_not-a-month`,
          fields: {
            ...checkInFields,
            monthKey: { stringValue: 'not-a-month' },
          },
        },
        updateTransforms: [
          { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
        ],
      },
    ], signedIn.data.idToken);
    assert(invalidCheckIn.status === 403, 'Firestore rules accepted an invalid check-in.');

    const foreignWrite = await firestoreCall(`users/${runId}-another-user`, {
      token: signedIn.data.idToken,
      method: 'PATCH',
      body: {
        fields: {
          role: { stringValue: 'youth' },
          accountStatus: { stringValue: 'active' },
        },
      },
    });
    assert(foreignWrite.status === 403, 'User unexpectedly wrote another user profile.');

    console.log(
      'PASS: verification required; owner profile and valid check-in allowed; foreign profile, invalid, duplicate, and edited check-ins denied.',
    );
  } finally {
    // Clear all data only inside this run's disposable demo project.
    await request(`${firestoreBase}/emulator/v1/projects/${projectId}/databases/(default)/documents`, {
      method: 'DELETE',
    });
    await request(`${authBase}/emulator/v1/projects/${projectId}/accounts`, { method: 'DELETE' });
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
