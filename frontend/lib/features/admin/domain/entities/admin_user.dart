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
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isAdmin =>
      const {'admin', 'platform_admin'}.contains(role.toLowerCase());
}
