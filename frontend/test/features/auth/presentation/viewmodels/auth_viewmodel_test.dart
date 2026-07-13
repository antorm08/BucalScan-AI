import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/auth/domain/entities/auth_session.dart';
import 'package:bucalscan_ai/features/auth/domain/entities/auth_user.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/features/profile/di/profile_providers.dart';
import 'package:bucalscan_ai/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

const _user = AuthUser(
  id: 1,
  fullName: 'Doctor Test',
  doctorId: 'DOC-001',
  email: 'doctor@hospital.org',
  role: 'doctor',
);

void main() {
  late MockLoginUseCase mockLoginUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockGetCachedUserUseCase mockGetCachedUserUseCase;
  late MockHasSessionTokenUseCase mockHasSessionTokenUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockUpdateProfileUseCase mockUpdateProfileUseCase;
  late ProviderContainer container;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockRegisterUseCase = MockRegisterUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockGetCachedUserUseCase = MockGetCachedUserUseCase();
    mockHasSessionTokenUseCase = MockHasSessionTokenUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockUpdateProfileUseCase = MockUpdateProfileUseCase();

    container = ProviderContainer(
      overrides: [
        loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
        registerUseCaseProvider.overrideWithValue(mockRegisterUseCase),
        getCurrentUserUseCaseProvider.overrideWithValue(
          mockGetCurrentUserUseCase,
        ),
        getCachedUserUseCaseProvider.overrideWithValue(
          mockGetCachedUserUseCase,
        ),
        hasSessionTokenUseCaseProvider.overrideWithValue(
          mockHasSessionTokenUseCase,
        ),
        logoutUseCaseProvider.overrideWithValue(mockLogoutUseCase),
        updateProfileUseCaseProvider.overrideWithValue(
          mockUpdateProfileUseCase,
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'login cambia a estado success cuando las credenciales son válidas',
    () async {
      when(
        mockLoginUseCase.call(email: 'doctor@hospital.org', password: '123456'),
      ).thenAnswer(
        (_) async => const AuthSession(user: _user, token: 'token_jwt'),
      );

      final success = await container
          .read(authViewModelProvider.notifier)
          .login(email: 'doctor@hospital.org', password: '123456');

      final state = container.read(authViewModelProvider);
      expect(success, true);
      expect(state.currentUser?.email, 'doctor@hospital.org');
      expect(state.isAuthenticated, true);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      verify(
        mockLoginUseCase.call(email: 'doctor@hospital.org', password: '123456'),
      ).called(1);
    },
  );

  test(
    'login cambia a estado error cuando las credenciales son inválidas',
    () async {
      when(
        mockLoginUseCase.call(email: 'doctor@hospital.org', password: 'wrong'),
      ).thenThrow(Exception('Invalid credentials'));

      final success = await container
          .read(authViewModelProvider.notifier)
          .login(email: 'doctor@hospital.org', password: 'wrong');

      final state = container.read(authViewModelProvider);
      expect(success, false);
      expect(state.currentUser, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    },
  );

  group('tryAutoLogin', () {
    test(
      'retorna false sin llamar a getCurrentUser cuando no hay token',
      () async {
        when(mockHasSessionTokenUseCase.call()).thenAnswer((_) async => false);

        final result = await container
            .read(authViewModelProvider.notifier)
            .tryAutoLogin();

        expect(result, false);
        verifyNever(mockGetCurrentUserUseCase.call());
      },
    );

    test(
      'retorna true y guarda el usuario cuando el token es válido',
      () async {
        when(mockHasSessionTokenUseCase.call()).thenAnswer((_) async => true);
        when(mockGetCurrentUserUseCase.call()).thenAnswer((_) async => _user);

        final result = await container
            .read(authViewModelProvider.notifier)
            .tryAutoLogin();

        final state = container.read(authViewModelProvider);
        expect(result, true);
        expect(state.currentUser?.email, 'doctor@hospital.org');
      },
    );

    test('cierra sesión y retorna error cuando el token expiró', () async {
      when(mockHasSessionTokenUseCase.call()).thenAnswer((_) async => true);
      when(
        mockGetCurrentUserUseCase.call(),
      ).thenThrow(Exception('Invalid or expired token'));
      when(mockGetCachedUserUseCase.call()).thenAnswer((_) async => _user);
      when(mockLogoutUseCase.call()).thenAnswer((_) async {});

      final result = await container
          .read(authViewModelProvider.notifier)
          .tryAutoLogin();

      final state = container.read(authViewModelProvider);
      expect(result, false);
      expect(state.error, isNotNull);
      verify(mockLogoutUseCase.call()).called(1);
    });

    test(
      'no usa caché y limpia sesión cuando la cuenta está suspendida',
      () async {
        when(mockHasSessionTokenUseCase.call()).thenAnswer((_) async => true);
        when(mockGetCurrentUserUseCase.call()).thenThrow(
          Exception('Tu cuenta está suspendida. Contacta al administrador.'),
        );
        when(mockGetCachedUserUseCase.call()).thenAnswer((_) async => _user);
        when(mockLogoutUseCase.call()).thenAnswer((_) async {});

        final result = await container
            .read(authViewModelProvider.notifier)
            .tryAutoLogin();

        expect(result, isFalse);
        expect(container.read(authViewModelProvider).currentUser, isNull);
        verify(mockLogoutUseCase.call()).called(1);
      },
    );

    test(
      'usa el usuario en caché cuando falla por un error no relacionado a auth',
      () async {
        when(mockHasSessionTokenUseCase.call()).thenAnswer((_) async => true);
        when(
          mockGetCurrentUserUseCase.call(),
        ).thenThrow(Exception('Error de conexión'));
        when(mockGetCachedUserUseCase.call()).thenAnswer((_) async => _user);

        final result = await container
            .read(authViewModelProvider.notifier)
            .tryAutoLogin();

        final state = container.read(authViewModelProvider);
        expect(result, true);
        expect(state.currentUser?.email, 'doctor@hospital.org');
        verifyNever(mockLogoutUseCase.call());
      },
    );

    test('retorna error cuando falla y no hay usuario en caché', () async {
      when(mockHasSessionTokenUseCase.call()).thenAnswer((_) async => true);
      when(
        mockGetCurrentUserUseCase.call(),
      ).thenThrow(Exception('Error de conexión'));
      when(mockGetCachedUserUseCase.call()).thenAnswer((_) async => null);

      final result = await container
          .read(authViewModelProvider.notifier)
          .tryAutoLogin();

      final state = container.read(authViewModelProvider);
      expect(result, false);
      expect(state.currentUser, isNull);
      expect(state.error, isNotNull);
    });
  });

  test('register retorna true cuando el registro es exitoso', () async {
    when(
      mockRegisterUseCase.call(
        fullName: 'Dra. Jane Doe',
        doctorId: 'MD-123456',
        medicalCenter: null,
        email: 'jane.doe@hospital.org',
        password: '123456',
        profession: 'Odontólogo/a',
      ),
    ).thenAnswer((_) async {});

    final success = await container
        .read(authViewModelProvider.notifier)
        .register(
          fullName: 'Dra. Jane Doe',
          doctorId: 'MD-123456',
          email: 'jane.doe@hospital.org',
          password: '123456',
          profession: 'Odontólogo/a',
        );

    expect(success, true);
    expect(container.read(authViewModelProvider).error, isNull);
  });

  test('register retorna false y setea error cuando falla', () async {
    when(
      mockRegisterUseCase.call(
        fullName: 'Dra. Jane Doe',
        doctorId: 'MD-123456',
        medicalCenter: null,
        email: 'jane.doe@hospital.org',
        password: '123456',
        profession: 'Odontólogo/a',
      ),
    ).thenThrow(Exception('El correo ya está registrado'));

    final success = await container
        .read(authViewModelProvider.notifier)
        .register(
          fullName: 'Dra. Jane Doe',
          doctorId: 'MD-123456',
          email: 'jane.doe@hospital.org',
          password: '123456',
          profession: 'Odontólogo/a',
        );

    expect(success, false);
    expect(container.read(authViewModelProvider).error, isNotNull);
  });

  test('logout invoca el caso de uso y limpia el usuario actual', () async {
    when(mockLogoutUseCase.call()).thenAnswer((_) async {});

    await container.read(authViewModelProvider.notifier).logout();

    expect(container.read(authViewModelProvider).currentUser, isNull);
    verify(mockLogoutUseCase.call()).called(1);
  });

  test('logout limpia el estado aunque falle el almacenamiento', () async {
    when(
      mockLoginUseCase.call(email: 'doctor@hospital.org', password: '123456'),
    ).thenAnswer(
      (_) async => const AuthSession(user: _user, token: 'token_jwt'),
    );
    await container
        .read(authViewModelProvider.notifier)
        .login(email: 'doctor@hospital.org', password: '123456');
    when(mockLogoutUseCase.call()).thenThrow(Exception('storage failed'));

    await expectLater(
      container.read(authViewModelProvider.notifier).logout(),
      throwsException,
    );

    expect(container.read(authViewModelProvider).currentUser, isNull);
    expect(container.read(authViewModelProvider).isLoading, isFalse);
  });

  test('updateProfile actualiza el usuario actual cuando es exitoso', () async {
    const profile = UserProfile(
      id: 1,
      fullName: 'Dra. Jane Doe Actualizada',
      doctorId: 'DOC-001',
      medicalCenter: 'Hospital Nuevo',
      email: 'jane.doe@hospital.org',
      role: 'doctor',
    );
    when(
      mockUpdateProfileUseCase.call(
        fullName: 'Dra. Jane Doe Actualizada',
        medicalCenter: 'Hospital Nuevo',
        email: 'jane.doe@hospital.org',
      ),
    ).thenAnswer((_) async => profile);

    final success = await container
        .read(authViewModelProvider.notifier)
        .updateProfile(
          fullName: 'Dra. Jane Doe Actualizada',
          medicalCenter: 'Hospital Nuevo',
          email: 'jane.doe@hospital.org',
        );

    final state = container.read(authViewModelProvider);
    expect(success, true);
    expect(state.currentUser?.fullName, 'Dra. Jane Doe Actualizada');
    expect(state.currentUser?.medicalCenter, 'Hospital Nuevo');
  });

  test('updateProfile retorna false y setea error cuando falla', () async {
    when(
      mockUpdateProfileUseCase.call(
        fullName: null,
        medicalCenter: null,
        email: null,
      ),
    ).thenThrow(Exception('No se pudo actualizar el perfil.'));

    final success = await container
        .read(authViewModelProvider.notifier)
        .updateProfile();

    expect(success, false);
    expect(container.read(authViewModelProvider).error, isNotNull);
  });
}
