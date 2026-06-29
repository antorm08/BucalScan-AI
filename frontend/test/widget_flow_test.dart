import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/auth/di/auth_viewmodel_provider.dart';
import 'package:bucalscan_ai/features/auth/presentation/views/login_view.dart';
import 'package:bucalscan_ai/features/dashboard/di/dashboard_providers.dart';
import 'package:bucalscan_ai/features/history/di/history_providers.dart';
import 'package:bucalscan_ai/features/home/presentation/views/home_view.dart';
import 'package:bucalscan_ai/features/prediction/di/prediction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_fakes.dart';

void main() {
  testWidgets('login shows validation errors for empty form', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const MaterialApp(home: LoginView()),
      ),
    );

    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pump();

    expect(find.text('Ingrese su correo electrónico'), findsOneWidget);
    expect(find.text('Ingrese su contraseña'), findsOneWidget);
  });

  testWidgets('login maps invalid credentials to user friendly message', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(failLogin: true),
          ),
        ],
        child: const MaterialApp(home: LoginView()),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'doctor@hospital.org');
    await tester.enterText(fields.at(1), 'wrong-password');
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Usuario y clave incorrectos'), findsOneWidget);
  });

  testWidgets('home dashboard loads summary and navigates between tabs', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        dashboardRepositoryProvider.overrideWithValue(FakeDashboardRepository()),
        historyRepositoryProvider.overrideWithValue(FakeHistoryRepository()),
        predictionRepositoryProvider.overrideWithValue(FakePredictionRepository()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authViewModelProvider.notifier).login(
      email: 'doctor@hospital.org',
      password: 'secret123',
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Panel de análisis clínico'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Benignos'), findsOneWidget);
    expect(find.text('Malignos'), findsOneWidget);

    await tester.tap(find.text('Nueva Captura'));
    await tester.pumpAndSettle();
    expect(find.text('Captura guiada'), findsOneWidget);
    expect(find.text('Seleccione una imagen para continuar'), findsOneWidget);

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text('Paciente Benigno'), findsOneWidget);
    expect(find.text('Paciente Maligno'), findsOneWidget);
  });

  testWidgets('history filter shows only malignant analyses', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyRepositoryProvider.overrideWithValue(FakeHistoryRepository()),
        ],
        child: const MaterialApp(home: HomeView(initialIndex: 2)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paciente Benigno'), findsOneWidget);
    expect(find.text('Paciente Maligno'), findsOneWidget);

    await tester.tap(find.text('Maligna'));
    await tester.pumpAndSettle();

    expect(find.text('Paciente Benigno'), findsNothing);
    expect(find.text('Paciente Maligno'), findsOneWidget);
  });
}
