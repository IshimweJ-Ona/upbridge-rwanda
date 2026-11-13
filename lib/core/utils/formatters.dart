// Stateless display formatters for Rwanda currency, dates, elapsed time, and phones.
import 'package:intl/intl.dart';

String formatRwf(num amount) =>
    'RWF ${NumberFormat('#,##0.##').format(amount)}';

String formatShortDate(DateTime date) => DateFormat('EEE d MMM').format(date);

String formatDateTime(DateTime date) =>
    DateFormat('d MMM yyyy, HH:mm').format(date);

String formatRelativeTime(DateTime date, {DateTime? now}) {
  final elapsed = (now ?? DateTime.now()).difference(date);
  if (elapsed.isNegative) return 'just now';
  if (elapsed.inMinutes < 1) return 'just now';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} min ago';
  if (elapsed.inHours < 24) return '${elapsed.inHours} hr ago';
  if (elapsed.inDays == 1) return 'yesterday';
  if (elapsed.inDays < 7) return '${elapsed.inDays} days ago';
  return formatShortDate(date);
}

String formatRwandaPhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  final local = digits.startsWith('250')
      ? digits.substring(3)
      : digits.startsWith('0')
      ? digits.substring(1)
      : digits;
  if (local.length != 9 || !local.startsWith('7')) return input.trim();
  return '+250 ${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
}
