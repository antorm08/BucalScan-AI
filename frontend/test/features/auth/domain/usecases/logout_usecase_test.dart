import 'package:bucalscan_ai/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  test('delega el cierre de sesión en el repositorio', () async {
    final mockRepository = MockAuthRepository();
    final useCase = LogoutUseCase(mockRepository);

    when(mockRepository.logout()).thenAnswer((_) async {});

    await useCase.call();

    verify(mockRepository.logout()).called(1);
  });
}
