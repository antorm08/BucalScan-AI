import 'package:bucalscan_ai/core/constants/app_constants.dart';
import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/domain/repositories/clinical_repository.dart';

class ClinicalRepositoryImpl implements ClinicalRepository {
  final ApiService _api;
  const ClinicalRepositoryImpl(this._api);

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
      )).map(_patient).toList();

  @override
  Future<Patient> createPatient({
    required String clinicalCode,
    required String fullName,
    String? identityDocument,
  }) async => _patient(
    await _api.postJson(ClinicalEndpoints.patients, {
      'clinical_code': clinicalCode,
      'full_name': fullName,
      if (identityDocument?.isNotEmpty ?? false)
        'identity_document': identityDocument,
    }, workspaceScoped: true),
  );

  @override
  Future<List<OralLesion>> getLesions(String patientId) async =>
      (await _api.getList(
        ClinicalEndpoints.patientLesions(patientId),
        workspaceScoped: true,
      )).map(_lesion).toList();

  @override
  Future<OralLesion> createLesion({
    required String patientId,
    required String anatomicalSite,
    required String temporalDescription,
    String? notes,
  }) async => _lesion(
    await _api.postJson(ClinicalEndpoints.patientLesions(patientId), {
      'anatomical_site': anatomicalSite,
      'estimated_duration': temporalDescription,
      'status': 'active',
      if (notes?.isNotEmpty ?? false) 'clinical_notes': notes,
    }, workspaceScoped: true),
  );

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

  Patient _patient(Map<String, dynamic> json) => Patient(
    id: '${json['id']}',
    clinicalCode: '${json['clinical_code'] ?? json['code']}',
    fullName: '${json['full_name'] ?? json['name']}',
    identityDocument: json['identity_document']?.toString(),
  );

  OralLesion _lesion(Map<String, dynamic> json) => OralLesion(
    id: '${json['id']}',
    anatomicalSite: '${json['anatomical_site'] ?? json['site']}',
    status: '${json['status'] ?? 'active'}',
    temporalDescription:
        '${json['temporal_description'] ?? json['estimated_duration'] ?? json['initial_observation_date'] ?? ''}',
    notes: json['clinical_notes']?.toString(),
  );
}
