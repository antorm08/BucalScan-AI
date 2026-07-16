import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/presentation/localized_status.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/lesion_comparison.dart';
import 'package:bucalscan_ai/features/clinical/domain/services/pdf_share_service.dart';
import 'package:bucalscan_ai/features/clinical/di/clinical_providers.dart';
import 'package:bucalscan_ai/features/clinical/presentation/views/lesion_comparison_view.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/patient_follow_up_controller.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/clinical_controller.dart';
import 'package:bucalscan_ai/features/priority/presentation/priority_copy.dart';
import 'package:flutter/material.dart';
import 'package:bucalscan_ai/core/widgets/heatmap_overlay_image.dart';
import 'package:bucalscan_ai/core/widgets/responsive_content.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LesionDetailView extends ConsumerStatefulWidget {
  final Patient patient;
  final String lesionId;
  final void Function(Patient, OralLesion) onRepeatAnalysis;

  const LesionDetailView({
    super.key,
    required this.patient,
    required this.lesionId,
    required this.onRepeatAnalysis,
  });

  @override
  ConsumerState<LesionDetailView> createState() => _LesionDetailViewState();
}

class _LesionDetailViewState extends ConsumerState<LesionDetailView> {
  final Set<String> _exportingEvaluationIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(patientFollowUpControllerProvider.notifier)
          .loadLesion(widget.lesionId),
    );
  }

  Future<void> _edit(LesionDetail detail) async {
    var status = detail.lesion.status;
    final notes = TextEditingController(text: detail.lesion.notes);
    final duration = TextEditingController(
      text: detail.lesion.estimatedDuration,
    );
    var observedAt = detail.lesion.observedAt;
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Estado y notas actuales'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Activa')),
                    DropdownMenuItem(
                      value: 'monitoring',
                      child: Text('En seguimiento'),
                    ),
                    DropdownMenuItem(
                      value: 'resolved',
                      child: Text('Resuelta'),
                    ),
                  ],
                  onChanged: (value) => setDialogState(() => status = value!),
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
                TextField(
                  controller: duration,
                  decoration: const InputDecoration(
                    labelText: 'Duración estimada',
                    hintText: 'Ej.: cerca de 3 semanas',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final value = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      initialDate: observedAt ?? DateTime.now(),
                    );
                    if (value != null) setDialogState(() => observedAt = value);
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    observedAt == null
                        ? 'Fecha de primera observación'
                        : 'Observada el ${observedAt!.day}/${observedAt!.month}/${observedAt!.year}',
                  ),
                ),
                TextField(
                  controller: notes,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notas longitudinales de la lesión',
                    helperText:
                        'Resumen de evolución, separado de hallazgos puntuales.',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (submit == true) {
      await ref
          .read(patientFollowUpControllerProvider.notifier)
          .updateLesion(
            status: status,
            notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
            observedAt: observedAt,
            estimatedDuration: duration.text.trim().isEmpty
                ? null
                : duration.text.trim(),
          );
    }
  }

  Future<void> _exportEvaluation(
    OralLesion lesion,
    LesionEvaluation evaluation,
    ShareOrigin origin,
  ) async {
    if (_exportingEvaluationIds.contains(evaluation.id)) return;
    final workspaceId = ref
        .read(clinicalControllerProvider)
        .activeWorkspace
        ?.id;
    setState(() => _exportingEvaluationIds.add(evaluation.id));
    try {
      final bytes = await ref.read(exportEvaluationPdfUseCaseProvider)(
        lesionId: lesion.id,
        evaluationId: evaluation.id,
      );
      if (!mounted ||
          ref.read(clinicalControllerProvider).activeWorkspace?.id !=
              workspaceId) {
        return;
      }
      await ref
          .read(pdfShareServiceProvider)
          .share(bytes, evaluationId: evaluation.id, origin: origin);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo exportar el informe PDF. Inténtelo nuevamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exportingEvaluationIds.remove(evaluation.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientFollowUpControllerProvider);
    final detail = state.lesionDetail;
    final comparableCount = detail == null
        ? 0
        : comparableEvaluations(detail.evaluations).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento de lesión')),
      body: detail == null && state.status == FollowUpStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.error ?? 'No se pudo cargar la lesión.'),
                  TextButton(
                    onPressed: () => ref
                        .read(patientFollowUpControllerProvider.notifier)
                        .loadLesion(widget.lesionId),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : ResponsiveContent(
              maxWidth: 840,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.lesion.anatomicalSite,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${detail.lesion.temporalDescription} · ${_label(detail.lesion.status)}',
                          ),
                          if (detail.lesion.notes != null) ...[
                            const SizedBox(height: 10),
                            const Text(
                              'Notas longitudinales',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(detail.lesion.notes!),
                          ],
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed:
                                state.actionStatus ==
                                    FollowUpActionStatus.updating
                                ? null
                                : () => _edit(detail),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar estado y notas'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('repeatAnalysisButton'),
                    onPressed: () =>
                        widget.onRepeatAnalysis(widget.patient, detail.lesion),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Nuevo análisis para esta lesión'),
                  ),
                  const SizedBox(height: 22),
                  OutlinedButton.icon(
                    key: const Key('compareEvaluationsButton'),
                    onPressed: comparableCount < 2
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => LesionComparisonView(
                                lesion: detail.lesion,
                                evaluations: detail.evaluations,
                              ),
                            ),
                          ),
                    icon: const Icon(Icons.compare_outlined),
                    label: const Text('Comparar dos evaluaciones'),
                  ),
                  if (comparableCount < 2)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Disponible cuando existan dos evaluaciones con imagen y resultado.',
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  const SizedBox(height: 22),
                  Text(
                    'Línea de tiempo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  if (detail.evaluations.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('Esta lesión aún no tiene evaluaciones.'),
                      ),
                    )
                  else
                    ...detail.evaluations.map(
                      (evaluation) => _EvaluationCard(
                        evaluation: evaluation,
                        isExporting: _exportingEvaluationIds.contains(
                          evaluation.id,
                        ),
                        onExport: (origin) => _exportEvaluation(
                          detail.lesion,
                          evaluation,
                          origin,
                        ),
                      ),
                    ),
                  if (state.actionError != null)
                    Text(
                      state.actionError!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                ],
              ),
            ),
    );
  }
}

