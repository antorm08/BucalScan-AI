import 'dart:async';

import 'package:bucalscan_ai/features/dashboard/di/dashboard_providers.dart';
import 'package:bucalscan_ai/features/dashboard/domain/entities/daily_summary.dart';
import 'package:bucalscan_ai/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:bucalscan_ai/features/home/presentation/views/home_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SummaryRepository implements DashboardRepository {
  final DailySummary? value;
  final Object? error;

  const _SummaryRepository({this.value, this.error});

  @override
  Future<DailySummary> getTodaySummary() async {
    if (error != null) throw error!;
    return value ?? const DailySummary(total: 0, benign: 0, malignant: 0);
  }
}

class _DeferredSummaryRepository implements DashboardRepository {
  final completer = Completer<DailySummary>();

  @override
  Future<DailySummary> getTodaySummary() => completer.future;
}

Future<void> _pump(
  WidgetTester tester,
  DashboardRepository repository, {
  Size size = const Size(320, 640),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dashboardRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: HomeTabView(
            onStartCapture: () {},
            onOpenHistory: () {},
            onOpenPatients: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('home exposes loading, empty, error and retry states', (tester) async {
    final deferred = _DeferredSummaryRepository();
    await _pump(tester, deferred);
    await tester.pump();
    expect(find.text('Cargando actividad del centro...'), findsOneWidget);
    deferred.completer.complete(
      const DailySummary(total: 0, benign: 0, malignant: 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay análisis registrados hoy.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pump(
      tester,
      _SummaryRepository(error: Exception('Resumen no disponible')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Resumen no disponible'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Reintentar'), findsOneWidget);
    expect(find.text('Nuevo análisis'), findsOneWidget);
  });

  for (final matrixCase in <(Size, double)>[
    (const Size(320, 640), 1),
    (const Size(390, 844), 1),
    (const Size(768, 1024), 1),
    (const Size(320, 640), 1.6),
  ]) {
    testWidgets(
      'home remains reachable at ${matrixCase.$1.width} and ${matrixCase.$2}x text',
      (tester) async {
        await _pump(
          tester,
          const _SummaryRepository(
            value: DailySummary(total: 3, benign: 2, malignant: 1),
          ),
          size: matrixCase.$1,
          textScale: matrixCase.$2,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Nuevo análisis'), findsOneWidget);
        expect(find.text('Seguimiento de pacientes'), findsOneWidget);
        expect(find.text('Últimos análisis'), findsOneWidget);
      },
    );
  }

  testWidgets('home action targets satisfy Android minimum size', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, const _SummaryRepository());
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });
}
