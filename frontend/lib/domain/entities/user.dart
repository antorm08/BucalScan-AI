class User {
  final int id;
  final String fullName;
  final String doctorId;
  final String? medicalCenter;
  final String email;

  User({
    required this.id,
    required this.fullName,
    required this.doctorId,
    this.medicalCenter,
    required this.email,
  });
}
