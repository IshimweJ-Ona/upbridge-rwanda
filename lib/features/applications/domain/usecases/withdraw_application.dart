// Owner: Student 4 · Opportunities & applications
// Holds: Withdraws an application while it is still sent or under review.

import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/features/applications/domain/repositories/application_repository.dart';
import 'package:upbridge/shared/models/models.dart';

class WithdrawApplication {
  const WithdrawApplication(this._repository);

  final ApplicationRepository _repository;

  Future<void> call(Application application) async {
    final canWithdraw =
        application.status == AppStatus.sent ||
        application.status == AppStatus.underReview;
    if (!canWithdraw) throw const ValidationFailure('cannot-withdraw');

    await _repository.withdraw(application.id);
  }
}