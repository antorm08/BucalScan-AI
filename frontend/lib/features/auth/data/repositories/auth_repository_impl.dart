import 'package:bucalscan_ai/data/services/auth_storage_service.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_session_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthStorageService _storage;

  const AuthRepositoryImpl(this._remoteDataSource, this._storage);

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      email: email,
      password: password,
    );
    final session = AuthSessionModel.fromJson(response);

    await _storage.saveToken(session.token);
    await _storage.saveUserJson(session.userJson);

    return session;
  }
}
