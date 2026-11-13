// Delegates application operations to an owner-approved persistence adapter.
import 'package:upbridge/features/admin/domain/repositories/admin_application_repository.dart';
import 'package:upbridge/shared/models/models.dart';

class AdminApplicationRepositoryImpl implements AdminApplicationRepository {
  const AdminApplicationRepositoryImpl({
    required this._loadPending,
    required this._forward,
    required this._recordOutcome,
  });

  final Future<List<ForwardItem>> Function() _loadPending;
  final Future<void> Function(String id) _forward;
  final Future<void> Function(String id, String outcome) _recordOutcome;

  @override
  Future<List<ForwardItem>> listPendingForwards() => _loadPending();

  @override
  Future<void> forward(String forwardId) => _forward(forwardId);

  @override
  Future<void> recordOutcome(String forwardId, String outcome) =>
      _recordOutcome(forwardId, outcome);
}
