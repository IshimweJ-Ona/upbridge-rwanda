// Contract for checking and creating a youth's one-per-month feedback record.
import '../entities/check_in.dart';

abstract interface class CheckInRepository {
  Future<CheckIn?> getForMonth(String userId, String monthKey);
  Future<void> submit(CheckIn checkIn);
}
