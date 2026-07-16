import 'package:bucalscan_ai/core/presentation/localized_status.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/widgets/responsive_content.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/lesion_comparison.dart';
import 'package:flutter/material.dart';

class LesionComparisonView extends StatefulWidget {
  final OralLesion lesion;
  final List<LesionEvaluation> evaluations;

  const LesionComparisonView({
    super.key,
    required this.lesion,
    required this.evaluations,
  });

  @override
  State<LesionComparisonView> createState() => _LesionComparisonViewState();
}

class _LesionComparisonViewState extends State<LesionComparisonView> {
  late final List<LesionEvaluation> _evaluations;
  LesionComparisonPair? _pair;

  @override
  void initState() {
    super.initState();
    _evaluations = comparableEvaluations(widget.evaluations);
    if (_evaluations.length >= 2) {
      _pair = LesionComparisonPair.latest(_evaluations);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comparar evaluaciones')),
      body: _pair == null
          ? const _UnavailableComparison()
          : ResponsiveContent(
              maxWidth: 920,
              child: ListView(
                key: const Key('lesionComparisonView'),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    widget.lesion.anatomicalSite,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Seleccione dos evaluaciones de esta misma lesión.',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stackSelectors =
                          constraints.maxWidth < 480 ||
                          MediaQuery.textScalerOf(context).scale(14) > 18;
                      final left = _selector(
                        key: const Key('leftEvaluationSelector'),
                        label: 'Evaluación anterior',
                        selected: _pair!.left,
                        onChanged: (evaluation) => setState(
                          () => _pair = _pair!.selectLeft(evaluation),
                        ),
                      );
                      final right = _selector(
                        key: const Key('rightEvaluationSelector'),
                        label: 'Evaluación posterior',
                        selected: _pair!.right,
                        onChanged: (evaluation) => setState(
                          () => _pair = _pair!.selectRight(evaluation),
                        ),
                      );
                      if (stackSelectors) {
                        return Column(
                          children: [left, const SizedBox(height: 12), right],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: left),
                          const SizedBox(width: 10),
                          Expanded(child: right),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stack =
                          constraints.maxWidth < 620 ||
                          MediaQuery.textScalerOf(context).scale(14) > 18;
                      final left = _EvaluationColumn(
                        key: const Key('leftEvaluationColumn'),
                        title: 'Anterior',
                        evaluation: _pair!.left,
                      );
                      final right = _EvaluationColumn(
                        key: const Key('rightEvaluationColumn'),
                        title: 'Posterior',
                        evaluation: _pair!.right,
                      );
                      if (stack) {
                        return Column(
                          children: [left, const SizedBox(height: 12), right],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: left),
                          const SizedBox(width: 12),
                          Expanded(child: right),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _DeltaCard(pair: _pair!),
                  const SizedBox(height: 16),
                  _FindingsComparison(pair: _pair!),
                ],
              ),
            ),
    );
  }

  Widget _selector({
    required Key key,
    required String label,
    required LesionEvaluation selected,
    required ValueChanged<LesionEvaluation> onChanged,
  }) => KeyedSubtree(
    key: key,
    child: DropdownButtonFormField<String>(
      key: ValueKey('comparisonDropdown-${selected.id}'),
      initialValue: selected.id,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final evaluation in _evaluations)
          DropdownMenuItem(
            value: evaluation.id,
            child: Text(
              _shortDate(evaluation.evaluatedAt),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (id) {
        if (id != null) {
          onChanged(
            _evaluations.firstWhere((evaluation) => evaluation.id == id),
          );
        }
      },
    ),
  );
}

class _EvaluationColumn extends StatelessWidget {
  final String title;
  final LesionEvaluation evaluation;

  const _EvaluationColumn({
    super.key,
    required this.title,
    required this.evaluation,
  });

  @override
  Widget build(BuildContext context) {
    final prediction = evaluation.prediction!;
    final image = evaluation.image!;
    final status = localizedModelOutput(prediction.label);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  image.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    key: Key('comparisonImageFallback-${evaluation.id}'),
                    color: AppColors.surfaceContainerHigh,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(_fullDate(evaluation.evaluatedAt)),
            Text(
              status.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              'Confianza ${(prediction.confidence * 100).toStringAsFixed(1)}%',
            ),
            Text(
              'Salida maligna ${(malignantOutput(evaluation) * 100).toStringAsFixed(1)}%',
            ),
            Text(
              'Modelo ${prediction.modelVersion}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeltaCard extends StatelessWidget {
  final LesionComparisonPair pair;

  const _DeltaCard({required this.pair});

  @override
  Widget build(BuildContext context) {
    final leftPrediction = pair.left.prediction!;
    final rightPrediction = pair.right.prediction!;
    final confidenceDelta = percentagePointDelta(
      leftPrediction.confidence,
      rightPrediction.confidence,
    );
    final malignantDelta = percentagePointDelta(
      malignantOutput(pair.left),
      malignantOutput(pair.right),
    );
    final labelsDiffer = leftPrediction.label != rightPrediction.label;
    final versionsDiffer =
        leftPrediction.modelVersion != rightPrediction.modelVersion;

    return Card(
      key: const Key('comparisonDeltaCard'),
      color: AppColors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diferencia numérica: posterior menos anterior',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('Confianza del clasificador: ${_signed(confidenceDelta)} pp'),
            Text(
              'Salida maligna del clasificador: ${_signed(malignantDelta)} pp',
            ),
            if (labelsDiffer) ...[
              const SizedBox(height: 8),
              const Text(
                'Las clases predichas son distintas; cada confianza corresponde a una salida diferente.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            if (versionsDiffer) ...[
              const SizedBox(height: 8),
              const Text(
                'Las versiones del modelo son distintas y reducen la comparabilidad directa.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Estas diferencias no demuestran evolución, mejoría, deterioro, diagnóstico ni probabilidad de cáncer.',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _FindingsComparison extends StatelessWidget {
  final LesionComparisonPair pair;

  const _FindingsComparison({required this.pair});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Hallazgos registrados',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      LayoutBuilder(
        builder: (context, constraints) {
          final previous = _finding('Anterior', pair.left.clinicalObservations);
          final current = _finding(
            'Posterior',
            pair.right.clinicalObservations,
          );
          if (constraints.maxWidth < 620 ||
              MediaQuery.textScalerOf(context).scale(14) > 18) {
            return Column(
              children: [previous, const SizedBox(height: 10), current],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: previous),
              const SizedBox(width: 12),
              Expanded(child: current),
            ],
          );
        },
      ),
    ],
  );

  Widget _finding(String label, String? value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.outlineVariant),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value?.trim().isNotEmpty == true ? value! : 'No registrado'),
      ],
    ),
  );
}

class _UnavailableComparison extends StatelessWidget {
  const _UnavailableComparison();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Se necesitan al menos dos evaluaciones con imagen y resultado para comparar.',
        key: Key('comparisonUnavailable'),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

String _signed(double value) =>
    '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}';

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _fullDate(DateTime value) =>
    '${_shortDate(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
