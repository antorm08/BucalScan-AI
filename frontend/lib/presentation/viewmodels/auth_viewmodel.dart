import 'package:flutter/foundation.dart';
import 'package:bucalscan_ai/data/repositories/auth_repository.dart';
import 'package:bucalscan_ai/domain/entities/user.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  AuthViewModel(this._repository);

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  /*Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _repository.login(email: email, password: password);
      _currentUser = User(
        id: response['user_id'] as int,
        fullName: response['full_name'] as String? ?? '',
        email: email,
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
  }*/

  // Temporary mocked login until backend JWT integration is ready
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    _currentUser = User(
      id: 1,
      fullName: 'John Doe',
      doctorId: 'MD-DEMO-001',
      email: email,
    );
    _isLoading = false;
    notifyListeners();
    return true;
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

  void logout() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
