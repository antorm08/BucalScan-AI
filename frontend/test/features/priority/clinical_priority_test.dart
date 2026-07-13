import 'package:bucalscan_ai/features/priority/data/models/clinical_priority_models.dart';
import 'package:bucalscan_ai/features/priority/di/priority_providers.dart';
import 'package:bucalscan_ai/features/priority/domain/entities/clinical_priority.dart';
import 'package:bucalscan_ai/features/priority/domain/repositories/clinical_priority_repository.dart';
import 'package:bucalscan_ai/features/priority/presentation/viewmodels/clinical_priority_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _PriorityRepository implements ClinicalPriorityRepository {
  final ClinicalPriorityCapability capability;

  const _PriorityRepository(this.capability);

  @override
  Future<ClinicalPriorityCapability> getCapability() async => capability;
}

void main() {
  test('unsupported server ruleset fails closed', () {
    final capability = ClinicalPriorityCapabilityModel.fromJson({
      'mode': 'enabled',
      'available': true,
      'active_ruleset': 'future-ruleset-v9',
      'assessment_schema_version': '1',
      'engine_version': '1',
      'notice': 'test',
    });

    expect(capability.mode, ClinicalPriorityMode.unsupported);
    expect(capability.available, isFalse);
  });

  test(
    'assessment preserves explicit unknown and only completes all fields',
    () async {
      const capability = ClinicalPriorityCapability(
        mode: ClinicalPriorityMode.academic,
        available: true,
        activeRuleset: supportedClinicalPriorityRuleset,
        assessmentSchemaVersion: '1',
        engineVersion: '1',
        notice: 'Academic',
      );
      final container = ProviderContainer(
        overrides: [
          clinicalPriorityRepositoryProvider.overrideWithValue(
            const _PriorityRepository(capability),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        clinicalPriorityControllerProvider.notifier,
      );
      await controller.loadCapability();
      for (final code in clinicalAssessmentFields.keys) {
        controller.answer(code, ClinicalTriState.unknown);
      }

      final state = container.read(clinicalPriorityControllerProvider);
      expect(state.complete, isTrue);
      expect(state.payload?['airway_compromise'], 'unknown');
      expect(state.payload?.values, everyElement('unknown'));
    },
  );

  test('priority result keeps immutable provenance fields', () {
    final result = ClinicalPriorityResultModel.fromJson({
      'priority_code': 'urgent',
      'reason_codes': ['rapid_growth'],
      'rendered_reasons': ['Crecimiento rápido confirmado'],
      'ruleset_id': 'clinical-priority',
      'ruleset_version': supportedClinicalPriorityRuleset,
      'engine_version': '1.0',
      'completion_status': 'complete',
      'evaluated_at': '2026-07-13T10:00:00Z',
    });

    expect(result?.priorityCode, 'urgent');
    expect(result?.rulesetVersion, supportedClinicalPriorityRuleset);
    expect(result?.reasons, ['Crecimiento rápido confirmado']);
  });
}
