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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clinicalPriorityControllerProvider);
    if (state.loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.hourglass_top_outlined),
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

    return Card(
      key: const Key('clinicalAssessmentCard'),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.fact_check_outlined),
        title: const Text('Checklist orientativo de atención'),
        subtitle: Text(
          state.complete
              ? 'Completa. La prioridad será calculada únicamente por el servidor.'
              : '${state.answers.length} de ${clinicalAssessmentFields.length} respuestas',
        ),
        children: [
          if (state.capability?.mode == ClinicalPriorityMode.academic)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Modo académico: apoyo no validado para triaje clínico. No reemplaza el juicio profesional ni los servicios de emergencia.',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
          ..._group(
            context,
            state,
            'Signos y síntomas actuales',
            clinicalAssessmentFields.entries.take(10),
          ),
          ..._group(
            context,
            state,
            'Factores de riesgo',
            clinicalAssessmentFields.entries.skip(10).take(4),
          ),
          ..._group(
            context,
            state,
            'Signos de emergencia',
            clinicalAssessmentFields.entries.skip(14),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              state.complete
                  ? 'Respuestas completas para el ruleset activo.'
                  : 'Responda Sí, No o No evaluado en cada elemento. No evaluado nunca se interpreta como ausencia.',
              style: TextStyle(
                color: state.complete
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _group(
    BuildContext context,
    ClinicalPriorityState state,
    String title,
    Iterable<MapEntry<String, String>> fields,
  ) => [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
    ),
    ...fields.map(
      (field) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Semantics(
          label: '${field.value}. Seleccione Sí, No o No evaluado',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(field.value),
              const SizedBox(height: 4),
              SegmentedButton<ClinicalTriState>(
                segments: const [
                  ButtonSegment(value: ClinicalTriState.yes, label: Text('Sí')),
                  ButtonSegment(value: ClinicalTriState.no, label: Text('No')),
                  ButtonSegment(
                    value: ClinicalTriState.unknown,
                    label: Text('No evaluado'),
                  ),
                ],
                selected: state.answers[field.key] == null
                    ? const {}
                    : {state.answers[field.key]!},
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  if (selection.isNotEmpty) {
                    ref
                        .read(clinicalPriorityControllerProvider.notifier)
                        .answer(field.key, selection.first);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
  ];
}
