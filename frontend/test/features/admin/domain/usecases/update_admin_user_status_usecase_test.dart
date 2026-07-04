import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:bucalscan_ai/features/admin/domain/usecases/update_admin_user_status_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockAdminRepository mockRepository;
  late UpdateAdminUserStatusUseCase useCase;

  setUp(() {
    mockRepository = MockAdminRepository();
    useCase = UpdateAdminUserStatusUseCase(mockRepository);
  });

  test('delega la actualización de estado con los parámetros correctos', () async {
    const updated = AdminUser(
      id: 1,
      fullName: 'Dr. Smith',
      doctorId: 'MD-001',
      email: 'smith@hospital.org',
      status: 'suspended',
      role: 'doctor',
    );

    when(
      mockRepository.updateUserStatus(userId: 1, status: 'suspended'),
    ).thenAnswer((_) async => updated);

    final result = await useCase.call(userId: 1, status: 'suspended');

    expect(result.status, 'suspended');
    verify(
      mockRepository.updateUserStatus(userId: 1, status: 'suspended'),
    ).called(1);
  });

  test('propaga la excepción cuando la actualización falla', () async {
    when(
      mockRepository.updateUserStatus(userId: 1, status: 'active'),
    ).thenThrow(Exception('No se pudo actualizar el usuario.'));

    expect(() => useCase.call(userId: 1, status: 'active'), throwsException);
  });
}
