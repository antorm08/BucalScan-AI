import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:bucalscan_ai/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:bucalscan_ai/features/profile/domain/repositories/profile_repository.dart';
import 'package:bucalscan_ai/features/profile/domain/usecases/update_profile_usecase.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((
  ref,
) {
  return ProfileRemoteDataSource(ref.watch(authApiServiceProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(profileRepositoryProvider));
});
