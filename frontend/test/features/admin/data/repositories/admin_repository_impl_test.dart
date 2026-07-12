import 'package:bucalscan_ai/features/admin/data/models/admin_user_model.dart';
import 'package:bucalscan_ai/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockAdminRemoteDataSource mockRemoteDataSource;
  late AdminRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockAdminRemoteDataSource();
    repository = AdminRepositoryImpl(mockRemoteDataSource);
  });

  test('getUsers mapea la lista de modelos a entidades', () async {
    when(mockRemoteDataSource.getUsers()).thenAnswer(
      (_) async => const [
        AdminUserModel(
          id: 1,
          fullName: 'Dr. Smith',
          doctorId: 'MD-001',
          email: 'smith@hospital.org',
          status: 'active',
          role: 'doctor',
        ),
      ],
    );

    final result = await repository.getUsers();

    expect(result, hasLength(1));
    expect(result.first.email, 'smith@hospital.org');
    expect(result.first.isActive, true);
  });

  test('getUsers propaga la excepción cuando la fuente remota falla', () async {
    when(
      mockRemoteDataSource.getUsers(),
    ).thenThrow(Exception('No se pudo cargar la gestión de usuarios.'));

    expect(() => repository.getUsers(), throwsException);
  });

  test('updateUserStatus mapea el modelo actualizado a entidad', () async {
    when(
      mockRemoteDataSource.updateUserStatus(userId: 1, status: 'suspended'),
    ).thenAnswer(
      (_) async => const AdminUserModel(
        id: 1,
        fullName: 'Dr. Smith',
        doctorId: 'MD-001',
        email: 'smith@hospital.org',
        status: 'suspended',
        role: 'doctor',
      ),
    );

    final result = await repository.updateUserStatus(
      userId: 1,
      status: 'suspended',
    );

    expect(result.status, 'suspended');
    expect(result.isActive, false);
  });

  test(
    'updateUserStatus propaga la excepción cuando la fuente remota falla',
    () async {
      when(
        mockRemoteDataSource.updateUserStatus(userId: 1, status: 'active'),
      ).thenThrow(Exception('No se pudo actualizar el usuario.'));

      expect(
        () => repository.updateUserStatus(userId: 1, status: 'active'),
        throwsException,
      );
    },
  );
}
