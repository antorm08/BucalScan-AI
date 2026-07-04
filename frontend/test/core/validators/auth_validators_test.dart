import 'package:bucalscan_ai/core/validators/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthValidators.validateEmail', () {
    test('rechaza valor nulo', () {
      expect(
        AuthValidators.validateEmail(null),
        'Ingrese su correo electrónico',
      );
    });

    test('rechaza valor vacío', () {
      expect(AuthValidators.validateEmail(''), 'Ingrese su correo electrónico');
    });

    test('rechaza correo sin arroba', () {
      expect(
        AuthValidators.validateEmail('doctorhospital.org'),
        'Ingrese un correo válido',
      );
    });

    test('acepta correo válido', () {
      expect(AuthValidators.validateEmail('doctor@hospital.org'), isNull);
    });
  });

  group('AuthValidators.validateLoginPassword', () {
    test('rechaza valor nulo', () {
      expect(
        AuthValidators.validateLoginPassword(null),
        'Ingrese su contraseña',
      );
    });

    test('rechaza valor vacío', () {
      expect(
        AuthValidators.validateLoginPassword(''),
        'Ingrese su contraseña',
      );
    });

    test('acepta cualquier contraseña no vacía', () {
      expect(AuthValidators.validateLoginPassword('123456'), isNull);
    });
  });

  group('AuthValidators.validateFullName', () {
    test('rechaza vacío', () {
      expect(
        AuthValidators.validateFullName(''),
        'Ingrese su nombre completo',
      );
    });

    test('acepta nombre válido', () {
      expect(AuthValidators.validateFullName('Dra. Jane Doe'), isNull);
    });
  });

  group('AuthValidators.validateDoctorId', () {
    test('rechaza vacío', () {
      expect(
        AuthValidators.validateDoctorId(''),
        'Ingrese su número de licencia',
      );
    });

    test('acepta id válido', () {
      expect(AuthValidators.validateDoctorId('MD-123456'), isNull);
    });
  });

  group('AuthValidators.validateRegisterPassword', () {
    test('rechaza vacío', () {
      expect(
        AuthValidators.validateRegisterPassword(''),
        'Ingrese una contraseña',
      );
    });

    test('rechaza contraseña menor a 6 caracteres', () {
      expect(
        AuthValidators.validateRegisterPassword('123'),
        'Mínimo 6 caracteres',
      );
    });

    test('acepta contraseña de 6 o más caracteres', () {
      expect(AuthValidators.validateRegisterPassword('123456'), isNull);
    });
  });

  group('AuthValidators.validateConfirmPassword', () {
    test('rechaza cuando no coincide con la contraseña', () {
      expect(
        AuthValidators.validateConfirmPassword('abc123', '123456'),
        'Las contraseñas no coinciden',
      );
    });

    test('acepta cuando coincide con la contraseña', () {
      expect(
        AuthValidators.validateConfirmPassword('123456', '123456'),
        isNull,
      );
    });
  });
}
