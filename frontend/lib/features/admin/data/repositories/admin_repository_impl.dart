import 'package:bucalscan_ai/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_request.dart';
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

  @override
  Future<AdminSummary> getSummary() async =>
      (await _remoteDataSource.getSummary()).value;

  @override
  Future<List<AdminWorkspaceRequest>> getWorkspaceRequests() async =>
      (await _remoteDataSource.getWorkspaceRequests())
          .map((item) => item.value)
          .toList();

  @override
  Future<List<AdminMembershipRequest>> getMembershipRequests() async =>
      (await _remoteDataSource.getMembershipRequests())
          .map((item) => item.value)
          .toList();

  @override
  Future<void> decideWorkspace(int id, {required bool approve}) =>
      _remoteDataSource.decideWorkspace(id, approve: approve);

  @override
  Future<void> decideMembership(
    int id, {
    required bool approve,
    required String role,
  }) => _remoteDataSource.decideMembership(id, approve: approve, role: role);
}
