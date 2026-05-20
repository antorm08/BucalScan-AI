class PredictionResultModel {
  final String prediction;
  final double confidence;
  final String recommendation;
  final Map<String, double>? probabilities;

  PredictionResultModel({
    required this.prediction,
    required this.confidence,
    required this.recommendation,
    this.probabilities,
  });

  factory PredictionResultModel.fromJson(Map<String, dynamic> json) {
    final rawPrediction = json['prediction'] ?? json['class'] ?? json['label'];
    final rawConfidence = json['confidence'] ?? json['score'] ?? json['probability'];

    if (rawPrediction == null || rawConfidence == null) {
      throw const FormatException('incomplete_prediction_response');
    }

    final prediction = rawPrediction.toString().trim();
    if (prediction.isEmpty) {
      throw const FormatException('incomplete_prediction_response');
    }

    if (rawConfidence is! num) {
      throw const FormatException('incomplete_prediction_response');
    }

    final rawProbabilities = json['probabilities'];

    return PredictionResultModel(
      prediction: prediction,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prediction': prediction,
      'confidence': confidence,
      'recommendation': recommendation,
      'probabilities': probabilities,
    };
  }
}
