import 'package:flutter_test/flutter_test.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_request.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:bucalscan_ai/features/admin/domain/repositories/admin_repository.dart';
import 'package:bucalscan_ai/features/admin/domain/usecases/admin_approvals_usecase.dart';
import 'package:bucalscan_ai/features/admin/presentation/viewmodels/admin_approvals_controller.dart';

class _Repository implements AdminRepository {
  var workspaceDecisions = 0;
  var fail = false;

  @override
  Future<AdminSummary> getSummary() async => const AdminSummary(
    pendingWorkspaces: 1,
    pendingMemberships: 0,
    totalUsers: 3,
  );
  @override
  Future<List<AdminWorkspaceRequest>> getWorkspaceRequests() async => const [
    AdminWorkspaceRequest(
      id: 7,
      name: 'Centro Norte',
      workspaceType: 'clinic',
      status: 'pending',
    ),
  ];
  @override
  Future<List<AdminMembershipRequest>> getMembershipRequests() async => [];
  @override
  Future<void> decideWorkspace(int id, {required bool approve}) async {
    if (fail) throw Exception('fallo');
    workspaceDecisions++;
  }

  @override
  Future<void> decideMembership(
    int id, {
    required bool approve,
    required String role,
  }) async {}
  @override
  Future<List<AdminUser>> getUsers() async => [];
  @override
  Future<AdminUser> updateUserStatus({
    required int userId,
    required String status,
  }) => throw UnimplementedError();
}

void main() {
  test('load exposes summary and pending requests', () async {
    final controller = AdminApprovalsController(
      AdminApprovalsUseCase(_Repository()),
    );
    await controller.load();
    expect(controller.state.summary?.pendingWorkspaces, 1);
    expect(controller.state.workspaces.single.name, 'Centro Norte');
    expect(controller.state.error, isNull);
  });

  test('decision reloads queues and reports failures', () async {
    final repository = _Repository();
    final controller = AdminApprovalsController(
      AdminApprovalsUseCase(repository),
    );
    await controller.load();
    expect(await controller.decideWorkspace(7, true), isTrue);
    expect(repository.workspaceDecisions, 1);
    repository.fail = true;
    expect(await controller.decideWorkspace(7, false), isFalse);
    expect(controller.state.error, contains('fallo'));
  });
}
