// Owner: Student 3 · Mentorship & mentor workspace
// Holds: A mentee as the mentor sees them: name, task progress, last active, whether they need attention.
//
// Mentees are the youth who have a confirmed or finished session with this
// mentor. Task progress needs the learning progress contract (Lisa) and is
// not part of this record yet.
import 'package:upbridge/shared/models/models.dart';

enum MenteeAttention { wantsSession, quiet, onTrack }

class MenteeRecord {
  const MenteeRecord({
    required this.youthId,
    required this.name,
    this.sessionsDone = 0,
    this.upcoming = 0,
    this.pendingRequests = 0,
    this.lastSessionAt,
    this.nextSessionAt,
    this.sessions = const [],
  });

  /// No session for this long and nothing booked = quiet.
  static const quietAfter = Duration(days: 21);

  final String youthId;
  final String name;
  final int sessionsDone;
  final int upcoming;
  final int pendingRequests;
  final DateTime? lastSessionAt;
  final DateTime? nextSessionAt;

  /// This youth's sessions with the mentor, oldest first.
  final List<Session> sessions;

  String get firstName => name.split(' ').first;

  MenteeAttention attentionAt(DateTime now) {
    if (pendingRequests > 0) return MenteeAttention.wantsSession;
    if (upcoming > 0) return MenteeAttention.onTrack;
    final last = lastSessionAt;
    if (last == null || now.difference(last) > quietAfter) {
      return MenteeAttention.quiet;
    }
    return MenteeAttention.onTrack;
  }

  bool needsAttentionAt(DateTime now) =>
      attentionAt(now) != MenteeAttention.onTrack;

  /// Groups a mentor's sessions by youth. Only youth with a confirmed or
  /// finished session count as mentees; a pending request alone does not.
  static List<MenteeRecord> fromSessions(List<Session> sessions) {
    final byYouth = <String, List<Session>>{};
    for (final s in sessions) {
      if (s.youthId.isEmpty) continue;
      byYouth.putIfAbsent(s.youthId, () => []).add(s);
    }
    final mentees = <MenteeRecord>[];
    byYouth.forEach((youthId, list) {
      final related = list
          .where(
            (s) =>
                s.state == SessionState.upcoming ||
                s.state == SessionState.done,
          )
          .toList();
      if (related.isEmpty) return;
      final ordered = [...list]..sort(_byStart);
      DateTime? last;
      DateTime? next;
      for (final s in ordered) {
        final at = s.startsAt;
        if (at == null) continue;
        if (s.state == SessionState.done) last = at;
        if (s.state == SessionState.upcoming && next == null) next = at;
      }
      mentees.add(
        MenteeRecord(
          youthId: youthId,
          name: ordered.last.youthName,
          sessionsDone: list.where((s) => s.state == SessionState.done).length,
          upcoming: list.where((s) => s.state == SessionState.upcoming).length,
          pendingRequests: list
              .where((s) => s.state == SessionState.requested)
              .length,
          lastSessionAt: last,
          nextSessionAt: next,
          sessions: ordered,
        ),
      );
    });
    return mentees
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  static int _byStart(Session a, Session b) {
    final l = a.startsAt;
    final r = b.startsAt;
    if (l == null && r == null) return 0;
    if (l == null) return 1;
    if (r == null) return -1;
    return l.compareTo(r);
  }
}
