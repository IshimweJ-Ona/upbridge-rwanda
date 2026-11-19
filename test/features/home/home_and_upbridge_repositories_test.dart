// ignore_for_file: subtype_of_sealed_class

// Tests HomeRepositoryImpl, CheckInRepositoryImpl, NotificationRepositoryImpl, and UpBridgeRepository.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/features/home/data/datasources/notification_remote_data_source.dart';
import 'package:upbridge/features/home/data/repositories/check_in_repository_impl.dart';
import 'package:upbridge/features/home/data/repositories/home_repository_impl.dart';
import 'package:upbridge/features/home/data/repositories/notification_repository_impl.dart';
import 'package:upbridge/features/home/domain/entities/check_in.dart';
import 'package:upbridge/features/home/domain/entities/next_step.dart';
import 'package:upbridge/shared/services/firebase/firestore_schema.dart';
import 'package:upbridge/shared/services/firebase/upbridge_repository.dart';

void main() {
  group('HomeRepositoryImpl', () {
    test('rejects empty userId and aggregates progress, submissions, projects, and opportunities', () async {
      final db = _MemoryFirestore();
      db.seed(Fs.taskProgress, 'u1_t1', {
        'userId': 'u1',
        'taskId': 't1',
        'status': SubmissionStatus.approved,
      });
      db.seed(Fs.taskProgress, 'u1_t2', {
        'userId': 'u1',
        'taskId': 't2',
        'status': SubmissionStatus.changesRequested,
      });
      db.seed(Fs.submissions, 'sub-1', {
        'userId': 'u1',
        'status': SubmissionStatus.submitted,
      });
      db.seed(Fs.projects, 'p-1', {'ownerId': 'u1'});
      db.seed(Fs.projects, 'p-2', {'ownerId': 'u1'});
      db.seed(Fs.opportunities, 'o-1', {'status': OpportunityStatus.published});
      db.seed(Fs.opportunities, 'o-2', {'status': 'draft'});

      final repo = HomeRepositoryImpl(firestore: db);
      await expectLater(() => repo.loadSummary('  '), throwsArgumentError);

      final summary = await repo.loadSummary('u1');
      expect(summary.approvedTasks, 1);
      expect(summary.pendingReviews, 1);
      expect(summary.projectCount, 2);
      expect(summary.publishedOpportunityCount, 1);
      expect(summary.nextStep?.kind, NextStepKind.reviseTask);
      expect(summary.nextStep?.route, '/task/t2');
    });

    test(
      'picks awaitReview when pending submissions exist without revisions',
      () async {
        final db = _MemoryFirestore();
        db.seed(Fs.submissions, 'sub-1', {
          'userId': 'u1',
          'status': SubmissionStatus.submitted,
        });

        final summary = await HomeRepositoryImpl(firestore: db)
            .loadSummary('u1');
        expect(summary.nextStep?.kind, NextStepKind.awaitReview);
      },
    );
  });

  group('CheckInRepositoryImpl', () {
    test('writes once per user and month and throws CheckInAlreadyExistsException on duplicate', () async {
      final db = _MemoryFirestore();
      final repo = CheckInRepositoryImpl(firestore: db);

      expect(await repo.getForMonth('u1', '2026-11'), isNull);

      const invalid = CheckIn(
        userId: '',
        monthKey: 'bad',
        usefulness: 5,
        applied: true,
      );
      await expectLater(() => repo.submit(invalid), throwsArgumentError);

      const valid = CheckIn(
        userId: 'u1',
        monthKey: '2026-11',
        usefulness: 4,
        applied: true,
        changeNote: 'Helped me complete my HTML card.',
      );
      await repo.submit(valid);

      final stored = await repo.getForMonth('u1', '2026-11');
      expect(stored, isNotNull);
      expect(stored!.usefulness, 4);
      expect(stored.changeNote, 'Helped me complete my HTML card.');

      await expectLater(
        () => repo.submit(valid),
        throwsA(isA<CheckInAlreadyExistsException>()),
      );
    });
  });

  group('NotificationRepositoryImpl', () {
    test(
      'maps snapshots to AppNotification and streams unread counts',
      () async {
        final db = _MemoryFirestore();
        db.seed(Fs.notifications, 'n1', {
          'userId': 'u1',
          'title': 'Review approved',
          'body': 'Nice work.',
          'isRead': false,
          'route': '/task/t1',
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
        db.seed(Fs.notifications, 'n2', {
          'userId': 'u1',
          'title': 'Old read',
          'body': 'Done.',
          'isRead': true,
        });

        final repo = NotificationRepositoryImpl(
          dataSource: NotificationRemoteDataSource(firestore: db),
        );
        final items = await repo.watch('u1').first;
        expect(items, hasLength(2));
        expect(items.first.id, 'n1');
        expect(items.first.unread, isTrue);

        final unreadCount = await repo.watchUnreadCount('u1').first;
        expect(unreadCount, 1);

        await repo.markRead('u1', 'n1');
        expect(db.docData(Fs.notifications, 'n1')?['isRead'], isTrue);
      },
    );
  });

  group('UpBridgeRepository', () {
    test(
      'ensureYouthProfile creates baseline profile only when missing',
      () async {
        final db = _MemoryFirestore();
        final repo = UpBridgeRepository(db: db);

        final created = await repo.ensureYouthProfile(
          uid: 'u1',
          displayName: ' Aline ',
        );
        expect(created, isTrue);
        final doc = db.docData(Fs.users, 'u1');
        expect(doc?['role'], 'youth');
        expect(doc?['accountStatus'], 'active');
        expect(doc?['displayName'], 'Aline');
        expect(doc?['onboarded'], isFalse);

        final createdAgain = await repo.ensureYouthProfile(
          uid: 'u1',
          displayName: 'Changed',
        );
        expect(createdAgain, isFalse);
        expect(db.docData(Fs.users, 'u1')?['displayName'], 'Aline');
      },
    );

    test('sets task progress, adds project, and submits work', () async {
      final db = _MemoryFirestore();
      final repo = UpBridgeRepository(db: db);

      await repo.setTaskStatus('u1', 't1', SubmissionStatus.approved);
      expect(
        db.docData(Fs.taskProgress, 'u1_t1')?['status'],
        SubmissionStatus.approved,
      );

      final projectId = await repo.addProject('u1', {'title': 'Demo site'});
      expect(db.docData(Fs.projects, projectId)?['ownerId'], 'u1');
      expect(db.docData(Fs.projects, projectId)?['visibility'], 'private');

      final subId = await repo.submitWork('u1', {'taskId': 't1'});
      expect(
        db.docData(Fs.submissions, subId)?['status'],
        SubmissionStatus.submitted,
      );
    });
  });
}

class _MemoryFirestore implements FirebaseFirestore {
  final Map<String, Map<String, Map<String, dynamic>>> _tables = {};
  int _seq = 0;

  void seed(String collection, String id, Map<String, dynamic> data) {
    _tables.putIfAbsent(collection, () => {})[id] = _materialize(data);
  }

  Map<String, dynamic> _materialize(Map<Object?, Object?> input) {
    final result = <String, dynamic>{};
    input.forEach((key, value) {
      result[key as String] = value is FieldValue ? Timestamp.now() : value;
    });
    return result;
  }

  Map<String, dynamic>? docData(String collection, String id) =>
      _tables[collection]?[id];

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _MemCollection(this, collectionPath);

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) => transactionHandler(_MemTransaction(this));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemTransaction implements Transaction {
  _MemTransaction(this._db);

  final _MemoryFirestore _db;

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async {
    final memRef = documentReference as _MemDocRef;
    final data = _db.docData(memRef.collectionName, memRef.id);
    return _MemDocSnapshot(memRef.id, data == null ? null : Map.of(data))
        as DocumentSnapshot<T>;
  }

  @override
  Transaction set<T>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) {
    final memRef = documentReference as _MemDocRef;
    _db._tables.putIfAbsent(memRef.collectionName, () => {})[memRef.id] = _db
        ._materialize(data as Map<Object?, Object?>);
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemCollection implements CollectionReference<Map<String, dynamic>> {
  _MemCollection(this._db, this.path);

  final _MemoryFirestore _db;
  @override
  final String path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? docPath]) =>
      _MemDocRef(_db, path, docPath ?? 'auto-${++_db._seq}');

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
    Map<String, dynamic> data,
  ) async {
    final id = 'auto-${++_db._seq}';
    _db._tables.putIfAbsent(path, () => {})[id] = _db._materialize(data);
    return _MemDocRef(_db, path, id);
  }

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) => _MemQuery(_db, path, filters: {(field as String): isEqualTo});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemQuery implements Query<Map<String, dynamic>> {
  _MemQuery(
    this._db,
    this._collection, {
    this.filters = const {},
    this.limitCount,
  });

  final _MemoryFirestore _db;
  final String _collection;
  final Map<String, Object?> filters;
  final int? limitCount;

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) => _MemQuery(
    _db,
    _collection,
    filters: {...filters, (field as String): isEqualTo},
    limitCount: limitCount,
  );

  @override
  Query<Map<String, dynamic>> orderBy(
    Object field, {
    bool descending = false,
  }) => this;

  @override
  Query<Map<String, dynamic>> limit(int limit) =>
      _MemQuery(_db, _collection, filters: filters, limitCount: limit);

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _matching() {
    final map = _db._tables[_collection] ?? const {};
    var docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final entry in map.entries) {
      var ok = true;
      for (final f in filters.entries) {
        if (entry.value[f.key] != f.value) {
          ok = false;
          break;
        }
      }
      if (ok) {
        docs.add(
          _MemQueryDoc(_db, _collection, entry.key, Map.of(entry.value)),
        );
      }
    }
    if (limitCount != null && docs.length > limitCount!) {
      docs = docs.sublist(0, limitCount!);
    }
    return docs;
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _MemQuerySnapshot(_matching());

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => Stream.value(_MemQuerySnapshot(_matching()));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _MemQuerySnapshot(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  int get size => docs.length;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemQueryDoc implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _MemQueryDoc(this._db, this._collection, this.id, this._data);

  final _MemoryFirestore _db;
  final String _collection;
  @override
  final String id;
  final Map<String, dynamic> _data;

  @override
  bool get exists => true;

  @override
  DocumentReference<Map<String, dynamic>> get reference =>
      _MemDocRef(_db, _collection, id);

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemDocSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _MemDocSnapshot(this.id, this._data);

  @override
  final String id;
  final Map<String, dynamic>? _data;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemDocRef implements DocumentReference<Map<String, dynamic>> {
  _MemDocRef(this._db, this.collectionName, this.id);

  final _MemoryFirestore _db;
  final String collectionName;
  @override
  final String id;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    final data = _db.docData(collectionName, id);
    return _MemDocSnapshot(id, data == null ? null : Map.of(data));
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    final materialized = _db._materialize(data);
    final table = _db._tables.putIfAbsent(collectionName, () => {});
    if (options?.merge == true && table.containsKey(id)) {
      table[id] = {...table[id]!, ...materialized};
    } else {
      table[id] = materialized;
    }
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    final existing = _db._tables[collectionName]![id]!;
    existing.addAll(_db._materialize(data));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
