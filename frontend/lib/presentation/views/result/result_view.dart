import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/presentation/viewmodels/prediction_viewmodel.dart';
import 'package:bucalscan_ai/presentation/widgets/app_app_bar.dart';

class ResultView extends StatelessWidget {
  const ResultView({super.key});

  Color _getPredictionColor(String prediction) {
    switch (prediction.toLowerCase()) {
      case 'benign':
        return Colors.green;
      case 'malignant':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData _getPredictionIcon(String prediction) {
    switch (prediction.toLowerCase()) {
      case 'benign':
        return Icons.check_circle;
      case 'malignant':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getDisplayLabel(String prediction) {
    switch (prediction.toLowerCase()) {
      case 'benign':
        return 'Benigno';
      case 'malignant':
        return 'Maligno';
      default:
        return prediction;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PredictionViewModel>();
    final result = viewModel.result;

    if (viewModel.isLoading) {
      return const Scaffold(
        appBar: AppAppBar(title: 'Resultado del análisis'),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Analizando imagen...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'BucalScan AI está procesando la captura para generar el resultado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
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
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  viewModel.error!,
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

    return Scaffold(
      appBar: const AppAppBar(title: 'Resultado del análisis'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: color.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(icon, size: 64, color: color),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: result.confidence,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
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
                      result.recommendation,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            if (result.probabilities != null) ...[
              const SizedBox(height: 16),
              Card(
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
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getPredictionColor(entry.key),
                                  ),
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
