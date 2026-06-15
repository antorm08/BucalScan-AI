import 'package:bucalscan_ai/features/profile/domain/entities/user_profile.dart';
import 'package:bucalscan_ai/features/profile/domain/repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository _repository;

  const UpdateProfileUseCase(this._repository);

  Future<UserProfile> call({
    String? fullName,
    String? medicalCenter,
    String? email,
  }) {
    return _repository.updateProfile(
      fullName: fullName,
      medicalCenter: medicalCenter,
      email: email,
    );
  }
}
