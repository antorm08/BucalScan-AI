import 'package:bucalscan_ai/features/priority/di/priority_providers.dart';
import 'package:bucalscan_ai/features/priority/domain/entities/clinical_priority.dart';
import 'package:bucalscan_ai/features/priority/domain/repositories/clinical_priority_repository.dart';
import 'package:bucalscan_ai/features/priority/presentation/widgets/clinical_assessment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _AcademicPriorityRepository implements ClinicalPriorityRepository {
  @override
  Future<ClinicalPriorityCapability> getCapability() async =>
      const ClinicalPriorityCapability(
        mode: ClinicalPriorityMode.academic,
        available: true,
        activeRuleset: supportedClinicalPriorityRuleset,
        assessmentSchemaVersion: '1',
        engineVersion: '1',
        notice: 'Uso académico',
      );
}

void main() {
  testWidgets('assessment uses a spacious scrollable sheet', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clinicalPriorityRepositoryProvider.overrideWithValue(
            _AcademicPriorityRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ClinicalAssessmentCard()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 de 18 respuestas completadas'), findsOneWidget);
    await tester.tap(find.byKey(const Key('openClinicalAssessment')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('clinicalAssessmentSheet')), findsOneWidget);
    expect(find.byKey(const Key('clinicalAssessmentScroll')), findsOneWidget);
    expect(find.byKey(const Key('closeClinicalAssessment')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('assessment-ulceration-unknown')));
    await tester.pump();
    expect(find.text('1 de 18 respuestas'), findsOneWidget);
  });
}
