import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/features/priority/domain/entities/clinical_priority.dart';
import 'package:bucalscan_ai/features/priority/presentation/viewmodels/clinical_priority_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClinicalAssessmentCard extends ConsumerStatefulWidget {
  const ClinicalAssessmentCard({super.key});

  @override
  ConsumerState<ClinicalAssessmentCard> createState() =>
      _ClinicalAssessmentCardState();
}

class _ClinicalAssessmentCardState
    extends ConsumerState<ClinicalAssessmentCard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(clinicalPriorityControllerProvider.notifier)
          .loadCapability(),
    );
  }

  Future<void> _openAssessment() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const FractionallySizedBox(
      heightFactor: 0.94,
      child: _AssessmentSheet(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clinicalPriorityControllerProvider);
    if (state.loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Consultando el semáforo orientativo...')),
            ],
          ),
        ),
      );
    }

    if (!state.available) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColors.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.capability?.mode == ClinicalPriorityMode.unsupported
                      ? 'La versión de prioridad clínica del servidor no es compatible. El análisis del modelo continúa sin calcular prioridad en el dispositivo.'
                      : 'El semáforo orientativo está desactivado. El análisis del modelo continúa de forma independiente.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final answered = state.answers.length;
    final total = clinicalAssessmentFields.length;
    return Card(
      key: const Key('clinicalAssessmentCard'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: state.complete
                        ? AppColors.benignBg
                        : AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    state.complete
                        ? Icons.check_circle_outline
                        : Icons.fact_check_outlined,
                    color: state.complete
                        ? AppColors.benignText
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Evaluación clínica orientativa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.complete
                            ? 'Completada. Puede revisarla antes de analizar.'
                            : '$answered de $total respuestas completadas',
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: answered / total,
              minHeight: 6,
              borderRadius: BorderRadius.circular(999),
            ),
            if (state.capability?.mode == ClinicalPriorityMode.academic) ...[
              const SizedBox(height: 12),
              const Text(
                'Apoyo académico no validado para triaje clínico. No reemplaza el juicio profesional.',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: const Key('openClinicalAssessment'),
              onPressed: _openAssessment,
              icon: Icon(
                state.complete ? Icons.edit_outlined : Icons.arrow_forward,
              ),
              label: Text(
                state.complete ? 'Revisar evaluación' : 'Completar evaluación',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentSheet extends ConsumerWidget {
  const _AssessmentSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clinicalPriorityControllerProvider);
    return Material(
      key: const Key('clinicalAssessmentSheet'),
      color: AppColors.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Evaluación clínica',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${state.answers.length} de ${clinicalAssessmentFields.length} respuestas',
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar evaluación',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: state.answers.length / clinicalAssessmentFields.length,
            minHeight: 5,
          ),
          Expanded(
            child: ListView(
              key: const Key('clinicalAssessmentScroll'),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                const _AssessmentNotice(),
                const SizedBox(height: 20),
                _AssessmentGroup(
                  title: 'Signos y síntomas actuales',
                  icon: Icons.medical_information_outlined,
                  fields: clinicalAssessmentFields.entries.take(10),
                  answers: state.answers,
                ),
                const SizedBox(height: 20),
                _AssessmentGroup(
                  title: 'Factores de riesgo',
                  icon: Icons.health_and_safety_outlined,
                  fields: clinicalAssessmentFields.entries.skip(10).take(4),
                  answers: state.answers,
                ),
                const SizedBox(height: 20),
                _AssessmentGroup(
                  title: 'Signos de emergencia',
                  icon: Icons.emergency_outlined,
                  fields: clinicalAssessmentFields.entries.skip(14),
                  answers: state.answers,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border(top: BorderSide(color: AppColors.outlineVariant)),
            ),
            child: SafeArea(
              top: false,
              child: FilledButton.icon(
                key: const Key('closeClinicalAssessment'),
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  state.complete ? Icons.check_rounded : Icons.save_outlined,
                ),
                label: Text(
                  state.complete
                      ? 'Evaluación completada'
                      : 'Guardar y continuar después',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentNotice extends StatelessWidget {
  const _AssessmentNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.primaryFixed,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Text(
      'Seleccione Sí, No o No evaluado en cada elemento. “No evaluado” nunca se interpreta como ausencia.',
      style: TextStyle(height: 1.4, color: AppColors.onSurfaceVariant),
    ),
  );
}

class _AssessmentGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final Iterable<MapEntry<String, String>> fields;
  final Map<String, ClinicalTriState> answers;

  const _AssessmentGroup({
    required this.title,
    required this.icon,
    required this.fields,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      ...fields.map(
        (field) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _AssessmentField(
            code: field.key,
            label: field.value,
            value: answers[field.key],
          ),
        ),
      ),
    ],
  );
}

class _AssessmentField extends ConsumerWidget {
  final String code;
  final String label;
  final ClinicalTriState? value;

  const _AssessmentField({
    required this.code,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => Semantics(
    label: '$label. Seleccione Sí, No o No evaluado',
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _choice(ref, ClinicalTriState.yes, 'Sí'),
              _choice(ref, ClinicalTriState.no, 'No'),
              _choice(ref, ClinicalTriState.unknown, 'No evaluado'),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _choice(WidgetRef ref, ClinicalTriState option, String text) =>
      ChoiceChip(
        key: Key('assessment-$code-${option.name}'),
        label: Text(text),
        selected: value == option,
        onSelected: (_) => ref
            .read(clinicalPriorityControllerProvider.notifier)
            .answer(code, option),
      );
}
