// Prevents an incomplete evidence review from reaching the application repository.
import 'package:upbridge/features/admin/domain/entities/forward_check.dart';
import 'package:upbridge/features/admin/domain/repositories/admin_application_repository.dart';

class ForwardApplication {
  const ForwardApplication(this._repository);

  final AdminApplicationRepository _repository;

  Future<void> call({required String forwardId, required ForwardCheck checks}) {
    if (forwardId.trim().isEmpty) {
      throw ArgumentError.value(forwardId, 'forwardId');
    }
    if (!checks.canForward) {
      throw StateError(
        'All evidence, requirements, contact, and note checks must pass before forwarding.',
      );
    }
    return _repository.forward(forwardId);
  }
}
