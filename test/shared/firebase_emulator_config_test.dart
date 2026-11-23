import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/shared/services/firebase/firebase_bootstrap.dart';
import 'package:upbridge/shared/services/firebase/firebase_options.dart';

void main() {
  test('Android emulator uses its host-side loopback alias by default', () {
    expect(firebaseEmulatorHost(isAndroid: true), '10.0.2.2');
  });

  test('desktop and simulators default to loopback', () {
    expect(firebaseEmulatorHost(isAndroid: false), '127.0.0.1');
  });

  test('configured host supports physical devices on the local network', () {
    expect(
      firebaseEmulatorHost(isAndroid: false, configuredHost: ' 192.168.1.12 '),
      '192.168.1.12',
    );
  });

  test('DefaultFirebaseOptions.fromEnvironment returns null without config', () {
    expect(
      DefaultFirebaseOptions.fromEnvironment(
        isWeb: false,
        platform: TargetPlatform.android,
      ),
      isNull,
    );
  });

  test('DefaultFirebaseOptions.fromEnvironment builds platform options', () {
    final android = DefaultFirebaseOptions.fromEnvironment(
      isWeb: false,
      platform: TargetPlatform.android,
      projectId: 'upridge-rwanda-dev',
      messagingSenderId: '710913599432',
      storageBucket: 'upridge-rwanda-dev.firebasestorage.app',
      androidApiKey: 'test-android-key',
      androidAppId: '1:710913599432:android:test',
    );
    expect(android, isNotNull);
    expect(android!.projectId, 'upridge-rwanda-dev');
    expect(android.apiKey, 'test-android-key');
    expect(android.appId, '1:710913599432:android:test');

    final web = DefaultFirebaseOptions.fromEnvironment(
      isWeb: true,
      platform: TargetPlatform.android,
      projectId: 'upridge-rwanda-dev',
      messagingSenderId: '710913599432',
      authDomain: 'upridge-rwanda-dev.firebaseapp.com',
      webApiKey: 'test-web-key',
      webAppId: '1:710913599432:web:test',
    );
    expect(web, isNotNull);
    expect(web!.authDomain, 'upridge-rwanda-dev.firebaseapp.com');
    expect(web.appId, '1:710913599432:web:test');
  });

  test('DefaultFirebaseOptions.emulatorFallbackOptions targets emulator project', () {
    final options = DefaultFirebaseOptions.emulatorFallbackOptions(
      isWeb: false,
      platform: TargetPlatform.android,
    );
    expect(options.projectId, 'upridge-rwanda-dev');
    expect(options.apiKey, isNotEmpty);
    expect(options.appId, contains(':android:emulator'));
  });
}
