import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/admin/di/admin_providers.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:bucalscan_ai/features/admin/domain/usecases/get_admin_users_usecase.dart';
import 'package:bucalscan_ai/features/admin/domain/usecases/update_admin_user_status_usecase.dart';

class AdminUsersState {
  final bool isLoading;
  final String? error;
  final List<AdminUser> users;
  final int? updatingUserId;

  const AdminUsersState({
    this.isLoading = false,
    this.error,
    this.users = const [],
    this.updatingUserId,
  });
}

class AdminUsersController extends StateNotifier<AdminUsersState> {
  final GetAdminUsersUseCase _getAdminUsersUseCase;
  final UpdateAdminUserStatusUseCase _updateAdminUserStatusUseCase;

  AdminUsersController(
    this._getAdminUsersUseCase,
    this._updateAdminUserStatusUseCase,
  ) : super(const AdminUsersState());

  Future<void> fetchUsers() async {
    state = const AdminUsersState(isLoading: true);
    try {
      final users = await _getAdminUsersUseCase();
      state = AdminUsersState(users: users);
    } catch (e) {
      state = AdminUsersState(error: e.toString());
    }
  }

  Future<AdminUser?> toggleStatus(AdminUser user) async {
    final nextStatus = user.isActive ? 'suspended' : 'active';
    state = AdminUsersState(users: state.users, updatingUserId: user.id);

    try {
      final updated = await _updateAdminUserStatusUseCase(
        userId: user.id,
        status: nextStatus,
      );
      state = AdminUsersState(
        users: state.users
            .map((item) => item.id == updated.id ? updated : item)
            .toList(),
      );
      return updated;
    } catch (e) {
      state = AdminUsersState(users: state.users, error: e.toString());
      return null;
    }
  }
}

final adminUsersControllerProvider =
    StateNotifierProvider<AdminUsersController, AdminUsersState>((ref) {
      return AdminUsersController(
        ref.watch(getAdminUsersUseCaseProvider),
        ref.watch(updateAdminUserStatusUseCaseProvider),
      );
    });
