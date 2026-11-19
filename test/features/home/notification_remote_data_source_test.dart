// ignore_for_file: subtype_of_sealed_class

// Tests paginated NotificationRemoteDataSource.markAllRead and ownership validation in markRead.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/features/home/data/datasources/notification_remote_data_source.dart';
import 'package:upbridge/shared/services/firebase/firestore_schema.dart';

void main() {
  test(
    'markAllRead updates more than 100 and across multiple 450-doc batches',
    () async {
      final store = _InMemoryNotificationFirestore();
      for (var i = 0; i < 520; i++) {
        store.seed(
          id: 'n-$i',
          userId: 'user-1',
          isRead: false,
          createdOrder: 1000 - i,
        );
      }
      store.seed(
        id: 'n-other',
        userId: 'user-2',
        isRead: false,
        createdOrder: 2000,
      );
      store.seed(
        id: 'n-already-read',
        userId: 'user-1',
        isRead: true,
        createdOrder: 5000,
      );

      final dataSource = NotificationRemoteDataSource(firestore: store);
      await dataSource.markAllRead('user-1');

      final userOneDocs = store.docsFor('user-1');
      expect(userOneDocs.length, 521);
      expect(userOneDocs.every((doc) => doc['isRead'] == true), isTrue);
      expect(store.committedBatchSizes, [450, 70]);
      expect(store.docsFor('user-2').single['isRead'], isFalse);
    },
  );

  test('markRead rejects notifications owned by a different user', () async {
    final store = _InMemoryNotificationFirestore();
    store.seed(
      id: 'n-foreign',
      userId: 'user-2',
      isRead: false,
      createdOrder: 10,
    );

    final dataSource = NotificationRemoteDataSource(firestore: store);
    await expectLater(
      () => dataSource.markRead('user-1', 'n-foreign'),
      throwsStateError,
    );
  });

  test('markRead marks owned notification read', () async {
    final store = _InMemoryNotificationFirestore();
    store.seed(id: 'n-own', userId: 'user-1', isRead: false, createdOrder: 10);

    final dataSource = NotificationRemoteDataSource(firestore: store);
    await dataSource.markRead('user-1', 'n-own');
    expect(store.docData('n-own')?['isRead'], isTrue);
  });
}

class _InMemoryNotificationFirestore implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> _records = {};
  final List<int> committedBatchSizes = [];

  void seed({
    required String id,
    required String userId,
    required bool isRead,
    required int createdOrder,
  }) {
    _records[id] = {
      'userId': userId,
      'isRead': isRead,
      'createdAt': createdOrder,
    };
  }

  List<Map<String, dynamic>> docsFor(String userId) =>
      _records.values.where((d) => d['userId'] == userId).toList();

  Map<String, dynamic>? docData(String id) => _records[id];

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    assert(collectionPath == Fs.notifications);
    return _FakeCollection(this);
  }

  @override
  WriteBatch batch() => _FakeBatch(this);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCollection implements CollectionReference<Map<String, dynamic>> {
  _FakeCollection(this._db);

  final _InMemoryNotificationFirestore _db;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _FakeDocRef(_db, path!);

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
  }) => _FakeQuery(_db, filters: {(field as String): isEqualTo});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQuery implements Query<Map<String, dynamic>> {
  _FakeQuery(
    this._db, {
    required this.filters,
    this.limitCount,
    this.startAfterId,
  });

  final _InMemoryNotificationFirestore _db;
  final Map<String, Object?> filters;
  final int? limitCount;
  final String? startAfterId;

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
  }) => _FakeQuery(
    _db,
    filters: {...filters, (field as String): isEqualTo},
    limitCount: limitCount,
    startAfterId: startAfterId,
  );

  @override
  Query<Map<String, dynamic>> orderBy(
    Object field, {
    bool descending = false,
  }) => this;

  @override
  Query<Map<String, dynamic>> limit(int limit) => _FakeQuery(
    _db,
    filters: filters,
    limitCount: limit,
    startAfterId: startAfterId,
  );

  @override
  Query<Map<String, dynamic>> startAfterDocument(
    DocumentSnapshot<Object?> documentSnapshot,
  ) => _FakeQuery(
    _db,
    filters: filters,
    limitCount: limitCount,
    startAfterId: documentSnapshot.id,
  );

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    var entries = _db._records.entries.where((entry) {
      for (final f in filters.entries) {
        if (entry.value[f.key] != f.value) return false;
      }
      return true;
    }).toList();

    entries.sort(
      (a, b) =>
          (b.value['createdAt'] as int).compareTo(a.value['createdAt'] as int),
    );

    if (startAfterId != null) {
      final index = entries.indexWhere((e) => e.key == startAfterId);
      if (index != -1) {
        entries = entries.sublist(index + 1);
      }
    }

    if (limitCount != null && entries.length > limitCount!) {
      entries = entries.sublist(0, limitCount!);
    }

    final docs = [
      for (final e in entries) _FakeQueryDoc(_db, e.key, Map.of(e.value)),
    ];
    return _FakeQuerySnapshot(docs);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _FakeQuerySnapshot(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQueryDoc implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeQueryDoc(this._db, this.id, this._data);

  final _InMemoryNotificationFirestore _db;
  @override
  final String id;
  final Map<String, dynamic> _data;

  @override
  bool get exists => true;

  @override
  DocumentReference<Map<String, dynamic>> get reference => _FakeDocRef(_db, id);

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDocSnapshot(this.id, this._data);

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

class _FakeDocRef implements DocumentReference<Map<String, dynamic>> {
  _FakeDocRef(this._db, this.id);

  final _InMemoryNotificationFirestore _db;
  @override
  final String id;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    final data = _db._records[id];
    return _FakeDocSnapshot(id, data == null ? null : Map.of(data));
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    final existing = _db._records[id]!;
    data.forEach((key, value) {
      existing[key as String] = value;
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBatch implements WriteBatch {
  _FakeBatch(this._db);

  final _InMemoryNotificationFirestore _db;
  final List<void Function()> _ops = [];

  @override
  void update<T>(DocumentReference<T> document, T data) {
    final map = data as Map<Object?, Object?>;
    _ops.add(() {
      final existing = _db._records[document.id]!;
      map.forEach((key, value) {
        existing[key as String] = value;
      });
    });
  }

  @override
  Future<void> commit() async {
    for (final op in _ops) {
      op();
    }
    _db.committedBatchSizes.add(_ops.length);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
