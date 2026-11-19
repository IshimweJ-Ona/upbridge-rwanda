// ignore_for_file: subtype_of_sealed_class

// Tests AdminRemoteDataSource, AdminListingDataSource, and AdminUsersRepositoryImpl.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/features/admin/data/datasources/admin_listing_data_source.dart';
import 'package:upbridge/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:upbridge/features/admin/data/repositories/admin_users_repository_impl.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/firebase/firestore_schema.dart';

void main() {
  group('AdminRemoteDataSource and AdminUsersRepositoryImpl', () {
    test(
      'enforces listUsers bounds, maps valid users, and counts records',
      () async {
        final db = _AdminMemoryFirestore();
        db.seed(Fs.users, 'u-1', {
          'role': 'youth',
          'displayName': 'Aline Uwase',
          'phone': '+250 788 000 001',
          'district': 'Gasabo',
          'accountStatus': 'active',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 10, 5)),
        });
        db.seed(Fs.users, 'u-2', {
          'role': 'mentor',
          'name': 'Alice Mentor',
          'location': 'Kigali',
          'accountStatus': 'pending',
        });
        db.seed(Fs.users, 'u-bad-role', {
          'role': 'unknown',
          'displayName': 'Skip Me',
        });
        db.seed(Fs.users, 'u-empty-name', {
          'role': 'youth',
          'displayName': '   ',
        });

        final dataSource = AdminRemoteDataSource(firestore: db);
        await expectLater(
          () => dataSource.listUsers(limit: 0),
          throwsRangeError,
        );
        await expectLater(
          () => dataSource.listUsers(limit: 101),
          throwsRangeError,
        );

        expect(await dataSource.countUsers(), 4);

        final repo = AdminUsersRepositoryImpl(dataSource: dataSource);
        final users = await repo.listUsers(limit: 50);
        expect(users.map((u) => u.id), ['u-1', 'u-2']);
        expect(users.first.role, Role.youth);
        expect(users.first.status, 'Active');
        expect(users.first.joined, '5/10/2026');
        expect(users[1].district, 'Kigali');

        final paged = await repo.listUsers(limit: 50, afterId: 'u-1');
        expect(paged.map((u) => u.id), ['u-2']);

        expect((await repo.getUser('u-2'))?.role, Role.mentor);
        expect(await repo.getUser('missing'), isNull);
      },
    );
  });

  group('AdminListingDataSource', () {
    test('validates bounds and returns published listings', () async {
      final db = _AdminMemoryFirestore();
      db.seed(Fs.opportunities, 'opp-1', {
        'status': OpportunityStatus.published,
        'title': 'Frontend Intern',
      });
      db.seed(Fs.opportunities, 'opp-2', {
        'status': 'draft',
        'title': 'Draft Role',
      });

      final dataSource = AdminListingDataSource(firestore: db);
      await expectLater(
        () => dataSource.listPublished(limit: 0),
        throwsRangeError,
      );
      await expectLater(
        () => dataSource.listPublished(limit: 101),
        throwsRangeError,
      );

      final snapshot = await dataSource.listPublished();
      expect(snapshot.docs.map((d) => d.id), ['opp-1']);
    });
  });
}

class _AdminMemoryFirestore implements FirebaseFirestore {
  final Map<String, Map<String, Map<String, dynamic>>> _tables = {};

  void seed(String collection, String id, Map<String, dynamic> data) {
    _tables.putIfAbsent(collection, () => {})[id] = Map.of(data);
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _AdminCollection(this, collectionPath);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AdminCollection extends _AdminQuery
    implements CollectionReference<Map<String, dynamic>> {
  _AdminCollection(super.db, super.collection);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _AdminDocRef(_db, _collection, path!);

  @override
  AggregateQuery count() =>
      _FakeAggregateCount((_db._tables[_collection] ?? {}).length);
}

class _FakeAggregateCount implements AggregateQuery {
  _FakeAggregateCount(this._count);

  final int _count;

  @override
  Future<AggregateQuerySnapshot> get({
    AggregateSource source = AggregateSource.server,
  }) async => _FakeAggregateSnapshot(_count);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAggregateSnapshot implements AggregateQuerySnapshot {
  _FakeAggregateSnapshot(this.count);

  @override
  final int? count;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AdminQuery implements Query<Map<String, dynamic>> {
  _AdminQuery(
    this._db,
    this._collection, {
    this.filters = const {},
    this.limitCount,
    this.afterId,
  });

  final _AdminMemoryFirestore _db;
  final String _collection;
  final Map<String, Object?> filters;
  final int? limitCount;
  final String? afterId;

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
  }) => _AdminQuery(
    _db,
    _collection,
    filters: {...filters, (field as String): isEqualTo},
    limitCount: limitCount,
    afterId: afterId,
  );

  @override
  Query<Map<String, dynamic>> orderBy(
    Object field, {
    bool descending = false,
  }) => this;

  @override
  Query<Map<String, dynamic>> limit(int limit) => _AdminQuery(
    _db,
    _collection,
    filters: filters,
    limitCount: limit,
    afterId: afterId,
  );

  @override
  Query<Map<String, dynamic>> startAfterDocument(
    DocumentSnapshot<Object?> documentSnapshot,
  ) => _AdminQuery(
    _db,
    _collection,
    filters: filters,
    limitCount: limitCount,
    afterId: documentSnapshot.id,
  );

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final table = _db._tables[_collection] ?? const {};
    var keys = table.keys.toList()..sort();
    var filtered = [
      for (final k in keys)
        if (filters.entries.every((f) => table[k]![f.key] == f.value))
          MapEntry(k, table[k]!),
    ];
    if (afterId != null) {
      final index = filtered.indexWhere((e) => e.key == afterId);
      if (index != -1) {
        filtered = filtered.sublist(index + 1);
      }
    }
    if (limitCount != null && filtered.length > limitCount!) {
      filtered = filtered.sublist(0, limitCount!);
    }
    return _AdminQuerySnapshot([
      for (final e in filtered) _AdminQueryDoc(e.key, Map.of(e.value)),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AdminQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _AdminQuerySnapshot(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AdminQueryDoc implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _AdminQueryDoc(this.id, this._data);

  @override
  final String id;
  final Map<String, dynamic> _data;

  @override
  bool get exists => true;

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AdminDocSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _AdminDocSnapshot(this.id, this._data);

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

class _AdminDocRef implements DocumentReference<Map<String, dynamic>> {
  _AdminDocRef(this._db, this._collection, this.id);

  final _AdminMemoryFirestore _db;
  final String _collection;
  @override
  final String id;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    final data = _db._tables[_collection]?[id];
    return _AdminDocSnapshot(id, data == null ? null : Map.of(data));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
