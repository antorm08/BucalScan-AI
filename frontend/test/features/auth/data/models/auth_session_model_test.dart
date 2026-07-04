import 'package:bucalscan_ai/features/auth/data/models/auth_session_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSessionModel.fromJson', () {
    test('lee correctamente el token y el usuario desde el JSON', () {
      final json = {
        'data': {
          'token': 'token_jwt_simulado_123456',
          'user': {
            'id': 1,
            'full_name': 'Dra. Jane Doe',
            'doctor_id': 'MD-123456',
            'email': 'jane.doe@hospital.org',
            'role': 'doctor',
          },
        },
      };

      final session = AuthSessionModel.fromJson(json);

      expect(session.token, 'token_jwt_simulado_123456');
      expect(session.token.isNotEmpty, true);
      expect(session.user.email, 'jane.doe@hospital.org');
      expect(session.userJson['id'], 1);
    });

    test('lanza FormatException cuando falta la clave "data"', () {
      final json = <String, dynamic>{};

      expect(
        () => AuthSessionModel.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('lanza FormatException cuando falta el usuario o el token', () {
      final missingUser = {
        'data': {'token': 'token_jwt_simulado_123456'},
      };
      final missingToken = {
        'data': {
          'user': {'id': 1},
        },
      };
      final emptyToken = {
        'data': {
          'token': '',
          'user': {'id': 1},
        },
      };

      expect(
        () => AuthSessionModel.fromJson(missingUser),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => AuthSessionModel.fromJson(missingToken),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => AuthSessionModel.fromJson(emptyToken),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
