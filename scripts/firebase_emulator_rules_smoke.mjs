// Exercises real Firestore rules against disposable Auth and Firestore emulators.
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

async function authCall(method, payload, { admin = false } = {}) {
  return request(
    `${authBase}/identitytoolkit.googleapis.com/v1/${method}?key=${apiKey}`,
    {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        ...(admin ? { authorization: 'Bearer owner' } : {}),
      },
      body: JSON.stringify(payload),
    },
  );
}

async function firestoreCall(path, { token, method = 'GET', body } = {}) {
  return request(
    `${firestoreBase}/v1/projects/${projectId}/databases/(default)/documents/${path}`,
    {
      method,
      headers: {
        ...(token ? { authorization: `Bearer ${token}` } : {}),
        ...(body ? { 'content-type': 'application/json' } : {}),
      },
      ...(body ? { body: JSON.stringify(body) } : {}),
    },
  );
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

async function createVerifiedUser(email, password) {
  const created = await authCall('accounts:signUp', {
    email,
    password,
    returnSecureToken: true,
  });
  assert(
    created.status === 200,
    `Auth emulator signup failed: ${JSON.stringify(created.data)}`,
  );
  const uid = created.data.localId;

  const unverifiedWrite = await firestoreCall(`users/${uid}`, {
    token: created.data.idToken,
    method: 'PATCH',
    body: {
      fields: {
        role: { stringValue: 'youth' },
        accountStatus: { stringValue: 'active' },
      },
    },
  });
  assert(
    unverifiedWrite.status === 403,
    'Unverified user unexpectedly wrote a profile.',
  );

  const verificationRequest = await authCall('accounts:sendOobCode', {
    requestType: 'VERIFY_EMAIL',
    idToken: created.data.idToken,
  });
  assert(
    verificationRequest.status === 200,
    `Verification request failed: ${JSON.stringify(verificationRequest.data)}`,
  );
  const pendingCodes = await request(
    `${authBase}/emulator/v1/projects/${projectId}/oobCodes`,
  );
  const verificationCode = pendingCodes.data?.oobCodes?.find(
    (entry) => entry.email === email && entry.requestType === 'VERIFY_EMAIL',
  )?.oobCode;
  assert(
    verificationCode,
    'Auth Emulator did not expose its verification code.',
  );

  const verified = await authCall('accounts:update', {
    oobCode: verificationCode,
  });
  assert(
    verified.status === 200,
    `Email verification failed: ${JSON.stringify(verified.data)}`,
  );
  const signedIn = await authCall('accounts:signInWithPassword', {
    email,
    password,
    returnSecureToken: true,
  });
  assert(
    signedIn.status === 200,
    `Verified account sign-in failed: ${JSON.stringify(signedIn.data)}`,
  );
  const tokenClaims = JSON.parse(
    Buffer.from(signedIn.data.idToken.split('.')[1], 'base64url'),
  );
  assert(
    tokenClaims.email_verified === true,
    'Auth Emulator did not issue a verified token.',
  );
  return { uid, idToken: signedIn.data.idToken };
}

async function main() {
  const runId = randomUUID();
  const password = `Emulator-${randomBytes(18).toString('hex')}`;
  const youthEmail = `jonathan-youth-${runId}@example.test`;
  const adminEmail = `jonathan-admin-${runId}@example.test`;

  try {
    const youth = await createVerifiedUser(youthEmail, password);
    const localId = youth.uid;

    // 1. Youth cannot self-promote to admin or create another user's document.
    const adminCreateAttempt = await firestoreCall(`users/${localId}`, {
      token: youth.idToken,
      method: 'PATCH',
      body: {
        fields: {
          role: { stringValue: 'admin' },
          accountStatus: { stringValue: 'active' },
        },
      },
    });
    assert(
      adminCreateAttempt.status === 403,
      'Youth user unexpectedly created an admin profile.',
    );

    const ownWrite = await firestoreCall(`users/${localId}`, {
      token: youth.idToken,
      method: 'PATCH',
      body: {
        fields: {
          role: { stringValue: 'youth' },
          accountStatus: { stringValue: 'active' },
        },
      },
    });
    assert(
      ownWrite.status === 200,
      `Verified owner write denied: ${JSON.stringify(ownWrite.data)}`,
    );

    // Owner can update allowed profile fields but cannot escalate role.
    const ownerProfileUpdate = await firestoreCall(
      `users/${localId}?updateMask.fieldPaths=displayName&updateMask.fieldPaths=onboarded`,
      {
        token: youth.idToken,
        method: 'PATCH',
        body: {
          fields: {
            displayName: { stringValue: 'Test Youth' },
            onboarded: { booleanValue: true },
          },
        },
      },
    );
    assert(
      ownerProfileUpdate.status === 200,
      `Allowed owner profile update denied: ${JSON.stringify(ownerProfileUpdate.data)}`,
    );

    const roleEscalation = await firestoreCall(
      `users/${localId}?updateMask.fieldPaths=role`,
      {
        token: youth.idToken,
        method: 'PATCH',
        body: { fields: { role: { stringValue: 'admin' } } },
      },
    );
    assert(
      roleEscalation.status === 403,
      'Youth user unexpectedly escalated their role.',
    );

    const foreignWrite = await firestoreCall(`users/${runId}-another-user`, {
      token: youth.idToken,
      method: 'PATCH',
      body: {
        fields: {
          role: { stringValue: 'youth' },
          accountStatus: { stringValue: 'active' },
        },
      },
    });
    assert(
      foreignWrite.status === 403,
      'User unexpectedly wrote another user profile.',
    );

    // 2. Check-ins: owner create allowed once, edits/duplicates/malformed denied.
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
    const validCheckIn = await firestoreCommit(
      [
        {
          update: { name: checkInName, fields: checkInFields },
          updateTransforms: [
            { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
          ],
        },
      ],
      youth.idToken,
    );
    assert(
      validCheckIn.status === 200,
      `Valid check-in denied: ${JSON.stringify(validCheckIn.data)}`,
    );

    const savedCheckIn = await firestoreCall(`checkIns/${checkInId}`, {
      token: youth.idToken,
    });
    assert(savedCheckIn.status === 200, 'Owner could not read their check-in.');
    assert(
      savedCheckIn.data.fields?.userId?.stringValue === localId,
      'Check-in owner was not persisted.',
    );

    const duplicateCheckIn = await firestoreCommit(
      [
        {
          update: { name: checkInName, fields: checkInFields },
          updateTransforms: [
            { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
          ],
        },
      ],
      youth.idToken,
    );
    assert(
      duplicateCheckIn.status === 403,
      'User unexpectedly replaced a submitted check-in.',
    );

    const editedCheckIn = await firestoreCall(`checkIns/${checkInId}`, {
      token: youth.idToken,
      method: 'PATCH',
      body: { fields: { usefulness: { integerValue: '1' } } },
    });
    assert(
      editedCheckIn.status === 403,
      'User unexpectedly edited a submitted check-in.',
    );

    const invalidCheckIn = await firestoreCommit(
      [
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
      ],
      youth.idToken,
    );
    assert(
      invalidCheckIn.status === 403,
      'Firestore rules accepted an invalid check-in.',
    );

    // 3. Notifications: owner read & markRead allowed, tamper/create/delete denied.
    const ownNotifId = `notif-own-${runId}`;
    const foreignNotifId = `notif-other-${runId}`;
    for (const [id, owner] of [
      [ownNotifId, localId],
      [foreignNotifId, `other-${runId}`],
    ]) {
      const seeded = await firestoreCall(`notifications/${id}`, {
        token: 'owner',
        method: 'PATCH',
        body: {
          fields: {
            userId: { stringValue: owner },
            title: { stringValue: 'Review ready' },
            body: { stringValue: 'Check your project feedback.' },
            isRead: { booleanValue: false },
          },
        },
      });
      assert(seeded.status === 200, `Failed seeding notification ${id}.`);
    }

    const clientCreateNotif = await firestoreCall(`notifications/spoof-${runId}`, {
      token: youth.idToken,
      method: 'PATCH',
      body: {
        fields: {
          userId: { stringValue: localId },
          title: { stringValue: 'Fake' },
          isRead: { booleanValue: false },
        },
      },
    });
    assert(
      clientCreateNotif.status === 403,
      'Client unexpectedly created a notification.',
    );

    const readForeignNotif = await firestoreCall(
      `notifications/${foreignNotifId}`,
      { token: youth.idToken },
    );
    assert(
      readForeignNotif.status === 403,
      'Youth user unexpectedly read another user notification.',
    );

    const tamperNotif = await firestoreCommit(
      [
        {
          update: {
            name: `projects/${projectId}/databases/(default)/documents/notifications/${ownNotifId}`,
            fields: {
              userId: { stringValue: localId },
              title: { stringValue: 'Tampered title' },
              body: { stringValue: 'Check your project feedback.' },
              isRead: { booleanValue: true },
            },
          },
          updateTransforms: [
            { fieldPath: 'readAt', setToServerValue: 'REQUEST_TIME' },
          ],
          updateMask: { fieldPaths: ['title', 'isRead', 'readAt'] },
        },
      ],
      youth.idToken,
    );
    assert(
      tamperNotif.status === 403,
      'Owner unexpectedly tampered with notification fields other than isRead/readAt.',
    );

    const markRead = await firestoreCommit(
      [
        {
          update: {
            name: `projects/${projectId}/databases/(default)/documents/notifications/${ownNotifId}`,
            fields: {
              userId: { stringValue: localId },
              title: { stringValue: 'Review ready' },
              body: { stringValue: 'Check your project feedback.' },
              isRead: { booleanValue: true },
            },
          },
          updateTransforms: [
            { fieldPath: 'readAt', setToServerValue: 'REQUEST_TIME' },
          ],
          updateMask: { fieldPaths: ['isRead', 'readAt'] },
        },
      ],
      youth.idToken,
    );
    assert(
      markRead.status === 200,
      `Owner markRead failed: ${JSON.stringify(markRead.data)}`,
    );

    // 4. Admin custom claim enforcement, auditLogs, appSettings, and immutability.
    const adminUser = await createVerifiedUser(adminEmail, password);
    const claimSet = await authCall(
      'accounts:update',
      {
        localId: adminUser.uid,
        customAttributes: JSON.stringify({ role: 'admin' }),
      },
      { admin: true },
    );
    assert(
      claimSet.status === 200,
      `Setting admin claim failed: ${JSON.stringify(claimSet.data)}`,
    );
    const adminSignedIn = await authCall('accounts:signInWithPassword', {
      email: adminEmail,
      password,
      returnSecureToken: true,
    });
    assert(adminSignedIn.status === 200, 'Admin re-signin failed.');
    const adminToken = adminSignedIn.data.idToken;
    const adminClaims = JSON.parse(
      Buffer.from(adminToken.split('.')[1], 'base64url'),
    );
    assert(
      adminClaims.role === 'admin',
      'Admin token did not carry role custom claim.',
    );

    // Admin must NOT be allowed to mutate immutable checkIns or forge/delete notifications.
    const adminEditCheckIn = await firestoreCall(`checkIns/${checkInId}`, {
      token: adminToken,
      method: 'PATCH',
      body: { fields: { usefulness: { integerValue: '2' } } },
    });
    assert(
      adminEditCheckIn.status === 403,
      'Admin unexpectedly mutated an immutable check-in.',
    );

    const adminDeleteNotif = await firestoreCall(`notifications/${ownNotifId}`, {
      token: adminToken,
      method: 'DELETE',
    });
    assert(
      adminDeleteNotif.status === 403,
      'Admin unexpectedly deleted a notification.',
    );

    // Audit logs & app settings boundaries.
    const seededAudit = await firestoreCall(`auditLogs/audit-${runId}`, {
      token: 'owner',
      method: 'PATCH',
      body: { fields: { action: { stringValue: 'seed' } } },
    });
    assert(seededAudit.status === 200, 'Failed seeding auditLog.');

    const youthReadAudit = await firestoreCall(`auditLogs/audit-${runId}`, {
      token: youth.idToken,
    });
    assert(youthReadAudit.status === 403, 'Youth read auditLogs.');

    const adminReadAudit = await firestoreCall(`auditLogs/audit-${runId}`, {
      token: adminToken,
    });
    assert(adminReadAudit.status === 200, 'Admin denied reading auditLogs.');

    const adminWriteAudit = await firestoreCall(`auditLogs/audit-${runId}`, {
      token: adminToken,
      method: 'PATCH',
      body: { fields: { action: { stringValue: 'tamper' } } },
    });
    assert(adminWriteAudit.status === 403, 'Admin unexpectedly wrote auditLogs.');

    const youthWriteSettings = await firestoreCall('appSettings/pilot', {
      token: youth.idToken,
      method: 'PATCH',
      body: { fields: { replyByRequired: { booleanValue: false } } },
    });
    assert(youthWriteSettings.status === 403, 'Youth wrote appSettings.');

    const adminWriteSettings = await firestoreCall('appSettings/pilot', {
      token: adminToken,
      method: 'PATCH',
      body: { fields: { replyByRequired: { booleanValue: true } } },
    });
    assert(
      adminWriteSettings.status === 200,
      'Admin denied writing appSettings.',
    );

    const youthReadSettings = await firestoreCall('appSettings/pilot', {
      token: youth.idToken,
    });
    assert(youthReadSettings.status === 200, 'Youth denied reading appSettings.');

    // 5. Catalog visibility and locked baseline feature collections.
    const adminPublishOpp = await firestoreCall(`opportunities/opp-pub-${runId}`, {
      token: adminToken,
      method: 'PATCH',
      body: {
        fields: {
          title: { stringValue: 'Published role' },
          status: { stringValue: 'published' },
        },
      },
    });
    assert(adminPublishOpp.status === 200, 'Admin denied publishing opportunity.');

    const adminDraftOpp = await firestoreCall(`opportunities/opp-draft-${runId}`, {
      token: adminToken,
      method: 'PATCH',
      body: {
        fields: {
          title: { stringValue: 'Draft role' },
          status: { stringValue: 'draft' },
        },
      },
    });
    assert(adminDraftOpp.status === 200, 'Admin denied saving draft opportunity.');

    const youthReadPublished = await firestoreCall(
      `opportunities/opp-pub-${runId}`,
      { token: youth.idToken },
    );
    assert(
      youthReadPublished.status === 200,
      'Signed-in youth denied reading published opportunity.',
    );

    const youthReadDraft = await firestoreCall(
      `opportunities/opp-draft-${runId}`,
      { token: youth.idToken },
    );
    assert(
      youthReadDraft.status === 403,
      'Youth unexpectedly read unpublished opportunity.',
    );

    const youthWriteProject = await firestoreCall(`projects/proj-${runId}`, {
      token: youth.idToken,
      method: 'PATCH',
      body: {
        fields: {
          userId: { stringValue: localId },
          title: { stringValue: 'Unreviewed collection write' },
        },
      },
    });
    assert(
      youthWriteProject.status === 403,
      'Youth unexpectedly wrote locked feature collection.',
    );

    // 6. Mentorship & Mentor Workspace (custom claim role: 'mentor').
    const mentorEmail = `jonathan-mentor-${runId}@example.test`;
    const mentorUser = await createVerifiedUser(mentorEmail, password);
    const mentorClaimSet = await authCall(
      'accounts:update',
      {
        localId: mentorUser.uid,
        customAttributes: JSON.stringify({ role: 'mentor' }),
      },
      { admin: true },
    );
    assert(mentorClaimSet.status === 200, 'Setting mentor claim failed.');
    const mentorSignedIn = await authCall('accounts:signInWithPassword', {
      email: mentorEmail,
      password,
      returnSecureToken: true,
    });
    assert(mentorSignedIn.status === 200, 'Mentor re-signin failed.');
    const mentorToken = mentorSignedIn.data.idToken;

    const seedMentorProfile = await firestoreCall(
      `mentorProfiles/${mentorUser.uid}`,
      {
        token: 'owner',
        method: 'PATCH',
        body: {
          fields: {
            displayName: { stringValue: 'Alice Mentor' },
            verified: { booleanValue: true },
            accepting: { booleanValue: false },
          },
        },
      },
    );
    assert(seedMentorProfile.status === 200, 'Failed seeding mentor profile.');

    const mentorUpdateAllowed = await firestoreCommit(
      [
        {
          update: {
            name: `projects/${projectId}/databases/(default)/documents/mentorProfiles/${mentorUser.uid}`,
            fields: {
              meetingLink: { stringValue: 'https://meet.google.com/abc-defg-hij' },
              menteeLimit: { integerValue: '5' },
              accepting: { booleanValue: true },
              availability: { stringValue: 'Tue 18:00' },
              availabilityWindows: { arrayValue: { values: [] } },
              openSlots: { arrayValue: { values: [] } },
            },
          },
          updateTransforms: [
            { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
          ],
          updateMask: {
            fieldPaths: [
              'meetingLink',
              'menteeLimit',
              'accepting',
              'availability',
              'availabilityWindows',
              'openSlots',
              'updatedAt',
            ],
          },
        },
      ],
      mentorToken,
    );
    assert(
      mentorUpdateAllowed.status === 200,
      `Mentor editable field update denied: ${JSON.stringify(mentorUpdateAllowed.data)}`,
    );

    const mentorTamperVerified = await firestoreCommit(
      [
        {
          update: {
            name: `projects/${projectId}/databases/(default)/documents/mentorProfiles/${mentorUser.uid}`,
            fields: { verified: { booleanValue: false } },
          },
          updateTransforms: [
            { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
          ],
          updateMask: { fieldPaths: ['verified', 'updatedAt'] },
        },
      ],
      mentorToken,
    );
    assert(
      mentorTamperVerified.status === 403,
      'Mentor unexpectedly changed verified flag.',
    );

    const sessionId = `session-${runId}`;
    const createSession = await firestoreCommit(
      [
        {
          update: {
            name: `projects/${projectId}/databases/(default)/documents/mentorSessions/${sessionId}`,
            fields: {
              requesterId: { stringValue: localId },
              requesterName: { stringValue: 'Test Youth' },
              mentorId: { stringValue: mentorUser.uid },
              mentorName: { stringValue: 'Alice Mentor' },
              topic: { stringValue: 'Review CSS layout' },
              note: { stringValue: 'Needs help with Flexbox' },
              startsAt: { timestampValue: '2026-12-01T16:00:00Z' },
              durationMinutes: { integerValue: '30' },
              mode: { stringValue: 'Google Meet' },
              status: { stringValue: 'requested' },
            },
          },
          updateTransforms: [
            { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
            { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
          ],
        },
      ],
      youth.idToken,
    );
    assert(
      createSession.status === 200,
      `Youth session create denied: ${JSON.stringify(createSession.data)}`,
    );

    const mentorReadSession = await firestoreCall(
      `mentorSessions/${sessionId}`,
      { token: mentorToken },
    );
    assert(
      mentorReadSession.status === 200,
      'Mentor could not read session addressed to mentorId.',
    );

    const youthConfirmAttempt = await firestoreCommit(
      [
        {
          update: {
            name: `projects/${projectId}/databases/(default)/documents/mentorSessions/${sessionId}`,
            fields: { status: { stringValue: 'confirmed' } },
          },
          updateTransforms: [
            { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
          ],
          updateMask: { fieldPaths: ['status', 'updatedAt'] },
        },
      ],
      youth.idToken,
    );
    assert(
      youthConfirmAttempt.status === 403,
      'Youth unexpectedly confirmed own session.',
    );

    const mentorConfirm = await firestoreCommit(
      [
        {
          update: {
            name: `projects/${projectId}/databases/(default)/documents/mentorSessions/${sessionId}`,
            fields: {
              status: { stringValue: 'confirmed' },
              meetingLink: { stringValue: 'https://meet.google.com/abc-defg-hij' },
            },
          },
          updateTransforms: [
            { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
          ],
          updateMask: { fieldPaths: ['status', 'meetingLink', 'updatedAt'] },
        },
      ],
      mentorToken,
    );
    assert(
      mentorConfirm.status === 200,
      `Mentor session confirm denied: ${JSON.stringify(mentorConfirm.data)}`,
    );

    // 7. Applications (Kellen's {uid}_{oppId} contract).
    const oppId = `opp-pub-${runId}`;
    const appId = `${localId}_${oppId}`;
    const validNote =
      'I built three responsive pages with mentor approval and am ready to start.';
    const shortNoteAttempt = await firestoreCommit(
      [
        {
          update: {
            name: `projects/${projectId}/databases/(default)/documents/applications/${localId}_short`,
            fields: {
              userId: { stringValue: localId },
              userName: { stringValue: 'Test Youth' },
              opportunityId: { stringValue: 'short' },
              projectIds: { arrayValue: { values: [{ stringValue: 'p1' }] } },
              note: { stringValue: 'Too short' },
              status: { stringValue: 'sent' },
              ref: { stringValue: 'UB-2026-00001' },
            },
          },
          updateTransforms: [
            { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
            { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
          ],
        },
      ],
      youth.idToken,
    );
    assert(
      shortNoteAttempt.status === 403,
      'Rules accepted an application note shorter than 60 chars.',
    );

    const validApp = await firestoreCommit(
      [
        {
          update: {
            name: `projects/${projectId}/databases/(default)/documents/applications/${appId}`,
            fields: {
              userId: { stringValue: localId },
              userName: { stringValue: 'Test Youth' },
              opportunityId: { stringValue: oppId },
              projectIds: { arrayValue: { values: [{ stringValue: 'p1' }] } },
              note: { stringValue: validNote },
              status: { stringValue: 'sent' },
              ref: { stringValue: 'UB-2026-00002' },
            },
          },
          updateTransforms: [
            { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
            { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
          ],
        },
      ],
      youth.idToken,
    );
    assert(
      validApp.status === 200,
      `Valid youth application denied: ${JSON.stringify(validApp.data)}`,
    );

    const withdrawApp = await firestoreCommit(
      [
        {
          update: {
            name: `projects/${projectId}/databases/(default)/documents/applications/${appId}`,
            fields: { status: { stringValue: 'withdrawn' } },
          },
          updateTransforms: [
            { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
          ],
          updateMask: { fieldPaths: ['status', 'updatedAt'] },
        },
      ],
      youth.idToken,
    );
    assert(
      withdrawApp.status === 200,
      `Youth application withdraw denied: ${JSON.stringify(withdrawApp.data)}`,
    );

    console.log(
      'PASS: verification, custom role claims, immutable checkIns, notification boundaries, auditLogs, appSettings, catalog, mentorship, and application rules verified.',
    );
  } finally {
    // Clear all data only inside this run's disposable demo project.
    await request(
      `${firestoreBase}/emulator/v1/projects/${projectId}/databases/(default)/documents`,
      { method: 'DELETE' },
    );
    await request(
      `${authBase}/emulator/v1/projects/${projectId}/accounts`,
      { method: 'DELETE' },
    );
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
