import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/features/auth/presentation/views/login_view.dart';
import 'package:bucalscan_ai/features/admin/presentation/views/admin_users_view.dart';
import 'package:bucalscan_ai/features/clinical/di/clinical_providers.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/domain/repositories/clinical_repository.dart';
import 'package:bucalscan_ai/features/clinical/presentation/views/workspace_gate_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_fakes.dart';

class _FakeClinicalRepository implements ClinicalRepository {
  String? activeWorkspaceId;

  @override
  Future<List<ClinicalWorkspace>> getMemberships() async => const [
    ClinicalWorkspace(
      id: 'pending-center',
      name: 'Centro Nuevo',
      type: 'clinic',
      status: 'pending',
      membershipStatus: MembershipStatus.pending,
    ),
  ];

  @override
  void setActiveWorkspace(String? workspaceId) {
    activeWorkspaceId = workspaceId;
  }

  @override
  Future<List<ClinicalWorkspace>> discoverWorkspaces(String query) async => [];

  @override
  Future<List<Patient>> searchPatients(String query) async => [];

  @override
  Future<Patient> createPatient({
    required String clinicalCode,
    required String fullName,
    String? identityDocument,
  }) => throw UnimplementedError();

  @override
  Future<List<OralLesion>> getLesions(String patientId) async => [];

  @override
  Future<OralLesion> createLesion({
    required String patientId,
    required String anatomicalSite,
    required String temporalDescription,
    String? notes,
  }) => throw UnimplementedError();
}

class _FailingClinicalRepository extends _FakeClinicalRepository {
  @override
  Future<List<ClinicalWorkspace>> getMemberships() =>
      throw Exception('connection failed');
}

void main() {
  testWidgets('standalone login fallback always opens workspace gate', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          clinicalRepositoryProvider.overrideWithValue(
            _FakeClinicalRepository(),
          ),
        ],
        child: const MaterialApp(home: LoginView()),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'doctor@hospital.org');
    await tester.enterText(fields.at(1), 'secret123');
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Tu espacio está en revisión'), findsOneWidget);
    expect(find.text('Centro pendiente de aprobación'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('workspaceGateLogoutButton')),
      200,
    );
    expect(find.byKey(const Key('workspaceGateLogoutButton')), findsOneWidget);
  });

  testWidgets('pending user can log out through root callback flow', (
    tester,
  ) async {
    var loggedOut = false;
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        clinicalRepositoryProvider.overrideWithValue(_FakeClinicalRepository()),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(authViewModelProvider.notifier)
        .login(email: 'doctor@hospital.org', password: 'secret123');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: WorkspaceGateView(
            onLoggedOut: () => loggedOut = true,
            child: const Text('Clinical home'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final logoutButton = find.byKey(const Key('workspaceGateLogoutButton'));
    await tester.scrollUntilVisible(logoutButton, 200);
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    expect(loggedOut, isTrue);
    expect(container.read(authViewModelProvider).currentUser, isNull);
  });

  testWidgets(
    'membership failure shows connection state, not pending approval',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          clinicalRepositoryProvider.overrideWithValue(
            _FailingClinicalRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(authViewModelProvider.notifier)
          .login(email: 'doctor@hospital.org', password: 'secret123');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WorkspaceGateView(child: Text('Clinical home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No pudimos consultar tus espacios'), findsOneWidget);
      expect(find.text('APROBACIÓN PENDIENTE'), findsNothing);
      expect(find.text('Tu espacio está en revisión'), findsNothing);
    },
  );

  testWidgets('direct non-admin construction does not render admin shell', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(authViewModelProvider.notifier)
        .login(email: 'doctor@hospital.org', password: 'secret123');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AdminUsersView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No tienes acceso a esta sección.'), findsOneWidget);
    expect(find.text('Administración'), findsNothing);
    expect(find.byType(TabBar), findsNothing);
  });
}
