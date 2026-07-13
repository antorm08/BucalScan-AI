import 'dart:async';

import 'package:bucalscan_ai/core/session/session_events.dart';
import 'package:bucalscan_ai/features/admin/di/admin_providers.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_query.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_request.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:bucalscan_ai/features/admin/domain/repositories/admin_repository.dart';
import 'package:bucalscan_ai/features/admin/presentation/views/admin_users_view.dart';
import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/auth/domain/entities/auth_session.dart';
import 'package:bucalscan_ai/features/auth/domain/entities/auth_user.dart';
import 'package:bucalscan_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/features/clinical/di/clinical_providers.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/domain/repositories/clinical_repository.dart';
import 'package:bucalscan_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _admin = AuthUser(
  id: 1,
  fullName: 'Admin Plataforma',
  doctorId: 'ADM-1',
  email: 'admin@example.org',
  role: 'platform_admin',
);

const _professional = AuthUser(
  id: 2,
  fullName: 'Profesional Pendiente',
  doctorId: 'DOC-2',
  email: 'doctor@example.org',
  role: 'professional',
);

class _AuthRepository implements AuthRepository {
  final AuthUser user;
  final Completer<void>? logoutCompleter;

  _AuthRepository(this.user, {this.logoutCompleter});

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => AuthSession(user: user, token: 'token');

  @override
  Future<void> logout() => logoutCompleter?.future ?? Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AdminRepository implements AdminRepository {
  @override
  Future<AdminPage<AdminWorkspaceRequest>> getCentersPage(
    AdminQuery query,
  ) async => const AdminPage(
    items: [],
    page: 1,
    pageSize: 25,
    total: 0,
    hasNext: false,
  );

  @override
  Future<AdminPage<AdminMembershipRequest>> getAccessPage(
    AdminQuery query,
  ) async => const AdminPage(
    items: [],
    page: 1,
    pageSize: 25,
    total: 0,
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
    pendingWorkspaces: 0,
    pendingMemberships: 0,
    totalUsers: 0,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PendingClinicalRepository implements ClinicalRepository {
  @override
  Future<List<ClinicalWorkspace>> getMemberships() async => const [
    ClinicalWorkspace(
      id: 'pending',
      name: 'Centro pendiente',
      type: 'clinic',
      status: 'pending',
      membershipStatus: MembershipStatus.pending,
    ),
  ];

  @override
  void setActiveWorkspace(String? workspaceId) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<ProviderContainer> _pumpAuthenticatedRoot(
  WidgetTester tester,
  AuthUser user, {
  Completer<void>? logoutCompleter,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        _AuthRepository(user, logoutCompleter: logoutCompleter),
      ),
      adminRepositoryProvider.overrideWithValue(_AdminRepository()),
      clinicalRepositoryProvider.overrideWithValue(
        _PendingClinicalRepository(),
      ),
    ],
  );
  await container
      .read(authViewModelProvider.notifier)
      .login(email: user.email, password: 'secret');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const BucalScanAiApp(skipStartupWakeup: true),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('platform admin renders only the permanent admin root', (
    tester,
  ) async {
    final container = await _pumpAuthenticatedRoot(tester, _admin);
    addTearDown(container.dispose);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Centros'), findsOneWidget);
    expect(find.text('Accesos'), findsOneWidget);
    expect(find.text('Usuarios'), findsOneWidget);
    expect(find.text('Panel de análisis clínico'), findsNothing);
  });

  testWidgets('admin logout renders login immediately without a black frame', (
    tester,
  ) async {
    final delayedLogout = Completer<void>();
    final container = await _pumpAuthenticatedRoot(
      tester,
      _admin,
      logoutCompleter: delayedLogout,
    );
    addTearDown(container.dispose);

    await tester.tap(find.byKey(const Key('adminLogoutButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión').last);
    await tester.pump();

    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.byType(AdminUsersView), findsNothing);

    delayedLogout.complete();
    await tester.pumpAndSettle();
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });

  testWidgets('pending workspace gate logout delegates to the root', (
    tester,
  ) async {
    final container = await _pumpAuthenticatedRoot(tester, _professional);
    addTearDown(container.dispose);

    final logout = find.byKey(const Key('workspaceGateLogoutButton'));
    await tester.scrollUntilVisible(logout, 200);
    await tester.tap(logout);
    await tester.pumpAndSettle();

    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Tu espacio está en revisión'), findsNothing);
  });

  testWidgets('session expiry renders login once and clears the admin root', (
    tester,
  ) async {
    final container = await _pumpAuthenticatedRoot(tester, _admin);
    addTearDown(container.dispose);

    SessionEvents().emitSessionExpired();
    await tester.pumpAndSettle();

    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(
      find.text('Tu sesión expiró. Inicia sesión nuevamente.'),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
  });
}
