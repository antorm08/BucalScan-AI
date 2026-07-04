import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:bucalscan_ai/features/admin/domain/usecases/get_admin_users_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockAdminRepository mockRepository;
  late GetAdminUsersUseCase useCase;

  setUp(() {
    mockRepository = MockAdminRepository();
    useCase = GetAdminUsersUseCase(mockRepository);
  });

  test('retorna la lista de usuarios administrados', () async {
    const users = [
      AdminUser(
        id: 1,
        fullName: 'Dr. Smith',
        doctorId: 'MD-001',
        email: 'smith@hospital.org',
        status: 'active',
        role: 'doctor',
      ),
    ];
    when(mockRepository.getUsers()).thenAnswer((_) async => users);

    final result = await useCase.call();

    expect(result, hasLength(1));
    verify(mockRepository.getUsers()).called(1);
  });

  test('propaga la excepción cuando falla la gestión de usuarios', () async {
    when(
      mockRepository.getUsers(),
    ).thenThrow(Exception('No se pudo cargar la gestión de usuarios.'));

    expect(() => useCase.call(), throwsException);
  });
}
