import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';

abstract class AdminRepository {
  Future<List<AdminUser>> getUsers();

  Future<AdminUser> updateUserStatus({
    required int userId,
    required String status,
  });
}
