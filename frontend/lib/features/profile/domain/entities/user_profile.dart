class UserProfile {
  final int id;
  final String fullName;
  final String doctorId;
  final String? medicalCenter;
  final String email;
  final DateTime? createdAt;
  final String role;
  final String status;
  final String? profession;
  final String? specialty;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.doctorId,
    this.medicalCenter,
    required this.email,
    this.createdAt,
    required this.role,
    this.status = 'active',
    this.profession,
    this.specialty,
  });
}
