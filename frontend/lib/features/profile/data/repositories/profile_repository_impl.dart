import 'package:bucalscan_ai/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:bucalscan_ai/features/profile/domain/entities/user_profile.dart';
import 'package:bucalscan_ai/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  const ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<UserProfile> updateProfile({
    String? fullName,
    String? medicalCenter,
    String? email,
    String? profession,
    String? specialty,
  }) async {
    final model = await _remoteDataSource.updateProfile(
      fullName: fullName,
      medicalCenter: medicalCenter,
      email: email,
      profession: profession,
      specialty: specialty,
    );
    return model.toEntity();
  }
}
