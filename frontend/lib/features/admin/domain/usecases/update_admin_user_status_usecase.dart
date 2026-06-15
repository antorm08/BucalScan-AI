import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:bucalscan_ai/features/admin/domain/repositories/admin_repository.dart';

class UpdateAdminUserStatusUseCase {
  final AdminRepository _repository;

  const UpdateAdminUserStatusUseCase(this._repository);

  Future<AdminUser> call({
    required int userId,
    required String status,
  }) {
    return _repository.updateUserStatus(userId: userId, status: status);
  }
}
