// Works out which of a mentor's offered slots a youth can still book.
import 'package:upbridge/features/mentorship/domain/entities/session.dart';
import 'package:upbridge/features/mentorship/domain/entities/session_slot.dart';

class FreeSlots {
  const FreeSlots({this.minimumNotice = const Duration(hours: 12)});

  final Duration minimumNotice;

  /// Future slots (12h+ away) the youth hasn't already booked, soonest first.
  List<SessionSlot> call({
    required List<SessionSlot> offered,
    required List<Session> mySessions,
    required DateTime now,
  }) {
    final earliest = now.toUtc().add(minimumNotice);
    final taken = {
      for (final session in mySessions)
        if (session.startsAt != null &&
            (session.state == SessionState.requested ||
                session.state == SessionState.upcoming))
          session.startsAt!.toUtc(),
    };
    final free = [
      for (final slot in offered)
        if (slot.startsAt != null &&
            !slot.startsAt!.toUtc().isBefore(earliest) &&
            !taken.contains(slot.startsAt!.toUtc()))
          slot,
    ]..sort((a, b) => a.startsAt!.compareTo(b.startsAt!));
    return free;
  }
}
