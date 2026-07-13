import 'package:bucalscan_ai/features/admin/di/admin_providers.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_query.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_request.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:bucalscan_ai/features/admin/domain/repositories/admin_repository.dart';
import 'package:bucalscan_ai/features/admin/presentation/views/admin_users_view.dart';
import 'package:bucalscan_ai/features/admin/presentation/viewmodels/admin_list_controllers.dart';
import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/auth/domain/entities/auth_session.dart';
import 'package:bucalscan_ai/features/auth/domain/entities/auth_user.dart';
import 'package:bucalscan_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _admin = AuthUser(
  id: 99,
  fullName: 'Admin',
  doctorId: 'ADM-99',
  email: 'admin@example.org',
  role: 'platform_admin',
);

const _requester = AdminRequester(
  id: 2,
  fullName: 'Dra. Solicitante',
  email: 'doctor@example.org',
  doctorId: 'DOC-2',
  profession: 'Odontóloga',
  specialty: 'Patología oral',
);

class _AuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => const AuthSession(user: _admin, token: 'token');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repository implements AdminRepository {
  @override
  Future<AdminPage<AdminWorkspaceRequest>> getCentersPage(
    AdminQuery query,
  ) async => AdminPage(
    items: [
      AdminWorkspaceRequest(
        id: 1,
        name: 'Centro Norte',
        workspaceType: 'clinic',
        status: 'pending',
        city: 'Quito',
        address: 'Av. Central 123',
        institutionalEmail: 'centro@example.org',
        createdAt: DateTime(2026, 1, 2),
        requester: _requester,
      ),
    ],
    page: 1,
    pageSize: 25,
    total: 1,
    hasNext: false,
  );

  @override
  Future<AdminPage<AdminMembershipRequest>> getAccessPage(
    AdminQuery query,
  ) async => AdminPage(
    items: [
      AdminMembershipRequest(
        id: 3,
        status: 'pending',
        role: 'professional',
        requester: _requester,
        workspaceId: 1,
        workspaceName: 'Centro Norte',
        workspaceType: 'clinic',
      ),
    ],
    page: 1,
    pageSize: 25,
    total: 1,
    hasNext: false,
  );

  @override
  Future<AdminPage<AdminUser>> getUsersPage(AdminQuery query) async =>
      const AdminPage(
        items: [],
        page: 1,
        pageSize: 25,
        total: 0,
        hasNext: false,
      );

  @override
  Future<AdminSummary> getSummary() async => const AdminSummary(
    pendingWorkspaces: 1,
    pendingMemberships: 1,
    totalUsers: 1,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<ProviderContainer> _pump(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_AuthRepository()),
      adminRepositoryProvider.overrideWithValue(_Repository()),
    ],
  );
  await container
      .read(authViewModelProvider.notifier)
      .login(email: _admin.email, password: 'secret');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: AdminUsersView()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('bottom navigation preserves destination search state', (
    tester,
  ) async {
    final container = await _pump(tester);
    addTearDown(container.dispose);

    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);

    final search = find.byType(TextField).first;
    await tester.enterText(search, 'norte');
    await tester.tap(find.text('Accesos').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Centros').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'norte'), findsOneWidget);
  });

  testWidgets('status filter can be applied and cleared', (tester) async {
    final container = await _pump(tester);
    addTearDown(container.dispose);

    await tester.tap(find.byTooltip('Filtrar por Estado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pendiente').last);
    await tester.pumpAndSettle();

    expect(
      container.read(adminCentersControllerProvider).query.status,
      'pending',
    );

    await tester.tap(find.byTooltip('Filtrar por Estado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todos los estados'));
    await tester.pumpAndSettle();

    expect(container.read(adminCentersControllerProvider).query.status, isNull);
  });

  testWidgets('center card opens a near-full detail sheet with safe actions', (
    tester,
  ) async {
    final container = await _pump(tester);
    addTearDown(container.dispose);

    await tester.tap(find.text('Centro Norte').first);
    await tester.pumpAndSettle();

    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('Av. Central 123'), findsOneWidget);
    expect(find.text('Dra. Solicitante'), findsOneWidget);
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No verifica identidad'), findsOneWidget);
    expect(find.byKey(const Key('rejectAdminAction')), findsOneWidget);
    expect(find.text('Aprobar'), findsOneWidget);
  });

  testWidgets(
    'access details expose declared professional data and disclaimer',
    (tester) async {
      final container = await _pump(tester);
      addTearDown(container.dispose);

      await tester.tap(find.text('Accesos').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dra. Solicitante').first);
      await tester.pumpAndSettle();

      expect(find.text('DOC-2'), findsOneWidget);
      expect(find.text('Odontóloga'), findsOneWidget);
      expect(find.text('Patología oral'), findsOneWidget);
      await tester.drag(
        find.byType(CustomScrollView).last,
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('competencia clínica'), findsOneWidget);
    },
  );
}
