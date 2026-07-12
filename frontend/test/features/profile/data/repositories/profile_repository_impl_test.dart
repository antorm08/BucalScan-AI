import 'package:bucalscan_ai/features/profile/data/models/user_profile_model.dart';
import 'package:bucalscan_ai/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockProfileRemoteDataSource mockRemoteDataSource;
  late ProfileRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockProfileRemoteDataSource();
    repository = ProfileRepositoryImpl(mockRemoteDataSource);
  });

  test(
    'updateProfile mapea el modelo a entidad cuando la respuesta es correcta',
    () async {
      when(
        mockRemoteDataSource.updateProfile(
          fullName: 'Dra. Jane Doe',
          medicalCenter: 'Hospital Central',
          email: 'jane.doe@hospital.org',
        ),
      ).thenAnswer(
        (_) async => const UserProfileModel(
          id: 1,
          fullName: 'Dra. Jane Doe',
          doctorId: 'MD-123456',
          medicalCenter: 'Hospital Central',
          email: 'jane.doe@hospital.org',
          role: 'doctor',
        ),
      );

      final result = await repository.updateProfile(
        fullName: 'Dra. Jane Doe',
        medicalCenter: 'Hospital Central',
        email: 'jane.doe@hospital.org',
      );

      expect(result.email, 'jane.doe@hospital.org');
    },
  );

  test('propaga la excepción cuando la fuente remota falla', () async {
    when(
      mockRemoteDataSource.updateProfile(
        fullName: null,
        medicalCenter: null,
        email: null,
      ),
    ).thenThrow(Exception('No se pudo actualizar el perfil.'));

    expect(() => repository.updateProfile(), throwsException);
  });
}
