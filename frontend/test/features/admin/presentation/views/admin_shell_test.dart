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
import 'package:bucalscan_ai/core/theme/app_theme.dart';
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

const _managedUser = AdminUser(
  id: 10,
  fullName: 'Dr. Usuario Activo',
  doctorId: 'DOC-10',
  email: 'usuario@example.org',
  status: 'active',
  role: 'professional',
  profession: 'Odontólogo',
  specialty: 'Medicina oral',
  memberships: [
    AdminUserMembership(
      id: 7,
      workspaceId: 1,
      workspaceName: 'Centro Norte',
      workspaceType: 'clinic',
      role: 'professional',
      status: 'active',
    ),
  ],
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
  String? city;
  String? address;
  int updateCenterCalls = 0;

  _Repository({this.city = 'Quito', this.address = 'Av. Central 123'});

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
        city: city,
        address: address,
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
        items: [_managedUser],
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
  Future<AdminWorkspaceRequest> updateCenter({
    required int id,
    required String city,
    required String address,
  }) async {
    updateCenterCalls++;
    this.city = city;
    this.address = address;
    return AdminWorkspaceRequest(
      id: id,
      name: 'Centro Norte',
      workspaceType: 'clinic',
      status: 'pending',
      city: city,
      address: address,
      requester: _requester,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  double textScale = 1,
  _Repository? repository,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_AuthRepository()),
      adminRepositoryProvider.overrideWithValue(repository ?? _Repository()),
    ],
  );
  await container
      .read(authViewModelProvider.notifier)
      .login(email: _admin.email, password: 'secret');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const AdminUsersView(),
        ),
      ),
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

    expect(find.byKey(const Key('adminDetailScroll')), findsOneWidget);
    expect(find.byKey(const Key('adminDetailActionFooter')), findsOneWidget);
    expect(find.byKey(const Key('rejectAdminAction')), findsOneWidget);
    expect(find.text('Aprobar'), findsOneWidget);
    final footerTop = tester
        .getTopLeft(find.byKey(const Key('adminDetailActionFooter')))
        .dy;
    expect(find.text('Av. Central 123'), findsOneWidget);
    expect(find.text('Dra. Solicitante'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('adminDetailScroll')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No verifica identidad'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('adminDetailActionFooter'))).dy,
      footerTop,
    );
  });

  testWidgets('admin completes center location before approval', (
    tester,
  ) async {
    final repository = _Repository(city: null, address: null);
    final container = await _pump(tester, repository: repository);
    addTearDown(container.dispose);

    await tester.tap(find.text('Centro Norte').first);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Complete la ciudad y la dirección'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Aprobar'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('editCenterLocation')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('adminCenterCityField')),
      'Cuenca',
    );
    await tester.enterText(
      find.byKey(const Key('adminCenterAddressField')),
      'Calle Larga 10',
    );
    await tester.tap(find.byKey(const Key('saveCenterLocation')));
    await tester.pumpAndSettle();

    expect(repository.updateCenterCalls, 1);
    expect(repository.city, 'Cuenca');
    expect(repository.address, 'Calle Larga 10');
    expect(find.text('Datos del centro actualizados.'), findsOneWidget);
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
        find.byKey(const Key('adminDetailScroll')),
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('competencia clínica'), findsOneWidget);
    },
  );

  testWidgets('admin header and resource cards expose visual hierarchy', (
    tester,
  ) async {
    final container = await _pump(tester);
    addTearDown(container.dispose);

    expect(
      tester.widget<Text>(find.text('Administración')).style?.color,
      Colors.white,
    );
    expect(find.text('Gestión de centros'), findsOneWidget);
    expect(find.text('CENTRO CLÍNICO'), findsOneWidget);
    expect(find.text('Clínica'), findsOneWidget);
    expect(find.text('Quito'), findsOneWidget);

    await tester.tap(find.text('Usuarios').last);
    await tester.pumpAndSettle();
    expect(find.text('Gestión de usuarios'), findsOneWidget);
    expect(find.text('PROFESIONAL'), findsOneWidget);
    expect(find.text('Odontólogo · Medicina oral'), findsOneWidget);
    expect(find.text('usuario@example.org'), findsOneWidget);
  });

  testWidgets('user detail keeps its account action visible', (tester) async {
    final container = await _pump(tester);
    addTearDown(container.dispose);

    await tester.tap(find.text('Usuarios').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dr. Usuario Activo'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminDetailActionFooter')), findsOneWidget);
    expect(find.text('Suspender cuenta'), findsOneWidget);
    expect(find.text('Cuenta y perfil'), findsOneWidget);
    expect(find.text('Membresía · Centro Norte'), findsOneWidget);
  });

  testWidgets('admin hierarchy remains usable on narrow large-text screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = await _pump(tester, textScale: 1.6);
    addTearDown(container.dispose);

    expect(find.text('Gestión de centros'), findsOneWidget);
    final listScrollable = find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first;
    final listPosition = tester.state<ScrollableState>(listScrollable).position;
    listPosition.jumpTo(listPosition.maxScrollExtent);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(160, 620));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminDetailActionFooter')), findsOneWidget);
    expect(find.byKey(const Key('rejectAdminAction')), findsOneWidget);
    expect(find.text('Aprobar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
