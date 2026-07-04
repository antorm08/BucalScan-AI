import 'package:bucalscan_ai/features/auth/data/models/auth_user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthUserModel.fromJson', () {
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

      final user = AuthUserModel.fromJson(json);

      expect(user.id, 1);
      expect(user.fullName, 'Dra. Jane Doe');
      expect(user.doctorId, 'MD-123456');
      expect(user.medicalCenter, 'Hospital Central');
      expect(user.email, 'jane.doe@hospital.org');
      expect(user.createdAt, DateTime.parse('2026-01-01T10:00:00.000Z'));
      expect(user.role, 'doctor');
    });

    test('aplica valores por defecto cuando faltan campos opcionales', () {
      final json = {'id': 2};

      final user = AuthUserModel.fromJson(json);

      expect(user.id, 2);
      expect(user.fullName, '');
      expect(user.doctorId, '');
      expect(user.medicalCenter, isNull);
      expect(user.email, '');
      expect(user.createdAt, isNull);
      expect(user.role, 'doctor');
    });
  });

  group('AuthUserModel.toJson', () {
    test('convierte el objeto en un mapa JSON correctamente', () {
      final user = AuthUserModel(
        id: 1,
        fullName: 'Dra. Jane Doe',
        doctorId: 'MD-123456',
        medicalCenter: 'Hospital Central',
        email: 'jane.doe@hospital.org',
        createdAt: DateTime.parse('2026-01-01T10:00:00.000Z'),
        role: 'admin',
      );

      final json = user.toJson();

      expect(json['id'], 1);
      expect(json['full_name'], 'Dra. Jane Doe');
      expect(json['doctor_id'], 'MD-123456');
      expect(json['medical_center'], 'Hospital Central');
      expect(json['email'], 'jane.doe@hospital.org');
      expect(json['created_at'], '2026-01-01T10:00:00.000Z');
      expect(json['role'], 'admin');
    });
  });
}
