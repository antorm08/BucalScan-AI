import 'package:bucalscan_ai/features/priority/di/priority_providers.dart';
import 'package:bucalscan_ai/features/priority/domain/entities/clinical_priority.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClinicalPriorityState {
  final bool loading;
  final ClinicalPriorityCapability? capability;
  final Map<String, ClinicalTriState> answers;
  final String? error;

  const ClinicalPriorityState({
    this.loading = false,
    this.capability,
    this.answers = const {},
    this.error,
  });

  bool get available => capability?.available == true;
  bool get complete =>
      available && clinicalAssessmentFields.keys.every(answers.containsKey);

  Map<String, String>? get payload => !available
      ? null
      : {
          for (final entry in answers.entries)
            entry.key: clinicalTriStateValue(entry.value),
        };
}

class ClinicalPriorityController extends Notifier<ClinicalPriorityState> {
  int _generation = 0;

  @override
  ClinicalPriorityState build() => const ClinicalPriorityState();

  Future<void> loadCapability() async {
    final generation = ++_generation;
    state = ClinicalPriorityState(loading: true, answers: state.answers);
    try {
      final capability = await ref.read(
        getClinicalPriorityCapabilityProvider,
      )();
      if (generation != _generation) return;
      state = ClinicalPriorityState(
        capability: capability,
        answers: capability.available ? state.answers : const {},
      );
    } catch (_) {
      if (generation != _generation) return;
      state = const ClinicalPriorityState(
        error: 'La prioridad clínica orientativa no está disponible.',
      );
    }
  }

  void answer(String code, ClinicalTriState value) {
    if (!state.available) return;
    state = ClinicalPriorityState(
      capability: state.capability,
      answers: {...state.answers, code: value},
    );
  }

  void clearAssessment() {
    _generation++;
    state = ClinicalPriorityState(capability: state.capability);
  }

  void clearAll() {
    _generation++;
    state = const ClinicalPriorityState();
  }
}

final clinicalPriorityControllerProvider =
    NotifierProvider<ClinicalPriorityController, ClinicalPriorityState>(
      ClinicalPriorityController.new,
    );
