import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/shared/services/firebase/firebase_bootstrap.dart';

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
}
