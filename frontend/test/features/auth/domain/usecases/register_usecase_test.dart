import 'package:bucalscan_ai/features/auth/domain/usecases/register_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockAuthRepository mockRepository;
  late RegisterUseCase useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RegisterUseCase(mockRepository);
  });

  test(
    'delega el registro en el repositorio con los datos correctos',
    () async {
      when(
        mockRepository.register(
          fullName: 'Dra. Jane Doe',
          doctorId: 'MD-123456',
          medicalCenter: 'Hospital Central',
          email: 'jane.doe@hospital.org',
          password: '123456',
        ),
      ).thenAnswer((_) async {});

      await useCase.call(
        fullName: 'Dra. Jane Doe',
        doctorId: 'MD-123456',
        medicalCenter: 'Hospital Central',
        email: 'jane.doe@hospital.org',
        password: '123456',
      );

      verify(
        mockRepository.register(
          fullName: 'Dra. Jane Doe',
          doctorId: 'MD-123456',
          medicalCenter: 'Hospital Central',
          email: 'jane.doe@hospital.org',
          password: '123456',
        ),
      ).called(1);
    },
  );

  test('propaga la excepción cuando el registro falla', () async {
    when(
      mockRepository.register(
        fullName: 'Dra. Jane Doe',
        doctorId: 'MD-123456',
        medicalCenter: null,
        email: 'jane.doe@hospital.org',
        password: '123456',
      ),
    ).thenThrow(Exception('El correo ya está registrado'));

    expect(
      () => useCase.call(
        fullName: 'Dra. Jane Doe',
        doctorId: 'MD-123456',
        email: 'jane.doe@hospital.org',
        password: '123456',
      ),
      throwsException,
    );
  });
}
