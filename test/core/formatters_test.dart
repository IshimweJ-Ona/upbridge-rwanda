import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/utils/formatters.dart';

void main() {
  test('formats Rwandan francs with grouping and no unnecessary decimals', () {
    expect(formatRwf(125000), 'RWF 125,000');
    expect(formatRwf(1250.5), 'RWF 1,250.5');
  });

  test('normalizes valid Rwanda phone numbers and preserves invalid input', () {
    expect(formatRwandaPhone('0788 123 456'), '+250 788 123 456');
    expect(formatRwandaPhone('+250788123456'), '+250 788 123 456');
    expect(formatRwandaPhone('12345'), '12345');
  });

  test('relative time handles future, recent, and older dates', () {
    final now = DateTime(2026, 11, 13, 12);
    expect(formatRelativeTime(now.add(const Duration(minutes: 1)), now: now), 'just now');
    expect(formatRelativeTime(now.subtract(const Duration(minutes: 12)), now: now), '12 min ago');
    expect(formatRelativeTime(now.subtract(const Duration(days: 1)), now: now), 'yesterday');
  });
}
