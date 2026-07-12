import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/core/session/session_events.dart';
import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/auth/domain/entities/auth_user.dart';
import 'package:bucalscan_ai/features/profile/di/profile_providers.dart';

class AuthState {
  final AuthUser? currentUser;
  final bool isLoading;
  final String? error;

  const AuthState({this.currentUser, this.isLoading = false, this.error});

  bool get isAuthenticated => currentUser != null;

  AuthState copyWith({
    AuthUser? currentUser,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      currentUser: clearUser ? null : currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() {
    final sessionSub = SessionEvents().onSessionExpired.listen((_) {
      state = state.copyWith(clearUser: true, clearError: true);
    });
    ref.onDispose(sessionSub.cancel);

    return const AuthState();
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final session = await ref.read(loginUseCaseProvider)(
        email: email,
        password: password,
      );
      state = AuthState(currentUser: session.user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> tryAutoLogin() async {
    final hasSessionToken = await ref.read(hasSessionTokenUseCaseProvider)();
    if (!hasSessionToken) {
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await ref.read(getCurrentUserUseCaseProvider)();
      state = AuthState(currentUser: user);
      return true;
    } catch (e) {
      final message = e.toString();
      final cachedUser = await ref.read(getCachedUserUseCaseProvider)();

      if (_isAuthenticationFailure(message)) {
        await ref.read(logoutUseCaseProvider)();
        state = AuthState(error: message);
        return false;
      }

      if (cachedUser != null) {
        state = AuthState(currentUser: cachedUser);
        return true;
      }

      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String doctorId,
    String? medicalCenter,
    required String email,
    required String password,
    String? workspaceChoice,
    String? workspaceId,
    String? workspaceName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await ref.read(registerUseCaseProvider)(
        fullName: fullName,
        doctorId: doctorId,
        medicalCenter: medicalCenter,
        email: email,
        password: password,
        workspaceChoice: workspaceChoice,
        workspaceId: workspaceId,
        workspaceName: workspaceName,
      );
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(clearUser: true, clearError: true);
    await ref.read(logoutUseCaseProvider)();
  }

  Future<bool> updateProfile({
    String? fullName,
    String? medicalCenter,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final profile = await ref.read(updateProfileUseCaseProvider)(
        fullName: fullName,
        medicalCenter: medicalCenter,
        email: email,
      );

      state = AuthState(
        currentUser: AuthUser(
          id: profile.id,
          fullName: profile.fullName,
          doctorId: profile.doctorId,
          medicalCenter: profile.medicalCenter,
          email: profile.email,
          createdAt: profile.createdAt,
          role: profile.role,
        ),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  bool _isAuthenticationFailure(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('invalid or expired token') ||
        normalized.contains('not authenticated') ||
        normalized.contains('user not found') ||
        normalized.contains('invalid token payload') ||
        normalized.contains('account suspended');
  }
}

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);
