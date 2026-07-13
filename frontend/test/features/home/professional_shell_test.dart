import 'package:bucalscan_ai/features/dashboard/di/dashboard_providers.dart';
import 'package:bucalscan_ai/features/home/presentation/views/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_fakes.dart';

void main() {
  testWidgets('professional shell has four ordered accessible destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(
            FakeDashboardRepository(),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: HomeView(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Pacientes'), findsOneWidget);
    expect(find.text('Analizar'), findsOneWidget);
    expect(find.text('Historial'), findsOneWidget);
    expect(find.text('Perfil'), findsNothing);
    await tester.tap(find.byKey(const Key('accountMenuButton')));
    await tester.pumpAndSettle();
    expect(find.text('Cuenta y perfil'), findsOneWidget);
    expect(find.text('Centro de ayuda'), findsOneWidget);
    expect(find.text('Modelo y apoyo de decisión'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });
}
