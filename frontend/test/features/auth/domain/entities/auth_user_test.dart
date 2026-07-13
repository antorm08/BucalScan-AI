import 'package:bucalscan_ai/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthUser.isAdmin', () {
    test('es true para platform_admin', () {
      const user = AuthUser(
        id: 1,
        fullName: 'Admin',
        doctorId: 'ADMIN-001',
        email: 'admin@bucalscan.test',
        role: 'platform_admin',
      );

      expect(user.isAdmin, true);
    });

    test('es true cuando el rol es "admin"', () {
      const user = AuthUser(
        id: 1,
        fullName: 'Admin User',
        doctorId: 'MD-000',
        email: 'admin@hospital.org',
        role: 'admin',
      );

      expect(user.isAdmin, true);
    });

    test('es true independientemente de la capitalización del rol', () {
      const user = AuthUser(
        id: 1,
        fullName: 'Admin User',
        doctorId: 'MD-000',
        email: 'admin@hospital.org',
        role: 'Admin',
      );

      expect(user.isAdmin, true);
    });

    test('es false cuando el rol no es admin', () {
      const user = AuthUser(
        id: 2,
        fullName: 'Doctor User',
        doctorId: 'MD-001',
        email: 'doctor@hospital.org',
        role: 'doctor',
      );

      expect(user.isAdmin, false);
    });
  });
}
