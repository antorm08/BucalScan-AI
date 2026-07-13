import 'package:bucalscan_ai/features/admin/domain/entities/admin_request.dart';
import 'package:bucalscan_ai/features/admin/domain/repositories/admin_repository.dart';

class AdminApprovalsData {
  final AdminSummary summary;
  final List<AdminWorkspaceRequest> workspaces;
  final List<AdminMembershipRequest> memberships;

  const AdminApprovalsData(this.summary, this.workspaces, this.memberships);
}

class AdminApprovalsUseCase {
  final AdminRepository repository;
  const AdminApprovalsUseCase(this.repository);

  Future<AdminApprovalsData> load() async {
    final values = await Future.wait([
      repository.getSummary(),
      repository.getWorkspaceRequests(),
      repository.getMembershipRequests(),
    ]);
    return AdminApprovalsData(
      values[0] as AdminSummary,
      values[1] as List<AdminWorkspaceRequest>,
      values[2] as List<AdminMembershipRequest>,
    );
  }

  Future<void> decideWorkspace(int id, bool approve) =>
      repository.decideWorkspace(id, approve: approve);
  Future<void> decideMembership(int id, bool approve, String role) =>
      repository.decideMembership(id, approve: approve, role: role);
}
