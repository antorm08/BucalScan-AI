import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/lesion_comparison.dart';
import 'package:bucalscan_ai/features/clinical/presentation/views/lesion_comparison_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _professional = ClinicalProfessional(
  id: 'professional-1',
  fullName: 'Dra. Ana Pérez',
  doctorId: 'COL-1',
);

const _lesion = OralLesion(
  id: 'lesion-1',
  anatomicalSite: 'Borde lateral de lengua',
  status: 'monitoring',
);

LesionEvaluation _evaluation({
  required String id,
  required int day,
  String label = 'benign',
  String modelVersion = 'v1',
  double confidence = 0.7,
  double malignant = 0.2,
  bool withImage = true,
  bool withPrediction = true,
}) {
  final date = DateTime(2026, 7, day, 10);
  return LesionEvaluation(
    id: id,
    evaluatedAt: date,
    createdAt: date,
    professional: _professional,
    clinicalObservations: 'Hallazgo $id',
    image: withImage
        ? EvaluationImage(
            id: 'image-$id',
            url: 'https://invalid.example/$id.jpg',
            createdAt: date,
          )
        : null,
    prediction: withPrediction
        ? EvaluationPrediction(
            id: 'prediction-$id',
            label: label,
            confidence: confidence,
            probabilities: {'benign': 1 - malignant, 'malignant': malignant},
            modelVersion: modelVersion,
            createdAt: date,
          )
        : null,
  );
}

Widget _app(List<LesionEvaluation> evaluations, {double textScale = 1}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: LesionComparisonView(lesion: _lesion, evaluations: evaluations),
      ),
    );

void main() {
  group('comparison domain', () {
    test('filters incomplete evaluations and orders eligible ones', () {
      final latest = _evaluation(id: 'latest', day: 12);
      final earliest = _evaluation(id: 'earliest', day: 2);

      final result = comparableEvaluations([
        latest,
        _evaluation(id: 'without-image', day: 4, withImage: false),
        earliest,
        _evaluation(id: 'without-result', day: 6, withPrediction: false),
      ]);

      expect(result.map((item) => item.id), ['earliest', 'latest']);
    });

    test('defaults to latest two and keeps selections distinct', () {
      final first = _evaluation(id: 'first', day: 1);
      final second = _evaluation(id: 'second', day: 2);
      final third = _evaluation(id: 'third', day: 3);

      final pair = LesionComparisonPair.latest([third, first, second]);

      expect(pair.left.id, 'second');
      expect(pair.right.id, 'third');
      final swapped = pair.selectLeft(third);
      expect(swapped.left.id, 'third');
      expect(swapped.right.id, 'second');
    });

    test('calculates signed percentage-point deltas and malignant output', () {
      final evaluation = _evaluation(id: 'evaluation', day: 1, malignant: 0.65);

      expect(percentagePointDelta(0.8, 0.62), closeTo(-18, 0.0001));
      expect(malignantOutput(evaluation), 0.65);
    });
  });

  testWidgets('shows unavailable state with fewer than two complete records', (
    tester,
  ) async {
    await tester.pumpWidget(_app([_evaluation(id: 'only', day: 1)]));

    expect(find.byKey(const Key('comparisonUnavailable')), findsOneWidget);
    expect(find.byKey(const Key('lesionComparisonView')), findsNothing);
  });

  testWidgets('shows latest pair, deltas, warnings, and image fallbacks', (
    tester,
  ) async {
    final evaluations = [
      _evaluation(id: 'old', day: 1),
      _evaluation(id: 'middle', day: 2, confidence: 0.8, malignant: 0.25),
      _evaluation(
        id: 'latest',
        day: 3,
        label: 'malignant',
        modelVersion: 'v2',
        confidence: 0.62,
        malignant: 0.7,
      ),
    ];

    await tester.pumpWidget(_app(evaluations));
    await tester.pumpAndSettle();

    expect(find.text('02/07/2026 10:00'), findsOneWidget);
    expect(find.text('03/07/2026 10:00'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('comparisonDeltaCard')),
      300,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('-18.0 pp'), findsOneWidget);
    expect(find.textContaining('+45.0 pp'), findsOneWidget);
    expect(
      find.textContaining('clases predichas son distintas'),
      findsOneWidget,
    );
    expect(
      find.textContaining('versiones del modelo son distintas'),
      findsOneWidget,
    );
    expect(find.textContaining('no demuestran evolución'), findsOneWidget);
    expect(
      find.byKey(const Key('comparisonImageFallback-middle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('comparisonImageFallback-latest')),
      findsOneWidget,
    );
  });

  testWidgets('supports narrow screens and large text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app([
        _evaluation(id: 'first', day: 1),
        _evaluation(id: 'second', day: 2),
      ], textScale: 1.6),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('leftEvaluationSelector')), findsOneWidget);
    expect(find.byKey(const Key('rightEvaluationSelector')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('comparisonDeltaCard')),
      300,
    );
    await tester.pumpAndSettle();
    expect(find.text('Hallazgos registrados'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
