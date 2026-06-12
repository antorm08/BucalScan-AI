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
    required String doctorId,
    String? medicalCenter,
    required String email,
    required String password,
  }) async {
    return _apiService.register(
      fullName: fullName,
      doctorId: doctorId,
      medicalCenter: medicalCenter,
      email: email,
      password: password,
    );
  }

  Future<Map<String, dynamic>> me() async {
    return _apiService.me();
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? medicalCenter,
    String? email,
  }) async {
    return _apiService.updateProfile(
      fullName: fullName,
      medicalCenter: medicalCenter,
      email: email,
    );
  }
}
