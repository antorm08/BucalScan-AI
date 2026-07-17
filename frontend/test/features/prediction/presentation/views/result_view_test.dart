import 'dart:io';

import 'package:bucalscan_ai/features/dashboard/di/dashboard_providers.dart';
import 'package:bucalscan_ai/features/history/di/history_providers.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_result.dart';
import 'package:bucalscan_ai/features/prediction/presentation/viewmodels/prediction_viewmodel.dart';
import 'package:bucalscan_ai/features/prediction/presentation/views/result_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_fakes.dart';

class _ResultViewModel extends PredictionViewModel {
  @override
  PredictionState build() => const PredictionState(
    result: PredictionResult(
      prediction: 'benign',
      confidence: 0.88,
      recommendation: 'Control profesional.',
      probabilities: {'benign': 0.88, 'malignant': 0.12},
      processingTimeMs: 125,
      modelVersion: 'resnet50-v1',
    ),
    patientId: '1',
    patientName: 'Ana Pérez',
    lesionId: '2',
    clinicalCode: '000123',
    lesionSite: 'Lengua',
    status: AnalysisAttemptStatus.succeeded,
  );
}

class _QualityErrorViewModel extends PredictionViewModel {
  @override
  PredictionState build() => const PredictionState(
    error:
        'Exception: La imagen no cumple los requisitos de calidad: la imagen está desenfocada. Tome otra foto con enfoque estable, buena luz y la lesión claramente visible.',
    status: AnalysisAttemptStatus.failed,
  );
}

void main() {
  testWidgets('result prioritizes summary and collapses technical details', (
    tester,
  ) async {
    final image = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}bucalscan-result-test.jpg',
    );
    image.writeAsBytesSync(const []);
    addTearDown(() {
      if (image.existsSync()) image.deleteSync();
    });

    final container = ProviderContainer(
      overrides: [
        predictionViewModelProvider.overrideWith(_ResultViewModel.new),
        dashboardRepositoryProvider.overrideWithValue(
          FakeDashboardRepository(),
        ),
        historyRepositoryProvider.overrideWithValue(FakeHistoryRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: ResultView(imageFile: image)),
      ),
    );
    await tester.pumpAndSettle();

    final summary = find.byKey(const Key('resultSummaryCard'));
    final guidance = find.byKey(const Key('resultGuidanceCard'));
    final imageHeading = find.text('Imagen analizada').first;
    expect(summary, findsOneWidget);
    expect(guidance, findsOneWidget);
    expect(
      tester.getTopLeft(summary).dy,
      lessThan(tester.getTopLeft(guidance).dy),
    );
    expect(
      tester.getTopLeft(guidance).dy,
      lessThan(tester.getTopLeft(imageHeading).dy),
    );
    expect(find.text('Versión del modelo'), findsNothing);

    final technical = find.byKey(const Key('resultTechnicalDetails'));
    await tester.ensureVisible(technical);
    await tester.tap(technical);
    await tester.pumpAndSettle();
    expect(find.text('Versión del modelo'), findsOneWidget);
    expect(find.text('resnet50-v1'), findsOneWidget);
    expect(find.byKey(const Key('anotherImagePrimaryAction')), findsOneWidget);
  });

  testWidgets('quality rejection explains recapture instead of system error', (
    tester,
  ) async {
    final image = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}bucalscan-quality-test.jpg',
    );
    image.writeAsBytesSync(const []);
    addTearDown(() {
      if (image.existsSync()) image.deleteSync();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          predictionViewModelProvider.overrideWith(_QualityErrorViewModel.new),
        ],
        child: MaterialApp(home: ResultView(imageFile: image)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mejore la calidad de la imagen'), findsOneWidget);
    expect(find.textContaining('imagen está desenfocada'), findsOneWidget);
    expect(find.text('Error en el analisis'), findsNothing);
    expect(find.text('Otra imagen para esta lesión'), findsOneWidget);
  });
}
