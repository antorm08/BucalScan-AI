import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_result.dart';

class PredictionResultModel {
  final String prediction;
  final double confidence;
  final String recommendation;
  final Map<String, double>? probabilities;

  const PredictionResultModel({
    required this.prediction,
    required this.confidence,
    required this.recommendation,
    this.probabilities,
  });

  factory PredictionResultModel.fromJson(Map<String, dynamic> json) {
    final rawPrediction = json['prediction'] ?? json['class'] ?? json['label'];
    final rawConfidence = json['confidence'] ?? json['score'] ?? json['probability'];

    if (rawPrediction == null || rawConfidence is! num) {
      throw const FormatException('incomplete_prediction_response');
    }

    final rawProbabilities = json['probabilities'];

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
                (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
              ),
            )
          : null,
    );
  }

  PredictionResult toEntity() {
    return PredictionResult(
      prediction: prediction,
      confidence: confidence,
      recommendation: recommendation,
      probabilities: probabilities,
    );
  }
}
