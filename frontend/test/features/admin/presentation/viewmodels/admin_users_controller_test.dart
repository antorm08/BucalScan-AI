import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:bucalscan_ai/features/admin/presentation/viewmodels/admin_users_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

const _doctor = AdminUser(
  id: 1,
  fullName: 'Dr. Smith',
  doctorId: 'MD-001',
  email: 'smith@hospital.org',
  status: 'active',
  role: 'doctor',
);

void main() {
  late MockGetAdminUsersUseCase mockGetAdminUsersUseCase;
  late MockUpdateAdminUserStatusUseCase mockUpdateAdminUserStatusUseCase;
  late AdminUsersController controller;

  setUp(() {
    mockGetAdminUsersUseCase = MockGetAdminUsersUseCase();
    mockUpdateAdminUserStatusUseCase = MockUpdateAdminUserStatusUseCase();
    controller = AdminUsersController(
      mockGetAdminUsersUseCase,
      mockUpdateAdminUserStatusUseCase,
    );
  });

  test('fetchUsers carga la lista de usuarios cuando la respuesta es correcta', () async {
    when(
      mockGetAdminUsersUseCase.call(),
    ).thenAnswer((_) async => const [_doctor]);

    await controller.fetchUsers();

    expect(controller.state.users, hasLength(1));
    expect(controller.state.isLoading, false);
    expect(controller.state.error, isNull);
  });

  test('fetchUsers setea error cuando el caso de uso falla', () async {
    when(
      mockGetAdminUsersUseCase.call(),
    ).thenThrow(Exception('No se pudo cargar la gestión de usuarios.'));

    await controller.fetchUsers();

    expect(controller.state.users, isEmpty);
    expect(controller.state.error, isNotNull);
  });

  test('toggleStatus suspende un usuario activo y actualiza la lista', () async {
    when(
      mockGetAdminUsersUseCase.call(),
    ).thenAnswer((_) async => const [_doctor]);
    await controller.fetchUsers();

    const suspended = AdminUser(
      id: 1,
      fullName: 'Dr. Smith',
      doctorId: 'MD-001',
      email: 'smith@hospital.org',
      status: 'suspended',
      role: 'doctor',
    );
    when(
      mockUpdateAdminUserStatusUseCase.call(userId: 1, status: 'suspended'),
    ).thenAnswer((_) async => suspended);

    final result = await controller.toggleStatus(_doctor);

    expect(result?.status, 'suspended');
    expect(controller.state.users.single.status, 'suspended');
    expect(controller.state.error, isNull);
  });

  test('toggleStatus mantiene la lista y setea error cuando falla', () async {
    when(
      mockGetAdminUsersUseCase.call(),
    ).thenAnswer((_) async => const [_doctor]);
    await controller.fetchUsers();

    when(
      mockUpdateAdminUserStatusUseCase.call(userId: 1, status: 'suspended'),
    ).thenThrow(Exception('No se pudo actualizar el usuario.'));

    final result = await controller.toggleStatus(_doctor);

    expect(result, isNull);
    expect(controller.state.users, hasLength(1));
    expect(controller.state.error, isNotNull);
  });
}
