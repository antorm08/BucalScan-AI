class AdminSummary {
  final int pendingWorkspaces;
  final int pendingMemberships;
  final int totalUsers;

  const AdminSummary({
    required this.pendingWorkspaces,
    required this.pendingMemberships,
    required this.totalUsers,
  });
}

class AdminRequester {
  final int id;
  final String fullName;
  final String email;
  final String doctorId;
  final String? profession;
  final String? specialty;

  const AdminRequester({
    required this.id,
    required this.fullName,
    required this.email,
    required this.doctorId,
    this.profession,
    this.specialty,
  });
}

class AdminWorkspaceRequest {
  final int id;
  final String name;
  final String workspaceType;
  final String status;
  final String? city;
  final DateTime? createdAt;
  final AdminRequester? requester;

  const AdminWorkspaceRequest({
    required this.id,
    required this.name,
    required this.workspaceType,
    required this.status,
    this.city,
    this.createdAt,
    this.requester,
  });
}

class AdminMembershipRequest {
  final int id;
  final String status;
  final String role;
  final DateTime? createdAt;
  final AdminRequester requester;
  final int workspaceId;
  final String workspaceName;
  final String workspaceType;

  const AdminMembershipRequest({
    required this.id,
    required this.status,
    required this.role,
    this.createdAt,
    required this.requester,
    required this.workspaceId,
    required this.workspaceName,
    required this.workspaceType,
  });

  bool get isIndependent => workspaceType == 'independent';
}
