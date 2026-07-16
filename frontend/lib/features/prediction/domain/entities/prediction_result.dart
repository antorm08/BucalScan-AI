import 'package:bucalscan_ai/features/priority/domain/entities/clinical_priority.dart';

class PredictionResult {
  final String prediction;
  final double confidence;
  final String recommendation;
  final Map<String, double>? probabilities;
  final double? processingTimeMs;
  final String? modelVersion;
  final String? evaluationId;
  final String? heatmapUrl;
  final ClinicalPriorityResult? priority;

  const PredictionResult({
    required this.prediction,
    required this.confidence,
    required this.recommendation,
    this.probabilities,
    this.processingTimeMs,
    this.modelVersion,
    this.evaluationId,
    this.heatmapUrl,
    this.priority,
  });
}
