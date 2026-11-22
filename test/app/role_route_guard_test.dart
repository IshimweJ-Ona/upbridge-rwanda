import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/app/router/route_guards.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';

void main() {
  group('claimsRoleAreaRedirect', () {
    test('student stays in student routes and shared locations', () {
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.student,
          location: AppRoutes.studentHome,
        ),
        isNull,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.student,
          location: AppRoutes.language,
        ),
        isNull,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.student,
          location: '/mentorship/m1',
        ),
        isNull,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.student,
          location: AppRoutes.mentorApply,
        ),
        isNull,
      );
    });

    test('student is redirected home when entering mentor or admin routes', () {
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.student,
          location: AppRoutes.mentorHome,
        ),
        AppRoutes.studentHome,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.student,
          location: AppRoutes.adminOverview,
        ),
        AppRoutes.studentHome,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.student,
          location: '/a-applicant/u1',
        ),
        AppRoutes.studentHome,
      );
    });

    test(
      'mentor stays in mentor routes and shared mentorship/profile routes',
      () {
        expect(
          claimsRoleAreaRedirect(
            role: UserRole.mentor,
            location: AppRoutes.mentorHome,
          ),
          isNull,
        );
        expect(
          claimsRoleAreaRedirect(
            role: UserRole.mentor,
            location: '/m/requests',
          ),
          isNull,
        );
        expect(
          claimsRoleAreaRedirect(
            role: UserRole.mentor,
            location: '/mentorship/m1',
          ),
          isNull,
        );
        expect(
          claimsRoleAreaRedirect(
            role: UserRole.mentor,
            location: '/user-profile/s1',
          ),
          isNull,
        );
        expect(
          claimsRoleAreaRedirect(
            role: UserRole.mentor,
            location: AppRoutes.language,
          ),
          isNull,
        );
      },
    );

    test('mentor is sent to mentor home outside mentor & shared areas', () {
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.mentor,
          location: AppRoutes.studentHome,
        ),
        AppRoutes.mentorHome,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.mentor,
          location: AppRoutes.adminOverview,
        ),
        AppRoutes.mentorHome,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.mentor,
          location: '/a-applicant/u1',
        ),
        AppRoutes.mentorHome,
      );
    });

    test('admin stays in admin & shared routes and is redirected from other role areas', () {
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.admin,
          location: AppRoutes.adminOverview,
        ),
        isNull,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.admin,
          location: '/a-applicant/u1',
        ),
        isNull,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.admin,
          location: '/user-profile/u1',
        ),
        isNull,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.admin,
          location: AppRoutes.mentorHome,
        ),
        AppRoutes.adminOverview,
      );
      expect(
        claimsRoleAreaRedirect(
          role: UserRole.admin,
          location: AppRoutes.studentHome,
        ),
        AppRoutes.adminOverview,
      );
    });
  });
}
