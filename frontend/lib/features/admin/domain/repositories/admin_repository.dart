import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_request.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_query.dart';

abstract class AdminRepository {
  Future<List<AdminUser>> getUsers();
  Future<AdminPage<AdminUser>> getUsersPage(AdminQuery query) async {
    final items = await getUsers();
    return AdminPage(
      items: items,
      page: 1,
      pageSize: items.length,
      total: items.length,
      hasNext: false,
    );
  }

  Future<AdminPage<AdminWorkspaceRequest>> getCentersPage(
    AdminQuery query,
  ) async {
    final items = await getWorkspaceRequests();
    return AdminPage(
      items: items,
      page: 1,
      pageSize: items.length,
      total: items.length,
      hasNext: false,
    );
  }

  Future<AdminPage<AdminMembershipRequest>> getAccessPage(
    AdminQuery query,
  ) async {
    final items = await getMembershipRequests();
    return AdminPage(
      items: items,
      page: 1,
      pageSize: items.length,
      total: items.length,
      hasNext: false,
    );
  }

  Future<AdminUser> updateUserStatus({
    required int userId,
    required String status,
  });

  Future<AdminSummary> getSummary();
  Future<List<AdminWorkspaceRequest>> getWorkspaceRequests();
  Future<List<AdminMembershipRequest>> getMembershipRequests();
  Future<void> decideWorkspace(int id, {required bool approve});
  Future<AdminWorkspaceRequest> updateCenter({
    required int id,
    required String city,
    required String address,
  });
  Future<void> decideMembership(
    int id, {
    required bool approve,
    required String role,
  });
}
