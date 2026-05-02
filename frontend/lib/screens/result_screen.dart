import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oral_lesion_detector/providers/prediction_provider.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  Color _getPredictionColor(String prediction) {
    switch (prediction.toLowerCase()) {
      case 'benign':
        return Colors.green;
      case 'opmd':
        return Colors.orange;
      case 'malignant':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPredictionIcon(String prediction) {
    switch (prediction.toLowerCase()) {
      case 'benign':
        return Icons.check_circle;
      case 'opmd':
        return Icons.warning;
      case 'malignant':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PredictionProvider>();
    final result = provider.lastResult;

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing image...'),
            ],
          ),
        ),
      );
    }

    if (provider.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('No result available')),
      );
    }

    final color = _getPredictionColor(result.prediction);
    final icon = _getPredictionIcon(result.prediction);

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: color.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(icon, size: 64, color: color),
                    const SizedBox(height: 16),
                    Text(
                      result.prediction.toUpperCase(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
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
                      'Recommendation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                        'Detailed Probabilities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                                  entry.key.toUpperCase(),
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
                provider.clearResult();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
