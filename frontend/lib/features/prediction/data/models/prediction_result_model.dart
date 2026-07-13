import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_result.dart';
import 'package:bucalscan_ai/features/priority/data/models/clinical_priority_models.dart';
import 'package:bucalscan_ai/features/priority/domain/entities/clinical_priority.dart';

class PredictionResultModel {
  final String prediction;
  final double confidence;
  final String recommendation;
  final Map<String, double>? probabilities;
  final double? processingTimeMs;
  final String? modelVersion;
  final String? evaluationId;
  final ClinicalPriorityResult? priority;

  const PredictionResultModel({
    required this.prediction,
    required this.confidence,
    required this.recommendation,
    this.probabilities,
    this.processingTimeMs,
    this.modelVersion,
    this.evaluationId,
    this.priority,
  });

  factory PredictionResultModel.fromJson(Map<String, dynamic> json) {
    final rawPrediction = json['prediction'] ?? json['class'] ?? json['label'];
    final rawConfidence =
        json['confidence'] ?? json['score'] ?? json['probability'];

    if (rawPrediction == null || rawConfidence is! num) {
      throw const FormatException('incomplete_prediction_response');
    }

    final rawProbabilities = json['probabilities'];
    final rawProcessingTime = json['processing_time_ms'];

    return PredictionResultModel(
      prediction: rawPrediction.toString().trim(),
      confidence: rawConfidence.toDouble(),
      recommendation:
          (json['recommendation'] ??
                  json['message'] ??
                  'Consulte el resultado con un profesional de salud para una evaluacion clinica completa.')
              .toString(),
      probabilities: rawProbabilities is Map
          ? Map<String, double>.from(
              rawProbabilities.map(
                (key, value) =>
                    MapEntry(key.toString(), (value as num).toDouble()),
              ),
            )
          : null,
      processingTimeMs: rawProcessingTime is num
          ? rawProcessingTime.toDouble()
          : null,
      modelVersion: json['model_version']?.toString(),
      evaluationId: json['evaluation_id']?.toString(),
      priority: ClinicalPriorityResultModel.fromJson(json['priority']),
    );
  }

  PredictionResult toEntity() {
    return PredictionResult(
      prediction: prediction,
      confidence: confidence,
      recommendation: recommendation,
      probabilities: probabilities,
      processingTimeMs: processingTimeMs,
      modelVersion: modelVersion,
      evaluationId: evaluationId,
      priority: priority,
    );
  }
}
