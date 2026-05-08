import 'package:bucalscan_ai/data/services/api_service.dart';

class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return _apiService.login(email: email, password: password);
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return _apiService.register(
      fullName: fullName,
      email: email,
      password: password,
    );
  }
}
