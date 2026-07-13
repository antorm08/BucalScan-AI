import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/admin/di/admin_providers.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_request.dart';
import 'package:bucalscan_ai/features/admin/domain/usecases/admin_approvals_usecase.dart';

class AdminApprovalsState {
  final bool isLoading;
  final String? error;
  final AdminSummary? summary;
  final List<AdminWorkspaceRequest> workspaces;
  final List<AdminMembershipRequest> memberships;
  final String? decidingKey;

  const AdminApprovalsState({
    this.isLoading = false,
    this.error,
    this.summary,
    this.workspaces = const [],
    this.memberships = const [],
    this.decidingKey,
  });
}

class AdminApprovalsController extends StateNotifier<AdminApprovalsState> {
  final AdminApprovalsUseCase _useCase;
  AdminApprovalsController(this._useCase) : super(const AdminApprovalsState());

  Future<void> load() async {
    state = AdminApprovalsState(
      isLoading: true,
      summary: state.summary,
      workspaces: state.workspaces,
      memberships: state.memberships,
    );
    try {
      final data = await _useCase.load();
      state = AdminApprovalsState(
        summary: data.summary,
        workspaces: data.workspaces,
        memberships: data.memberships,
      );
    } catch (e) {
      state = AdminApprovalsState(
        error: e.toString(),
        summary: state.summary,
        workspaces: state.workspaces,
        memberships: state.memberships,
      );
    }
  }

  Future<bool> decideWorkspace(int id, bool approve) =>
      _decide('w$id', () => _useCase.decideWorkspace(id, approve));
  Future<bool> decideMembership(int id, bool approve, String role) =>
      _decide('m$id', () => _useCase.decideMembership(id, approve, role));

  Future<bool> _decide(String key, Future<void> Function() action) async {
    state = AdminApprovalsState(
      summary: state.summary,
      workspaces: state.workspaces,
      memberships: state.memberships,
      decidingKey: key,
    );
    try {
      await action();
      await load();
      return true;
    } catch (e) {
      state = AdminApprovalsState(
        error: e.toString(),
        summary: state.summary,
        workspaces: state.workspaces,
        memberships: state.memberships,
      );
      return false;
    }
  }
}

final adminApprovalsControllerProvider =
    StateNotifierProvider<AdminApprovalsController, AdminApprovalsState>((ref) {
      return AdminApprovalsController(ref.watch(adminApprovalsUseCaseProvider));
    });
