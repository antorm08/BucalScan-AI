import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/data/services/auth_interceptor.dart';
import 'package:bucalscan_ai/data/services/auth_storage_service.dart';
import 'package:bucalscan_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bucalscan_ai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bucalscan_ai/features/auth/domain/entities/auth_session.dart';
import 'package:bucalscan_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/get_cached_user_usecase.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/has_session_token_usecase.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/login_usecase.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/logout_usecase.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/register_usecase.dart';

final authStorageProvider = Provider<AuthStorageService>((ref) {
  return AuthStorageService();
});

final authApiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.watch(authStorageProvider);
  return ApiService(interceptors: [AuthInterceptor(storage)]);
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(authApiServiceProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(authStorageProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

final hasSessionTokenUseCaseProvider = Provider<HasSessionTokenUseCase>((ref) {
  return HasSessionTokenUseCase(ref.watch(authRepositoryProvider));
});

final getCachedUserUseCaseProvider = Provider<GetCachedUserUseCase>((ref) {
  return GetCachedUserUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(loginUseCaseProvider));
  },
);

class AuthState {
  final bool isLoading;
  final String? error;
  final AuthSession? session;

  const AuthState({this.isLoading = false, this.error, this.session});

  AuthState copyWith({
    bool? isLoading,
    String? error,
    AuthSession? session,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      session: session ?? this.session,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;

  AuthController(this._loginUseCase) : super(const AuthState());

  Future<AuthSession?> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final session = await _loginUseCase(email: email, password: password);
      state = AuthState(session: session);
      return session;
    } catch (e) {
      state = AuthState(error: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
