import '../entities/auth_session.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

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
    String? workspaceType,
  });

  Future<AuthUser> getCurrentUser();

  Future<bool> hasSessionToken();

  Future<AuthUser?> getCachedUser();

  Future<void> logout();
}
