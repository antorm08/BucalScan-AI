import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/features/admin/data/models/admin_user_model.dart';
import 'package:bucalscan_ai/features/admin/data/models/admin_request_models.dart';

class AdminRemoteDataSource {
  final ApiService _apiService;

  const AdminRemoteDataSource(this._apiService);

  Future<List<AdminUserModel>> getUsers() async {
    final data = await _apiService.getAdminUsers();
    return data.map(AdminUserModel.fromJson).toList();
  }

  Future<AdminUserModel> updateUserStatus({
    required int userId,
    required String status,
  }) async {
    final json = await _apiService.updateAdminUserStatus(
      userId: userId,
      status: status,
    );
    return AdminUserModel.fromJson(json);
  }

  Future<AdminSummaryModel> getSummary() async =>
      AdminSummaryModel.fromJson(await _apiService.getAdminSummary());

  Future<List<AdminWorkspaceRequestModel>> getWorkspaceRequests() async =>
      (await _apiService.getAdminWorkspaceRequests())
          .map(AdminWorkspaceRequestModel.fromJson)
          .toList();

  Future<List<AdminMembershipRequestModel>> getMembershipRequests() async =>
      (await _apiService.getAdminMembershipRequests())
          .map(AdminMembershipRequestModel.fromJson)
          .toList();

  Future<void> decideWorkspace(int id, {required bool approve}) =>
      _apiService.decideAdminWorkspace(id, approve: approve);

  Future<void> decideMembership(
    int id, {
    required bool approve,
    String role = 'professional',
  }) => _apiService.decideAdminMembership(id, approve: approve, role: role);
}
