import 'package:bucalscan_ai/features/profile/domain/entities/user_profile.dart';

class UserProfileModel {
  final int id;
  final String fullName;
  final String doctorId;
  final String? medicalCenter;
  final String email;
  final DateTime? createdAt;
  final String role;

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.doctorId,
    this.medicalCenter,
    required this.email,
    this.createdAt,
    required this.role,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      doctorId: json['doctor_id'] as String? ?? '',
      medicalCenter: json['medical_center'] as String?,
      email: json['email'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      role: json['role'] as String? ?? 'doctor',
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      id: id,
      fullName: fullName,
      doctorId: doctorId,
      medicalCenter: medicalCenter,
      email: email,
      createdAt: createdAt,
      role: role,
    );
  }
}
