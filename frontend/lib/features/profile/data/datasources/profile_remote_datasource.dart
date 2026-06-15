import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/features/profile/data/models/user_profile_model.dart';

class ProfileRemoteDataSource {
  final ApiService _apiService;

  const ProfileRemoteDataSource(this._apiService);

  Future<UserProfileModel> updateProfile({
    String? fullName,
    String? medicalCenter,
    String? email,
  }) async {
    final response = await _apiService.updateProfile(
      fullName: fullName,
      medicalCenter: medicalCenter,
      email: email,
    );
    final data = response['data'] as Map<String, dynamic>?;
    final userData = data?['user'] as Map<String, dynamic>?;
    if (userData == null) {
      throw Exception('Respuesta inesperada del servidor');
    }
    return UserProfileModel.fromJson(userData);
  }
}
