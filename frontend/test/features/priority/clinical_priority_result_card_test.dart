import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/features/priority/domain/entities/clinical_priority.dart';
import 'package:bucalscan_ai/features/priority/presentation/widgets/clinical_priority_result_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ClinicalPriorityResult _result(String code) => ClinicalPriorityResult(
  priorityCode: code,
  reasonCodes: const ['priority.urgent.score'],
  reasons: const ['Backend fallback in English'],
  rulesetId: 'clinical-priority',
  rulesetVersion: supportedClinicalPriorityRuleset,
  engineVersion: 'priority-engine-1.0',
  evaluatedAt: DateTime.utc(2026, 7, 16),
  completionStatus: code == 'incomplete' ? 'incomplete' : 'complete',
);

void main() {
  final cases = <String, ({String label, Color color})>{
    'standard': (label: 'Atención habitual', color: AppColors.benignBg),
    'prompt': (label: 'Atención pronta', color: const Color(0xFFFFF4CC)),
    'urgent': (label: 'Atención urgente', color: const Color(0xFFFFE2C2)),
    'emergency': (
      label: 'Atención de emergencia',
      color: AppColors.errorContainer,
    ),
    'incomplete': (
      label: 'Evaluación incompleta',
      color: AppColors.surfaceContainerHigh,
    ),
  };

  for (final entry in cases.entries) {
    testWidgets('${entry.key} has independent text, icon and color', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: Scaffold(
              body: SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: ClinicalPriorityResultCard(
                    priority: _result(entry.key),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text(entry.value.label), findsOneWidget);
      expect(find.byKey(Key('prioritySignal-${entry.key}')), findsOneWidget);
      expect(find.byType(Icon), findsWidgets);
      expect(
        tester.widget<Card>(find.byKey(const Key('priorityResultCard'))).color,
        entry.value.color,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('explains academic separation from model percentage', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalPriorityResultCard(priority: _result('urgent')),
        ),
      ),
    );

    expect(
      find.textContaining('No usa el porcentaje del modelo'),
      findsOneWidget,
    );
    expect(find.textContaining('Modo académico'), findsOneWidget);
    expect(
      find.textContaining('umbral académico de atención urgente'),
      findsOneWidget,
    );
  });
}
