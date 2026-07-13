import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';
import 'package:bucalscan_ai/features/priority/data/models/clinical_priority_models.dart';
import 'package:bucalscan_ai/features/priority/domain/entities/clinical_priority.dart';

class AnalysisModel {
  final int id;
  final String prediction;
  final double confidence;
  final String timestamp;
  final String? imageUrl;
  final String? patientId;
  final String? patientName;
  final String? modelVersion;
  final double? processingTimeMs;
  final int? createdById;
  final String? createdByName;
  final String? createdByEmail;
  final String? createdByDoctorId;
  final int? evaluationId;
  final int? patientRecordId;
  final int? lesionId;
  final String? lesionSite;
  final String? evaluatedAt;
  final String? clinicalObservations;
  final int? professionalId;
  final String? professionalName;
  final String? professionalDoctorId;
  final String? professionalProfession;
  final String? professionalSpecialty;
  final ClinicalPriorityResult? priority;

  const AnalysisModel({
    required this.id,
    required this.prediction,
    required this.confidence,
    required this.timestamp,
    this.imageUrl,
    this.patientId,
    this.patientName,
    this.modelVersion,
    this.processingTimeMs,
    this.createdById,
    this.createdByName,
    this.createdByEmail,
    this.createdByDoctorId,
    this.evaluationId,
    this.patientRecordId,
    this.lesionId,
    this.lesionSite,
    this.evaluatedAt,
    this.clinicalObservations,
    this.professionalId,
    this.professionalName,
    this.professionalDoctorId,
    this.professionalProfession,
    this.professionalSpecialty,
    this.priority,
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
      modelVersion: json['model_version'] as String?,
      processingTimeMs: json['processing_time_ms'] is num
          ? (json['processing_time_ms'] as num).toDouble()
          : null,
      createdById: json['created_by_id'] as int?,
      createdByName: json['created_by_name'] as String?,
      createdByEmail: json['created_by_email'] as String?,
      createdByDoctorId: json['created_by_doctor_id'] as String?,
      evaluationId: json['evaluation_id'] as int?,
      patientRecordId: json['patient_record_id'] as int?,
      lesionId: json['lesion_id'] as int?,
      lesionSite: json['lesion_site'] as String?,
      evaluatedAt: json['evaluated_at'] as String?,
      clinicalObservations: json['clinical_observations'] as String?,
      professionalId: json['professional_id'] as int?,
      professionalName: json['professional_name'] as String?,
      professionalDoctorId: json['professional_doctor_id'] as String?,
      professionalProfession: json['professional_profession'] as String?,
      professionalSpecialty: json['professional_specialty'] as String?,
      priority: ClinicalPriorityResultModel.fromJson(json['priority']),
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
      modelVersion: modelVersion,
      processingTimeMs: processingTimeMs,
      createdById: createdById,
      createdByName: createdByName,
      createdByEmail: createdByEmail,
      createdByDoctorId: createdByDoctorId,
      evaluationId: evaluationId,
      patientRecordId: patientRecordId,
      lesionId: lesionId,
      lesionSite: lesionSite,
      evaluatedAt: evaluatedAt == null ? null : DateTime.tryParse(evaluatedAt!),
      clinicalObservations: clinicalObservations,
      professionalId: professionalId,
      professionalName: professionalName,
      professionalDoctorId: professionalDoctorId,
      professionalProfession: professionalProfession,
      professionalSpecialty: professionalSpecialty,
      priority: priority,
    );
  }
}
