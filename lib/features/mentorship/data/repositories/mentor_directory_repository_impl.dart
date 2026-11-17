// Maps verified `mentorProfiles` documents to `Mentor` and sorts them by name.
import 'package:upbridge/features/mentorship/data/datasources/mentor_directory_data_source.dart';
import 'package:upbridge/features/mentorship/data/models/mentor_model.dart';
import 'package:upbridge/features/mentorship/domain/entities/mentor.dart';
import 'package:upbridge/features/mentorship/domain/repositories/mentor_directory_repository.dart';
import 'package:upbridge/shared/services/firebase/firebase_failure_mapper.dart';

class MentorDirectoryRepositoryImpl implements MentorDirectoryRepository {
  MentorDirectoryRepositoryImpl({required this._dataSource});

  final MentorDirectoryDataSource _dataSource;

  @override
  Stream<List<Mentor>> watchMentors() => _dataSource
      .watchVerified()
      .map(
        (snapshot) => [
          for (final document in snapshot.docs)
            MentorModel.fromFirestore(document.id, document.data()),
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
      )
      .handleError(_rethrowMapped);

  @override
  Stream<Mentor?> watchMentor(String mentorId) => _dataSource
      .watchOne(mentorId)
      .map((snapshot) {
        final data = snapshot.data();
        if (!snapshot.exists ||
            data == null ||
            data[MentorFields.verified] != true) {
          return null;
        }
        return MentorModel.fromFirestore(snapshot.id, data);
      })
      .handleError(_rethrowMapped);

  static Never _rethrowMapped(Object error) => throw mapFirebaseFailure(error);
}
