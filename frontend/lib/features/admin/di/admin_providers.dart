import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:bucalscan_ai/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:bucalscan_ai/features/admin/domain/repositories/admin_repository.dart';
import 'package:bucalscan_ai/features/admin/domain/usecases/get_admin_users_usecase.dart';
import 'package:bucalscan_ai/features/admin/domain/usecases/update_admin_user_status_usecase.dart';
import 'package:bucalscan_ai/features/admin/domain/usecases/admin_approvals_usecase.dart';
import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSource(ref.watch(authApiServiceProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(ref.watch(adminRemoteDataSourceProvider));
});

final getAdminUsersUseCaseProvider = Provider<GetAdminUsersUseCase>((ref) {
  return GetAdminUsersUseCase(ref.watch(adminRepositoryProvider));
});

final updateAdminUserStatusUseCaseProvider =
    Provider<UpdateAdminUserStatusUseCase>((ref) {
      return UpdateAdminUserStatusUseCase(ref.watch(adminRepositoryProvider));
    });

final adminApprovalsUseCaseProvider = Provider<AdminApprovalsUseCase>((ref) {
  return AdminApprovalsUseCase(ref.watch(adminRepositoryProvider));
});
