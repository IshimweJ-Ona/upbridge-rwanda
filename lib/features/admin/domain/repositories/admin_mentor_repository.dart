// Port for mentor reviews; persisted mentor fields remain owned by Boaz's contract.
import 'package:upbridge/shared/models/models.dart';

abstract interface class AdminMentorRepository {
  Future<List<MentorApplicant>> listApplicants();
  Future<void> updateChecks(String applicantId, List<Check> checks);
  Future<void> approve(String applicantId);
  Future<void> decline(String applicantId, {required String reason});
}
