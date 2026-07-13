import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';

class AdminUserModel {
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

  const AdminUserModel({
    required this.id,
    required this.fullName,
    required this.doctorId,
    required this.email,
    this.medicalCenter,
    required this.status,
    required this.role,
    this.createdAt,
    this.profession,
    this.specialty,
    this.memberships = const [],
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
      profession: json['profession'] as String?,
      specialty: json['specialty'] as String?,
      memberships: (json['memberships'] as List? ?? const [])
          .whereType<Map>()
          .map((raw) {
            final item = Map<String, dynamic>.from(raw);
            final workspace = item['workspace'] is Map
                ? Map<String, dynamic>.from(item['workspace'] as Map)
                : const <String, dynamic>{};
            return AdminUserMembership(
              id: item['id'] as int,
              workspaceId: item['workspace_id'] as int,
              workspaceName: workspace['name'] as String? ?? 'No disponible',
              workspaceType: workspace['workspace_type'] as String? ?? '',
              role: item['role'] as String? ?? '',
              status: item['status'] as String? ?? '',
              createdAt: DateTime.tryParse(item['created_at'] as String? ?? ''),
              updatedAt: DateTime.tryParse(item['updated_at'] as String? ?? ''),
              approvedAt: DateTime.tryParse(
                item['approved_at'] as String? ?? '',
              ),
            );
          })
          .toList(),
    );
  }

  AdminUser toEntity() {
    return AdminUser(
      id: id,
      fullName: fullName,
      doctorId: doctorId,
      email: email,
      medicalCenter: medicalCenter,
      createdAt: createdAt,
      status: status,
      role: role,
      profession: profession,
      specialty: specialty,
      memberships: memberships,
    );
  }
}
