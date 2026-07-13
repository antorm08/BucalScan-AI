import 'package:bucalscan_ai/features/auth/data/models/auth_session_model.dart';
import 'package:bucalscan_ai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthStorageService mockStorage;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockStorage = MockAuthStorageService();
    repository = AuthRepositoryImpl(mockRemoteDataSource, mockStorage);
  });

  group('login', () {
    test(
      'guarda el token y el usuario en el storage tras un login exitoso',
      () async {
        when(
          mockRemoteDataSource.login(
            email: 'doctor@hospital.org',
            password: '123456',
          ),
        ).thenAnswer(
          (_) async => {
            'data': {
              'token': 'token_jwt_simulado',
              'user': {
                'id': 1,
                'full_name': 'Doctor Test',
                'doctor_id': 'DOC-001',
                'email': 'doctor@hospital.org',
                'role': 'doctor',
              },
            },
          },
        );
        when(mockStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockStorage.saveUserJson(any)).thenAnswer((_) async {});

        final session = await repository.login(
          email: 'doctor@hospital.org',
          password: '123456',
        );

        expect(session.token, 'token_jwt_simulado');
        expect(session.user.email, 'doctor@hospital.org');
        verify(mockStorage.saveToken('token_jwt_simulado')).called(1);
        verify(
          mockStorage.saveUserJson((session as AuthSessionModel).userJson),
        ).called(1);
      },
    );

    test(
      'propaga la excepción cuando las credenciales son inválidas',
      () async {
        when(
          mockRemoteDataSource.login(
            email: 'doctor@hospital.org',
            password: 'wrong',
          ),
        ).thenThrow(Exception('Invalid credentials'));

        expect(
          () =>
              repository.login(email: 'doctor@hospital.org', password: 'wrong'),
          throwsException,
        );
      },
    );
  });

  group('getCurrentUser', () {
    test('retorna el usuario actual y actualiza el caché', () async {
      when(mockRemoteDataSource.me()).thenAnswer(
        (_) async => {
          'data': {
            'user': {
              'id': 1,
              'full_name': 'Doctor Test',
              'doctor_id': 'DOC-001',
              'email': 'doctor@hospital.org',
              'role': 'doctor',
            },
          },
        },
      );
      when(mockStorage.saveUserJson(any)).thenAnswer((_) async {});

      final user = await repository.getCurrentUser();

      expect(user.email, 'doctor@hospital.org');
      verify(mockStorage.saveUserJson(any)).called(1);
    });

    test(
      'lanza FormatException cuando falta el usuario en la respuesta',
      () async {
        when(
          mockRemoteDataSource.me(),
        ).thenAnswer((_) async => {'data': <String, dynamic>{}});

        expect(
          () => repository.getCurrentUser(),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });

  group('hasSessionToken', () {
    test('retorna true cuando hay un token almacenado', () async {
      when(mockStorage.getToken()).thenAnswer((_) async => 'token');

      expect(await repository.hasSessionToken(), true);
    });

    test('retorna false cuando no hay token almacenado', () async {
      when(mockStorage.getToken()).thenAnswer((_) async => null);

      expect(await repository.hasSessionToken(), false);
    });
  });

  group('getCachedUser', () {
    test('retorna el usuario en caché cuando existe', () async {
      when(mockStorage.getUserJson()).thenAnswer(
        (_) async => {
          'id': 1,
          'full_name': 'Doctor Test',
          'doctor_id': 'DOC-001',
          'email': 'doctor@hospital.org',
          'role': 'doctor',
        },
      );

      final user = await repository.getCachedUser();

      expect(user?.email, 'doctor@hospital.org');
    });

    test('retorna null cuando no hay usuario en caché', () async {
      when(mockStorage.getUserJson()).thenAnswer((_) async => null);

      expect(await repository.getCachedUser(), isNull);
    });
  });

  test('logout limpia el storage', () async {
    when(mockStorage.clear()).thenAnswer((_) async {});

    await repository.logout();

    verify(mockStorage.clear()).called(1);
  });

  test('register delega en la fuente remota', () async {
    when(
      mockRemoteDataSource.register(
        fullName: 'Dra. Jane Doe',
        doctorId: 'MD-123456',
        medicalCenter: null,
        email: 'jane.doe@hospital.org',
        password: '123456',
        profession: 'Odontólogo/a',
      ),
    ).thenAnswer((_) async => <String, dynamic>{});

    await repository.register(
      fullName: 'Dra. Jane Doe',
      doctorId: 'MD-123456',
      email: 'jane.doe@hospital.org',
      password: '123456',
      profession: 'Odontólogo/a',
    );

    verify(
      mockRemoteDataSource.register(
        fullName: 'Dra. Jane Doe',
        doctorId: 'MD-123456',
        medicalCenter: null,
        email: 'jane.doe@hospital.org',
        password: '123456',
        profession: 'Odontólogo/a',
      ),
    ).called(1);
  });
}
