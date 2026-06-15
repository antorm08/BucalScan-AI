import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bucalscan_ai/core/session/session_events.dart';
import 'package:bucalscan_ai/features/auth/domain/entities/auth_user.dart';
import 'package:bucalscan_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/get_cached_user_usecase.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/has_session_token_usecase.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/logout_usecase.dart';
import 'package:bucalscan_ai/features/profile/domain/usecases/update_profile_usecase.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  final UpdateProfileUseCase _updateProfileUseCase;
  final HasSessionTokenUseCase _hasSessionTokenUseCase;
  final GetCachedUserUseCase _getCachedUserUseCase;
  final LogoutUseCase _logoutUseCase;
  late final StreamSubscription<void> _sessionSub;

  AuthViewModel(
    this._repository,
    this._updateProfileUseCase,
    this._hasSessionTokenUseCase,
    this._getCachedUserUseCase,
    this._logoutUseCase,
  ) {
    _sessionSub = SessionEvents().onSessionExpired.listen((_) {
      _currentUser = null;
      _error = null;
      notifyListeners();
    });
  }

  AuthUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  void syncAuthenticatedUser(AuthUser user) {
    _currentUser = user;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final session = await _repository.login(
        email: email,
        password: password,
      );

      _currentUser = session.user;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> tryAutoLogin() async {
    final hasSessionToken = await _hasSessionTokenUseCase();
    if (!hasSessionToken) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _repository.getCurrentUser();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final message = e.toString();
      final cachedUser = await _getCachedUserUseCase();

      if (_isAuthenticationFailure(message)) {
        await _logoutUseCase();
        _currentUser = null;
        _error = message;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (cachedUser != null) {
        _currentUser = cachedUser;
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String doctorId,
    String? medicalCenter,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.register(
        fullName: fullName,
        doctorId: doctorId,
        medicalCenter: medicalCenter,
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _error = null;
    await _logoutUseCase();
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? fullName,
    String? medicalCenter,
    String? email,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profile = await _updateProfileUseCase(
        fullName: fullName,
        medicalCenter: medicalCenter,
        email: email,
      );

      final userData = {
        'id': profile.id,
        'full_name': profile.fullName,
        'doctor_id': profile.doctorId,
        'medical_center': profile.medicalCenter,
        'email': profile.email,
        'created_at': profile.createdAt?.toIso8601String(),
        'role': profile.role,
      };
      final user = _parseUser(userData);
      _currentUser = user;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionSub.cancel();
    super.dispose();
  }

  AuthUser _parseUser(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      doctorId: json['doctor_id'] as String? ?? '',
      medicalCenter: json['medical_center'] as String?,
      email: json['email'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      role: json['role'] as String? ?? 'doctor',
    );
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
