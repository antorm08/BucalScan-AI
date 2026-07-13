import 'package:bucalscan_ai/core/constants/app_constants.dart';
import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/domain/repositories/clinical_repository.dart';
import 'package:bucalscan_ai/features/clinical/data/models/clinical_models.dart';

class ClinicalRepositoryImpl implements ClinicalRepository {
  final ApiService _api;
  const ClinicalRepositoryImpl(this._api);

  @override
  void setActiveWorkspace(String? workspaceId) {
    _api.setActiveWorkspace(workspaceId);
  }

  @override
  Future<List<ClinicalWorkspace>> getMemberships() async => (await _api.getList(
    ClinicalEndpoints.memberships,
  )).map(_workspace).toList();

  @override
  Future<List<ClinicalWorkspace>> discoverWorkspaces(String query) async =>
      (await _api.getList(
        ClinicalEndpoints.workspaces,
        query: {'q': query},
      )).map(_workspace).toList();

  @override
  Future<List<Patient>> searchPatients(String query) async =>
      (await _api.getList(
        ClinicalEndpoints.patients,
        query: {'q': query},
        workspaceScoped: true,
      )).map((json) => PatientModel.fromJson(json).toEntity()).toList();

  @override
  Future<Patient> getPatient(String patientId) async => PatientModel.fromJson(
    await _api.getJson(
      ClinicalEndpoints.patient(patientId),
      workspaceScoped: true,
    ),
  ).toEntity();

  @override
  Future<Patient> createPatient({
    required String clinicalCode,
    required String fullName,
    String? identityDocument,
  }) async => PatientModel.fromJson(
    await _api.postJson(ClinicalEndpoints.patients, {
      'clinical_code': clinicalCode,
      'full_name': fullName,
      if (identityDocument?.isNotEmpty ?? false)
        'identity_document': identityDocument,
    }, workspaceScoped: true),
  ).toEntity();

  @override
  Future<List<OralLesion>> getLesions(String patientId) async =>
      (await _api.getList(
        ClinicalEndpoints.patientLesions(patientId),
        workspaceScoped: true,
      )).map((json) => OralLesionModel.fromJson(json).toEntity()).toList();

  @override
  Future<LesionDetail> getLesionDetail(String lesionId) async =>
      LesionDetailModel.fromJson(
        await _api.getJson(
          ClinicalEndpoints.lesion(lesionId),
          workspaceScoped: true,
        ),
      ).toEntity();

  @override
  Future<OralLesion> createLesion({
    required String patientId,
    required String anatomicalSite,
    DateTime? observedAt,
    String? estimatedDuration,
    String? notes,
  }) async => OralLesionModel.fromJson(
    await _api.postJson(ClinicalEndpoints.patientLesions(patientId), {
      'anatomical_site': anatomicalSite,
      if (observedAt != null)
        'observed_at': observedAt.toIso8601String().split('T').first,
      if (estimatedDuration?.isNotEmpty == true)
        'estimated_duration': estimatedDuration,
      'status': 'active',
      if (notes?.isNotEmpty ?? false) 'clinical_notes': notes,
    }, workspaceScoped: true),
  ).toEntity();

  @override
  Future<OralLesion> updateLesion({
    required String lesionId,
    required String status,
    String? notes,
    DateTime? observedAt,
    String? estimatedDuration,
  }) async => OralLesionModel.fromJson(
    await _api.patchJson(ClinicalEndpoints.lesion(lesionId), {
      'status': status,
      'clinical_notes': notes,
      if (observedAt != null)
        'observed_at': observedAt.toIso8601String().split('T').first,
      'estimated_duration': estimatedDuration,
    }, workspaceScoped: true),
  ).toEntity();

  ClinicalWorkspace _workspace(Map<String, dynamic> json) {
    final workspace = json['workspace'] is Map
        ? json['workspace'] as Map
        : json;
    final membership = json['membership'] is Map
        ? json['membership'] as Map
        : json;
    final rawMembership =
        '${membership['status'] ?? membership['approval_status'] ?? 'pending'}';
    return ClinicalWorkspace(
      id: '${workspace['id']}',
      name: '${workspace['name'] ?? 'Espacio clinico'}',
      type: '${workspace['workspace_type'] ?? workspace['type'] ?? 'clinic'}',
      status: '${workspace['status'] ?? 'active'}',
      membershipStatus: MembershipStatus.values.firstWhere(
        (value) => value.name == rawMembership,
        orElse: () => MembershipStatus.pending,
      ),
      role: membership['role']?.toString(),
    );
  }
}
