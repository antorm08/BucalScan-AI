import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';

class AnalysisModel {
  final int id;
  final String prediction;
  final double confidence;
  final String timestamp;
  final String? imageUrl;
  final String? patientId;
  final String? patientName;

  const AnalysisModel({
    required this.id,
    required this.prediction,
    required this.confidence,
    required this.timestamp,
    this.imageUrl,
    this.patientId,
    this.patientName,
  });

  factory AnalysisModel.fromJson(Map<String, dynamic> json) {
    return AnalysisModel(
      id: json['id'] as int,
      prediction: json['prediction'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
      imageUrl: json['image_url'] as String?,
      patientId: json['patient_id'] as String?,
      patientName: json['patient_name'] as String?,
    );
  }

  Analysis toEntity() {
    final parsedTimestamp = DateTime.tryParse(timestamp) ?? DateTime.now();
    return Analysis(
      id: id,
      prediction: prediction,
      confidence: confidence,
      timestamp: parsedTimestamp,
      imageUrl: imageUrl,
      patientId: patientId,
      patientName: patientName,
    );
  }
}
