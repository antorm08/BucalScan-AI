import 'package:bucalscan_ai/data/services/auth_storage_service.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_session_model.dart';
import '../models/auth_user_model.dart';

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

  @override
  Future<void> register({
    required String fullName,
    required String doctorId,
    String? medicalCenter,
    required String email,
    required String password,
    required String profession,
    String? specialty,
    String? workspaceChoice,
    String? workspaceId,
    String? workspaceName,
  }) {
    return _remoteDataSource.register(
      fullName: fullName,
      doctorId: doctorId,
      medicalCenter: medicalCenter,
      email: email,
      password: password,
      profession: profession,
      specialty: specialty,
      workspaceChoice: workspaceChoice,
      workspaceId: workspaceId,
      workspaceName: workspaceName,
    );
  }

  @override
  Future<AuthUser> getCurrentUser() async {
    final response = await _remoteDataSource.me();
    final data = response['data'] as Map<String, dynamic>?;
    final userJson = data?['user'] as Map<String, dynamic>?;
    if (userJson == null) {
      throw const FormatException('missing_current_user');
    }

    final user = AuthUserModel.fromJson(userJson);
    await _storage.saveUserJson(user.toJson());
    return user;
  }

  @override
  Future<bool> hasSessionToken() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<AuthUser?> getCachedUser() async {
    final userJson = await _storage.getUserJson();
    if (userJson == null) return null;
    return AuthUserModel.fromJson(userJson);
  }

  @override
  Future<void> logout() {
    return _storage.clear();
  }
}
