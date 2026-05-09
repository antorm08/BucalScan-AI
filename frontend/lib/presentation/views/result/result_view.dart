import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/presentation/viewmodels/prediction_viewmodel.dart';
import 'package:bucalscan_ai/presentation/widgets/app_app_bar.dart';

class ResultView extends StatelessWidget {
  final File imageFile;

  const ResultView({super.key, required this.imageFile});

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

  String _translateRecommendation(String recommendation) {
    final normalized = recommendation.trim().toLowerCase();

    if (normalized.contains('no immediate concern') ||
        normalized.contains('regular check-ups recommended')) {
      return 'No se observan signos de alarma inmediatos. Se recomiendan controles periodicos.';
    }

    if (normalized.contains('malignant lesion suspected') ||
        normalized.contains('immediate medical attention required')) {
      return 'Se sospecha lesion maligna. Se recomienda atencion medica inmediata.';
    }

    return recommendation.trim();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PredictionViewModel>();
    final result = viewModel.result;

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
      return Scaffold(
        appBar: const AppAppBar(title: 'Error en el análisis'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AnalyzedImageCard(imageFile: imageFile, compact: true),
                const SizedBox(height: 24),
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  viewModel.error!.replaceFirst('Exception: ', ''),
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
                ElevatedButton(
                  onPressed: () {
                    viewModel.clearResult();
                    Navigator.pop(context);
                  },
                  child: const Text('Volver a captura'),
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
    final confidenceLevel = _getConfidenceLevel(result.confidence);
    final confidenceAccent = _getConfidenceAccent(result.confidence);
    final confidenceMessage = _getConfidenceMessage(
      result.confidence,
      result.prediction,
    );
    final translatedRecommendation = _translateRecommendation(
      result.recommendation,
    );

    return Scaffold(
      appBar: const AppAppBar(title: 'Resultado del análisis'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AnalyzedImageCard(imageFile: imageFile),
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
                    const Text(
                      'Resultado principal',
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
                      'Confianza: ${(result.confidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 18),
                    ),
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
            if (result.probabilities != null) ...[
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
                      ...result.probabilities!.entries.map(
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
                                  value: entry.value,
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
                              Text(
                                '${(entry.value * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                viewModel.clearResult();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver a captura'),
            ),
          ],
        ),
      ),
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
