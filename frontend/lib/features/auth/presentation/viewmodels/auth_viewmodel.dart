import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/core/session/session_events.dart';
import 'package:bucalscan_ai/core/session/user_sensitive_state.dart';
import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/auth/domain/entities/auth_user.dart';
import 'package:bucalscan_ai/features/profile/di/profile_providers.dart';

class AuthState {
  final AuthUser? currentUser;
  final bool isLoading;
  final String? error;
  final int generation;
  final SessionEndReason? sessionEndReason;

  const AuthState({
    this.currentUser,
    this.isLoading = false,
    this.error,
    this.generation = 0,
    this.sessionEndReason,
  });

  bool get isAuthenticated => currentUser != null;

  AuthState copyWith({
    AuthUser? currentUser,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
    int? generation,
    SessionEndReason? sessionEndReason,
    bool clearSessionEndReason = false,
  }) {
    return AuthState(
      currentUser: clearUser ? null : currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      generation: generation ?? this.generation,
      sessionEndReason: clearSessionEndReason
          ? null
          : sessionEndReason ?? this.sessionEndReason,
    );
  }
}

class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() {
    final sessionSub = SessionEvents().onSessionExpired.listen((reason) {
      ref.resetUserSensitiveState();
      state = state.copyWith(
        clearUser: true,
        clearError: true,
        generation: state.generation + 1,
        sessionEndReason: reason,
      );
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
      ref.resetUserSensitiveState();
      state = AuthState(
        currentUser: session.user,
        generation: state.generation + 1,
      );
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
      ref.resetUserSensitiveState();
      state = AuthState(currentUser: user, generation: state.generation + 1);
      return true;
    } catch (e) {
      final message = e.toString();
      if (_isAuthenticationFailure(message)) {
        await ref.read(logoutUseCaseProvider)();
        state = AuthState(error: message);
        return false;
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
    required String profession,
    String? specialty,
    String? workspaceChoice,
    String? workspaceId,
    String? workspaceName,
    String? workspaceType,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await ref.read(registerUseCaseProvider)(
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
        workspaceType: workspaceType,
      );
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(
      clearUser: true,
      clearError: true,
      clearSessionEndReason: true,
      generation: state.generation + 1,
    );
    ref.resetUserSensitiveState();
    await ref.read(logoutUseCaseProvider)();
  }

  Future<bool> updateProfile({
    String? fullName,
    String? medicalCenter,
    String? email,
    String? profession,
    String? specialty,
  }) async {
    final generation = state.generation;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final profile = await ref.read(updateProfileUseCaseProvider)(
        fullName: fullName,
        medicalCenter: medicalCenter,
        email: email,
        profession: profession,
        specialty: specialty,
      );
      if (generation != state.generation) return false;

      state = AuthState(
        currentUser: AuthUser(
          id: profile.id,
          fullName: profile.fullName,
          doctorId: profile.doctorId,
          medicalCenter: profile.medicalCenter,
          email: profile.email,
          createdAt: profile.createdAt,
          role: profile.role,
          status: profile.status,
          profession: profile.profession,
          specialty: profile.specialty,
        ),
        generation: generation,
      );
      return true;
    } catch (e) {
      if (generation != state.generation) return false;
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
        normalized.contains('account suspended') ||
        normalized.contains('cuenta está suspendida') ||
        normalized.contains('sesión expiró');
  }
}

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);
