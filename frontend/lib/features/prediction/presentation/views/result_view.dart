import 'dart:io';

import 'package:flutter/material.dart';
import 'package:bucalscan_ai/core/widgets/heatmap_overlay_image.dart';
import 'package:bucalscan_ai/core/presentation/localized_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/widgets/app_app_bar.dart';
import 'package:bucalscan_ai/core/widgets/responsive_content.dart';
import 'package:bucalscan_ai/features/dashboard/presentation/viewmodels/summary_viewmodel.dart';
import 'package:bucalscan_ai/features/history/presentation/viewmodels/history_viewmodel.dart';
import 'package:bucalscan_ai/features/prediction/presentation/viewmodels/prediction_viewmodel.dart';
import 'package:bucalscan_ai/features/priority/presentation/widgets/clinical_priority_result_card.dart';

class ResultView extends ConsumerStatefulWidget {
  final File imageFile;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onAnotherImage;
  final VoidCallback? onNewAnalysis;

  const ResultView({
    super.key,
    required this.imageFile,
    this.onOpenHistory,
    this.onAnotherImage,
    this.onNewAnalysis,
  });

  @override
  ConsumerState<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends ConsumerState<ResultView> {
  bool _hasSyncedPostAnalysis = false;

  ({String title, String message, IconData icon}) _getErrorPresentation(
    String error,
  ) {
    final normalized = error.toLowerCase();

    if (normalized.contains('no cumple los requisitos de calidad')) {
      return (
        title: 'Mejore la calidad de la imagen',
        message: error.replaceFirst('Exception: ', ''),
        icon: Icons.center_focus_strong_outlined,
      );
    }

    if (normalized.contains('invalid file type') ||
        normalized.contains('cannot decode image file')) {
      return (
        title: 'Imagen invalida',
        message:
            'La imagen seleccionada no pudo analizarse. Use una foto JPG, PNG o WEBP valida y vuelva a intentarlo.',
        icon: Icons.image_not_supported_outlined,
      );
    }

    if (normalized.contains('no se pudo conectar con el servidor') ||
        normalized.contains('no respondio a tiempo')) {
      return (
        title: 'Servidor no disponible',
        message:
            'No fue posible comunicarse con el backend de analisis. Verifique la conexion o vuelva a intentar en unos minutos.',
        icon: Icons.cloud_off_outlined,
      );
    }

    if (normalized.contains('no incluyo todos los datos esperados')) {
      return (
        title: 'Respuesta incompleta',
        message:
            'El servidor respondio, pero no envio todos los datos necesarios para mostrar el resultado.',
        icon: Icons.data_object_outlined,
      );
    }

    if (normalized.contains('model inference failed') ||
        normalized.contains('model file not loaded') ||
        normalized.contains('modelo de análisis no está disponible')) {
      return (
        title: 'Modelo no disponible',
        message:
            'El servidor no tiene disponible el modelo de análisis en este momento. Verifique el despliegue del backend o intente nuevamente más tarde.',
        icon: Icons.cloud_sync_outlined,
      );
    }

    return (
      title: 'Error en el analisis',
      message: error.replaceFirst('Exception: ', ''),
      icon: Icons.error_outline,
    );
  }

  String _normalizePrediction(String prediction) =>
      prediction.trim().toLowerCase();

  Color _getPredictionColor(String prediction) {
    return switch (localizedModelOutput(prediction).tone) {
      StatusTone.info => AppColors.primaryContainer,
      StatusTone.warning => AppColors.secondary,
      StatusTone.danger => AppColors.error,
      StatusTone.success => AppColors.primaryContainer,
      StatusTone.neutral => AppColors.secondary,
    };
  }

  IconData _getPredictionIcon(String prediction) =>
      localizedModelOutput(prediction).icon;

  String _getDisplayLabel(String prediction) =>
      localizedModelOutput(prediction).label;

  String _getClinicalHeadline(String prediction) =>
      'Salida orientativa del modelo: ${localizedModelOutput(prediction).label.toLowerCase()}';

  String _getConfidenceLevel(double confidence) {
    if (confidence >= 0.8) {
      return 'Alta';
    }
    if (confidence >= 0.65) {
      return 'Media';
    }
    return 'Baja';
  }

  String _getConfidenceMessage(double confidence, String prediction) {
    final label = _getDisplayLabel(prediction).toLowerCase();

    if (confidence >= 0.8) {
      return 'Confianza del clasificador para la salida $label. No expresa diagnóstico ni urgencia.';
    }
    if (confidence >= 0.65) {
      return 'Confianza intermedia del clasificador para $label; requiere interpretación profesional.';
    }
    return 'Confianza limitada del clasificador para $label; no permite descartar hallazgos clínicos.';
  }

  String _formatProcessingTime(double milliseconds) {
    if (milliseconds >= 1000) {
      return '${(milliseconds / 1000).toStringAsFixed(2)} s';
    }
    return '${milliseconds.toStringAsFixed(1)} ms';
  }

  List<MapEntry<String, double?>> _orderedProbabilities(
    Map<String, double>? probabilities,
  ) {
    final normalized = <String, double>{};
    probabilities?.forEach((key, value) {
      normalized[_normalizePrediction(key)] = value.clamp(0.0, 1.0).toDouble();
    });

    return [
      MapEntry('benign', normalized['benign'] ?? normalized['benigno']),
      MapEntry('malignant', normalized['malignant'] ?? normalized['maligno']),
    ];
  }

  Future<void> _retryAnalysis(PredictionState state) async {
    await ref.read(predictionViewModelProvider.notifier).retry();
  }

  void _goToNewAnalysis() {
    widget.onNewAnalysis?.call();
    Navigator.pop(context);
  }

  void _goToAnotherImage() {
    widget.onAnotherImage?.call();
    Navigator.pop(context);
  }

  void _goToHistory() {
    ref.read(predictionViewModelProvider.notifier).clearResult();
    Navigator.pop(context);
    widget.onOpenHistory?.call();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(predictionViewModelProvider);
    final result = viewModel.result;

    if (!_hasSyncedPostAnalysis &&
        !viewModel.isLoading &&
        viewModel.error == null &&
        result != null) {
      _hasSyncedPostAnalysis = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        ref.read(summaryViewModelProvider.notifier).fetchTodaySummary();
        ref.read(historyViewModelProvider.notifier).fetchHistory();
      });
    }

