// Port for admin review actions; application fields remain owned by Kellen's contract.
import 'package:upbridge/shared/models/models.dart';

abstract interface class AdminApplicationRepository {
  Future<List<ForwardItem>> listPendingForwards();
  Future<void> forward(String forwardId);
  Future<void> recordOutcome(String forwardId, String outcome);
}
