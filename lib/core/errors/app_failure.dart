// Represents safe, typed failures returned by shared application services.

sealed class AppFailure implements Exception {
  const AppFailure(this.code);

  final String code;

  @override
  String toString() => '$runtimeType($code)';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.code = 'network-error']);
}

final class PermissionFailure extends AppFailure {
  const PermissionFailure([super.code = 'permission-denied']);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.code = 'not-found']);
}

final class ConflictFailure extends AppFailure {
  const ConflictFailure([super.code = 'conflict']);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure([super.code = 'invalid-data']);
}

final class RemoteServiceFailure extends AppFailure {
  const RemoteServiceFailure(super.code);
}