    if (viewModel.isLoading) {
      return Scaffold(
        appBar: const AppAppBar(title: 'Resultado del análisis'),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _AnalysisLoadingCard(
                  statusMessage: viewModel.analysisStatusMessage,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (viewModel.error != null) {
      final errorUi = _getErrorPresentation(viewModel.error!);

      return Scaffold(
        appBar: const AppAppBar(title: 'Error en el análisis'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
                    _AnalyzedImageCard(
                      imageFile: widget.imageFile,
                      compact: true,
                    ),
                    const SizedBox(height: 24),
                    Icon(errorUi.icon, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      errorUi.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      errorUi.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vuelva a intentarlo con otra imagen o regrese a la pantalla de captura.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final another = OutlinedButton.icon(
                          onPressed: _goToAnotherImage,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: const Text('Otra imagen para esta lesión'),
                        );
                        final retry = ElevatedButton.icon(
                          onPressed: () => _retryAnalysis(viewModel),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        );
                        if (constraints.maxWidth < 520) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              another,
                              const SizedBox(height: 10),
                              retry,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: another),
                            const SizedBox(width: 12),
                            Expanded(child: retry),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (result == null) {
      return Scaffold(
        appBar: const AppAppBar(title: 'Resultado del análisis'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_search_outlined,
                  size: 64,
                  color: AppColors.surfaceContainerHighest,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aún no hay un análisis disponible',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Seleccione una imagen desde la pantalla de captura para generar un resultado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver a captura'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final color = _getPredictionColor(result.prediction);
    final icon = _getPredictionIcon(result.prediction);
    final displayLabel = _getDisplayLabel(result.prediction);
    final clinicalHeadline = _getClinicalHeadline(result.prediction);
    final confidenceLevel = _getConfidenceLevel(result.confidence);
    final confidenceMessage = _getConfidenceMessage(
      result.confidence,
      result.prediction,
    );
    final translatedRecommendation = localizedModelRecommendation(
      result.prediction,
    );
    final orderedProbabilities = _orderedProbabilities(result.probabilities);

    return Scaffold(
      appBar: const AppAppBar(title: 'Resultado del análisis'),
      body: ResponsiveContent(
        maxWidth: 840,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ResultSummaryCard(
                color: color,
                icon: icon,
                displayLabel: displayLabel,
                clinicalHeadline: clinicalHeadline,
                confidence: result.confidence,
                confidenceLevel: confidenceLevel,
                patientName: viewModel.patientName,
                clinicalCode: viewModel.clinicalCode,
                lesionSite: viewModel.lesionSite,
              ),
              const SizedBox(height: 16),
              if (result.priority case final priority?) ...[
                ClinicalPriorityResultCard(priority: priority),
                const SizedBox(height: 16),
              ],
              _GuidanceCard(message: translatedRecommendation),
              const SizedBox(height: 20),
              const _ResultSectionHeading(
                icon: Icons.image_outlined,
                title: 'Imagen analizada',
                subtitle:
                    'Revise la fotografía y, si está disponible, la superposición CAM.',
              ),
              const SizedBox(height: 10),
              _AnalyzedImageCard(
                imageFile: widget.imageFile,
                heatmapUrl: result.heatmapUrl,
              ),
              const SizedBox(height: 16),
              _TechnicalDetailsCard(
                confidenceMessage: confidenceMessage,
                modelVersion: result.modelVersion,
                processingTime: result.processingTimeMs == null
                    ? null
                    : _formatProcessingTime(result.processingTimeMs!),
                probabilityRows: orderedProbabilities
                    .map(
                      (entry) => _ProbabilityRow(
                        label: _getDisplayLabel(entry.key).toUpperCase(),
                        value: entry.value,
                        color: _getPredictionColor(entry.key),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Card(
                color: AppColors.secondaryFixed.withValues(alpha: 0.45),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: AppColors.secondary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'La salida del modelo y la prioridad clínica orientativa son apoyos independientes. No constituyen diagnóstico, probabilidad de cáncer ni reemplazan la evaluación profesional.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _ResultActions(
                onNewAnalysis: _goToNewAnalysis,
                onAnotherImage: _goToAnotherImage,
                onRetry: () => _retryAnalysis(viewModel),
                onHistory: _goToHistory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultSummaryCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String displayLabel;
  final String clinicalHeadline;
  final double confidence;
  final String confidenceLevel;
  final String? patientName;
  final String? clinicalCode;
  final String? lesionSite;

  const _ResultSummaryCard({
    required this.color,
    required this.icon,
    required this.displayLabel,
    required this.clinicalHeadline,
    required this.confidence,
    required this.confidenceLevel,
    this.patientName,
    this.clinicalCode,
    this.lesionSite,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedConfidence = confidence.clamp(0, 1).toDouble();
    return Container(
      key: const Key('resultSummaryCard'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1200355F),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (patientName != null || lesionSite != null) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (patientName != null)
                  _ContextChip(
                    icon: Icons.person_outline,
                    text: [
                      patientName!,
                      if (clinicalCode != null) 'Código: $clinicalCode',
                    ].join(' · '),
                  ),
                if (lesionSite != null)
                  _ContextChip(icon: Icons.adjust, text: 'Lesión: $lesionSite'),
              ],
            ),
            const SizedBox(height: 18),
          ],
          const Text(
            'Clasificación estimada',
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clinicalHeadline,
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Confianza del clasificador',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${(normalizedConfidence * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: normalizedConfidence,
            minHeight: 7,
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Nivel $confidenceLevel',
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContextChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _GuidanceCard extends StatelessWidget {
  final String message;

  const _GuidanceCard({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('resultGuidanceCard'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primaryFixed,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.route_outlined, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Orientación profesional',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(message, style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ResultSectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ResultSectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primaryFixed,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 21, color: AppColors.primary),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _TechnicalDetailsCard extends StatelessWidget {
  final String confidenceMessage;
  final String? modelVersion;
  final String? processingTime;
  final List<Widget> probabilityRows;

  const _TechnicalDetailsCard({
    required this.confidenceMessage,
    required this.modelVersion,
    required this.processingTime,
    required this.probabilityRows,
  });

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('resultTechnicalDetails'),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      leading: const Icon(Icons.analytics_outlined),
      title: const Text('Detalles técnicos'),
      subtitle: const Text('Distribución, modelo y procesamiento'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Distribución de la salida',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 12),
        ...probabilityRows,
        const SizedBox(height: 8),
        _TechnicalDatum(
          label: 'Versión del modelo',
          value: modelVersion?.trim().isNotEmpty == true
              ? modelVersion!
              : 'No disponible',
        ),
        if (processingTime != null)
          _TechnicalDatum(
            label: 'Tiempo de inferencia',
            value: processingTime!,
          ),
        const SizedBox(height: 6),
        Text(
          confidenceMessage,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

class _ProbabilityRow extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;

  const _ProbabilityRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value ?? 0,
            minHeight: 8,
            color: color,
            backgroundColor: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          child: Text(
            value == null ? 'N/D' : '${(value! * 100).toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _TechnicalDatum extends StatelessWidget {
  final String label;
  final String value;

  const _TechnicalDatum({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _ResultActions extends StatelessWidget {
  final VoidCallback onNewAnalysis;
  final VoidCallback onHistory;
  final Future<void> Function() onRetry;
  final VoidCallback onAnotherImage;

  const _ResultActions({
    required this.onNewAnalysis,
    required this.onRetry,
    required this.onHistory,
    required this.onAnotherImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const Key('anotherImagePrimaryAction'),
          onPressed: onAnotherImage,
          icon: const Icon(Icons.photo_camera_back_outlined),
          label: const Text('Otra imagen para esta lesión'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onNewAnalysis,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Nuevo análisis'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onHistory,
                icon: const Icon(Icons.history),
                label: const Text('Ver historial'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnalyzedImageCard extends StatelessWidget {
  final File imageFile;
  final String? heatmapUrl;
  final bool compact;

  const _AnalyzedImageCard({
    required this.imageFile,
    this.heatmapUrl,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heatmapUrl == null
                  ? 'Imagen analizada'
                  : 'Imagen y mapa de activación CAM',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: compact ? 120 : 220,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: HeatmapOverlayImage(
                  baseImage: FileImage(imageFile),
                  heatmapUrl: heatmapUrl,
                ),
              ),
            ),
            if (heatmapUrl != null) ...[
              const SizedBox(height: 8),
              const Text(
                'El color resalta regiones que influyeron en la salida; no localiza ni confirma una lesión.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnalysisLoadingCard extends StatefulWidget {
  final String? statusMessage;

  const _AnalysisLoadingCard({this.statusMessage});

  @override
  State<_AnalysisLoadingCard> createState() => _AnalysisLoadingCardState();
}

class _AnalysisLoadingCardState extends State<_AnalysisLoadingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final firstStepCompleted = progress >= 0.28;
        final secondStepActive = progress >= 0.28 && progress < 0.68;
        final secondStepCompleted = progress >= 0.68;
        final thirdStepActive = progress >= 0.68;

        return Card(
          color: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.memory_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Analisis de IA en progreso...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.statusMessage ??
                      'Procesando imagenes clinicas. Los resultados suelen estar listos en menos de 5 segundos.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: 0.14 + (progress * 0.74),
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _ProgressStep(
                  title: 'Validacion de imagen completada',
                  state: firstStepCompleted
                      ? _ProgressStepStateType.completed
                      : _ProgressStepStateType.active,
                ),
                const SizedBox(height: 12),
                _ProgressStep(
                  title: 'Extrayendo caracteristicas...',
                  state: secondStepCompleted
                      ? _ProgressStepStateType.completed
                      : secondStepActive
                      ? _ProgressStepStateType.active
                      : _ProgressStepStateType.pending,
                ),
                const SizedBox(height: 12),
                _ProgressStep(
                  title: 'Procesando con el modelo de análisis',
                  state: thirdStepActive
                      ? _ProgressStepStateType.active
                      : _ProgressStepStateType.pending,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _ProgressStepStateType { pending, active, completed }

class _ProgressStep extends StatefulWidget {
  final String title;
  final _ProgressStepStateType state;

  const _ProgressStep({required this.title, required this.state});

  @override
  State<_ProgressStep> createState() => _ProgressStepState();
}

class _ProgressStepState extends State<_ProgressStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.state == _ProgressStepStateType.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _ProgressStep oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.state == _ProgressStepStateType.active) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.state == _ProgressStepStateType.completed;
    final isActive = widget.state == _ProgressStepStateType.active;
    final iconColor = isCompleted || isActive
        ? AppColors.primary
        : AppColors.outlineVariant;
    final textColor = isCompleted || isActive
        ? AppColors.primary
        : AppColors.onSurfaceVariant.withValues(alpha: 0.7);
    final icon = isCompleted
        ? Icons.check_circle
        : isActive
        ? Icons.autorenew
        : Icons.radio_button_unchecked;

    return Row(
      children: [
        isActive
            ? RotationTransition(
                turns: _controller,
                child: Icon(icon, color: iconColor, size: 18),
              )
            : Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            widget.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
