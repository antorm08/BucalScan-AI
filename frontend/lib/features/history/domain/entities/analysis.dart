class Analysis {
  final int id;
  final String prediction;
  final double confidence;
  final DateTime timestamp;
  final String? imageUrl;
  final String? patientId;
  final String? patientName;
  final String? modelVersion;
  final double? processingTimeMs;

  const Analysis({
    required this.id,
    required this.prediction,
    required this.confidence,
    required this.timestamp,
    this.imageUrl,
    this.patientId,
    this.patientName,
    this.modelVersion,
    this.processingTimeMs,
  });
}
