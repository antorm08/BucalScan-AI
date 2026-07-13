enum MembershipStatus { pending, active, rejected, inactive }

class ClinicalWorkspace {
  final String id;
  final String name;
  final String type;
  final String status;
  final MembershipStatus membershipStatus;
  final String? role;

  const ClinicalWorkspace({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.membershipStatus,
    this.role,
  });

  bool get canEnter =>
      status == 'active' && membershipStatus == MembershipStatus.active;
}

class Patient {
  final String id;
  final String? workspaceId;
  final String clinicalCode;
  final String fullName;
  final String? identityDocument;
  final DateTime? birthDate;
  final String? sex;
  final String? telephone;
  final String? email;
  final String? notes;
  final DateTime? createdAt;

  const Patient({
    required this.id,
    required this.clinicalCode,
    required this.fullName,
    this.workspaceId,
    this.identityDocument,
    this.birthDate,
    this.sex,
    this.telephone,
    this.email,
    this.notes,
    this.createdAt,
  });
}

class OralLesion {
  final String id;
  final String? patientId;
  final String anatomicalSite;
  final String status;
  final String temporalDescription;
  final String? notes;
  final DateTime? observedAt;
  final DateTime? createdAt;

  const OralLesion({
    required this.id,
    required this.anatomicalSite,
    required this.status,
    required this.temporalDescription,
    this.patientId,
    this.notes,
    this.observedAt,
    this.createdAt,
  });
}

class ClinicalProfessional {
  final String id;
  final String fullName;
  final String doctorId;
  final String? profession;
  final String? specialty;

  const ClinicalProfessional({
    required this.id,
    required this.fullName,
    required this.doctorId,
    this.profession,
    this.specialty,
  });
}

class EvaluationImage {
  final String id;
  final String url;
  final String? contentType;
  final String? originalFilename;
  final DateTime createdAt;

  const EvaluationImage({
    required this.id,
    required this.url,
    required this.createdAt,
    this.contentType,
    this.originalFilename,
  });
}

class EvaluationPrediction {
  final String id;
  final String label;
  final double confidence;
  final Map<String, double> probabilities;
  final String modelVersion;
  final double? processingTimeMs;
  final DateTime createdAt;

  const EvaluationPrediction({
    required this.id,
    required this.label,
    required this.confidence,
    required this.probabilities,
    required this.modelVersion,
    required this.createdAt,
    this.processingTimeMs,
  });
}

class LesionEvaluation {
  final String id;
  final DateTime evaluatedAt;
  final DateTime createdAt;
  final String? clinicalObservations;
  final ClinicalProfessional professional;
  final EvaluationImage? image;
  final EvaluationPrediction? prediction;
  final DateTime? consentAttestedAt;

  const LesionEvaluation({
    required this.id,
    required this.evaluatedAt,
    required this.createdAt,
    required this.professional,
    this.clinicalObservations,
    this.image,
    this.prediction,
    this.consentAttestedAt,
  });
}

class LesionDetail {
  final OralLesion lesion;
  final List<LesionEvaluation> evaluations;

  const LesionDetail({required this.lesion, required this.evaluations});
}
