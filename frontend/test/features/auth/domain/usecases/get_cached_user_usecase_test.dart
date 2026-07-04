import 'package:bucalscan_ai/features/auth/domain/entities/auth_user.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/get_cached_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockAuthRepository mockRepository;
  late GetCachedUserUseCase useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GetCachedUserUseCase(mockRepository);
  });

  test('retorna el usuario en caché cuando existe', () async {
    const user = AuthUser(
      id: 1,
      fullName: 'Doctor Test',
      doctorId: 'DOC-001',
      email: 'doctor@hospital.org',
      role: 'doctor',
    );
    when(mockRepository.getCachedUser()).thenAnswer((_) async => user);

    final result = await useCase.call();

    expect(result?.email, 'doctor@hospital.org');
  });

  test('retorna null cuando no hay usuario en caché', () async {
    when(mockRepository.getCachedUser()).thenAnswer((_) async => null);

    final result = await useCase.call();

    expect(result, isNull);
  });
}
