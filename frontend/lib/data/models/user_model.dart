class UserModel {
  final int? id;
  final String fullName;
  final String doctorId;
  final String? medicalCenter;
  final String email;

  UserModel({
    this.id,
    required this.fullName,
    required this.doctorId,
    this.medicalCenter,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int?,
      fullName: json['full_name'] as String? ?? '',
      doctorId: json['doctor_id'] as String? ?? '',
      medicalCenter: json['medical_center'] as String?,
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'doctor_id': doctorId,
      if (medicalCenter != null) 'medical_center': medicalCenter,
      'email': email,
    };
  }
}
