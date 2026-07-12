import 'package:bucalscan_ai/features/auth/domain/entities/auth_session.dart';
import 'package:bucalscan_ai/features/auth/domain/entities/auth_user.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockAuthRepository mockRepository;
  late LoginUseCase useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  test(
    'delega en el repositorio y retorna la sesión cuando el login es correcto',
    () async {
      const user = AuthUser(
        id: 1,
        fullName: 'Doctor Test',
        doctorId: 'DOC-001',
        email: 'doctor@hospital.org',
        role: 'doctor',
      );
      const session = AuthSession(user: user, token: 'token_jwt_simulado');

      when(
        mockRepository.login(email: 'doctor@hospital.org', password: '123456'),
      ).thenAnswer((_) async => session);

      final result = await useCase.call(
        email: 'doctor@hospital.org',
        password: '123456',
      );

      expect(result.token, 'token_jwt_simulado');
      verify(
        mockRepository.login(email: 'doctor@hospital.org', password: '123456'),
      ).called(1);
    },
  );

  test('propaga la excepción cuando las credenciales son inválidas', () async {
    when(
      mockRepository.login(email: 'doctor@hospital.org', password: 'wrong'),
    ).thenThrow(Exception('Invalid credentials'));

    expect(
      () => useCase.call(email: 'doctor@hospital.org', password: 'wrong'),
      throwsException,
    );
  });
}
