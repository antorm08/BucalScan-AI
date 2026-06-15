import 'package:bucalscan_ai/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:bucalscan_ai/features/admin/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _remoteDataSource;

  const AdminRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<AdminUser>> getUsers() async {
    final models = await _remoteDataSource.getUsers();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<AdminUser> updateUserStatus({
    required int userId,
    required String status,
  }) async {
    final model = await _remoteDataSource.updateUserStatus(
      userId: userId,
      status: status,
    );
    return model.toEntity();
  }
}
