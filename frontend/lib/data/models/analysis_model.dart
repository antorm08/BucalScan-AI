class AnalysisModel {
  final int id;
  final String prediction;
  final double confidence;
  final String timestamp;
  final String? imageUrl;

  AnalysisModel({
    required this.id,
    required this.prediction,
    required this.confidence,
    required this.timestamp,
    this.imageUrl,
  });

  factory AnalysisModel.fromJson(Map<String, dynamic> json) {
    return AnalysisModel(
      id: json['id'] as int,
      prediction: json['prediction'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prediction': prediction,
      'confidence': confidence,
      'timestamp': timestamp,
      'image_url': imageUrl,
    };
  }
}
