import 'package:bucalscan_ai/features/profile/domain/entities/user_profile.dart';
import 'package:bucalscan_ai/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockProfileRepository mockRepository;
  late UpdateProfileUseCase useCase;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = UpdateProfileUseCase(mockRepository);
  });

  test(
    'delega la actualización en el repositorio con los datos correctos',
    () async {
      const profile = UserProfile(
        id: 1,
        fullName: 'Dra. Jane Doe',
        doctorId: 'MD-123456',
        medicalCenter: 'Hospital Central',
        email: 'jane.doe@hospital.org',
        role: 'doctor',
      );

      when(
        mockRepository.updateProfile(
          fullName: 'Dra. Jane Doe',
          medicalCenter: 'Hospital Central',
          email: 'jane.doe@hospital.org',
        ),
      ).thenAnswer((_) async => profile);

      final result = await useCase.call(
        fullName: 'Dra. Jane Doe',
        medicalCenter: 'Hospital Central',
        email: 'jane.doe@hospital.org',
      );

      expect(result.email, 'jane.doe@hospital.org');
      verify(
        mockRepository.updateProfile(
          fullName: 'Dra. Jane Doe',
          medicalCenter: 'Hospital Central',
          email: 'jane.doe@hospital.org',
        ),
      ).called(1);
    },
  );

  test('propaga la excepción cuando la actualización falla', () async {
    when(
      mockRepository.updateProfile(
        fullName: null,
        medicalCenter: null,
        email: null,
      ),
    ).thenThrow(Exception('No se pudo actualizar el perfil.'));

    expect(() => useCase.call(), throwsException);
  });
}
