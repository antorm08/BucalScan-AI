import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/features/admin/data/models/admin_user_model.dart';

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
}
