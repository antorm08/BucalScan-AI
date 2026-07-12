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

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String doctorId,
    String? medicalCenter,
    required String email,
    required String password,
    String? workspaceChoice,
    String? workspaceId,
    String? workspaceName,
  }) {
    return _apiService.register(
      fullName: fullName,
      doctorId: doctorId,
      medicalCenter: medicalCenter,
      email: email,
      password: password,
      workspaceChoice: workspaceChoice,
      workspaceId: workspaceId,
      workspaceName: workspaceName,
    );
  }

  Future<Map<String, dynamic>> me() {
    return _apiService.me();
  }
}
