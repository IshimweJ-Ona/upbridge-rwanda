// Read-only contract for the Firebase-backed youth overview aggregate.
import '../entities/home_summary.dart';

abstract interface class HomeRepository {
  Future<HomeSummary> loadSummary(String userId);
}
