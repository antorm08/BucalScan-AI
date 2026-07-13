import 'package:bucalscan_ai/features/priority/domain/entities/clinical_priority.dart';

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
  final int? createdById;
  final String? createdByName;
  final String? createdByEmail;
  final String? createdByDoctorId;
  final int? evaluationId;
  final int? patientRecordId;
  final int? lesionId;
  final String? lesionSite;
  final DateTime? evaluatedAt;
  final String? clinicalObservations;
  final int? professionalId;
  final String? professionalName;
  final String? professionalDoctorId;
  final String? professionalProfession;
  final String? professionalSpecialty;
  final ClinicalPriorityResult? priority;

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
}
