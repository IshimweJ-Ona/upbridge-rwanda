import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import test, { after, before, beforeEach } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(__dirname, '..', 'firestore.rules'), 'utf8');

let testEnv;

before(async () => {
  const hostPort = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
  const [host, portStr] = hostPort.split(':');
  testEnv = await initializeTestEnvironment({
    projectId: process.env.UPBRIDGE_RULES_PROJECT_ID || 'demo-upbridge-rules',
    firestore: {
      host,
      port: Number(portStr),
      rules,
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv?.cleanup();
});

const verifiedStudent = (uid = 'student-1') =>
  testEnv.authenticatedContext(uid, {
    email_verified: true,
    role: 'student',
  });

const unapprovedApplicant = (uid = 'applicant-1') =>
  testEnv.authenticatedContext(uid, {
    email_verified: true,
    role: 'student',
  });

const verifiedMentor = (uid = 'mentor-1') =>
  testEnv.authenticatedContext(uid, {
    email_verified: true,
    role: 'mentor',
  });

const verifiedAdmin = (uid = 'admin-1') =>
  testEnv.authenticatedContext(uid, {
    email_verified: true,
    role: 'admin',
  });

const ts = () => new Date('2026-11-19T12:00:00Z');

test('denies unauthenticated users and blocks unverified users from platform data and privilege forgery', async () => {
  const anonDb = testEnv.unauthenticatedContext().firestore();
  const unverifiedDb = testEnv
    .authenticatedContext('unv-1', { email_verified: false })
    .firestore();

  await assertFails(getDoc(doc(anonDb, 'courses', 'c-1')));
  await assertFails(getDoc(doc(unverifiedDb, 'courses', 'c-1')));

  // Unverified self-signup cannot forge emailVerified=true, isApproved=true, or admin role.
  await assertFails(
    setDoc(doc(unverifiedDb, 'users', 'unv-1'), {
      ownerUid: 'unv-1',
      email: 'u@test.rw',
      displayName: 'Forged Verified',
      phone: '',
      role: 'student',
      isApproved: false,
      approvalStatus: 'notRequired',
      emailVerified: true,
      status: 'active',
      onboarded: false,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertFails(
    setDoc(doc(unverifiedDb, 'users', 'unv-1'), {
      ownerUid: 'unv-1',
      email: 'u@test.rw',
      displayName: 'Forged Admin',
      phone: '',
      role: 'admin',
      isApproved: true,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Initial unverified student signup doc with emailVerified=false succeeds.
  await assertSucceeds(
    setDoc(doc(unverifiedDb, 'users', 'unv-1'), {
      ownerUid: 'unv-1',
      email: 'u@test.rw',
      displayName: 'Unverified Student',
      phone: '',
      role: 'student',
      isApproved: false,
      approvalStatus: 'notRequired',
      emailVerified: false,
      status: 'active',
      onboarded: false,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Unverified user still cannot read profiles or create student/mentor activity.
  await assertFails(getDoc(doc(unverifiedDb, 'profiles', 'unv-1')));
  await assertFails(
    setDoc(doc(unverifiedDb, 'mentorRequests', 'req-unv'), {
      ownerUid: 'unv-1',
      studentUid: 'unv-1',
      studentName: 'Unverified',
      studentPhotoUrl: '',
      mentorUid: 'mentor-1',
      mentorName: 'Mentor',
      mentorPhotoUrl: '',
      message: 'Help me',
      goals: 'Learn',
      status: 'pending',
      responseNote: '',
      respondedAt: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
});

test('student cannot self-assign mentor or admin role, and cannot read others private data', async () => {
  const s1Db = verifiedStudent('student-1').firestore();
  const s2Db = verifiedStudent('student-2').firestore();

  // Valid self-signup user doc with role=student succeeds.
  await assertSucceeds(
    setDoc(doc(s1Db, 'users', 'student-1'), {
      ownerUid: 'student-1',
      email: 's1@test.rw',
      displayName: 'Student One',
      phone: '+250788000001',
      role: 'student',
      isApproved: false,
      status: 'active',
      onboarded: false,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Attempting to create with role=mentor or role=admin fails.
  await assertFails(
    setDoc(doc(s2Db, 'users', 'student-2'), {
      ownerUid: 'student-2',
      email: 's2@test.rw',
      displayName: 'Sneaky Mentor',
      phone: '',
      role: 'mentor',
      isApproved: true,
      status: 'active',
      onboarded: false,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Student-1 cannot escalate role or isApproved on update.
  await assertFails(
    updateDoc(doc(s1Db, 'users', 'student-1'), { role: 'mentor' }),
  );
  await assertFails(
    updateDoc(doc(s1Db, 'users', 'student-1'), { isApproved: true }),
  );

  // Student-2 cannot read student-1's users/{uid}.
  await assertFails(getDoc(doc(s2Db, 'users', 'student-1')));

  // Student-1 cannot publish themselves as a public mentor in profiles/{uid}.
  await assertFails(
    setDoc(doc(s1Db, 'profiles', 'student-1'), {
      ownerUid: 'student-1',
      displayName: 'Student One',
      headline: 'Dev',
      location: 'Kigali',
      about: 'Learning',
      photoAsset: null,
      cvAsset: null,
      skills: ['Dart'],
      interests: ['Mobile'],
      learningGoal: 'job',
      education: [],
      experience: [],
      certificates: [],
      isMentorPublic: true,
      status: 'active',
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
});

test('unapproved mentor cannot self-approve or act as mentor on requests/mentorships/sessions', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const adminDb = ctx.firestore();
    await setDoc(doc(adminDb, 'profiles', 'mentor-1'), {
      ownerUid: 'mentor-1',
      displayName: 'Approved Mentor',
      isMentorPublic: true,
      status: 'active',
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(adminDb, 'profiles', 'applicant-1'), {
      ownerUid: 'applicant-1',
      displayName: 'Pending Applicant',
      isMentorPublic: true, // even if mistakenly set, token claim gates mentor actions
      status: 'active',
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(adminDb, 'mentorRequests', 'req-unapproved'), {
      ownerUid: 'student-1',
      studentUid: 'student-1',
      studentName: 'Student One',
      mentorUid: 'applicant-1',
      mentorName: 'Pending Applicant',
      message: 'Please mentor me on Flutter architecture.',
      goals: 'Build portfolio',
      status: 'pending',
      responseNote: '',
      respondedAt: null,
      createdAt: ts(),
      updatedAt: ts(),
    });
  });

  const appDb = unapprovedApplicant('applicant-1').firestore();

  // Can submit pending mentor application.
  await assertSucceeds(
    setDoc(doc(appDb, 'mentorApplications', 'applicant-1'), {
      ownerUid: 'applicant-1',
      applicantName: 'Pending Applicant',
      applicantEmail: 'app@test.rw',
      headline: 'Senior Developer',
      bio: '8 years of experience mentoring junior developers in Kigali.',
      expertise: ['Flutter', 'Firebase'],
      experienceYears: 8,
      availability: 'Tue 18:00',
      cvAsset: null,
      supportingLinks: [],
      status: 'pending',
      rejectionReason: '',
      reviewedBy: null,
      reviewedAt: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Unapproved mentor cannot approve their own mentor application.
  await assertFails(
    updateDoc(doc(appDb, 'mentorApplications', 'applicant-1'), {
      status: 'approved',
      reviewedBy: 'applicant-1',
    }),
  );

  // Unapproved mentor lacks custom claim role='mentor', so cannot accept mentorRequests.
  await assertFails(
    updateDoc(doc(appDb, 'mentorRequests', 'req-unapproved'), {
      status: 'accepted',
      responseNote: 'Accepted',
      respondedAt: ts(),
      updatedAt: ts(),
    }),
  );
});

test('enforces mentorship request, mentorship, and session status transitions and ownership', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'profiles', 'mentor-1'), {
      ownerUid: 'mentor-1',
      displayName: 'Alice Mentor',
      isMentorPublic: true,
      status: 'active',
      createdAt: ts(),
      updatedAt: ts(),
    });
  });

  const s1Db = verifiedStudent('student-1').firestore();
  const s2Db = verifiedStudent('student-2').firestore();
  const m1Db = verifiedMentor('mentor-1').firestore();
  const m2Db = verifiedMentor('mentor-2').firestore();

  // Student creates pending request.
  await assertSucceeds(
    setDoc(doc(s1Db, 'mentorRequests', 'req-1'), {
      ownerUid: 'student-1',
      studentUid: 'student-1',
      studentName: 'Student One',
      studentPhotoUrl: '',
      mentorUid: 'mentor-1',
      mentorName: 'Alice Mentor',
      mentorPhotoUrl: '',
      message: 'Seeking guidance on Flutter and Firebase projects.',
      goals: 'Ship an app',
      status: 'pending',
      responseNote: '',
      respondedAt: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Another student or another mentor cannot read or modify req-1.
  await assertFails(getDoc(doc(s2Db, 'mentorRequests', 'req-1')));
  await assertFails(
    updateDoc(doc(m2Db, 'mentorRequests', 'req-1'), {
      status: 'accepted',
      responseNote: '',
      respondedAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Student cannot accept their own request.
  await assertFails(
    updateDoc(doc(s1Db, 'mentorRequests', 'req-1'), {
      status: 'accepted',
      responseNote: '',
      respondedAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Mentor accepts pending -> accepted and creates active mentorship.
  await assertSucceeds(
    updateDoc(doc(m1Db, 'mentorRequests', 'req-1'), {
      status: 'accepted',
      responseNote: 'Happy to mentor you.',
      respondedAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Cannot transition accepted -> declined (status skip/reversal blocked).
  await assertFails(
    updateDoc(doc(m1Db, 'mentorRequests', 'req-1'), {
      status: 'declined',
      responseNote: 'Changed mind',
      respondedAt: ts(),
      updatedAt: ts(),
    }),
  );

  await assertSucceeds(
    setDoc(doc(m1Db, 'mentorships', 'req-1'), {
      ownerUid: 'student-1',
      studentUid: 'student-1',
      studentName: 'Student One',
      mentorUid: 'mentor-1',
      mentorName: 'Alice Mentor',
      requestId: 'req-1',
      goalSummary: 'Ship an app',
      status: 'active',
      feedbackRating: null,
      feedbackComment: '',
      endedByUid: null,
      endedAt: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Schedule session inside active mentorship.
  await assertSucceeds(
    setDoc(doc(s1Db, 'sessions', 'sess-1'), {
      ownerUid: 'student-1',
      mentorshipId: 'req-1',
      studentUid: 'student-1',
      studentName: 'Student One',
      mentorUid: 'mentor-1',
      mentorName: 'Alice Mentor',
      topic: 'Architecture review',
      notes: '',
      meetingMode: 'Online',
      meetingLink: '',
      scheduledAt: ts(),
      durationMinutes: 30,
      status: 'scheduled',
      cancelReason: '',
      completedAt: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Student cannot mark session completed (mentor-only).
  await assertFails(
    updateDoc(doc(s1Db, 'sessions', 'sess-1'), {
      status: 'completed',
      notes: 'Done',
      completedAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Mentor marks session completed, and then cannot cancel a completed session.
  await assertSucceeds(
    updateDoc(doc(m1Db, 'sessions', 'sess-1'), {
      status: 'completed',
      notes: 'Reviewed models and state machine.',
      cancelReason: '',
      completedAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertFails(
    updateDoc(doc(s1Db, 'sessions', 'sess-1'), {
      status: 'cancelled',
      cancelReason: 'Too late',
      updatedAt: ts(),
    }),
  );

  // Complete mentorship and block reopening.
  await assertSucceeds(
    updateDoc(doc(s1Db, 'mentorships', 'req-1'), {
      status: 'completed',
      endedByUid: 'student-1',
      endedAt: ts(),
      feedbackRating: 5,
      feedbackComment: 'Super helpful!',
      updatedAt: ts(),
    }),
  );
  await assertFails(
    updateDoc(doc(m1Db, 'mentorships', 'req-1'), {
      status: 'active',
      endedByUid: 'mentor-1',
      endedAt: ts(),
      updatedAt: ts(),
    }),
  );
});

test('admin custom claim scopes catalog writes and blocks client auditLog tampering', async () => {
  const s1Db = verifiedStudent('student-1').firestore();
  const adminDb = verifiedAdmin('admin-1').firestore();

  await assertFails(
    setDoc(doc(s1Db, 'courses', 'c-1'), {
      ownerUid: 'student-1',
      title: 'Unauthorized Course',
      status: 'published',
    }),
  );

  await assertSucceeds(
    setDoc(doc(adminDb, 'courses', 'c-1'), {
      ownerUid: 'admin-1',
      title: 'Dart & Flutter Foundations',
      summary: 'Production patterns.',
      status: 'published',
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  await assertSucceeds(getDoc(doc(s1Db, 'courses', 'c-1')));

  // Student and malformed admin writes to auditLogs are blocked; valid admin create is append-only.
  await assertFails(
    setDoc(doc(s1Db, 'auditLogs', 'log-student'), {
      ownerUid: 'student-1',
      actorUid: 'student-1',
      actorEmail: 's1@test.rw',
      action: 'forged',
      targetCollection: 'users',
      targetId: 'student-1',
      details: 'Unauthorized',
      status: 'recorded',
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertFails(
    setDoc(doc(adminDb, 'auditLogs', 'log-bad'), {
      ownerUid: 'admin-1',
      action: 'forged',
    }),
  );
  await assertSucceeds(
    setDoc(doc(adminDb, 'auditLogs', 'log-1'), {
      ownerUid: 'admin-1',
      actorUid: 'admin-1',
      actorEmail: 'authapp05@gmail.com',
      action: 'publishCourse',
      targetCollection: 'courses',
      targetId: 'c-1',
      details: 'Published c-1',
      status: 'recorded',
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertFails(
    updateDoc(doc(adminDb, 'auditLogs', 'log-1'), { details: 'tampered' }),
  );
  await assertFails(deleteDoc(doc(adminDb, 'auditLogs', 'log-1')));
});

test('Spark rules: admin rejects pending mentorApplication & validates Cloudinary image assets', async () => {
  const s1Db = verifiedStudent('student-1').firestore();
  const s2Db = verifiedStudent('student-2').firestore();
  const adminDb = verifiedAdmin('admin-1').firestore();

  // Unsigned Cloudinary URL for vbzq5ssu image is accepted.
  await assertSucceeds(
    setDoc(doc(s1Db, 'mentorApplications', 'student-1'), {
      ownerUid: 'student-1',
      applicantName: 'Aline Uwase',
      applicantEmail: 'aline@example.com',
      headline: 'Backend Developer',
      bio: 'Excited to mentor youth building APIs.',
      expertise: ['Dart', 'APIs'],
      experienceYears: 4,
      availability: 'Weekends',
      cvAsset: {
        url: 'https://res.cloudinary.com/vbzq5ssu/image/upload/v1700000000/upbridge/users/student-1/mentor-cv/cv.png',
        publicId: 'upbridge/users/student-1/mentor-cv/cv',
        resourceType: 'image',
        size: 102400,
        ownerUid: 'student-1',
        createdAt: serverTimestamp(),
      },
      supportingLinks: [],
      status: 'pending',
      rejectionReason: '',
      reviewedBy: null,
      reviewedAt: null,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );

  // Non-Cloudinary URL or raw asset is blocked by validOptionalAsset.
  await assertFails(
    setDoc(doc(s2Db, 'mentorApplications', 'student-2'), {
      ownerUid: 'student-2',
      applicantName: 'Bob Mugisha',
      applicantEmail: 'bob@example.com',
      headline: 'Backend Engineer',
      bio: 'Excited to mentor youth building APIs.',
      expertise: ['Python'],
      experienceYears: 3,
      availability: 'Evenings',
      cvAsset: {
        url: 'https://evil.example.com/cv.pdf',
        publicId: 'bad',
        resourceType: 'raw',
        size: 1024,
        ownerUid: 'student-2',
        createdAt: serverTimestamp(),
      },
      supportingLinks: [],
      status: 'pending',
      rejectionReason: '',
      reviewedBy: null,
      reviewedAt: null,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );

  // Student cannot reject a mentor application.
  await assertFails(
    updateDoc(doc(s1Db, 'mentorApplications', 'student-1'), {
      status: 'rejected',
      rejectionReason: 'Forged rejection',
      reviewedBy: 'student-1',
      reviewedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );

  // Student cannot self-approve mentorApplications.
  await assertFails(
    updateDoc(doc(s1Db, 'mentorApplications', 'student-1'), {
      status: 'approved',
      reviewedBy: 'student-1',
      reviewedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );

  // Admin can reject pending -> rejected in Spark Firestore and notify applicant.
  await assertSucceeds(
    updateDoc(doc(adminDb, 'mentorApplications', 'student-1'), {
      status: 'rejected',
      rejectionReason: 'Please include verifiable project mentoring examples.',
      reviewedBy: 'admin-1',
      reviewedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(
    setDoc(doc(adminDb, 'notifications', 'notif-reject-1'), {
      ownerUid: 'student-1',
      title: 'Mentor application update',
      body: 'Your mentor application was not approved yet.',
      type: 'mentorRejection',
      route: '/mentor-apply',
      isRead: false,
      readAt: null,
      status: 'unread',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );

  // Applicant resubmits rejected -> pending, then verified admin approves directly in Spark Firestore.
  await assertSucceeds(
    updateDoc(doc(s1Db, 'mentorApplications', 'student-1'), {
      status: 'pending',
      rejectionReason: '',
      reviewedBy: null,
      reviewedAt: null,
      updatedAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(
    setDoc(doc(adminDb, 'users', 'student-1'), {
      ownerUid: 'student-1',
      email: 'aline@example.com',
      displayName: 'Aline Uwase',
      phone: '',
      role: 'mentor',
      isApproved: true,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(
    updateDoc(doc(adminDb, 'mentorApplications', 'student-1'), {
      status: 'approved',
      rejectionReason: '',
      reviewedBy: 'admin-1',
      reviewedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  // Newly approved mentor can toggle public mentor profile without requiring a custom claim yet.
  await assertSucceeds(
    setDoc(doc(s1Db, 'profiles', 'student-1'), {
      ownerUid: 'student-1',
      displayName: 'Aline Uwase',
      headline: 'Backend Developer',
      location: 'Kigali',
      about: 'Mentoring youth.',
      photoAsset: null,
      cvAsset: null,
      skills: ['Dart'],
      interests: [],
      learningGoal: '',
      education: [],
      experience: [],
      certificates: [],
      isMentorPublic: true,
      status: 'active',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
});

test('mentor course ownership, engagement scoping, session rescheduling, revocation & deactivated blocks', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users', 'mentor-1'), {
      ownerUid: 'mentor-1',
      email: 'm1@test.rw',
      displayName: 'Mentor One',
      phone: '',
      role: 'mentor',
      isApproved: true,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'users', 'mentor-2'), {
      ownerUid: 'mentor-2',
      email: 'm2@test.rw',
      displayName: 'Mentor Two',
      phone: '',
      role: 'mentor',
      isApproved: true,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'users', 'student-1'), {
      ownerUid: 'student-1',
      email: 's1@test.rw',
      displayName: 'Student One',
      phone: '',
      role: 'student',
      isApproved: false,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'mentorApplications', 'mentor-1'), {
      ownerUid: 'mentor-1',
      applicantName: 'Mentor One',
      applicantEmail: 'm1@test.rw',
      headline: 'Flutter Architect',
      bio: '8+ years shipping scalable mobile platforms.',
      expertise: ['Flutter'],
      experienceYears: 8,
      availability: 'Weekends',
      cvAsset: null,
      supportingLinks: [],
      status: 'approved',
      rejectionReason: '',
      reviewedBy: 'admin-1',
      reviewedAt: ts(),
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'profiles', 'mentor-1'), {
      ownerUid: 'mentor-1',
      displayName: 'Mentor One',
      isMentorPublic: true,
      status: 'active',
      createdAt: ts(),
      updatedAt: ts(),
    });
  });

  const s1Db = verifiedStudent('student-1').firestore();
  const s2Db = verifiedStudent('student-2').firestore();
  const m1Db = verifiedMentor('mentor-1').firestore();
  const m2Db = verifiedMentor('mentor-2').firestore();
  const adminDb = verifiedAdmin('admin-1').firestore();

  // Approved mentor creates draft course, publishes, student reads published only.
  await assertSucceeds(
    setDoc(doc(m1Db, 'courses', 'mc-1'), {
      ownerUid: 'mentor-1',
      ownerName: 'Mentor One',
      title: 'Clean Flutter Architecture',
      summary: 'Production module patterns and testing in Dart.',
      category: 'it',
      customCategory: '',
      level: 'Intermediate',
      estimatedMinutes: 60,
      learningObjectives: ['Layer separation'],
      resources: [],
      modules: [],
      skills: ['Flutter'],
      coverAsset: null,
      status: 'draft',
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertFails(getDoc(doc(s1Db, 'courses', 'mc-1')));
  await assertFails(getDoc(doc(m2Db, 'courses', 'mc-1')));
  await assertSucceeds(getDoc(doc(m1Db, 'courses', 'mc-1')));

  // Other mentor cannot edit mentor-1's course; owner mentor can publish it.
  await assertFails(
    updateDoc(doc(m2Db, 'courses', 'mc-1'), {
      title: 'Hijacked Course',
      updatedAt: ts(),
    }),
  );
  await assertSucceeds(
    updateDoc(doc(m1Db, 'courses', 'mc-1'), {
      status: 'published',
      updatedAt: ts(),
    }),
  );
  await assertSucceeds(getDoc(doc(s1Db, 'courses', 'mc-1')));

  // Student submits progress with courseOwnerUid; owner mentor can inspect engagement, other mentor cannot.
  await assertSucceeds(
    setDoc(doc(s1Db, 'courseProgress', 'student-1_mc-1'), {
      ownerUid: 'student-1',
      courseId: 'mc-1',
      courseTitle: 'Clean Flutter Architecture',
      courseOwnerUid: 'mentor-1',
      completedModuleIds: ['m1'],
      progressPercent: 100,
      evidenceUrl: '',
      evidenceAsset: null,
      status: 'completed',
      completedAt: ts(),
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertSucceeds(getDoc(doc(m1Db, 'courseProgress', 'student-1_mc-1')));
  await assertFails(getDoc(doc(m2Db, 'courseProgress', 'student-1_mc-1')));

  // Batch mentorRequest + participant notification works; spoofing unrelated user fails.
  const validBatch = writeBatch(s1Db);
  validBatch.set(doc(s1Db, 'mentorRequests', 'req-batch-1'), {
    ownerUid: 'student-1',
    studentUid: 'student-1',
    studentName: 'Student One',
    studentPhotoUrl: '',
    mentorUid: 'mentor-1',
    mentorName: 'Mentor One',
    mentorPhotoUrl: '',
    message: 'Looking for architecture mentorship on my app.',
    goals: 'Architecture review',
    status: 'pending',
    responseNote: '',
    respondedAt: null,
    createdAt: ts(),
    updatedAt: ts(),
  });
  validBatch.set(doc(s1Db, 'notifications', 'mr_req_req-batch-1'), {
    ownerUid: 'mentor-1',
    title: 'New mentorship request',
    body: 'Student One sent you a request.',
    type: 'mentorshipRequest',
    route: '/m/requests',
    sourceCollection: 'mentorRequests',
    sourceId: 'req-batch-1',
    isRead: false,
    readAt: null,
    status: 'unread',
    createdAt: ts(),
    updatedAt: ts(),
  });
  await assertSucceeds(validBatch.commit());

  await assertFails(
    setDoc(doc(s1Db, 'notifications', 'spoof-notif'), {
      ownerUid: 'student-2',
      title: 'Fake alert',
      body: 'Spam notification from another user.',
      type: 'system',
      route: '/home',
      sourceCollection: 'mentorRequests',
      sourceId: 'req-batch-1',
      isRead: false,
      readAt: null,
      status: 'unread',
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Admin revokes mentor-1 -> immediately blocked even while holding mentor token claim.
  await assertSucceeds(
    updateDoc(doc(adminDb, 'mentorApplications', 'mentor-1'), {
      status: 'revoked',
      rejectionReason: 'Violated mentoring code of conduct.',
      reviewedBy: 'admin-1',
      reviewedAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertSucceeds(
    updateDoc(doc(adminDb, 'users', 'mentor-1'), {
      role: 'student',
      isApproved: false,
      updatedAt: ts(),
    }),
  );
  await assertFails(
    setDoc(doc(m1Db, 'courses', 'mc-after-revoke'), {
      ownerUid: 'mentor-1',
      ownerName: 'Mentor One',
      title: 'Blocked After Revoke',
      summary: 'Should fail immediately on Spark.',
      status: 'draft',
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Deactivated student cannot access platform collections (only read own users/{uid}).
  await assertSucceeds(
    updateDoc(doc(adminDb, 'users', 'student-1'), {
      status: 'deactivated',
      updatedAt: ts(),
    }),
  );
  await assertSucceeds(getDoc(doc(s1Db, 'users', 'student-1')));
  await assertFails(getDoc(doc(s1Db, 'courses', 'mc-1')));
  await assertFails(getDoc(doc(s2Db, 'users', 'student-1')));
});

test('mentor registration persists pending mentor role across signup and verification while blocking mentor and student actions until admin approval', async () => {
  const unverifiedAppDb = testEnv
    .authenticatedContext('app-2', { email_verified: false })
    .firestore();
  const appDb = unapprovedApplicant('app-2').firestore();
  const anotherMentorDb = verifiedMentor('mentor-other').firestore();

  // Unverified mentor cannot forge isApproved=true, approvalStatus='approved', or emailVerified=true.
  await assertFails(
    setDoc(doc(unverifiedAppDb, 'users', 'app-2'), {
      ownerUid: 'app-2',
      email: 'kevine@upbridge.rw',
      displayName: 'Kevine Mukiza',
      phone: '+250 788 123 456',
      role: 'mentor',
      isApproved: true,
      approvalStatus: 'approved',
      emailVerified: false,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Unverified mentor signup persists role=mentor, approvalStatus=pending, emailVerified=false.
  await assertSucceeds(
    setDoc(doc(unverifiedAppDb, 'users', 'app-2'), {
      ownerUid: 'app-2',
      email: 'kevine@upbridge.rw',
      displayName: 'Kevine Mukiza',
      phone: '+250 788 123 456',
      role: 'mentor',
      isApproved: false,
      approvalStatus: 'pending',
      emailVerified: false,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertSucceeds(
    setDoc(doc(unverifiedAppDb, 'mentorApplications', 'app-2'), {
      ownerUid: 'app-2',
      applicantName: 'Kevine Mukiza',
      applicantEmail: 'kevine@upbridge.rw',
      headline: 'Staff Mobile Engineer',
      profession: 'Mobile Architect',
      education: 'BSc CS, University of Rwanda',
      bio: '8 years building production mobile platforms across East Africa.',
      expertise: ['Mobile Development'],
      skills: ['Flutter', 'Firebase'],
      experienceYears: 8,
      availability: 'Tue & Thu 18:00 CAT',
      mentoringInterests: 'Portfolio code reviews',
      maxMentees: 5,
      cvAsset: null,
      supportingLinks: ['https://github.com/kevine'],
      status: 'pending',
      rejectionReason: '',
      reviewedBy: null,
      reviewedAt: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Once email is verified, user may sync emailVerified=true ONLY while keeping mentor/pending.
  await assertSucceeds(
    updateDoc(doc(appDb, 'users', 'app-2'), {
      emailVerified: true,
      updatedAt: ts(),
    }),
  );

  // Pending applicant can refine details while remaining pending with null reviewer fields.
  await assertSucceeds(
    updateDoc(doc(appDb, 'mentorApplications', 'app-2'), {
      headline: 'Principal Mobile Engineer',
      maxMentees: 8,
      reviewedBy: null,
      reviewedAt: null,
      rejectionReason: '',
      status: 'pending',
      updatedAt: ts(),
    }),
  );

  // Self-approval, tampering with approvalStatus, mentor courses, and student requests all fail.
  await assertFails(
    updateDoc(doc(appDb, 'mentorApplications', 'app-2'), {
      status: 'approved',
      updatedAt: ts(),
    }),
  );
  await assertFails(
    updateDoc(doc(appDb, 'users', 'app-2'), {
      isApproved: true,
      approvalStatus: 'approved',
    }),
  );
  await assertFails(
    updateDoc(doc(appDb, 'users', 'app-2'), {
      approvalStatus: 'approved',
    }),
  );
  await assertFails(
    setDoc(doc(appDb, 'courses', 'unapproved-course'), {
      ownerUid: 'app-2',
      ownerName: 'Kevine Mukiza',
      title: 'Unauthorized Course',
      summary: 'Pending mentor must not create courses.',
      status: 'draft',
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertFails(
    setDoc(doc(appDb, 'mentorRequests', 'pending-mentor-req'), {
      ownerUid: 'app-2',
      studentUid: 'app-2',
      studentName: 'Kevine Mukiza',
      studentPhotoUrl: '',
      mentorUid: 'mentor-other',
      mentorName: 'Other Mentor',
      mentorPhotoUrl: '',
      message: 'Should be blocked',
      goals: 'Test',
      status: 'pending',
      responseNote: '',
      respondedAt: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Non-admin verified mentor cannot approve another applicant.
  await assertFails(
    updateDoc(doc(anotherMentorDb, 'mentorApplications', 'app-2'), {
      status: 'approved',
      reviewedBy: 'mentor-other',
      reviewedAt: ts(),
      updatedAt: ts(),
    }),
  );
});

test('authorization attack matrix: privilege escalation, private reads, protected fields & courseProgress forgery', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users', 'student-1'), {
      ownerUid: 'student-1',
      email: 's1@test.rw',
      displayName: 'Student One',
      phone: '',
      role: 'student',
      isApproved: false,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'profiles', 'student-1'), {
      ownerUid: 'student-1',
      displayName: 'Student One',
      headline: 'Aspiring Developer',
      location: 'Kigali',
      about: 'Learning Dart',
      photoAsset: null,
      cvAsset: null,
      skills: ['Dart'],
      interests: ['it'],
      learningGoal: 'job',
      education: [],
      experience: [],
      certificates: [],
      isMentorPublic: false,
      status: 'active',
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'users', 'mentor-1'), {
      ownerUid: 'mentor-1',
      email: 'm1@test.rw',
      displayName: 'Mentor One',
      phone: '',
      role: 'mentor',
      isApproved: true,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'courses', 'draft-course'), {
      ownerUid: 'mentor-1',
      ownerName: 'Mentor One',
      title: 'Hidden Draft Course',
      summary: 'Still in authoring mode.',
      category: 'it',
      customCategory: '',
      level: 'beginner',
      estimatedMinutes: 45,
      learningObjectives: ['Basics'],
      resources: [],
      modules: [],
      skills: ['Flutter'],
      coverAsset: null,
      status: 'draft',
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'courses', 'pub-course'), {
      ownerUid: 'mentor-1',
      ownerName: 'Mentor One',
      title: 'Published Architecture Course',
      summary: 'Open for enrolled youth.',
      category: 'it',
      customCategory: '',
      level: 'intermediate',
      estimatedMinutes: 60,
      learningObjectives: ['Architecture'],
      resources: [],
      modules: [{ id: 'm1', title: 'Intro', summary: 'Overview', resourceUrl: '', estimatedMinutes: 20 }],
      skills: ['Flutter'],
      coverAsset: null,
      status: 'published',
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'applications', 'app-priv-1'), {
      ownerUid: 'student-1',
      studentUid: 'student-1',
      studentName: 'Student One',
      opportunityId: 'opp-1',
      opportunityTitle: 'Junior Dev',
      projectIds: [],
      coverNote: 'My application',
      cvAsset: null,
      status: 'submitted',
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'notifications', 'notif-priv-1'), {
      ownerUid: 'student-1',
      title: 'Private alert',
      body: 'Private details for student-1.',
      type: 'system',
      route: '/home',
      isRead: false,
      readAt: null,
      status: 'unread',
      createdAt: ts(),
      updatedAt: ts(),
    });
  });

  const s1Db = verifiedStudent('student-1').firestore();
  const s2Db = verifiedStudent('student-2').firestore();
  const m1Db = verifiedMentor('mentor-1').firestore();
  const m2Db = verifiedMentor('mentor-2').firestore();

  // 1. Admin role escalation denied on self-signup, user update, and opportunities.
  await assertFails(
    setDoc(doc(s2Db, 'users', 'student-2'), {
      ownerUid: 'student-2',
      email: 's2@test.rw',
      displayName: 'Fake Admin',
      phone: '',
      role: 'admin',
      isApproved: true,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertFails(
    updateDoc(doc(s1Db, 'users', 'student-1'), { role: 'admin', isApproved: true }),
  );
  await assertFails(
    setDoc(doc(m1Db, 'opportunities', 'opp-hack'), {
      ownerUid: 'mentor-1',
      title: 'Unauthorized Opp',
      status: 'open',
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // 2. Accessing other users' private applications, notifications, and courseProgress fails.
  await assertFails(getDoc(doc(s2Db, 'applications', 'app-priv-1')));
  await assertFails(getDoc(doc(s2Db, 'notifications', 'notif-priv-1')));
  await assertFails(getDoc(doc(m1Db, 'applications', 'app-priv-1')));

  // 3. Student cannot mutate protected mentor/ownership fields on profiles/{uid}.
  await assertFails(
    updateDoc(doc(s1Db, 'profiles', 'student-1'), {
      isMentorPublic: true,
      updatedAt: ts(),
    }),
  );
  await assertFails(
    updateDoc(doc(s1Db, 'profiles', 'student-1'), {
      mentorBio: 'Claiming mentor bio illegally',
      updatedAt: ts(),
    }),
  );
  await assertFails(
    updateDoc(doc(s1Db, 'profiles', 'student-1'), {
      ownerUid: 'student-2',
      updatedAt: ts(),
    }),
  );

  // 4. Injecting unexpected fields or editing another mentor's course fails.
  await assertFails(
    setDoc(doc(m1Db, 'courses', 'course-extra-field'), {
      ownerUid: 'mentor-1',
      ownerName: 'Mentor One',
      title: 'Injected Course',
      summary: 'Contains disallowed extra field.',
      category: 'it',
      customCategory: '',
      level: 'beginner',
      estimatedMinutes: 30,
      learningObjectives: [],
      resources: [],
      modules: [],
      skills: [],
      coverAsset: null,
      status: 'draft',
      isVerifiedOfficial: true,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertFails(
    updateDoc(doc(m2Db, 'courses', 'pub-course'), {
      title: 'Hijacked By M2',
      updatedAt: ts(),
    }),
  );

  // 5. courseProgress blocks draft/nonexistent courses and forged courseOwnerUid; another student cannot read.
  await assertFails(
    setDoc(doc(s1Db, 'courseProgress', 'student-1_draft-course'), {
      ownerUid: 'student-1',
      courseId: 'draft-course',
      courseTitle: 'Hidden Draft Course',
      courseOwnerUid: 'mentor-1',
      completedModuleIds: [],
      progressPercent: 0,
      evidenceUrl: '',
      evidenceAsset: null,
      status: 'inProgress',
      completedAt: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertFails(
    setDoc(doc(s1Db, 'courseProgress', 'student-1_missing-course'), {
      ownerUid: 'student-1',
      courseId: 'missing-course',
      courseTitle: 'Missing Course',
      courseOwnerUid: 'mentor-1',
      completedModuleIds: [],
      progressPercent: 0,
      evidenceUrl: '',
      evidenceAsset: null,
      status: 'inProgress',
      completedAt: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertFails(
    setDoc(doc(s1Db, 'courseProgress', 'student-1_pub-course'), {
      ownerUid: 'student-1',
      courseId: 'pub-course',
      courseTitle: 'Published Architecture Course',
      courseOwnerUid: 'mentor-2',
      completedModuleIds: ['m1'],
      progressPercent: 100,
      evidenceUrl: '',
      evidenceAsset: null,
      status: 'completed',
      completedAt: ts(),
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertSucceeds(
    setDoc(doc(s1Db, 'courseProgress', 'student-1_pub-course'), {
      ownerUid: 'student-1',
      courseId: 'pub-course',
      courseTitle: 'Published Architecture Course',
      courseOwnerUid: 'mentor-1',
      completedModuleIds: ['m1'],
      progressPercent: 100,
      evidenceUrl: '',
      evidenceAsset: null,
      status: 'completed',
      completedAt: ts(),
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertFails(getDoc(doc(s2Db, 'courseProgress', 'student-1_pub-course')));
});

test('legacy users with accountStatus or missing status can read profiles, projects, courses and mentors; legacy deactivated stays blocked', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const adminDb = ctx.firestore();
    await setDoc(doc(adminDb, 'users', 'legacy-active'), {
      ownerUid: 'legacy-active',
      email: 'legacy@upbridge.rw',
      displayName: 'Legacy Student',
      role: 'youth',
      accountStatus: 'active',
      onboarded: true,
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(adminDb, 'users', 'legacy-deactivated'), {
      ownerUid: 'legacy-deactivated',
      email: 'blocked@upbridge.rw',
      displayName: 'Legacy Blocked',
      role: 'youth',
      accountStatus: 'deactivated',
      onboarded: true,
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(adminDb, 'profiles', 'mentor-pub'), {
      ownerUid: 'mentor-pub',
      displayName: 'Mentor Public',
      isMentorPublic: true,
      status: 'active',
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(adminDb, 'courses', 'course-pub'), {
      ownerUid: 'admin-1',
      title: 'Flutter Career Track',
      summary: 'Learn Flutter fundamentals',
      status: 'published',
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(adminDb, 'projects', 'proj-1'), {
      ownerUid: 'legacy-active',
      title: 'My Portfolio App',
      description: 'Built a mobile solution in Kigali.',
      skills: ['Flutter'],
      images: [],
      attachments: [],
      isPublic: false,
      status: 'draft',
      createdAt: ts(),
      updatedAt: ts(),
    });
  });

  const activeDb = verifiedStudent('legacy-active').firestore();
  const deactivatedDb = verifiedStudent('legacy-deactivated').firestore();

  // Even when profiles/{uid} does not exist yet, owner read succeeds instead of throwing permission-denied.
  await assertSucceeds(getDoc(doc(activeDb, 'profiles', 'legacy-active')));

  // Owner projects query matching FirestoreProjectRepository.watchUserProjects succeeds.
  await assertSucceeds(
    getDocs(
      query(
        collection(activeDb, 'projects'),
        where('ownerUid', '==', 'legacy-active'),
        orderBy('createdAt', 'desc'),
      ),
    ),
  );

  // Published courses & mentors discovery queries succeed.
  await assertSucceeds(
    getDocs(
      query(
        collection(activeDb, 'courses'),
        where('status', '==', 'published'),
        orderBy('createdAt', 'desc'),
      ),
    ),
  );
  await assertSucceeds(
    getDocs(
      query(
        collection(activeDb, 'profiles'),
        where('isMentorPublic', '==', true),
        where('status', '==', 'active'),
        orderBy('updatedAt', 'desc'),
      ),
    ),
  );

  // Legacy active user can update safe account flags.
  await assertSucceeds(
    updateDoc(doc(activeDb, 'users', 'legacy-active'), {
      onboarded: true,
      updatedAt: ts(),
    }),
  );

  // Legacy deactivated account remains blocked across all collections.
  await assertFails(getDoc(doc(deactivatedDb, 'profiles', 'legacy-deactivated')));
  await assertFails(
    getDocs(
      query(
        collection(deactivatedDb, 'projects'),
        where('ownerUid', '==', 'legacy-deactivated'),
        orderBy('createdAt', 'desc'),
      ),
    ),
  );
  await assertFails(
    getDocs(
      query(
        collection(deactivatedDb, 'courses'),
        where('status', '==', 'published'),
        orderBy('createdAt', 'desc'),
      ),
    ),
  );
});

test('Phase 2 & 8 hardening: Youth cannot create mentorApplications, demoted admins fail closed, missing users fail isStudent, mentors read-mark notifications, and mail is admin-only', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users', 'youth-locked'), {
      ownerUid: 'youth-locked',
      email: 'youth@test.rw',
      displayName: 'Locked Youth',
      phone: '',
      role: 'student',
      isApproved: false,
      approvalStatus: 'notRequired',
      emailVerified: true,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'users', 'demoted-admin'), {
      ownerUid: 'demoted-admin',
      email: 'demoted@test.rw',
      displayName: 'Former Admin',
      phone: '',
      role: 'student',
      isApproved: false,
      approvalStatus: 'notRequired',
      emailVerified: true,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'users', 'corrupt-user'), {
      ownerUid: 'corrupt-user',
      email: 'corrupt@test.rw',
      displayName: 'Corrupt User',
      phone: '',
      role: 'superhacker',
      isApproved: false,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'notifications', 'mentor-notif-1'), {
      ownerUid: 'mentor-1',
      title: 'Welcome mentor',
      body: 'Approved!',
      type: 'mentorApproval',
      route: '/m/home',
      isRead: false,
      readAt: null,
      status: 'unread',
      createdAt: ts(),
      updatedAt: ts(),
    });
  });

  const youthDb = verifiedStudent('youth-locked').firestore();
  const demotedAdminDb = verifiedAdmin('demoted-admin').firestore();
  const orphanDb = testEnv
    .authenticatedContext('orphan-no-doc', { email_verified: true })
    .firestore();
  const corruptDb = verifiedStudent('corrupt-user').firestore();
  const mentorDb = verifiedMentor('mentor-1').firestore();
  const adminDb = verifiedAdmin('admin-real').firestore();

  // 1. Existing Youth (users/{uid}.role == 'student') cannot create mentorApplications/{uid}.
  await assertFails(
    setDoc(doc(youthDb, 'mentorApplications', 'youth-locked'), {
      ownerUid: 'youth-locked',
      applicantName: 'Locked Youth',
      applicantEmail: 'youth@test.rw',
      headline: 'Attempting self upgrade',
      bio: 'Trying to convert student account into mentor account illegally.',
      expertise: ['Web Development'],
      experienceYears: 3,
      availability: 'Weekends',
      cvAsset: null,
      supportingLinks: [],
      status: 'pending',
      rejectionReason: '',
      reviewedBy: null,
      reviewedAt: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // 2. Demoted admin (token still carries role='admin', Firestore role='student') cannot perform admin writes.
  await assertFails(
    setDoc(doc(demotedAdminDb, 'opportunities', 'hacked-opp'), {
      ownerUid: 'demoted-admin',
      title: 'Stale Admin Claim Hack',
      status: 'published',
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // 3. Verified user with NO users/{uid} doc (and corrupt role doc) fails isStudent() on project creation.
  await assertFails(
    setDoc(doc(orphanDb, 'projects', 'orphan-proj'), {
      ownerUid: 'orphan-no-doc',
      title: 'Should Fail Without User Doc',
      description: 'Users without a valid student account record cannot bypass role rules.',
      skills: ['Dart'],
      images: [],
      attachments: [],
      isPublic: false,
      status: 'draft',
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertFails(
    setDoc(doc(corruptDb, 'projects', 'corrupt-proj'), {
      ownerUid: 'corrupt-user',
      title: 'Should Fail With Corrupt Role',
      description: 'Users with invalid role strings cannot bypass role rules.',
      skills: ['Dart'],
      images: [],
      attachments: [],
      isPublic: false,
      status: 'draft',
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // 4. Approved mentor CAN mark their own notification as read.
  await assertSucceeds(
    updateDoc(doc(mentorDb, 'notifications', 'mentor-notif-1'), {
      isRead: true,
      status: 'read',
      readAt: ts(),
      updatedAt: ts(),
    }),
  );

  // 5. mail/ collection (Trigger Email) is strictly admin-only and immutable after create.
  await assertFails(
    setDoc(doc(youthDb, 'mail', 'spoof-mail'), {
      to: ['someone@test.rw'],
      message: { subject: 'Spoof', text: 'Hack' },
    }),
  );
  await assertSucceeds(
    setDoc(doc(adminDb, 'mail', 'mentor_approval_m1'), {
      to: ['mentor@test.rw'],
      message: {
        subject: "You're Approved! Welcome to SkillBridge as a Mentor",
        text: 'Welcome!',
      },
      createdAt: ts(),
    }),
  );
  await assertFails(deleteDoc(doc(adminDb, 'mail', 'mentor_approval_m1')));

  // 6. Revoked mentor (even holding stale mentor claim) cannot set isMentorPublic, write courses,
  //    or impersonate Youth, while valid field-scoped resubmission preserves admin approvalEmail* metadata.
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users', 'revoked-m1'), {
      ownerUid: 'revoked-m1',
      email: 'revoked@test.rw',
      displayName: 'Revoked Mentor',
      phone: '',
      role: 'mentor',
      isApproved: false,
      approvalStatus: 'revoked',
      emailVerified: true,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'profiles', 'revoked-m1'), {
      ownerUid: 'revoked-m1',
      displayName: 'Revoked Mentor',
      headline: 'Backend Lead',
      location: 'Kigali',
      about: 'Mentoring engineers.',
      photoAsset: null,
      cvAsset: null,
      skills: ['Dart'],
      interests: [],
      learningGoal: '',
      professionalLinks: [],
      education: [],
      experience: [],
      certificates: [],
      isMentorPublic: false,
      status: 'active',
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'mentorApplications', 'revoked-m1'), {
      ownerUid: 'revoked-m1',
      applicantName: 'Revoked Mentor',
      applicantEmail: 'revoked@test.rw',
      headline: 'Backend Lead',
      profession: 'Staff Engineer',
      education: 'BSc CS',
      bio: 'Mentoring Rwandan youth engineers for 7 years.',
      expertise: ['Web Development'],
      skills: ['Dart'],
      experienceYears: 7,
      availability: 'Weekends',
      mentoringInterests: 'Code review',
      maxMentees: 5,
      cvAsset: null,
      supportingLinks: [],
      status: 'revoked',
      rejectionReason: 'Availability lapsed',
      reviewedBy: 'admin-real',
      reviewedAt: ts(),
      approvalEmailStatus: 'sent',
      approvalEmailRecipient: 'revoked@test.rw',
      approvalEmailAttempts: 1,
      approvalEmailMessageId: 'msg-prev-1',
      createdAt: ts(),
      updatedAt: ts(),
    });
  });

  const revokedMentorDb = verifiedMentor('revoked-m1').firestore();
  await assertFails(
    updateDoc(doc(revokedMentorDb, 'profiles', 'revoked-m1'), {
      isMentorPublic: true,
      updatedAt: ts(),
    }),
  );
  await assertFails(
    setDoc(doc(revokedMentorDb, 'courses', 'revoked-c1'), {
      ownerUid: 'revoked-m1',
      ownerName: 'Revoked Mentor',
      title: 'Blocked Course',
      summary: 'Revoked mentors cannot author courses even with stale token claim.',
      status: 'draft',
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertFails(
    setDoc(doc(revokedMentorDb, 'courseProgress', 'revoked-m1_c-1'), {
      ownerUid: 'revoked-m1',
      courseId: 'c-1',
      courseTitle: 'Course',
      courseOwnerUid: 'mentor-1',
      completedModuleIds: [],
      progressPercent: 10,
      evidenceUrl: '',
      evidenceAsset: null,
      status: 'inProgress',
      completedAt: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  // Resubmission updating only owner-editable fields succeeds even when admin approvalEmail* metadata exists.
  await assertSucceeds(
    updateDoc(doc(revokedMentorDb, 'mentorApplications', 'revoked-m1'), {
      bio: 'Updated bio with renewed availability for Rwandan youth developers.',
      status: 'pending',
      rejectionReason: '',
      reviewedBy: null,
      reviewedAt: null,
      updatedAt: ts(),
    }),
  );
  await assertFails(
    updateDoc(doc(revokedMentorDb, 'mentorApplications', 'revoked-m1'), {
      approvalEmailStatus: 'tampered',
      updatedAt: ts(),
    }),
  );
});

test('Youth students can read non-existent own courseProgress/applications, submit courses (even when course ownerUid is null/empty), and submit/withdraw/resubmit opportunity applications', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users', 'youth-plain'), {
      ownerUid: 'youth-plain',
      email: 'plain@upbridge.rw',
      displayName: 'Plain Youth',
      phone: '',
      role: 'student',
      isApproved: false,
      approvalStatus: 'notRequired',
      emailVerified: true,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'users', 'youth-legacy'), {
      ownerUid: 'youth-legacy',
      email: 'legacyyouth@upbridge.rw',
      displayName: 'Legacy Youth',
      phone: '',
      role: 'youth',
      isApproved: false,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'courses', 'course-mentor'), {
      ownerUid: 'mentor-1',
      ownerName: 'Mentor One',
      title: 'Mobile Craft',
      summary: 'Build mobile interfaces cleanly.',
      status: 'published',
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'courses', 'course-no-owner'), {
      ownerUid: null,
      title: 'Admin Legacy Course',
      summary: 'Legacy course without an ownerUid.',
      status: 'published',
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'opportunities', 'opp-open'), {
      ownerUid: 'admin-1',
      title: 'Junior Software Intern',
      organization: 'Kigali Labs',
      location: 'Kigali, Rwanda',
      type: 'internship',
      description: 'Join our engineering cohort in Kigali.',
      deadline: ts(),
      status: 'published',
      createdAt: ts(),
      updatedAt: ts(),
    });
  });

  // Note: real email/password youth accounts have NO custom role claim on token.
  const plainYouthDb = testEnv
    .authenticatedContext('youth-plain', { email_verified: true })
    .firestore();
  const legacyYouthDb = testEnv
    .authenticatedContext('youth-legacy', {
      email_verified: true,
      role: 'youth',
    })
    .firestore();

  // 1. Pre-create getDoc on own deterministic IDs must succeed when document does not exist yet (tx.get / snapshots),
  //    while reading another user's non-existent deterministic doc stays denied.
  await assertSucceeds(
    getDoc(doc(plainYouthDb, 'courseProgress', 'youth-plain_course-mentor')),
  );
  await assertSucceeds(
    getDoc(doc(plainYouthDb, 'applications', 'youth-plain_opp-open')),
  );
  await assertFails(
    getDoc(doc(legacyYouthDb, 'courseProgress', 'youth-plain_course-mentor')),
  );
  await assertFails(
    getDoc(doc(legacyYouthDb, 'applications', 'youth-plain_opp-open')),
  );

  // 2. Submit course completion for mentor-owned course and legacy null-owner course.
  await assertSucceeds(
    setDoc(doc(plainYouthDb, 'courseProgress', 'youth-plain_course-mentor'), {
      ownerUid: 'youth-plain',
      courseId: 'course-mentor',
      courseTitle: 'Mobile Craft',
      courseOwnerUid: 'mentor-1',
      completedModuleIds: ['m1'],
      progressPercent: 100,
      evidenceUrl: 'https://github.com/youth/mobile-craft',
      evidenceAsset: null,
      status: 'completed',
      completedAt: ts(),
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertSucceeds(
    updateDoc(doc(plainYouthDb, 'courseProgress', 'youth-plain_course-mentor'), {
      courseTitle: 'Mobile Craft',
      courseOwnerUid: 'mentor-1',
      completedModuleIds: ['m1'],
      progressPercent: 100,
      evidenceUrl: 'https://github.com/youth/mobile-craft-v2',
      evidenceAsset: null,
      status: 'completed',
      completedAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertSucceeds(
    setDoc(doc(legacyYouthDb, 'courseProgress', 'youth-legacy_course-no-owner'), {
      ownerUid: 'youth-legacy',
      courseId: 'course-no-owner',
      courseTitle: 'Admin Legacy Course',
      courseOwnerUid: '',
      completedModuleIds: [],
      progressPercent: 100,
      evidenceUrl: 'https://github.com/youth/legacy',
      evidenceAsset: null,
      status: 'completed',
      completedAt: ts(),
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // 3. Submit opportunity application, withdraw, and resubmit with updated opportunityTitle/organization.
  await assertSucceeds(
    setDoc(doc(plainYouthDb, 'applications', 'youth-plain_opp-open'), {
      ownerUid: 'youth-plain',
      opportunityId: 'opp-open',
      opportunityTitle: 'Junior Software Intern',
      organization: 'Kigali Labs',
      studentName: 'Plain Youth',
      projectIds: ['proj-1'],
      coverNote:
        'I have built two Flutter apps and want to contribute to Kigali Labs.',
      cvAsset: null,
      status: 'submitted',
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertSucceeds(
    updateDoc(doc(plainYouthDb, 'applications', 'youth-plain_opp-open'), {
      status: 'withdrawn',
      updatedAt: ts(),
    }),
  );
  await assertSucceeds(
    updateDoc(doc(plainYouthDb, 'applications', 'youth-plain_opp-open'), {
      opportunityTitle: 'Junior Software Intern (Updated)',
      organization: 'Kigali Labs Rwanda',
      studentName: 'Plain Youth',
      projectIds: ['proj-1', 'proj-2'],
      coverNote:
        'Re-applying with updated portfolio links and project experience in Kigali.',
      cvAsset: null,
      status: 'submitted',
      updatedAt: ts(),
    }),
  );

  // Legacy youth user can also submit opportunity application.
  await assertSucceeds(
    setDoc(doc(legacyYouthDb, 'applications', 'youth-legacy_opp-open'), {
      ownerUid: 'youth-legacy',
      opportunityId: 'opp-open',
      opportunityTitle: 'Junior Software Intern',
      organization: 'Kigali Labs',
      studentName: 'Legacy Youth',
      projectIds: [],
      coverNote:
        'Excited to learn and contribute as a software intern in Kigali.',
      cvAsset: null,
      status: 'submitted',
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
});

test('students can book direct 1-on-1 sessions with approved public mentors, reschedule/cancel their sessions, and cannot complete or spoof mentors', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users', 'student-1'), {
      ownerUid: 'student-1',
      email: 's1@test.rw',
      displayName: 'Student One',
      role: 'student',
      isApproved: false,
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'users', 'mentor-1'), {
      ownerUid: 'mentor-1',
      email: 'm1@test.rw',
      displayName: 'Alice Mentor',
      role: 'mentor',
      isApproved: true,
      approvalStatus: 'approved',
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'profiles', 'mentor-1'), {
      ownerUid: 'mentor-1',
      displayName: 'Alice Mentor',
      isMentorPublic: true,
      status: 'active',
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'users', 'mentor-unapproved'), {
      ownerUid: 'mentor-unapproved',
      email: 'pending@test.rw',
      displayName: 'Pending Mentor',
      role: 'mentor',
      isApproved: false,
      approvalStatus: 'pending',
      status: 'active',
      onboarded: true,
      preferredLocale: 'en',
      photoAsset: null,
      createdAt: ts(),
      updatedAt: ts(),
    });
    await setDoc(doc(db, 'profiles', 'mentor-unapproved'), {
      ownerUid: 'mentor-unapproved',
      displayName: 'Pending Mentor',
      isMentorPublic: true,
      status: 'active',
      createdAt: ts(),
      updatedAt: ts(),
    });
  });

  const s1Db = verifiedStudent('student-1').firestore();
  const s2Db = verifiedStudent('student-2').firestore();
  const m1Db = verifiedMentor('mentor-1').firestore();

  // Direct booking batch (session + mentor notification) succeeds without an active mentorship doc.
  const bookBatch = writeBatch(s1Db);
  bookBatch.set(doc(s1Db, 'sessions', 'direct-sess-1'), {
    ownerUid: 'student-1',
    mentorshipId: '',
    studentUid: 'student-1',
    studentName: 'Student One',
    mentorUid: 'mentor-1',
    mentorName: 'Alice Mentor',
    topic: 'CV & Flutter portfolio feedback',
    notes: 'Want to review my Kigali Transit app before applying.',
    meetingMode: 'Online',
    meetingLink: 'https://meet.google.com/abc-defg-hij',
    scheduledAt: new Date('2026-12-01T15:00:00Z'),
    durationMinutes: 45,
    status: 'scheduled',
    cancelReason: '',
    completedAt: null,
    createdAt: ts(),
    updatedAt: ts(),
  });
  bookBatch.set(doc(s1Db, 'notifications', 'sess_new_direct-sess-1'), {
    ownerUid: 'mentor-1',
    title: 'New session booked',
    body: 'Student One booked "CV & Flutter portfolio feedback".',
    type: 'sessionScheduled',
    route: '/m/sessions',
    sourceCollection: 'sessions',
    sourceId: 'direct-sess-1',
    isRead: false,
    readAt: null,
    status: 'unread',
    createdAt: ts(),
    updatedAt: ts(),
  });
  await assertSucceeds(bookBatch.commit());

  // Unapproved mentor or self-booking or out-of-range duration fail.
  await assertFails(
    setDoc(doc(s1Db, 'sessions', 'direct-unapproved'), {
      ownerUid: 'student-1',
      mentorshipId: '',
      studentUid: 'student-1',
      studentName: 'Student One',
      mentorUid: 'mentor-unapproved',
      mentorName: 'Pending Mentor',
      topic: 'Portfolio review',
      notes: '',
      meetingMode: 'Online',
      meetingLink: '',
      scheduledAt: new Date('2026-12-02T15:00:00Z'),
      durationMinutes: 30,
      status: 'scheduled',
      cancelReason: '',
      completedAt: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertFails(
    setDoc(doc(s1Db, 'sessions', 'direct-self'), {
      ownerUid: 'student-1',
      mentorshipId: '',
      studentUid: 'student-1',
      studentName: 'Student One',
      mentorUid: 'student-1',
      mentorName: 'Student One',
      topic: 'Self session',
      notes: '',
      meetingMode: 'Online',
      meetingLink: '',
      scheduledAt: new Date('2026-12-02T15:00:00Z'),
      durationMinutes: 30,
      status: 'scheduled',
      cancelReason: '',
      completedAt: null,
      createdAt: ts(),
      updatedAt: ts(),
    }),
  );

  // Student can reschedule their own scheduled session, and mentor can read/complete it.
  await assertSucceeds(
    updateDoc(doc(s1Db, 'sessions', 'direct-sess-1'), {
      topic: 'Mock interview & Flutter CV review',
      notes: 'Focusing on state management questions.',
      meetingMode: 'In-person',
      meetingLink: 'Kigali Innovation City',
      scheduledAt: new Date('2026-12-03T14:00:00Z'),
      durationMinutes: 60,
      updatedAt: ts(),
    }),
  );

  // Unrelated student cannot read or modify another student's session.
  await assertFails(getDoc(doc(s2Db, 'sessions', 'direct-sess-1')));
  await assertFails(
    updateDoc(doc(s2Db, 'sessions', 'direct-sess-1'), {
      status: 'cancelled',
      cancelReason: 'Hijack',
      updatedAt: ts(),
    }),
  );

  // Student still cannot mark a session completed; only approved mentor can.
  await assertFails(
    updateDoc(doc(s1Db, 'sessions', 'direct-sess-1'), {
      status: 'completed',
      notes: 'Self-completed',
      completedAt: ts(),
      updatedAt: ts(),
    }),
  );
  await assertSucceeds(
    updateDoc(doc(m1Db, 'sessions', 'direct-sess-1'), {
      status: 'completed',
      notes: 'Great portfolio progress.',
      cancelReason: '',
      completedAt: ts(),
      updatedAt: ts(),
    }),
  );
});
