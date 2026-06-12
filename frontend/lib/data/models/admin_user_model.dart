class AdminUserModel {
  final int id;
  final String fullName;
  final String doctorId;
  final String email;
  final String? medicalCenter;
  final DateTime? createdAt;
  final String status;
  final String role;

  const AdminUserModel({
    required this.id,
    required this.fullName,
    required this.doctorId,
    required this.email,
    this.medicalCenter,
    this.createdAt,
    required this.status,
    required this.role,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      doctorId: json['doctor_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      medicalCenter: json['medical_center'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      status: json['status'] as String? ?? 'active',
      role: json['role'] as String? ?? 'doctor',
    );
  }

  bool get isActive => status.toLowerCase() == 'active';
  bool get isAdmin => role.toLowerCase() == 'admin';
}
