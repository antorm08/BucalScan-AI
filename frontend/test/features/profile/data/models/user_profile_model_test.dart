import 'package:bucalscan_ai/features/profile/data/models/user_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfileModel.fromJson', () {
    test('convierte un JSON completo en un objeto correctamente', () {
      final json = {
        'id': 1,
        'full_name': 'Dra. Jane Doe',
        'doctor_id': 'MD-123456',
        'medical_center': 'Hospital Central',
        'email': 'jane.doe@hospital.org',
        'created_at': '2026-01-01T10:00:00.000Z',
        'role': 'doctor',
      };

      final model = UserProfileModel.fromJson(json);

      expect(model.id, 1);
      expect(model.fullName, 'Dra. Jane Doe');
      expect(model.doctorId, 'MD-123456');
      expect(model.medicalCenter, 'Hospital Central');
      expect(model.email, 'jane.doe@hospital.org');
      expect(model.createdAt, DateTime.parse('2026-01-01T10:00:00.000Z'));
      expect(model.role, 'doctor');
    });

    test('aplica valores por defecto cuando faltan campos opcionales', () {
      final model = UserProfileModel.fromJson({'id': 2});

      expect(model.fullName, '');
      expect(model.doctorId, '');
      expect(model.medicalCenter, isNull);
      expect(model.email, '');
      expect(model.createdAt, isNull);
      expect(model.role, 'doctor');
    });
  });

  group('UserProfileModel.toEntity', () {
    test('mapea todos los campos hacia UserProfile', () {
      final model = UserProfileModel(
        id: 1,
        fullName: 'Dra. Jane Doe',
        doctorId: 'MD-123456',
        medicalCenter: 'Hospital Central',
        email: 'jane.doe@hospital.org',
        createdAt: DateTime.parse('2026-01-01T10:00:00.000Z'),
        role: 'doctor',
      );

      final entity = model.toEntity();

      expect(entity.id, 1);
      expect(entity.fullName, 'Dra. Jane Doe');
      expect(entity.doctorId, 'MD-123456');
      expect(entity.medicalCenter, 'Hospital Central');
      expect(entity.email, 'jane.doe@hospital.org');
      expect(entity.createdAt, DateTime.parse('2026-01-01T10:00:00.000Z'));
      expect(entity.role, 'doctor');
    });
  });
}
