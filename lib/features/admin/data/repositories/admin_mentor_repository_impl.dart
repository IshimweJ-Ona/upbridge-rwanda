// Delegates mentor decisions to a persistence adapter after Boaz confirms mentor fields.
import 'package:upbridge/features/admin/domain/repositories/admin_mentor_repository.dart';
import 'package:upbridge/shared/models/models.dart';

class AdminMentorRepositoryImpl implements AdminMentorRepository {
  const AdminMentorRepositoryImpl({
    required this._listApplicants,
    required this._updateChecks,
    required this._approve,
    required this._decline,
  });

  final Future<List<MentorApplicant>> Function() _listApplicants;
  final Future<void> Function(String id, List<Check> checks) _updateChecks;
  final Future<void> Function(String id) _approve;
  final Future<void> Function(String id, String reason) _decline;

  @override
  Future<List<MentorApplicant>> listApplicants() => _listApplicants();

  @override
  Future<void> updateChecks(String applicantId, List<Check> checks) =>
      _updateChecks(applicantId, checks);

  @override
  Future<void> approve(String applicantId) => _approve(applicantId);

  @override
  Future<void> decline(String applicantId, {required String reason}) =>
      _decline(applicantId, reason);
}
