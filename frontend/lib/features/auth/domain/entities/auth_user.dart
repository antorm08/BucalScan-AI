class AuthUser {
  final int id;
  final String fullName;
  final String doctorId;
  final String? medicalCenter;
  final String email;
  final DateTime? createdAt;
  final String role;

  const AuthUser({
    required this.id,
    required this.fullName,
    required this.doctorId,
    this.medicalCenter,
    required this.email,
    this.createdAt,
    required this.role,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
}
