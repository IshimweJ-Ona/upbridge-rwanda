// Turns a mentorProfiles document into a Mentor, with defaults for missing fields.
import 'package:intl/intl.dart';

import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/utils/kigali_time.dart';
import 'package:upbridge/features/mentorship/domain/entities/mentor.dart';
import 'package:upbridge/features/mentorship/domain/entities/session_slot.dart';
import 'package:upbridge/shared/services/firebase/firestore_converters.dart';

/// Doc ID = the mentor's Firebase Auth UID.
abstract final class MentorFields {
  static const displayName = 'displayName';
  static const title = 'title';
  static const employer = 'employer';
  static const yearsExperience = 'yearsExperience';
  static const city = 'city';
  static const bio = 'bio';
  static const skills = 'skills';
  static const helpsWith = 'helpsWith';
  static const area = 'area';
  static const languages = 'languages';
  static const availability = 'availability';
  static const openSlots = 'openSlots';
  static const reviewsCount = 'reviewsCount';
  static const medianReplyHours = 'medianReplyHours';
  static const menteeCount = 'menteeCount';
  static const accepting = 'accepting';
  static const verified = 'verified';
  static const updatedAt = 'updatedAt';
}

/// Slot label in Kigali time, e.g. THU 22 OCT · 18:00.
SessionSlot slotFromInstant(DateTime instant) {
  final utc = instant.toUtc();
  final kigali = KigaliTime.fromUtc(utc);
  return SessionSlot(
    DateFormat('EEE d MMM').format(kigali).toUpperCase(),
    DateFormat('HH:mm').format(kigali),
    startsAt: utc,
  );
}

String formatReplyTime(num? hours) {
  if (hours == null || hours <= 0) return 'New';
  if (hours < 24) return '${hours.round()} h';
  final days = hours / 24;
  return '${days.toStringAsFixed(1)} d';
}

abstract final class MentorModel {
  static const _tones = [Tone.accent, Tone.info, Tone.success, Tone.warning];

  static Mentor fromFirestore(String id, Map<String, dynamic> data) {
    final slots = <SessionSlot>[
      for (final value in _list(data[MentorFields.openSlots]))
        if (_instant(value) case final DateTime instant)
          slotFromInstant(instant),
    ]..sort((a, b) => a.startsAt!.compareTo(b.startsAt!));

    return Mentor(
      id: id,
      name: _text(data[MentorFields.displayName], fallback: 'UpBridge mentor'),
      title: _text(data[MentorFields.title], fallback: 'Mentor'),
      employer: _text(data[MentorFields.employer]),
      years: _int(data[MentorFields.yearsExperience]),
      city: _text(data[MentorFields.city], fallback: 'Rwanda'),
      bio: _text(data[MentorFields.bio]),
      skills: _strings(data[MentorFields.skills]),
      helpsWith: _strings(data[MentorFields.helpsWith]),
      reviews: _int(data[MentorFields.reviewsCount]),
      replyTime: formatReplyTime(data[MentorFields.medianReplyHours] as num?),
      mentees: _int(data[MentorFields.menteeCount]),
      availability: _text(
        data[MentorFields.availability],
        fallback: 'Availability not set yet',
      ),
      languages: _strings(data[MentorFields.languages]).join(', '),
      tone: toneFor(id),
      slots: slots,
      accepting: data[MentorFields.accepting] != false,
      area: _text(data[MentorFields.area], fallback: 'General'),
    );
  }

  static Tone toneFor(String id) {
    final sum = id.codeUnits.fold<int>(0, (total, unit) => total + unit);
    return _tones[sum % _tones.length];
  }

  static String _text(Object? value, {String fallback = ''}) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? fallback : text;
  }

  static int _int(Object? value) => value is num ? value.toInt() : 0;

  static List<Object?> _list(Object? value) =>
      value is List ? value : const <Object?>[];

  static List<String> _strings(Object? value) => [
    for (final item in _list(value))
      if (item is String && item.trim().isNotEmpty) item.trim(),
  ];

  static DateTime? _instant(Object? value) {
    try {
      return dateTimeFromFirestore(value);
    } on FormatException {
      return null;
    }
  }
}
