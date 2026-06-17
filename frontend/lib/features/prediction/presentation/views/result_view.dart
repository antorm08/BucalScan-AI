import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/widgets/app_app_bar.dart';
import 'package:bucalscan_ai/features/dashboard/di/dashboard_providers.dart';
import 'package:bucalscan_ai/features/history/di/history_providers.dart';
import 'package:bucalscan_ai/features/home/presentation/views/home_view.dart';
import 'package:bucalscan_ai/features/prediction/di/prediction_providers.dart';

class ResultView extends ConsumerStatefulWidget {
  final File imageFile;

  const ResultView({super.key, required this.imageFile});

  @override
  ConsumerState<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends ConsumerState<ResultView> {
  bool _hasSyncedPostAnalysis = false;

  ({String title, String message, IconData icon}) _getErrorPresentation(
    String error,
  ) {
    final normalized = error.toLowerCase();

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

    return (
      title: 'Error en el analisis',
      message: error.replaceFirst('Exception: ', ''),
      icon: Icons.error_outline,
    );
  }

  String _normalizePrediction(String prediction) {
    return prediction.trim().toLowerCase();
  }

  Color _getPredictionColor(String prediction) {
    switch (_normalizePrediction(prediction)) {
      case 'benign':
      case 'benigno':
        return Colors.green;
      case 'malignant':
      case 'maligno':
        return AppColors.error;
      default:
        return AppColors.secondary;
    }
  }

  IconData _getPredictionIcon(String prediction) {
    switch (_normalizePrediction(prediction)) {
      case 'benign':
      case 'benigno':
        return Icons.check_circle;
      case 'malignant':
      case 'maligno':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getDisplayLabel(String prediction) {
    switch (_normalizePrediction(prediction)) {
      case 'benign':
      case 'benigno':
        return 'Benigno';
      case 'malignant':
      case 'maligno':
        return 'Maligno';
      default:
        return prediction;
    }
  }

  String _getClinicalHeadline(String prediction) {
    switch (_normalizePrediction(prediction)) {
      case 'benign':
      case 'benigno':
        return 'Lesion compatible con patron benigno';
      case 'malignant':
      case 'maligno':
        return 'Hallazgos compatibles con posible lesion maligna';
      default:
        return 'Clasificacion estimada por IA';
    }
  }

  String _getConfidenceLevel(double confidence) {
    if (confidence >= 0.8) {
      return 'Alta';
    }
    if (confidence >= 0.65) {
      return 'Media';
    }
    return 'Baja';
  }

  Color _getConfidenceAccent(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    }
    if (confidence >= 0.65) {
      return Colors.orange;
    }
    return AppColors.secondary;
  }

  String _getConfidenceMessage(double confidence, String prediction) {
    final label = _getDisplayLabel(prediction).toLowerCase();

    if (confidence >= 0.8) {
      return 'El modelo muestra una inclinacion clara hacia $label.';
    }
    if (confidence >= 0.65) {
      return 'La prediccion se inclina a $label, pero conviene interpretarla con cautela.';
    }
    return 'La prediccion se inclina a $label, pero el margen es reducido y requiere mayor cautela.';
  }

  String _formatProcessingTime(double milliseconds) {
    if (milliseconds >= 1000) {
      return '${(milliseconds / 1000).toStringAsFixed(2)} s';
    }
    return '${milliseconds.toStringAsFixed(1)} ms';
  }

  String _translateRecommendation(String recommendation) {
    final normalized = recommendation.trim().toLowerCase();

    if (normalized.contains('no immediate concern') ||
        normalized.contains('regular check-ups recommended')) {
      return 'No se observan signos de alarma inmediatos. Se recomiendan controles periodicos.';
    }

    if (normalized.contains('malignant lesion suspected') ||
        normalized.contains('immediate medical attention required') ||
        normalized.contains('consult a specialist immediately')) {
      return 'Se recomienda derivacion o evaluacion por especialista lo antes posible.';
    }

    return recommendation.trim();
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
    await ref
        .read(predictionViewModelProvider.notifier)
        .predictImage(
          widget.imageFile,
          patientId: state.patientId,
          patientName: state.patientName,
          consentToStore: true,
        );
  }

  void _goToNewAnalysis() {
    ref.read(predictionViewModelProvider.notifier).clearResult();
    Navigator.pop(context);
  }

  void _goToHistory() {
    ref.read(predictionViewModelProvider.notifier).clearResult();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeView(initialIndex: 2)),
      (route) => false,
    );
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AnalyzedImageCard(imageFile: widget.imageFile, compact: true),
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _goToNewAnalysis,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Otra imagen'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _retryAnalysis(viewModel),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ),
                  ],
                ),
              ],
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
    final confidenceAccent = _getConfidenceAccent(result.confidence);
    final confidenceMessage = _getConfidenceMessage(
      result.confidence,
      result.prediction,
    );
    final translatedRecommendation = _translateRecommendation(
      result.recommendation,
    );
    final orderedProbabilities = _orderedProbabilities(result.probabilities);

    return Scaffold(
      appBar: const AppAppBar(title: 'Resultado del análisis'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AnalyzedImageCard(imageFile: widget.imageFile),
            const SizedBox(height: 16),
            Card(
              color: color.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: color.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, size: 64, color: color),
                    const SizedBox(height: 16),
                    if (viewModel.patientName != null ||
                        viewModel.patientId != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              [
                                if (viewModel.patientName != null)
                                  viewModel.patientName!,
                                if (viewModel.patientId != null)
                                  'ID: ${viewModel.patientId!}',
                              ].join(' · '),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text(
                      'Clasificacion estimada',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      clinicalHeadline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Confianza: ${(result.confidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 18),
                    ),
                    if (result.processingTimeMs != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tiempo de inferencia: ${_formatProcessingTime(result.processingTimeMs!)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: confidenceAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Nivel de confianza: $confidenceLevel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: confidenceAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: result.confidence,
                      backgroundColor: AppColors.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      borderRadius: BorderRadius.circular(999),
                      minHeight: 10,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      confidenceMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: AppColors.surfaceContainerLowest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recomendación clínica inicial',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      translatedRecommendation,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: AppColors.surfaceContainerLowest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Probabilidades detalladas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...orderedProbabilities.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                _getDisplayLabel(entry.key).toUpperCase(),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: entry.value ?? 0,
                                backgroundColor:
                                    AppColors.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getPredictionColor(entry.key),
                                ),
                                borderRadius: BorderRadius.circular(999),
                                minHeight: 10,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 56,
                              child: Text(
                                entry.value == null
                                    ? 'N/D'
                                    : '${(entry.value! * 100).toStringAsFixed(1)}%',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                        'Este resultado es una estimacion asistida por IA y no reemplaza una evaluacion clinica profesional.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
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
              onRetry: () => _retryAnalysis(viewModel),
              onHistory: _goToHistory,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultActions extends StatelessWidget {
  final VoidCallback onNewAnalysis;
  final VoidCallback onHistory;
  final Future<void> Function() onRetry;

  const _ResultActions({
    required this.onNewAnalysis,
    required this.onRetry,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: onNewAnalysis,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Nuevo analisis'),
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
  final bool compact;

  const _AnalyzedImageCard({required this.imageFile, this.compact = false});

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
            const Text(
              'Imagen analizada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                imageFile,
                height: compact ? 120 : 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
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
                  title: 'Comparando con base de datos clinica',
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
