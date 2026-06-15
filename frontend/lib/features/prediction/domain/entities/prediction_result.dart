class PredictionResult {
  final String prediction;
  final double confidence;
  final String recommendation;
  final Map<String, double>? probabilities;

  const PredictionResult({
    required this.prediction,
    required this.confidence,
    required this.recommendation,
    this.probabilities,
  });
}
