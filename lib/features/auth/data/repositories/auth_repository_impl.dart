import 'package:firebase_auth/firebase_auth.dart';

import 'package:upbridge/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:upbridge/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthRemoteDataSource dataSource})
    : _dataSource = dataSource;
  final AuthRemoteDataSource _dataSource;

  @override
  Stream<User?> get authStateChanges => _dataSource.authStateChanges;
  @override
  User? get currentUser => _dataSource.currentUser;
  @override
  Future<UserCredential> signIn(String email, String password) =>
      _dataSource.signIn(email, password);
  @override
  Future<UserCredential> signUp(String email, String password) =>
      _dataSource.signUp(email, password);
  @override
  Future<void> sendPasswordReset(String email) =>
      _dataSource.sendPasswordReset(email);
  @override
  Future<void> signOut() => _dataSource.signOut();
}