String _label(String status) => localizedLesionStatus(status).label;

class _EvaluationCard extends StatelessWidget {
  final LesionEvaluation evaluation;
  final bool isExporting;
  final ValueChanged<ShareOrigin> onExport;

  const _EvaluationCard({
    required this.evaluation,
    required this.isExporting,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final prediction = evaluation.prediction;
    return Card(
      key: Key('evaluation-${evaluation.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _format(evaluation.evaluatedAt),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              '${evaluation.professional.fullName} · ${evaluation.professional.profession ?? 'Profesional'}',
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
            if (evaluation.image != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: HeatmapOverlayImage(
                    baseImage: NetworkImage(evaluation.image!.url),
                    heatmapUrl: prediction?.heatmapUrl,
                    errorFallback: const Center(
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ],
            if (evaluation.clinicalObservations != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Hallazgos de esta evaluación',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(evaluation.clinicalObservations!),
            ],
            if (prediction != null) ...[
              const Divider(height: 24),
              Text(
                'Salida del modelo: ${_predictionLabel(prediction.label)} · confianza ${(prediction.confidence * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                'La confianza describe la salida del clasificador; no es diagnóstico ni urgencia.',
              ),
              Text(
                'Modelo ${prediction.modelVersion}${prediction.processingTimeMs == null ? '' : ' · ${prediction.processingTimeMs!.toStringAsFixed(0)} ms'}',
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Resultado de apoyo clínico; no constituye un diagnóstico.',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
            if (evaluation.priority case final priority?) ...[
              const Divider(height: 24),
              const Text(
                'Semáforo orientativo de atención',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(localizedPriorityStatus(priority.priorityCode).label),
              ...localizedPriorityReasons(priority).map(Text.new),
              Text(
                'Ruleset ${priority.rulesetVersion} · motor ${priority.engineVersion}',
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const Text(
                'Apoyo no diagnóstico; no reemplaza el juicio profesional ni los servicios de emergencia.',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
            if (evaluation.consentAttestedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Autorización atestada: ${_format(evaluation.consentAttestedAt!)}',
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Builder(
              builder: (buttonContext) => SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: Key('exportEvaluationPdf-${evaluation.id}'),
                  onPressed: isExporting
                      ? null
                      : () => onExport(_shareOrigin(buttonContext)),
                  icon: isExporting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(
                    isExporting
                        ? 'Preparando informe…'
                        : 'Exportar informe PDF',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

ShareOrigin _shareOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) {
    return const ShareOrigin(left: 0, top: 0, width: 1, height: 1);
  }
  final offset = box.localToGlobal(Offset.zero);
  return ShareOrigin(
    left: offset.dx,
    top: offset.dy,
    width: box.size.width,
    height: box.size.height,
  );
}

String _format(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _predictionLabel(String value) {
  final status = localizedModelOutput(value);
  return status.tone == StatusTone.neutral
      ? status.label
      : 'Compatible con ${status.label.toLowerCase()}';
}
