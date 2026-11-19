// Owner: Student 3 · Mentorship & mentor workspace
// Holds: Maps mentorship and progress documents into Mentee.
//
// Mentees come from mentorSessions today. Task progress fields stay empty
// until the learning progress contract (taskProgress) is agreed.
import 'package:intl/intl.dart';

import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/features/mentor_workspace/domain/entities/mentee.dart';
import 'package:upbridge/shared/models/models.dart';

abstract final class MenteeModel {
  /// The shared [Mentee] the screens draw, with status text for [now].
  static Mentee toMentee(MenteeRecord record, DateTime now) {
    final (status, tone) = statusOf(record.attentionAt(now));
    return Mentee(
      id: record.youthId,
      name: record.name,
      path: '',
      approved: 0,
      total: 0,
      lastActive: lastActiveLabel(record, now),
      status: status,
      tone: tone,
      district: '',
    );
  }

  static (String, Tone) statusOf(MenteeAttention attention) =>
      switch (attention) {
        MenteeAttention.wantsSession => ('Wants a session', Tone.info),
        MenteeAttention.quiet => ('Quiet', Tone.warning),
        MenteeAttention.onTrack => ('On track', Tone.success),
      };

  static String lastActiveLabel(MenteeRecord record, DateTime now) {
    final next = record.nextSessionAt;
    if (next != null) {
      return 'Next session ${DateFormat('d MMM').format(next.toLocal())}';
    }
    final last = record.lastSessionAt;
    if (last == null) return 'No sessions yet';
    final days = now.difference(last).inDays;
    return switch (days) {
      <= 0 => 'Last session today',
      1 => 'Last session yesterday',
      _ => 'Last session $days days ago',
    };
  }
}
