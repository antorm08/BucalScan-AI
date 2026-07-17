import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/features/admin/data/models/admin_user_model.dart';
import 'package:bucalscan_ai/features/admin/data/models/admin_request_models.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_query.dart';

class AdminRemoteDataSource {
  final ApiService _apiService;

  const AdminRemoteDataSource(this._apiService);

  Future<List<AdminUserModel>> getUsers() async {
    final data = await _apiService.getAdminUsers();
    return data.map(AdminUserModel.fromJson).toList();
  }

  Future<AdminPage<AdminUserModel>> getUsersPage(AdminQuery query) async {
    final json = await _apiService.getAdminPage(
      'users',
      query.toQuery(typeKey: 'workspace_type'),
    );
    return _page(json, AdminUserModel.fromJson);
  }

  Future<AdminPage<AdminWorkspaceRequestModel>> getCentersPage(
    AdminQuery query,
  ) async {
    final json = await _apiService.getAdminPage(
      'centers',
      query.toQuery(typeKey: 'workspace_type'),
    );
    return _page(json, AdminWorkspaceRequestModel.fromJson);
  }

  Future<AdminPage<AdminMembershipRequestModel>> getAccessPage(
    AdminQuery query,
  ) async {
    final json = await _apiService.getAdminPage(
      'access',
      query.toQuery(typeKey: 'workspace_type'),
    );
    return _page(json, AdminMembershipRequestModel.fromJson);
  }

  AdminPage<T> _page<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) => AdminPage(
    items: (json['items'] as List? ?? const [])
        .map((item) => parse(Map<String, dynamic>.from(item as Map)))
        .toList(),
    page: json['page'] as int? ?? 1,
    pageSize: json['page_size'] as int? ?? 25,
    total: json['total'] as int? ?? 0,
    hasNext: json['has_next'] as bool? ?? false,
  );

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

  Future<AdminWorkspaceRequestModel> updateCenter({
    required int id,
    required String city,
    required String address,
  }) async => AdminWorkspaceRequestModel.fromJson(
    await _apiService.updateAdminCenter(id: id, city: city, address: address),
  );

  Future<void> decideMembership(
    int id, {
    required bool approve,
    String role = 'professional',
  }) => _apiService.decideAdminMembership(id, approve: approve, role: role);
}
