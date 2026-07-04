import 'package:bucalscan_ai/features/auth/domain/entities/auth_user.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockAuthRepository mockRepository;
  late GetCurrentUserUseCase useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GetCurrentUserUseCase(mockRepository);
  });

  test('retorna el usuario actual desde el repositorio', () async {
    const user = AuthUser(
      id: 1,
      fullName: 'Doctor Test',
      doctorId: 'DOC-001',
      email: 'doctor@hospital.org',
      role: 'doctor',
    );
    when(mockRepository.getCurrentUser()).thenAnswer((_) async => user);

    final result = await useCase.call();

    expect(result.email, 'doctor@hospital.org');
    verify(mockRepository.getCurrentUser()).called(1);
  });

  test('propaga la excepción cuando la sesión expiró', () async {
    when(
      mockRepository.getCurrentUser(),
    ).thenThrow(Exception('Invalid or expired token'));

    expect(() => useCase.call(), throwsException);
  });
}
