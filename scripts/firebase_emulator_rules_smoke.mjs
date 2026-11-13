// Exercises real Firestore rules against disposable Auth/Firestore emulators.
const projectId = 'demo-upbridge-jonathan';
const authBase = `http://127.0.0.1:${process.env.UPBRIDGE_AUTH_EMULATOR_PORT ?? '9099'}`;
const firestoreBase = `http://127.0.0.1:${process.env.UPBRIDGE_FIRESTORE_EMULATOR_PORT ?? '8080'}`;
const apiKey = 'emulator-only-key';

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

async function main() {
  const email = `jonathan-rules-${Date.now()}@example.test`;
  let localId;
  try {
    const created = await authCall('accounts:signUp', {
      email,
      password: 'EmulatorOnly-12345',
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
      password: 'EmulatorOnly-12345',
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

    const foreignWrite = await firestoreCall('users/another-user', {
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

    console.log('PASS: unverified writes denied; verified owner write allowed; foreign write denied.');
  } finally {
    // Emulator-only endpoints clear all test documents and Auth accounts for this demo project.
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
