import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/presentation/localized_status.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/lesion_comparison.dart';
import 'package:bucalscan_ai/features/clinical/domain/services/pdf_save_service.dart';
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
    final formKey = GlobalKey<FormState>();
    var observedAt = detail.lesion.observedAt;
    var submitting = false;
    String? submitError;
    var saved = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => PopScope(
          canPop: !submitting,
          child: AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            title: const Text('Actualizar seguimiento'),
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _DialogSectionLabel(
                        icon: Icons.monitor_heart_outlined,
                        title: 'Estado actual',
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        key: const Key('editLesionStatus'),
                        initialValue: status,
                        items: const [
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Activa'),
                          ),
                          DropdownMenuItem(
                            value: 'monitoring',
                            child: Text('En seguimiento'),
                          ),
                          DropdownMenuItem(
                            value: 'resolved',
                            child: Text('Resuelta'),
                          ),
                        ],
                        onChanged: submitting
                            ? null
                            : (value) => setDialogState(() => status = value!),
                        decoration: const InputDecoration(
                          labelText: 'Estado de la lesión',
                        ),
                      ),
                      const SizedBox(height: 22),
                      const _DialogSectionLabel(
                        icon: Icons.schedule_outlined,
                        title: 'Temporalidad',
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: const Key('editLesionObservedAt'),
                        onPressed: submitting
                            ? null
                            : () async {
                                final value = await showDatePicker(
                                  context: dialogContext,
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                  initialDate: observedAt ?? DateTime.now(),
                                  helpText: 'Primera observación',
                                  cancelText: 'Cancelar',
                                  confirmText: 'Seleccionar',
                                );
                                if (value != null) {
                                  setDialogState(() => observedAt = value);
                                }
                              },
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          observedAt == null
                              ? 'Agregar fecha de primera observación'
                              : 'Observada el ${_formatDate(observedAt!)}',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      if (observedAt != null) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            key: const Key('clearLesionObservedAt'),
                            onPressed: submitting
                                ? null
                                : () => setDialogState(() => observedAt = null),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Quitar fecha'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('editLesionDuration'),
                        controller: duration,
                        enabled: !submitting,
                        decoration: const InputDecoration(
                          labelText: 'Duración estimada',
                          hintText: 'Ej.: cerca de 3 semanas',
                          helperText:
                              'Conserve una fecha, una duración o ambas.',
                          helperMaxLines: 2,
                        ),
                        validator: (value) =>
                            observedAt == null && value!.trim().isEmpty
                            ? 'Indique una fecha o una duración.'
                            : null,
                      ),
                      const SizedBox(height: 22),
                      const _DialogSectionLabel(
                        icon: Icons.notes_outlined,
                        title: 'Seguimiento longitudinal',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Actualice la evolución general. Los hallazgos de una consulta específica permanecen en su evaluación.',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('editLesionNotes'),
                        controller: notes,
                        enabled: !submitting,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText:
                              'Ej.: lesión estable desde la consulta anterior',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (submitError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          submitError!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: const Key('editLesionSubmit'),
                onPressed: submitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          submitting = true;
                          submitError = null;
                        });
                        saved = await ref
                            .read(patientFollowUpControllerProvider.notifier)
                            .updateLesion(
                              status: status,
                              notes: notes.text.trim().isEmpty
                                  ? null
                                  : notes.text.trim(),
                              observedAt: observedAt,
                              estimatedDuration: duration.text.trim().isEmpty
                                  ? null
                                  : duration.text.trim(),
                            );
                        if (!dialogContext.mounted) return;
                        if (saved) {
                          Navigator.pop(dialogContext);
                        } else {
                          setDialogState(() {
                            submitting = false;
                            submitError =
                                'No se pudo actualizar la lesión. Inténtelo nuevamente.';
                          });
                        }
                      },
                child: submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seguimiento actualizado correctamente.')),
      );
    }
  }

  Future<void> _exportEvaluation(
    OralLesion lesion,
    LesionEvaluation evaluation,
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
      final result = await ref
          .read(pdfSaveServiceProvider)
          .save(bytes, evaluationId: evaluation.id);
      if (mounted && result == PdfSaveResult.saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe PDF guardado correctamente.')),
        );
      }
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
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              detail.evaluations.length < 2
                                  ? 'Necesitas una segunda evaluación de esta misma lesión con imagen y resultado del modelo.'
                                  : 'Hay ${detail.evaluations.length} evaluaciones, pero solo $comparableCount ${comparableCount == 1 ? 'incluye' : 'incluyen'} imagen y resultado del modelo. Realiza otro análisis completo sobre esta misma lesión para habilitar la comparación.',
                              style: const TextStyle(
                                color: AppColors.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 22),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Línea de tiempo',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Evolución cronológica · registro más antiguo primero',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      if (detail.evaluations.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _MetaChip(
                            icon: Icons.event_note_outlined,
                            label:
                                '${detail.evaluations.length} ${detail.evaluations.length == 1 ? 'evaluación' : 'evaluaciones'}',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (detail.evaluations.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('Esta lesión aún no tiene evaluaciones.'),
                      ),
                    )
                  else
                    ...detail.evaluations.indexed.map(
                      (entry) => _TimelineEntry(
                        position: entry.$1 + 1,
                        isLast: entry.$1 == detail.evaluations.length - 1,
                        child: _EvaluationCard(
                          evaluation: entry.$2,
                          position: entry.$1 + 1,
                          isExporting: _exportingEvaluationIds.contains(
                            entry.$2.id,
                          ),
                          onExport: () =>
                              _exportEvaluation(detail.lesion, entry.$2),
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
  final int position;
  final bool isExporting;
  final VoidCallback onExport;

  const _EvaluationCard({
    required this.evaluation,
    required this.position,
    required this.isExporting,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final prediction = evaluation.prediction;
    return Card(
      key: Key('evaluation-${evaluation.id}'),
      margin: const EdgeInsets.only(bottom: 18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primaryFixed.withValues(alpha: 0.42),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EVALUACIÓN $position',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _format(evaluation.evaluatedAt),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.person_outline,
                        size: 18,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${evaluation.professional.fullName} · ${evaluation.professional.profession ?? 'Profesional'}',
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (evaluation.image != null) ...[
                  SizedBox(
                    height: 190,
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
                  const SizedBox(height: 16),
                  _SectionPanel(
                    icon: Icons.description_outlined,
                    title: 'Hallazgos de esta evaluación',
                    child: Text(
                      evaluation.clinicalObservations!,
                      style: const TextStyle(height: 1.45),
                    ),
                  ),
                ],
                if (prediction != null) ...[
                  const SizedBox(height: 16),
                  _SectionPanel(
                    icon: Icons.biotech_outlined,
                    title: 'Resultado del modelo',
                    color: AppColors.secondaryFixed.withValues(alpha: 0.45),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _predictionLabel(prediction.label),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        _MetaChip(
                          icon: Icons.analytics_outlined,
                          label:
                              'Confianza ${(prediction.confidence * 100).toStringAsFixed(1)}%',
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'La confianza describe la salida del clasificador; no es diagnóstico ni urgencia.',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (evaluation.priority case final priority?) ...[
                  const SizedBox(height: 16),
                  _SectionPanel(
                    icon: Icons.flag_outlined,
                    title: 'Prioridad clínica orientativa',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizedPriorityStatus(priority.priorityCode).label,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (localizedPriorityReasons(priority).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...localizedPriorityReasons(priority).map(
                            (reason) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• $reason'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        const Text(
                          'Apoyo no diagnóstico; no reemplaza el juicio profesional ni los servicios de emergencia.',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (prediction != null ||
                    evaluation.priority != null ||
                    evaluation.consentAttestedAt != null) ...[
                  const SizedBox(height: 12),
                  ExpansionTile(
                    key: Key('evaluationTechnical-${evaluation.id}'),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    leading: const Icon(Icons.tune_outlined, size: 21),
                    title: const Text(
                      'Detalles técnicos y consentimiento',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    children: [
                      if (prediction != null)
                        _TechnicalRow(
                          label: 'Modelo',
                          value:
                              '${prediction.modelVersion}${prediction.processingTimeMs == null ? '' : ' · ${prediction.processingTimeMs!.toStringAsFixed(0)} ms'}',
                        ),
                      if (evaluation.priority case final priority?)
                        _TechnicalRow(
                          label: 'Reglas clínicas',
                          value:
                              '${priority.rulesetVersion} · motor ${priority.engineVersion}',
                        ),
                      if (evaluation.consentAttestedAt != null)
                        _TechnicalRow(
                          label: 'Autorización atestada',
                          value: _format(evaluation.consentAttestedAt!),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: Key('exportEvaluationPdf-${evaluation.id}'),
                    onPressed: isExporting ? null : onExport,
                    icon: isExporting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(
                      isExporting
                          ? 'Preparando descarga…'
                          : 'Descargar informe PDF',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final int position;
  final bool isLast;
  final Widget child;

  const _TimelineEntry({
    required this.position,
    required this.isLast,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      if (!isLast)
        const Positioned(
          left: 14,
          top: 28,
          bottom: 0,
          child: ColoredBox(
            color: AppColors.primaryFixedDim,
            child: SizedBox(width: 2),
          ),
        ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: Text(
              '$position',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    ],
  );
}

class _SectionPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Color? color;

  const _SectionPanel({
    required this.icon,
    required this.title,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color ?? AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.outlineVariant),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _TechnicalRow extends StatelessWidget {
  final String label;
  final String value;

  const _TechnicalRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, height: 1.35),
          ),
        ),
      ],
    ),
  );
}

class _DialogSectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;

  const _DialogSectionLabel({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

String _format(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _predictionLabel(String value) {
  final status = localizedModelOutput(value);
  return status.tone == StatusTone.neutral
      ? status.label
      : 'Compatible con ${status.label.toLowerCase()}';
}
