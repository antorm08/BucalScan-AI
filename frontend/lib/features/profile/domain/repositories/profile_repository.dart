import 'package:bucalscan_ai/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> updateProfile({
    String? fullName,
    String? medicalCenter,
    String? email,
  });
}
