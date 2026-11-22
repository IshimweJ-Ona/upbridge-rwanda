import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/features/admin/domain/models/audit_log_entry.dart';
import 'package:upbridge/features/auth/domain/models/app_user_account.dart';
import 'package:upbridge/features/learning/domain/models/course.dart';
import 'package:upbridge/features/learning/domain/models/course_progress.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_request.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship_session.dart';
import 'package:upbridge/features/notifications/domain/models/user_notification.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_application.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_listing.dart';
import 'package:upbridge/features/profile/domain/models/portfolio_project.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';

void main() {
  final fixedTime = DateTime.utc(2026, 11, 19, 10, 30);
  final sampleAsset = MediaAsset(
    url: 'https://res.cloudinary.com/vbzq5ssu/image/upload/v1/sample.webp',
    publicId: 'upbridge/sample',
    resourceType: 'image',
    size: 42000,
    ownerUid: 'uid-1',
    createdAt: fixedTime,
  );

  group('Phase 1: Status lifecycle transitions', () {
    test(
      'allows valid mentor request transitions and blocks illegal jumps',
      () {
        expect(
          StatusTransitions.canTransition(
            StatusTransitions.mentorRequest,
            MentorRequestStatus.pending,
            MentorRequestStatus.accepted,
          ),
          isTrue,
        );
        expect(
          StatusTransitions.canTransition(
            StatusTransitions.mentorRequest,
            MentorRequestStatus.pending,
            MentorRequestStatus.cancelled,
          ),
          isTrue,
        );
        expect(
          StatusTransitions.canTransition(
            StatusTransitions.mentorRequest,
            MentorRequestStatus.declined,
            MentorRequestStatus.accepted,
          ),
          isFalse,
        );
        expect(
          () => StatusTransitions.requireTransition(
            StatusTransitions.mentorRequest,
            MentorRequestStatus.accepted,
            MentorRequestStatus.cancelled,
          ),
          throwsStateError,
        );
      },
    );

    test('enforces mentorship and session lifecycles', () {
      expect(
        StatusTransitions.canTransition(
          StatusTransitions.mentorship,
          MentorshipStatus.active,
          MentorshipStatus.completed,
        ),
        isTrue,
      );
      expect(
        StatusTransitions.canTransition(
          StatusTransitions.mentorship,
          MentorshipStatus.completed,
          MentorshipStatus.active,
        ),
        isFalse,
      );
      expect(
        StatusTransitions.canTransition(
          StatusTransitions.session,
          SessionStatus.scheduled,
          SessionStatus.completed,
        ),
        isTrue,
      );
      expect(
        StatusTransitions.canTransition(
          StatusTransitions.session,
          SessionStatus.cancelled,
          SessionStatus.completed,
        ),
        isFalse,
      );
    });

    test('enforces mentor application transitions', () {
      expect(
        StatusTransitions.canTransition(
          StatusTransitions.mentorApplication,
          MentorApplicationStatus.pending,
          MentorApplicationStatus.approved,
        ),
        isTrue,
      );
      expect(
        StatusTransitions.canTransition(
          StatusTransitions.mentorApplication,
          MentorApplicationStatus.rejected,
          MentorApplicationStatus.pending,
        ),
        isTrue,
      );
      expect(
        StatusTransitions.canTransition(
          StatusTransitions.mentorApplication,
          MentorApplicationStatus.approved,
          MentorApplicationStatus.rejected,
        ),
        isFalse,
      );
    });
  });

  group('Phase 1: Typed Firestore model roundtrips', () {
    test('MediaAsset stores exact Cloudinary metadata fields only', () {
      final json = sampleAsset.toJson();
      expect(json.keys.toSet(), {
        'url',
        'publicId',
        'resourceType',
        'size',
        'ownerUid',
        'createdAt',
      });
      expect(json['createdAt'], isA<Timestamp>());
      expect(MediaAsset.fromJson(json), equals(sampleAsset));
    });

    test('AppUserAccount roundtrips cleanly', () {
      final account = AppUserAccount(
        id: 'uid-1',
        ownerUid: 'uid-1',
        email: 'student@upbridge.rw',
        displayName: 'Aline Uwase',
        phone: '+250 788 000 111',
        role: UserRole.student,
        isApproved: false,
        status: AccountStatus.active,
        onboarded: true,
        preferredLocale: 'en',
        photoAsset: sampleAsset,
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final restored = AppUserAccount.fromJson(account.toJson(), id: 'uid-1');
      expect(restored.ownerUid, 'uid-1');
      expect(restored.role, UserRole.student);
      expect(restored.status, AccountStatus.active);
      expect(restored.photoAsset, equals(sampleAsset));
    });

    test('UserProfile and PortfolioProject roundtrip CV and evidence', () {
      final profile = UserProfile(
        id: 'uid-1',
        ownerUid: 'uid-1',
        displayName: 'Aline Uwase',
        headline: 'Junior Flutter Developer',
        location: 'Kigali, Rwanda',
        about: 'Building civic mobile tools.',
        photoAsset: sampleAsset,
        skills: const ['Flutter', 'Dart', 'Firebase'],
        education: const [
          EducationEntry(
            id: 'edu-1',
            institution: 'University of Rwanda',
            program: 'BSc Computer Science',
            period: '2022–2026',
          ),
        ],
        experience: const [
          ExperienceEntry(
            id: 'exp-1',
            roleTitle: 'Mobile Intern',
            organization: 'Kigali Tech Hub',
            period: '2025',
          ),
        ],
        certificates: [
          CertificateEntry(
            id: 'cert-1',
            title: 'Dart Fundamentals',
            issuer: 'UpBridge',
            issuedDate: '2026',
            evidenceAsset: sampleAsset,
          ),
        ],
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final restoredProfile = UserProfile.fromJson(
        profile.toJson(),
        id: 'uid-1',
      );
      expect(restoredProfile.headline, 'Junior Flutter Developer');
      expect(
        restoredProfile.education.single.institution,
        'University of Rwanda',
      );
      expect(
        restoredProfile.certificates.single.evidenceAsset,
        equals(sampleAsset),
      );

      final project = PortfolioProject(
        id: 'proj-1',
        ownerUid: 'uid-1',
        title: 'Kigali Transit Tracker',
        description: 'Live bus ETA app.',
        skills: const ['Flutter', 'REST'],
        projectUrl: 'https://example.com',
        images: [sampleAsset],
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final restoredProject = PortfolioProject.fromJson(
        project.toJson(),
        id: 'proj-1',
      );
      expect(restoredProject.title, 'Kigali Transit Tracker');
      expect(restoredProject.images.single, equals(sampleAsset));
      expect(restoredProject.status, ProjectStatus.published);
    });

    test('Mentorship domain models roundtrip cleanly', () {
      final app = MentorApplication(
        id: 'm-1',
        ownerUid: 'm-1',
        applicantName: 'Alice Mentor',
        applicantEmail: 'alice@mentor.rw',
        headline: 'Senior Engineer',
        bio: '8 years building backend systems.',
        expertise: const ['Backend', 'Architecture'],
        experienceYears: 8,
        cvAsset: sampleAsset,
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      expect(
        MentorApplication.fromJson(app.toJson(), id: 'm-1').status,
        MentorApplicationStatus.pending,
      );

      final req = MentorRequest(
        id: 'req-1',
        ownerUid: 's-1',
        studentUid: 's-1',
        studentName: 'Student One',
        mentorUid: 'm-1',
        mentorName: 'Alice Mentor',
        message: 'Would love guidance on system design.',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      expect(
        MentorRequest.fromJson(req.toJson(), id: 'req-1').mentorUid,
        'm-1',
      );

      final mentorship = Mentorship(
        id: 'req-1',
        ownerUid: 's-1',
        studentUid: 's-1',
        studentName: 'Student One',
        mentorUid: 'm-1',
        mentorName: 'Alice Mentor',
        requestId: 'req-1',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      expect(
        Mentorship.fromJson(mentorship.toJson(), id: 'req-1').status,
        MentorshipStatus.active,
      );

      final session = MentorshipSession(
        id: 'sess-1',
        ownerUid: 's-1',
        mentorshipId: 'req-1',
        studentUid: 's-1',
        studentName: 'Student One',
        mentorUid: 'm-1',
        mentorName: 'Alice Mentor',
        topic: 'Portfolio review',
        scheduledAt: fixedTime,
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      expect(
        MentorshipSession.fromJson(session.toJson(), id: 'sess-1').status,
        SessionStatus.scheduled,
      );
    });

    test(
      'Course, Opportunity, Notification, and AuditLog models roundtrip',
      () {
        final course = Course(
          id: 'c-1',
          ownerUid: 'admin-1',
          title: 'Git & Collaboration',
          summary: 'Branches and PR reviews.',
          category: CourseCategory.custom,
          customCategory: 'AgriTech & IoT',
          level: 'Bootcamp',
          modules: const [
            CourseModule(
              id: 'm1',
              title: 'Branching',
              summary: 'Create branches',
              resourceUrl: 'https://example.com/git',
              estimatedMinutes: 35,
            ),
          ],
          coverAsset: sampleAsset,
          status: CourseStatus.published,
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );
        final roundtrippedCourse = Course.fromJson(course.toJson(), id: 'c-1');
        expect(roundtrippedCourse.modules.single.title, 'Branching');
        expect(roundtrippedCourse.modules.single.estimatedMinutes, 35);
        expect(roundtrippedCourse.displayCategory, 'AgriTech & IoT');
        expect(roundtrippedCourse.level, 'Bootcamp');
        expect(roundtrippedCourse.coverAsset?.publicId, sampleAsset.publicId);

        final progress = CourseProgress(
          id: 's-1_c-1',
          ownerUid: 's-1',
          courseId: 'c-1',
          courseTitle: 'Git & Collaboration',
          completedModuleIds: const ['m1'],
          progressPercent: 100,
          status: CourseProgressStatus.completed,
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );
        expect(
          CourseProgress.fromJson(progress.toJson(), id: 's-1_c-1').status,
          CourseProgressStatus.completed,
        );

        final opp = OpportunityListing(
          id: 'o-1',
          ownerUid: 'admin-1',
          title: 'Flutter Intern',
          organization: 'Irembo',
          location: 'Kigali',
          type: OpportunityType.custom,
          customType: 'Venture Grant',
          workMode: 'Hybrid',
          compensation: 'RWF 300,000/mo',
          coverAsset: sampleAsset,
          description: 'Build public services.',
          deadline: fixedTime.add(const Duration(days: 14)),
          status: OpportunityStatus.published,
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );
        final roundtrippedOpp = OpportunityListing.fromJson(
          opp.toJson(),
          id: 'o-1',
        );
        expect(roundtrippedOpp.organization, 'Irembo');
        expect(roundtrippedOpp.displayType, 'Venture Grant');
        expect(roundtrippedOpp.workMode, 'Hybrid');
        expect(roundtrippedOpp.compensation, 'RWF 300,000/mo');
        expect(roundtrippedOpp.coverAsset?.publicId, sampleAsset.publicId);

        final oppApp = OpportunityApplication(
          id: 's-1_o-1',
          ownerUid: 's-1',
          opportunityId: 'o-1',
          opportunityTitle: 'Flutter Intern',
          organization: 'Irembo',
          studentName: 'Student One',
          coverNote: 'Looking forward to contributing.',
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );
        expect(
          OpportunityApplication.fromJson(
            oppApp.toJson(),
            id: 's-1_o-1',
          ).status,
          OpportunityApplicationStatus.submitted,
        );

        final notif = UserNotification(
          id: 'n-1',
          ownerUid: 's-1',
          title: 'Mentor approved',
          body: 'Welcome to the mentor workspace.',
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );
        expect(
          UserNotification.fromJson(notif.toJson(), id: 'n-1').status,
          NotificationStatus.unread,
        );

        final audit = AuditLogEntry(
          id: 'log-1',
          ownerUid: 'admin-1',
          actorUid: 'admin-1',
          actorEmail: 'authapp05@gmail.com',
          action: 'approveMentor',
          targetCollection: 'mentorApplications',
          targetId: 'm-1',
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );
        expect(
          AuditLogEntry.fromJson(audit.toJson(), id: 'log-1').actorEmail,
          'authapp05@gmail.com',
        );
      },
    );
  });

  group('Phase 1: Firestore indexes validation', () {
    test(
      'firestore.indexes.json parses and defines core composite indexes',
      () {
        final raw = File('firestore.indexes.json').readAsStringSync();
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final indexes = (decoded['indexes'] as List)
            .cast<Map<String, dynamic>>();
        final collections = indexes.map((e) => e['collectionGroup']).toSet();
        expect(
          collections,
          containsAll([
            'users',
            'profiles',
            'projects',
            'mentorApplications',
            'mentorRequests',
            'mentorships',
            'sessions',
            'courses',
            'courseProgress',
            'opportunities',
            'applications',
            'notifications',
          ]),
        );
      },
    );
  });
}
