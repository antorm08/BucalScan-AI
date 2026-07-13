enum AdminUserStatus { pending, active, suspended, unknown }

class AdminUserMembership {
  final int id;
  final int workspaceId;
  final String workspaceName;
  final String workspaceType;
  final String role;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;

  const AdminUserMembership({
    required this.id,
    required this.workspaceId,
    required this.workspaceName,
    required this.workspaceType,
    required this.role,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.approvedAt,
  });
}

class AdminUser {
  final int id;
  final String fullName;
  final String doctorId;
  final String email;
  final String? medicalCenter;
  final DateTime? createdAt;
  final String status;
  final String role;
  final String? profession;
  final String? specialty;
  final List<AdminUserMembership> memberships;

  const AdminUser({
    required this.id,
    required this.fullName,
    required this.doctorId,
    required this.email,
    this.medicalCenter,
    this.createdAt,
    required this.status,
    required this.role,
    this.profession,
    this.specialty,
    this.memberships = const [],
  });

  bool get isActive => status.toLowerCase() == 'active';
  AdminUserStatus get lifecycleStatus => AdminUserStatus.values.firstWhere(
    (value) => value.name == status.toLowerCase(),
    orElse: () => AdminUserStatus.unknown,
  );
  bool get isPending => lifecycleStatus == AdminUserStatus.pending;
  bool get isSuspended => lifecycleStatus == AdminUserStatus.suspended;
  bool get canToggleStatus => isActive || isSuspended;
  bool get isAdmin =>
      const {'admin', 'platform_admin'}.contains(role.toLowerCase());
}
