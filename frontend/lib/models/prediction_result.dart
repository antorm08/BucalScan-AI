class PredictionResult {
  final String prediction;
  final double confidence;
  final String recommendation;
  final Map<String, double>? probabilities;
  final DateTime timestamp;

  PredictionResult({
    required this.prediction,
    required this.confidence,
    required this.recommendation,
    this.probabilities,
    required this.timestamp,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      prediction: json['prediction'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      recommendation: json['recommendation'] as String,
      probabilities: json['probabilities'] != null
          ? Map<String, double>.from(
              json['probabilities'].map((k, v) => MapEntry(k, (v as num).toDouble())))
          : null,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prediction': prediction,
      'confidence': confidence,
      'recommendation': recommendation,
      'probabilities': probabilities,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
