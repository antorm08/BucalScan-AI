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
    final rawProbabilities = json['probabilities'];

    return PredictionResultModel(
      prediction:
          (json['prediction'] ?? json['class'] ?? json['label'] ?? 'unknown')
              .toString(),
      confidence:
          ((json['confidence'] ?? json['score'] ?? json['probability'] ?? 0)
                  as num)
              .toDouble(),
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
