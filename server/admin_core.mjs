/**
 * Shared trusted backend admin authorization, transactional mentor review,
 * audit logging, and idempotent approval email delivery.
 */

import { buildMentorApprovalEmail, createEmailSender } from './email_service.mjs';

export class HttpAuthError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.statusCode = statusCode;
  }
}

export async function verifyAdminActor({ auth, db, idToken }) {
  if (!idToken || typeof idToken !== 'string' || idToken.trim().length === 0) {
    throw new HttpAuthError(401, 'Missing Bearer authentication token.');
  }

  let decoded;
  try {
    // checkRevoked=true rejects revoked tokens or disabled Firebase accounts immediately.
    decoded = await auth.verifyIdToken(idToken.trim(), true);
  } catch (err) {
    throw new HttpAuthError(401, `Invalid or revoked token: ${err?.message || err}`);
  }

  if (decoded.email_verified !== true) {
    throw new HttpAuthError(403, 'Administrator email must be verified.');
  }
  if (decoded.role !== 'admin') {
    throw new HttpAuthError(403, 'Administrator custom claim is required.');
  }

  const userSnap = await db.collection('users').doc(decoded.uid).get();
  if (userSnap.exists) {
    const data = userSnap.data() || {};
    const status = data.status ?? data.accountStatus ?? 'active';
    if (status !== 'active') {
      throw new HttpAuthError(403, 'Administrator account is deactivated.');
    }
    if (data.role !== 'admin') {
      throw new HttpAuthError(403, 'Administrator role in Firestore has been revoked.');
    }
  }

  return {
    uid: decoded.uid,
    email: String(decoded.email || '').trim().toLowerCase(),
  };
}

