class User {
  final int id;
  final String fullName;
  final String doctorId;
  final String? medicalCenter;
  final String email;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.doctorId,
    this.medicalCenter,
    required this.email,
    this.createdAt,
  });
}
