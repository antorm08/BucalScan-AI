import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.fullName,
    required super.doctorId,
    super.medicalCenter,
    required super.email,
    super.createdAt,
    required super.role,
    super.status,
    super.profession,
    super.specialty,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      doctorId: json['doctor_id'] as String? ?? '',
      medicalCenter: json['medical_center'] as String?,
      email: json['email'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      role: json['role'] as String? ?? 'doctor',
      status: json['status'] as String? ?? 'active',
      profession: json['profession'] as String?,
      specialty: json['specialty'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'doctor_id': doctorId,
      'medical_center': medicalCenter,
      'email': email,
      'created_at': createdAt?.toIso8601String(),
      'role': role,
      'status': status,
      'profession': profession,
      'specialty': specialty,
    };
  }
}
