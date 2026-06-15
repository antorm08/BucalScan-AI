import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:bucalscan_ai/features/admin/domain/repositories/admin_repository.dart';

class GetAdminUsersUseCase {
  final AdminRepository _repository;

  const GetAdminUsersUseCase(this._repository);

  Future<List<AdminUser>> call() {
    return _repository.getUsers();
  }
}
