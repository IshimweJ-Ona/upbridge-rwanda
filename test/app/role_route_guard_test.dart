import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/app/router/route_guards.dart';
import 'package:upbridge/shared/models/models.dart';

void main() {
  group('roleAreaRedirect', () {
    test('youth can stay in youth routes and use shared language settings', () {
      expect(roleAreaRedirect(role: Role.youth, location: '/home'), isNull);
      expect(roleAreaRedirect(role: Role.youth, location: '/language'), isNull);
    });

    test('youth is sent home when entering mentor or admin routes', () {
      expect(roleAreaRedirect(role: Role.youth, location: '/m/home'), '/home');
      expect(
        roleAreaRedirect(role: Role.youth, location: '/a/overview'),
        '/home',
      );
      expect(
        roleAreaRedirect(role: Role.youth, location: '/a-new-user'),
        '/home',
      );
    });

    test('mentor stays in mentor routes and shared settings', () {
      expect(
        roleAreaRedirect(role: Role.mentor, location: '/m/reviews'),
        isNull,
      );
      expect(
        roleAreaRedirect(role: Role.mentor, location: '/language'),
        isNull,
      );
    });

    test('mentor is sent to mentor home outside the mentor area', () {
      expect(roleAreaRedirect(role: Role.mentor, location: '/home'), '/m/home');
      expect(
        roleAreaRedirect(role: Role.mentor, location: '/a/overview'),
        '/m/home',
      );
      expect(
        roleAreaRedirect(role: Role.mentor, location: '/a-forward/123'),
        '/m/home',
      );
    });

    test(
      'admin stays in admin routes and is redirected from other role areas',
      () {
        expect(
          roleAreaRedirect(role: Role.admin, location: '/a/overview'),
          isNull,
        );
        expect(
          roleAreaRedirect(role: Role.admin, location: '/a-listing/123'),
          isNull,
        );
        expect(
          roleAreaRedirect(role: Role.admin, location: '/m/home'),
          '/a/overview',
        );
        expect(
          roleAreaRedirect(role: Role.admin, location: '/home'),
          '/a/overview',
        );
      },
    );
  });
}
