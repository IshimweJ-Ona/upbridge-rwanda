import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/utils/kigali_time.dart';

void main() {
  test('converts Kigali wall time to and from UTC across date boundaries', () {
    final utc = DateTime.utc(2026, 11, 13, 22, 30);
    final kigali = KigaliTime.fromUtc(utc);

    expect(kigali, DateTime.utc(2026, 11, 14, 0, 30));
    expect(KigaliTime.toUtc(kigali), utc);
  });

  test('calculates Kigali midnight as a UTC instant', () {
    final instant = DateTime.utc(2026, 11, 13, 22, 30);
    expect(
      KigaliTime.startOfDayUtc(instant),
      DateTime.utc(2026, 11, 13, 22),
    );
  });
}
