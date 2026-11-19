// Owner: Student 3 · Mentorship & mentor workspace
// Holds: Implements MentorProfileRepository: profile and availability windows.
//
// Reads and updates mentorProfiles/{mentorUid}. Uses the same field names as
// the youth-side MentorModel so the directory shows what the mentor saves.
// Saving needs a Firestore rule that lets a mentor update their own profile
// fields; until then the rules reject it and the screen shows the error.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/features/mentor_workspace/domain/entities/availability_window.dart';
import 'package:upbridge/features/mentor_workspace/domain/entities/mentor_profile.dart';
import 'package:upbridge/features/mentor_workspace/domain/repositories/mentor_profile_repository.dart';
import 'package:upbridge/features/mentorship/data/models/mentor_model.dart';
import 'package:upbridge/features/mentorship/domain/entities/session.dart';
import 'package:upbridge/shared/services/firebase/firebase_failure_mapper.dart';
import 'package:upbridge/shared/services/firebase/firestore_schema.dart';

/// Profile fields that only the mentor workspace writes.
abstract final class MentorProfileFields {
  static const meetingLink = 'meetingLink';
  static const menteeLimit = 'menteeLimit';
  static const availabilityWindows = 'availabilityWindows';
  static const weekday = 'weekday';
  static const startMinutes = 'startMinutes';
  static const endMinutes = 'endMinutes';

  /// firestore.rules rejects more than this many open slots.
  static const maxOpenSlots = 300;

  /// Everything [MentorProfileRepositoryImpl.save] may change.
  static const editable = {
    meetingLink,
    menteeLimit,
    availabilityWindows,
    MentorFields.accepting,
    MentorFields.availability,
    MentorFields.openSlots,
    MentorFields.updatedAt,
  };
}

class MentorProfileRepositoryImpl implements MentorProfileRepository {
  MentorProfileRepositoryImpl(this._firestore, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final FirebaseFirestore _firestore;
  final DateTime Function() _clock;

  DocumentReference<Map<String, dynamic>> _doc(String id) =>
      _firestore.collection(Fs.mentorProfiles).doc(id);

  @override
  Stream<MentorProfile?> watchProfile(String mentorId) => _doc(mentorId)
      .snapshots()
      .map((snapshot) {
        final data = snapshot.data();
        if (!snapshot.exists || data == null) return null;
        return fromFirestore(snapshot.id, data);
      })
      .handleError((Object e) => throw mapFirebaseFailure(e));

  @override
  Future<void> save(MentorProfile profile) async {
    final problem = profile.validate();
    if (problem != null) throw ArgumentError(problem);
    try {
      await _doc(profile.id).update(toUpdateMap(profile, now: _clock()));
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapFirebaseFailure(e);
    }
  }

  static MentorProfile fromFirestore(String id, Map<String, dynamic> data) {
    final mentor = MentorModel.fromFirestore(id, data);
    final limit = data[MentorProfileFields.menteeLimit];
    return MentorProfile(
      id: id,
      name: mentor.name,
      title: mentor.title,
      employer: mentor.employer,
      bio: mentor.bio,
      skills: mentor.skills,
      languages: [
        for (final l in mentor.languages.split(','))
          if (l.trim().isNotEmpty) l.trim(),
      ],
      meetingLink: data[MentorProfileFields.meetingLink] is String
          ? (data[MentorProfileFields.meetingLink] as String).trim()
          : '',
      // A missing flag means not accepting, unlike the youth directory default.
      accepting: data[MentorFields.accepting] == true,
      menteeLimit: limit is num
          ? limit.toInt()
          : MentorProfile.defaultMenteeLimit,
      windows: windowsFrom(data[MentorProfileFields.availabilityWindows]),
      verified: data[MentorFields.verified] == true,
      reviewsCount: mentor.reviews,
      menteeCount: mentor.mentees,
      replyTime: mentor.replyTime,
    );
  }

  static List<AvailabilityWindow> windowsFrom(Object? value) => [
    if (value is List)
      for (final item in value)
        if (item is Map &&
            item[MentorProfileFields.weekday] is num &&
            item[MentorProfileFields.startMinutes] is num &&
            item[MentorProfileFields.endMinutes] is num)
          AvailabilityWindow(
            weekday: (item[MentorProfileFields.weekday] as num).toInt(),
            startMinutes: (item[MentorProfileFields.startMinutes] as num)
                .toInt(),
            endMinutes: (item[MentorProfileFields.endMinutes] as num).toInt(),
          ),
  ];

  /// Only editable fields. Open slots for the next two weeks are rebuilt
  /// from the windows so youth can book them.
  static Map<String, Object?> toUpdateMap(
    MentorProfile profile, {
    required DateTime now,
  }) {
    final windows = profile.sortedWindows;
    final starts = AvailabilityWindow.upcomingStarts(
      windows,
      from: now,
      sessionMinutes: SessionRequest.defaultDurationMinutes,
    );
    return {
      MentorProfileFields.meetingLink: profile.meetingLink.trim(),
      MentorProfileFields.menteeLimit: profile.menteeLimit,
      MentorProfileFields.availabilityWindows: [
        for (final w in windows)
          {
            MentorProfileFields.weekday: w.weekday,
            MentorProfileFields.startMinutes: w.startMinutes,
            MentorProfileFields.endMinutes: w.endMinutes,
          },
      ],
      MentorFields.accepting: profile.accepting,
      MentorFields.availability: profile.availabilityLabel,
      MentorFields.openSlots: [
        for (final s in starts.take(MentorProfileFields.maxOpenSlots))
          Timestamp.fromDate(s),
      ],
      MentorFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }
}
