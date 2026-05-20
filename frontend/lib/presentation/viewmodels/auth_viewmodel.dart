import 'package:flutter/foundation.dart';
import 'package:bucalscan_ai/data/repositories/auth_repository.dart';
import 'package:bucalscan_ai/data/services/auth_storage_service.dart';
import 'package:bucalscan_ai/domain/entities/user.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  final AuthStorageService _storage;

  AuthViewModel(this._repository, this._storage);

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _repository.login(
        email: email,
        password: password,
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Respuesta inesperada del servidor');
      }

      final userData = data['user'] as Map<String, dynamic>?;
      final token = data['token'] as String?;

      if (userData == null || token == null) {
        throw Exception('Respuesta inesperada del servidor');
      }

      final user = _parseUser(userData);
      _currentUser = user;

      await _storage.saveToken(token);
      await _storage.saveUserJson(userData);

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
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _repository.me();
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Respuesta inesperada del servidor');
      }

      final userData = data['user'] as Map<String, dynamic>?;
      if (userData == null) {
        throw Exception('Respuesta inesperada del servidor');
      }

      final user = _parseUser(userData);
      _currentUser = user;
      await _storage.saveUserJson(userData);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final message = e.toString();
      final cachedUser = await _storage.getUserJson();

      if (_isAuthenticationFailure(message)) {
        await _storage.clear();
        _currentUser = null;
        _error = message;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (cachedUser != null) {
        _currentUser = _parseUser(cachedUser);
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
    await _storage.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  User _parseUser(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      doctorId: json['doctor_id'] as String? ?? '',
      medicalCenter: json['medical_center'] as String?,
      email: json['email'] as String? ?? '',
    );
  }

  bool _isAuthenticationFailure(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('invalid or expired token') ||
        normalized.contains('not authenticated') ||
        normalized.contains('user not found') ||
        normalized.contains('invalid token payload');
  }
}
