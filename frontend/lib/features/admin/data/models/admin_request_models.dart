import 'package:bucalscan_ai/features/admin/domain/entities/admin_request.dart';

class AdminSummaryModel {
  final AdminSummary value;
  const AdminSummaryModel(this.value);

  factory AdminSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminSummaryModel(
      AdminSummary(
        pendingWorkspaces: json['pending_workspaces'] as int? ?? 0,
        pendingMemberships: json['pending_memberships'] as int? ?? 0,
        totalUsers: json['total_users'] as int? ?? 0,
      ),
    );
  }
}

AdminRequester _requester(Map<String, dynamic> json) => AdminRequester(
  id: json['id'] as int,
  fullName: json['full_name'] as String? ?? '',
  email: json['email'] as String? ?? '',
  doctorId: json['doctor_id'] as String? ?? '',
  profession: json['profession'] as String?,
  specialty: json['specialty'] as String?,
  status: json['status'] as String? ?? 'active',
);

class AdminWorkspaceRequestModel {
  final AdminWorkspaceRequest value;
  const AdminWorkspaceRequestModel(this.value);

  factory AdminWorkspaceRequestModel.fromJson(Map<String, dynamic> json) {
    final requester = json['requester'];
    return AdminWorkspaceRequestModel(
      AdminWorkspaceRequest(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        workspaceType: json['workspace_type'] as String? ?? '',
        status: json['status'] as String? ?? '',
        city: json['city'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
        requester: requester is Map
            ? _requester(Map<String, dynamic>.from(requester))
            : null,
      ),
    );
  }
}

class AdminMembershipRequestModel {
  final AdminMembershipRequest value;
  const AdminMembershipRequestModel(this.value);

  factory AdminMembershipRequestModel.fromJson(Map<String, dynamic> json) {
    final requester = Map<String, dynamic>.from(json['requester'] as Map);
    final workspace = Map<String, dynamic>.from(json['workspace'] as Map);
    return AdminMembershipRequestModel(
      AdminMembershipRequest(
        id: json['id'] as int,
        status: json['status'] as String? ?? '',
        role: json['role'] as String? ?? 'professional',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
        requester: _requester(requester),
        workspaceId: workspace['id'] as int,
        workspaceName: workspace['name'] as String? ?? '',
        workspaceType: workspace['workspace_type'] as String? ?? '',
      ),
    );
  }
}