export async function deliverMentorApprovalEmail({
  db,
  FieldValue,
  applicantUid,
  recipientEmail,
  mentorName,
  actorUid,
  actorEmail,
  emailSender,
  forceLockResetAfterMs = 60_000,
}) {
  const cleanRecipient = String(recipientEmail || '').trim();
  if (!cleanRecipient || !cleanRecipient.includes('@')) {
    return {
      status: 'failed',
      delivered: false,
      error: 'Applicant account has no valid email address.',
    };
  }

  const appRef = db.collection('mentorApplications').doc(applicantUid);
  const sender = emailSender ?? createEmailSender();
  let lockResult;

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(appRef);
    if (!snap.exists) {
      throw new HttpAuthError(404, 'Mentor application not found.');
    }
    const data = snap.data() || {};
    if (data.status !== 'approved') {
      throw new HttpAuthError(
        409,
        `Approval email cannot be sent while application status is "${data.status}".`,
      );
    }
    if (data.approvalEmailStatus === 'sent') {
      lockResult = {
        status: 'already_sent',
        delivered: true,
        alreadySent: true,
        messageId: data.approvalEmailMessageId || '',
        attempts: Number(data.approvalEmailAttempts || 1),
      };
      return;
    }

    const lastAttemptMillis =
      typeof data.approvalEmailLastAttemptAt?.toMillis === 'function'
        ? data.approvalEmailLastAttemptAt.toMillis()
        : Number(data.approvalEmailLastAttemptMillis || 0);
    if (
      data.approvalEmailStatus === 'sending' &&
      lastAttemptMillis > 0 &&
      Date.now() - lastAttemptMillis < forceLockResetAfterMs
    ) {
      lockResult = {
        status: 'in_progress',
        delivered: false,
        alreadySent: false,
      };
      return;
    }

    const nextAttempts = Number(data.approvalEmailAttempts || 0) + 1;
    tx.update(appRef, {
      approvalEmailStatus: 'sending',
      approvalEmailRecipient: cleanRecipient,
      approvalEmailAttempts: nextAttempts,
      approvalEmailError: '',
      approvalEmailLastAttemptAt: FieldValue.serverTimestamp(),
      approvalEmailLastAttemptMillis: Date.now(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    lockResult = {
      status: 'locked',
      attempts: nextAttempts,
      effectiveName:
        mentorName ||
        String(data.applicantName || '').trim() ||
        'Mentor',
    };
  });

  if (lockResult.alreadySent || lockResult.status === 'in_progress') {
    return lockResult;
  }

  const emailContent = buildMentorApprovalEmail({
    mentorName: lockResult.effectiveName,
  });

  try {
    const sendResult = await sender({
      to: cleanRecipient,
      subject: emailContent.subject,
      text: emailContent.text,
      html: emailContent.html,
    });

    if (!sendResult?.delivered) {
      const nextStatus = sendResult?.configured === false ? 'not_configured' : 'failed';
      const errText =
        sendResult?.error || 'Email transport failed to confirm delivery.';
      await appRef.update({
        approvalEmailStatus: nextStatus,
        approvalEmailError: errText,
        updatedAt: FieldValue.serverTimestamp(),
      });
      await db.collection('auditLogs').add({
        ownerUid: actorUid,
        actorUid,
        actorEmail,
        action: 'approvalEmailFailed',
        targetCollection: 'mentorApplications',
        targetId: applicantUid,
        details: `Approval email (${nextStatus}) for ${cleanRecipient}: ${errText}`,
        status: 'recorded',
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return {
        status: nextStatus,
        delivered: false,
        attempts: lockResult.attempts,
        error: errText,
      };
    }

    await appRef.update({
      approvalEmailStatus: 'sent',
      approvalEmailMessageId: String(sendResult.messageId || ''),
      approvalEmailSentAt: FieldValue.serverTimestamp(),
      approvalEmailError: '',
      updatedAt: FieldValue.serverTimestamp(),
    });
    await db.collection('auditLogs').add({
      ownerUid: actorUid,
      actorUid,
      actorEmail,
      action: 'approvalEmailSent',
      targetCollection: 'mentorApplications',
      targetId: applicantUid,
      details: `Sent approval email (${sendResult.provider || 'smtp'}) to ${cleanRecipient} [messageId=${sendResult.messageId || 'n/a'}]`,
      status: 'recorded',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return {
      status: 'sent',
      delivered: true,
      attempts: lockResult.attempts,
      provider: sendResult.provider || 'smtp',
      messageId: sendResult.messageId || '',
    };
  } catch (err) {
    const errText = String(err?.message || err);
    await appRef.update({
      approvalEmailStatus: 'failed',
      approvalEmailError: errText.slice(0, 500),
      updatedAt: FieldValue.serverTimestamp(),
    });
    await db.collection('auditLogs').add({
      ownerUid: actorUid,
      actorUid,
      actorEmail,
      action: 'approvalEmailFailed',
      targetCollection: 'mentorApplications',
      targetId: applicantUid,
      details: `Approval email delivery error for ${cleanRecipient}: ${errText}`,
      status: 'recorded',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return {
      status: 'failed',
      delivered: false,
      attempts: lockResult.attempts,
      error: errText,
    };
  }
}

function buildMentorProfileCreateData({
  mentorUid,
  appData,
  userData,
  FieldValue,
  isPublic,
}) {
  const expertise = Array.isArray(appData.expertise) ? appData.expertise : [];
  const skills = Array.isArray(appData.skills) ? appData.skills : [];
  const supportingLinks = Array.isArray(appData.supportingLinks)
    ? appData.supportingLinks
    : [];
  const mergedSkills = [...new Set([...expertise, ...skills])];
  const experienceYears = Number(appData.experienceYears || 0);
  const maxMentees = Math.min(50, Math.max(1, Number(appData.maxMentees || 5)));
  const availability = String(appData.availability || '');
  const bio = String(appData.bio || '');
  const headline = String(appData.headline || '').trim();
  const displayName = String(
    appData.applicantName || userData.displayName || 'Mentor',
  ).trim();

  return {
    ownerUid: mentorUid,
    displayName,
    headline,
    location: 'Kigali, Rwanda',
    about: bio,
    photoAsset: userData.photoAsset ?? null,
    cvAsset: appData.cvAsset ?? null,
    skills: mergedSkills,
    interests: [],
    learningGoal: '',
    professionalLinks: supportingLinks,
    education: [],
    experience: [],
    certificates: [],
    isMentorPublic: isPublic,
    mentorExpertise: expertise,
    mentorExperienceYears: experienceYears,
    mentorAvailability: availability,
    mentorMaxMentees: maxMentees,
    mentorBio: bio,
    status: 'active',
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function buildMentorProfileUpdatePatch({
  existingProfile,
  appData,
  userData,
  FieldValue,
  isPublic,
  syncApplicationFields,
}) {
  const expertise = Array.isArray(appData.expertise) ? appData.expertise : [];
  const skills = Array.isArray(appData.skills) ? appData.skills : [];
  const supportingLinks = Array.isArray(appData.supportingLinks)
    ? appData.supportingLinks
    : [];
  const mergedSkills = [...new Set([...expertise, ...skills])];
  const experienceYears = Number(appData.experienceYears || 0);
  const maxMentees = Math.min(50, Math.max(1, Number(appData.maxMentees || 5)));
  const availability = String(appData.availability || '');
  const bio = String(appData.bio || '');
  const headline = String(appData.headline || '').trim();
  const displayName = String(
    appData.applicantName || userData.displayName || '',
  ).trim();

  const patch = {
    isMentorPublic: isPublic,
    status: 'active',
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (
    syncApplicationFields ||
    ((!Array.isArray(existingProfile.mentorExpertise) ||
      existingProfile.mentorExpertise.length === 0) &&
      expertise.length > 0)
  ) {
    patch.mentorExpertise = expertise;
  }
  if (
    syncApplicationFields ||
    (Number(existingProfile.mentorExperienceYears || 0) === 0 &&
      experienceYears > 0)
  ) {
    patch.mentorExperienceYears = experienceYears;
  }
  if (
    syncApplicationFields ||
    (String(existingProfile.mentorAvailability || '').trim().length === 0 &&
      availability.trim().length > 0)
  ) {
    patch.mentorAvailability = availability;
  }
  if (syncApplicationFields || existingProfile.mentorMaxMentees == null) {
    patch.mentorMaxMentees = maxMentees;
  }
  if (
    syncApplicationFields ||
    (String(existingProfile.mentorBio || '').trim().length === 0 &&
      bio.trim().length > 0)
  ) {
    patch.mentorBio = bio;
  }
  if (
    displayName &&
    String(existingProfile.displayName || '').trim().length === 0
  ) {
    patch.displayName = displayName;
  }
  if (
    headline &&
    (syncApplicationFields ||
      String(existingProfile.headline || '').trim().length === 0)
  ) {
    patch.headline = headline;
  }
  if (
    (!Array.isArray(existingProfile.skills) ||
      existingProfile.skills.length === 0) &&
    mergedSkills.length > 0
  ) {
    patch.skills = mergedSkills;
  }
  if (
    (!Array.isArray(existingProfile.professionalLinks) ||
      existingProfile.professionalLinks.length === 0) &&
    supportingLinks.length > 0
  ) {
    patch.professionalLinks = supportingLinks;
  }
  if (existingProfile.cvAsset == null && appData.cvAsset != null) {
    patch.cvAsset = appData.cvAsset;
  }

  return patch;
}

export async function reviewMentorApplicationTx({
  auth,
  db,
  FieldValue,
  actor,
  applicantUid,
  decision,
  reason = '',
  emailSender,
}) {
  if (!applicantUid) {
    throw new HttpAuthError(400, 'applicantUid is required.');
  }
  if (actor.uid === applicantUid) {
    throw new HttpAuthError(403, 'Admins cannot review their own application.');
  }
  if (decision !== 'approved' && decision !== 'rejected') {
    throw new HttpAuthError(400, 'Decision must be "approved" or "rejected".');
  }
  const cleanReason = String(reason || '').trim();
  if (decision === 'rejected' && cleanReason.length < 5) {
    throw new HttpAuthError(
      400,
      'Rejection reason must be at least 5 characters.',
    );
  }

  const appRef = db.collection('mentorApplications').doc(applicantUid);
  const userRef = db.collection('users').doc(applicantUid);
  const profileRef = db.collection('profiles').doc(applicantUid);

  const txOutcome = await db.runTransaction(async (tx) => {
    const [appSnap, userSnap, profileSnap] = await Promise.all([
      tx.get(appRef),
      tx.get(userRef),
      tx.get(profileRef),
    ]);

    if (!appSnap.exists) {
      throw new HttpAuthError(404, 'Mentor application not found.');
    }

    const appData = appSnap.data() || {};
    const userData = userSnap.exists ? userSnap.data() || {} : {};
    const previousApprovalStatus = String(
      appData.status || userData.approvalStatus || 'pending',
    );
    const recipientEmail = String(
      userData.email || appData.applicantEmail || '',
    ).trim();
    const applicantName = String(
      appData.applicantName || userData.displayName || 'Mentor',
    ).trim();

    if (previousApprovalStatus === 'approved' && decision === 'approved') {
      return {
        alreadyApproved: true,
        previousApprovalStatus,
        newApprovalStatus: 'approved',
        recipientEmail,
        applicantName,
      };
    }

    if (previousApprovalStatus !== 'pending') {
      throw new HttpAuthError(
        409,
        `Invalid MentorApplication transition: ${previousApprovalStatus} -> ${decision}.`,
      );
    }

    if (userSnap.exists && userData.role === 'admin') {
      throw new HttpAuthError(
        409,
        'Administrator accounts cannot be converted to mentor.',
      );
    }

    if (decision === 'approved') {
      tx.update(appRef, {
        status: 'approved',
        rejectionReason: '',
        reviewedBy: actor.uid,
        reviewedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      if (userSnap.exists) {
        const userPatch = {
          role: 'mentor',
          isApproved: true,
          approvalStatus: 'approved',
          status: 'active',
          onboarded: true,
          updatedAt: FieldValue.serverTimestamp(),
        };
        if (
          applicantName &&
          String(userData.displayName || '').trim().length === 0
        ) {
          userPatch.displayName = applicantName;
        }
        tx.update(userRef, userPatch);
      } else {
        tx.set(userRef, {
          ownerUid: applicantUid,
          email: recipientEmail,
          displayName: applicantName,
          phone: '',
          role: 'mentor',
          isApproved: true,
          approvalStatus: 'approved',
          emailVerified: true,
          status: 'active',
          onboarded: true,
          preferredLocale: 'en',
          photoAsset: null,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      if (profileSnap.exists) {
        const existingProfile = profileSnap.data() || {};
        tx.update(
          profileRef,
          buildMentorProfileUpdatePatch({
            existingProfile,
            appData,
            userData,
            FieldValue,
            isPublic: true,
            syncApplicationFields: true,
          }),
        );
      } else {
        tx.set(
          profileRef,
          buildMentorProfileCreateData({
            mentorUid: applicantUid,
            appData,
            userData,
            FieldValue,
            isPublic: true,
          }),
        );
      }

      tx.set(db.collection('notifications').doc(), {
        ownerUid: applicantUid,
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

      tx.set(db.collection('auditLogs').doc(), {
        ownerUid: actor.uid,
        actorUid: actor.uid,
        actorEmail: actor.email,
        action: 'approveMentorApplication',
        targetCollection: 'mentorApplications',
        targetId: applicantUid,
        details: `Approved mentor ${recipientEmail || applicantUid} (${previousApprovalStatus} -> approved)`,
        status: 'recorded',
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      return {
        alreadyApproved: false,
        previousApprovalStatus,
        newApprovalStatus: 'approved',
        recipientEmail,
        applicantName,
      };
    }

    // Rejected transition
    tx.update(appRef, {
      status: 'rejected',
      rejectionReason: cleanReason,
      reviewedBy: actor.uid,
      reviewedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    if (userSnap.exists && userData.role !== 'admin') {
      tx.update(userRef, {
        role: 'mentor',
        isApproved: false,
        approvalStatus: 'rejected',
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    tx.set(db.collection('notifications').doc(), {
      ownerUid: applicantUid,
      title: 'Mentor application update',
      body: `Your mentor application was not approved yet: ${cleanReason}`,
      type: 'mentorRejection',
      route: '/mentor-pending',
      isRead: false,
      readAt: null,
      status: 'unread',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(db.collection('auditLogs').doc(), {
      ownerUid: actor.uid,
      actorUid: actor.uid,
      actorEmail: actor.email,
      action: 'rejectMentorApplication',
      targetCollection: 'mentorApplications',
      targetId: applicantUid,
      details: `Rejected mentor ${recipientEmail || applicantUid} (${previousApprovalStatus} -> rejected): ${cleanReason}`,
      status: 'recorded',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return {
      alreadyApproved: false,
      previousApprovalStatus,
      newApprovalStatus: 'rejected',
      recipientEmail,
      applicantName,
    };
  });

  if (decision === 'rejected') {
    return {
      ok: true,
      decision: 'rejected',
      previousApprovalStatus: txOutcome.previousApprovalStatus,
      newApprovalStatus: 'rejected',
      emailDelivery: { status: 'not_applicable', delivered: false },
    };
  }

  // Sync Firebase Auth custom claims for approved mentor.
  try {
    const authUser = await auth.getUser(applicantUid);
    const existingClaims = authUser.customClaims || {};
    if (existingClaims.role !== 'mentor' && existingClaims.role !== 'admin') {
      await auth.setCustomUserClaims(applicantUid, {
        ...existingClaims,
        role: 'mentor',
      });
    }
  } catch (_) {
    // Non-fatal in Spark environments where Firestore users/{uid} enforces isApprovedMentor().
  }

  // Only deliver approval email AFTER successful approval commit.
  const emailDelivery = await deliverMentorApprovalEmail({
    db,
    FieldValue,
    applicantUid,
    recipientEmail: txOutcome.recipientEmail,
    mentorName: txOutcome.applicantName,
    actorUid: actor.uid,
    actorEmail: actor.email,
    emailSender,
  });

  return {
    ok: true,
    decision: 'approved',
    alreadyApproved: txOutcome.alreadyApproved,
    previousApprovalStatus: txOutcome.previousApprovalStatus,
    newApprovalStatus: txOutcome.newApprovalStatus,
    emailDelivery,
  };
}

export async function revokeMentorTx({
  auth,
  db,
  FieldValue,
  actor,
  targetUid,
  reason,
}) {
  if (!targetUid) {
    throw new HttpAuthError(400, 'targetUid is required.');
  }
  if (actor.uid === targetUid) {
    throw new HttpAuthError(403, 'Admins cannot revoke their own account.');
  }
  const cleanReason = String(reason || '').trim();
  if (cleanReason.length < 5) {
    throw new HttpAuthError(400, 'Revocation reason must be at least 5 characters.');
  }

  const appRef = db.collection('mentorApplications').doc(targetUid);
  const userRef = db.collection('users').doc(targetUid);
  const profileRef = db.collection('profiles').doc(targetUid);

  const txResult = await db.runTransaction(async (tx) => {
    const [appSnap, userSnap, profileSnap] = await Promise.all([
      tx.get(appRef),
      tx.get(userRef),
      tx.get(profileRef),
    ]);

    const appData = appSnap.exists ? appSnap.data() || {} : null;
    const userData = userSnap.exists ? userSnap.data() || {} : null;
    const previousApprovalStatus = String(
      appData?.status || userData?.approvalStatus || 'approved',
    );

    if (appData && appData.status === 'approved') {
      tx.update(appRef, {
        status: 'revoked',
        rejectionReason: cleanReason,
        reviewedBy: actor.uid,
        reviewedAt: FieldValue.serverTimestamp(),
        approvalEmailStatus: '',
        approvalEmailError: '',
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    if (userSnap.exists && userData?.role !== 'admin') {
      tx.update(userRef, {
        role: 'mentor',
        isApproved: false,
        approvalStatus: 'revoked',
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    if (profileSnap.exists) {
      tx.update(profileRef, {
        isMentorPublic: false,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    tx.set(db.collection('notifications').doc(), {
      ownerUid: targetUid,
      title: 'Mentor access revoked',
      body: `Your mentor privileges were revoked: ${cleanReason}`,
      type: 'mentorRevocation',
      route: '/mentor-pending',
      isRead: false,
      readAt: null,
      status: 'unread',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.set(db.collection('auditLogs').doc(), {
      ownerUid: actor.uid,
      actorUid: actor.uid,
      actorEmail: actor.email,
      action: 'revokeMentorRole',
      targetCollection: 'users',
      targetId: targetUid,
      details: `Revoked mentor access for ${targetUid} (${previousApprovalStatus} -> revoked): ${cleanReason}`,
      status: 'recorded',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { previousApprovalStatus };
  });

  try {
    const authUser = await auth.getUser(targetUid);
    const claims = { ...(authUser.customClaims || {}) };
    if (claims.role === 'mentor') {
      delete claims.role;
      await auth.setCustomUserClaims(targetUid, claims);
    }
    await auth.revokeRefreshTokens(targetUid);
  } catch (_) {}

  return {
    ok: true,
    previousApprovalStatus: txResult.previousApprovalStatus,
    newApprovalStatus: 'revoked',
  };
}

export async function setUserStatusTx({
  auth,
  db,
  FieldValue,
  actor,
  targetUid,
  status,
  reason = '',
}) {
  if (!targetUid) {
    throw new HttpAuthError(400, 'targetUid is required.');
  }
  if (actor.uid === targetUid) {
    throw new HttpAuthError(403, 'Admins cannot deactivate their own account.');
  }
  if (status !== 'active' && status !== 'deactivated') {
    throw new HttpAuthError(400, 'status must be "active" or "deactivated".');
  }

  const userRef = db.collection('users').doc(targetUid);
  await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new HttpAuthError(404, 'User account not found.');
    }
    const prev = userSnap.data()?.status || 'active';
    tx.update(userRef, {
      status,
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(db.collection('auditLogs').doc(), {
      ownerUid: actor.uid,
      actorUid: actor.uid,
      actorEmail: actor.email,
      action: status === 'deactivated' ? 'deactivateUser' : 'reactivateUser',
      targetCollection: 'users',
      targetId: targetUid,
      details: `Set user ${targetUid} status (${prev} -> ${status})${reason ? `: ${reason}` : ''}`,
      status: 'recorded',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  try {
    await auth.updateUser(targetUid, {
      disabled: status === 'deactivated',
    });
    if (status === 'deactivated') {
      await auth.revokeRefreshTokens(targetUid);
    }
  } catch (_) {}

  return { ok: true, status };
}

export async function setMentorVisibilityTx({
  db,
  FieldValue,
  actor,
  mentorUid,
  isPublic,
}) {
  if (!mentorUid) {
    throw new HttpAuthError(400, 'mentorUid is required.');
  }
  if (typeof isPublic !== 'boolean') {
    throw new HttpAuthError(400, 'isPublic must be a boolean.');
  }

  const appRef = db.collection('mentorApplications').doc(mentorUid);
  const userRef = db.collection('users').doc(mentorUid);
  const profileRef = db.collection('profiles').doc(mentorUid);

  await db.runTransaction(async (tx) => {
    const [appSnap, userSnap, profileSnap] = await Promise.all([
      tx.get(appRef),
      tx.get(userRef),
      tx.get(profileRef),
    ]);

    const appData = appSnap.exists ? appSnap.data() || {} : {};
    const userData = userSnap.exists ? userSnap.data() || {} : {};
    const userApproved =
      userSnap.exists &&
      userData.role === 'mentor' &&
      userData.isApproved === true &&
      (!userData.approvalStatus || userData.approvalStatus === 'approved');
    const appApproved = appSnap.exists && appData.status === 'approved';
    if (!userApproved && !appApproved) {
      throw new HttpAuthError(
        409,
        'Mentor must be approved before changing directory visibility.',
      );
    }

    if (profileSnap.exists) {
      const existingProfile = profileSnap.data() || {};
      tx.update(
        profileRef,
        buildMentorProfileUpdatePatch({
          existingProfile,
          appData,
          userData,
          FieldValue,
          isPublic,
          syncApplicationFields: false,
        }),
      );
    } else {
      tx.set(
        profileRef,
        buildMentorProfileCreateData({
          mentorUid,
          appData,
          userData,
          FieldValue,
          isPublic,
        }),
      );
    }

    tx.set(db.collection('auditLogs').doc(), {
      ownerUid: actor.uid,
      actorUid: actor.uid,
      actorEmail: actor.email,
      action: isPublic ? 'publishMentorProfile' : 'hideMentorProfile',
      targetCollection: 'profiles',
      targetId: mentorUid,
      details: isPublic
        ? `Published approved mentor ${mentorUid} to student directory`
        : `Hid approved mentor ${mentorUid} from student directory`,
      status: 'recorded',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return { ok: true, mentorUid, isMentorPublic: isPublic };
}
