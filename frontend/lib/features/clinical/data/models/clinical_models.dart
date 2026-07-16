import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/priority/data/models/clinical_priority_models.dart';

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());

class PatientModel {
  final Patient value;

  const PatientModel(this.value);

  factory PatientModel.fromJson(Map<String, dynamic> json) => PatientModel(
    Patient(
      id: '${json['id']}',
      workspaceId: json['workspace_id']?.toString(),
      clinicalCode: '${json['clinical_code'] ?? json['code'] ?? ''}',
      fullName: '${json['full_name'] ?? json['name'] ?? ''}',
      identityDocument: json['identity_document']?.toString(),
      birthDate: _date(json['birth_date']),
      sex: json['sex']?.toString(),
      telephone: json['telephone']?.toString(),
      email: json['email']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: _date(json['created_at']),
    ),
  );

  Patient toEntity() => value;
}

class OralLesionModel {
  final OralLesion value;

  const OralLesionModel(this.value);

  factory OralLesionModel.fromJson(Map<String, dynamic> json) {
    final observedAt = _date(json['observed_at']);
    return OralLesionModel(
      OralLesion(
        id: '${json['id']}',
        patientId: json['patient_id']?.toString(),
        anatomicalSite: '${json['anatomical_site'] ?? json['site'] ?? ''}',
        status: '${json['status'] ?? 'active'}',
        estimatedDuration:
            (json['estimated_duration'] ?? json['temporal_description'])
                ?.toString(),
        notes: json['clinical_notes']?.toString(),
        observedAt: observedAt,
        createdAt: _date(json['created_at']),
      ),
    );
  }

  OralLesion toEntity() => value;
}

class LesionDetailModel {
  final LesionDetail value;

  const LesionDetailModel(this.value);

  factory LesionDetailModel.fromJson(Map<String, dynamic> json) {
    final lesion = OralLesionModel.fromJson(
      Map<String, dynamic>.from(json['lesion'] as Map),
    ).toEntity();
    final evaluations =
        (json['evaluations'] as List? ?? const [])
            .map((raw) => _evaluation(Map<String, dynamic>.from(raw as Map)))
            .toList()
          ..sort((a, b) => a.evaluatedAt.compareTo(b.evaluatedAt));
    return LesionDetailModel(
      LesionDetail(lesion: lesion, evaluations: evaluations),
    );
  }

  static LesionEvaluation _evaluation(Map<String, dynamic> json) {
    final professional = Map<String, dynamic>.from(json['professional'] as Map);
    final imageJson = json['image'] is Map
        ? Map<String, dynamic>.from(json['image'] as Map)
        : null;
    final predictionJson = json['prediction'] is Map
        ? Map<String, dynamic>.from(json['prediction'] as Map)
        : null;
    return LesionEvaluation(
      id: '${json['id']}',
      evaluatedAt: _date(json['evaluated_at'])!,
      createdAt: _date(json['created_at'])!,
      clinicalObservations: json['clinical_observations']?.toString(),
      professional: ClinicalProfessional(
        id: '${professional['id']}',
        fullName: '${professional['full_name']}',
        doctorId: '${professional['doctor_id']}',
        profession: professional['profession']?.toString(),
        specialty: professional['specialty']?.toString(),
      ),
      image: imageJson == null
          ? null
          : EvaluationImage(
              id: '${imageJson['id']}',
              url: '${imageJson['url']}',
              contentType: imageJson['content_type']?.toString(),
              originalFilename: imageJson['original_filename']?.toString(),
              createdAt: _date(imageJson['created_at'])!,
            ),
      prediction: predictionJson == null
          ? null
          : EvaluationPrediction(
              id: '${predictionJson['id']}',
              label: '${predictionJson['label']}',
              confidence: (predictionJson['confidence'] as num).toDouble(),
              probabilities: (predictionJson['probabilities'] as Map).map(
                (key, value) => MapEntry('$key', (value as num).toDouble()),
              ),
              modelVersion: '${predictionJson['model_version']}',
              processingTimeMs: predictionJson['processing_time_ms'] is num
                  ? (predictionJson['processing_time_ms'] as num).toDouble()
                  : null,
              heatmapUrl: predictionJson['heatmap_url']?.toString(),
              createdAt: _date(predictionJson['created_at'])!,
            ),
      consentAttestedAt: _date(json['consent_attested_at']),
      priority: ClinicalPriorityResultModel.fromJson(json['priority']),
    );
  }

  LesionDetail toEntity() => value;
}
