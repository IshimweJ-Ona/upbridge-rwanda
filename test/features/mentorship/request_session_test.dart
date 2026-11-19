import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/features/mentorship/domain/entities/session.dart';
import 'package:upbridge/features/mentorship/domain/repositories/session_repository.dart';
import 'package:upbridge/features/mentorship/domain/usecases/request_session.dart';

/// Records requests instead of touching Firestore.
class _FakeSessionRepository implements SessionRepository {
  final requests = <SessionRequest>[];

  @override
  Future<String> request(SessionRequest request) async {
    requests.add(request);
    return 'session-${requests.length}';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime.utc(2026, 10, 18, 12);

  SessionRequest request({String topic = 'Career advice'}) => SessionRequest(
    requesterId: 'youth-1',
    requesterName: 'Jean',
    mentorId: 'alice-uid',
    mentorName: 'Alice Uwimana',
    startsAt: DateTime.utc(2026, 10, 22, 16),
    topic: topic,
  );

  test('sends a valid request to the repository', () async {
    final repository = _FakeSessionRepository();
    final id = await RequestSession(repository, clock: () => now)(request());
    expect(id, 'session-1');
    expect(repository.requests.single.mentorId, 'alice-uid');
  });

  test('rejects an invalid request without writing anything', () {
    final repository = _FakeSessionRepository();
    expect(
      () => RequestSession(repository, clock: () => now)(request(topic: '')),
      throwsArgumentError,
    );
    expect(repository.requests, isEmpty);
  });
}
