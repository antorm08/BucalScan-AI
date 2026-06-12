import 'package:bucalscan_ai/data/services/api_service.dart';

class AuthRemoteDataSource {
  final ApiService _apiService;

  const AuthRemoteDataSource(this._apiService);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _apiService.login(email: email, password: password);
  }
}
