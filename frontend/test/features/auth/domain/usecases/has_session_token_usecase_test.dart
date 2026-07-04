import 'package:bucalscan_ai/features/auth/domain/usecases/has_session_token_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockAuthRepository mockRepository;
  late HasSessionTokenUseCase useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = HasSessionTokenUseCase(mockRepository);
  });

  test('retorna true cuando hay un token de sesión almacenado', () async {
    when(mockRepository.hasSessionToken()).thenAnswer((_) async => true);

    expect(await useCase.call(), true);
  });

  test('retorna false cuando no hay token de sesión almacenado', () async {
    when(mockRepository.hasSessionToken()).thenAnswer((_) async => false);

    expect(await useCase.call(), false);
  });
}
