import 'package:bucalscan_ai/features/admin/data/models/admin_user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminUserModel.fromJson', () {
    test('convierte un JSON completo en un objeto correctamente', () {
      final json = {
        'id': 1,
        'full_name': 'Dr. John Smith',
        'doctor_id': 'MD-987654',
        'email': 'john.smith@hospital.org',
        'medical_center': 'Hospital Norte',
        'created_at': '2026-02-01T08:00:00.000Z',
        'status': 'suspended',
        'role': 'admin',
      };

      final user = AdminUserModel.fromJson(json);

      expect(user.id, 1);
      expect(user.fullName, 'Dr. John Smith');
      expect(user.doctorId, 'MD-987654');
      expect(user.email, 'john.smith@hospital.org');
      expect(user.medicalCenter, 'Hospital Norte');
      expect(user.createdAt, DateTime.parse('2026-02-01T08:00:00.000Z'));
      expect(user.status, 'suspended');
      expect(user.role, 'admin');
    });

    test('aplica valores por defecto cuando faltan campos opcionales', () {
      final json = {'id': 2};

      final user = AdminUserModel.fromJson(json);

      expect(user.fullName, '');
      expect(user.doctorId, '');
      expect(user.email, '');
      expect(user.medicalCenter, isNull);
      expect(user.createdAt, isNull);
      expect(user.status, 'active');
      expect(user.role, 'doctor');
    });
  });

  group('AdminUserModel.toEntity', () {
    test('mapea correctamente todos los campos hacia AdminUser', () {
      const model = AdminUserModel(
        id: 3,
        fullName: 'Dra. Ana Ruiz',
        doctorId: 'MD-555555',
        email: 'ana.ruiz@hospital.org',
        medicalCenter: 'Hospital Sur',
        status: 'active',
        role: 'admin',
      );

      final entity = model.toEntity();

      expect(entity.id, 3);
      expect(entity.fullName, 'Dra. Ana Ruiz');
      expect(entity.doctorId, 'MD-555555');
      expect(entity.email, 'ana.ruiz@hospital.org');
      expect(entity.medicalCenter, 'Hospital Sur');
      expect(entity.status, 'active');
      expect(entity.role, 'admin');
      expect(entity.isActive, true);
      expect(entity.isAdmin, true);
    });
  });
}
