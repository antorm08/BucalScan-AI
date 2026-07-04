import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminUser.isActive', () {
    test('es true cuando el status es "active"', () {
      const user = AdminUser(
        id: 1,
        fullName: 'Dr. Smith',
        doctorId: 'MD-001',
        email: 'smith@hospital.org',
        status: 'active',
        role: 'doctor',
      );

      expect(user.isActive, true);
    });

    test('es true independientemente de la capitalización', () {
      const user = AdminUser(
        id: 1,
        fullName: 'Dr. Smith',
        doctorId: 'MD-001',
        email: 'smith@hospital.org',
        status: 'ACTIVE',
        role: 'doctor',
      );

      expect(user.isActive, true);
    });

    test('es false cuando el status es "suspended"', () {
      const user = AdminUser(
        id: 2,
        fullName: 'Dr. Jones',
        doctorId: 'MD-002',
        email: 'jones@hospital.org',
        status: 'suspended',
        role: 'doctor',
      );

      expect(user.isActive, false);
    });
  });

  group('AdminUser.isAdmin', () {
    test('es true cuando el rol es "admin"', () {
      const user = AdminUser(
        id: 1,
        fullName: 'Admin User',
        doctorId: 'MD-000',
        email: 'admin@hospital.org',
        status: 'active',
        role: 'admin',
      );

      expect(user.isAdmin, true);
    });

    test('es false cuando el rol no es admin', () {
      const user = AdminUser(
        id: 2,
        fullName: 'Doctor User',
        doctorId: 'MD-001',
        email: 'doctor@hospital.org',
        status: 'active',
        role: 'doctor',
      );

      expect(user.isAdmin, false);
    });
  });
}
