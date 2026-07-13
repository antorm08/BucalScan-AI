import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_request.dart';

abstract class AdminRepository {
  Future<List<AdminUser>> getUsers();

  Future<AdminUser> updateUserStatus({
    required int userId,
    required String status,
  });

  Future<AdminSummary> getSummary();
  Future<List<AdminWorkspaceRequest>> getWorkspaceRequests();
  Future<List<AdminMembershipRequest>> getMembershipRequests();
  Future<void> decideWorkspace(int id, {required bool approve});
  Future<void> decideMembership(
    int id, {
    required bool approve,
    required String role,
  });
}
