import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/features/home/domain/entities/check_in.dart';

void main() {
  CheckIn validCheckIn({
    String userId = 'user-1',
    String monthKey = '2026-11',
    int usefulness = 4,
    String changeNote = 'Used the practice task',
  }) => CheckIn(
    userId: userId,
    monthKey: monthKey,
    usefulness: usefulness,
    applied: true,
    changeNote: changeNote,
  );

  test('accepts valid feedback and maps only contract fields', () {
    final checkIn = validCheckIn();
    expect(checkIn.validate(), isNull);
    expect(checkIn.toFirestore(), {
      'userId': 'user-1',
      'monthKey': '2026-11',
      'usefulness': 4,
      'applied': true,
      'changeNote': 'Used the practice task',
    });
  });

  test('rejects invalid owner, month, rating, and oversized note', () {
    expect(validCheckIn(userId: ' ').validate(), contains('Sign in'));
    expect(validCheckIn(monthKey: '2026-13').validate(), contains('month'));
    expect(validCheckIn(usefulness: 0).validate(), contains('rating'));
    expect(validCheckIn(changeNote: 'x' * 501).validate(), contains('500'));
  });
}
