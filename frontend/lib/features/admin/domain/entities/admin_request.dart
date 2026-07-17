class AdminSummary {
  final int pendingWorkspaces;
  final int pendingMemberships;
  final int totalUsers;
  final int activeUsers;
  final int suspendedUsers;

  const AdminSummary({
    required this.pendingWorkspaces,
    required this.pendingMemberships,
    required this.totalUsers,
    this.activeUsers = 0,
    this.suspendedUsers = 0,
  });
}

class AdminRequester {
  final int id;
  final String fullName;
  final String email;
  final String doctorId;
  final String? profession;
  final String? specialty;
  final String status;
  final String? medicalCenter;
  final String role;
  final DateTime? createdAt;

  const AdminRequester({
    required this.id,
    required this.fullName,
    required this.email,
    required this.doctorId,
    this.profession,
    this.specialty,
    this.status = 'active',
    this.medicalCenter,
    this.role = 'professional',
    this.createdAt,
  });

  bool get isSuspended => status.toLowerCase() == 'suspended';
}

class AdminWorkspaceRequest {
  final int id;
  final String name;
  final String workspaceType;
  final String status;
  final String? city;
  final String? address;
  final String? taxIdentifier;
  final String? telephone;
  final String? institutionalEmail;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;
  final AdminRequester? approvedBy;
  final AdminRequester? requester;

  const AdminWorkspaceRequest({
    required this.id,
    required this.name,
    required this.workspaceType,
    required this.status,
    this.city,
    this.address,
    this.taxIdentifier,
    this.telephone,
    this.institutionalEmail,
    this.createdAt,
    this.updatedAt,
    this.approvedAt,
    this.approvedBy,
    this.requester,
  });

  bool get hasLocation =>
      city?.trim().isNotEmpty == true && address?.trim().isNotEmpty == true;
}

class AdminMembershipRequest {
  final int id;
  final String status;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;
  final AdminRequester? approvedBy;
  final AdminRequester requester;
  final int workspaceId;
  final String workspaceName;
  final String workspaceType;
  final String? workspaceCity;

  const AdminMembershipRequest({
    required this.id,
    required this.status,
    required this.role,
    this.createdAt,
    this.updatedAt,
    this.approvedAt,
    this.approvedBy,
    required this.requester,
    required this.workspaceId,
    required this.workspaceName,
    required this.workspaceType,
    this.workspaceCity,
  });

  bool get isIndependent => workspaceType == 'independent';
}
