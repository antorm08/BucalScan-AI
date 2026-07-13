import '../entities/clinical_entities.dart';

abstract class ClinicalRepository {
  void setActiveWorkspace(String? workspaceId);
  Future<List<ClinicalWorkspace>> getMemberships();
  Future<List<ClinicalWorkspace>> discoverWorkspaces(String query);
  Future<List<Patient>> searchPatients(String query);
  Future<Patient> getPatient(String patientId) =>
      throw UnimplementedError('Patient detail is not implemented.');
  Future<Patient> createPatient({
    required String clinicalCode,
    required String fullName,
    String? identityDocument,
  });
  Future<List<OralLesion>> getLesions(String patientId);
  Future<LesionDetail> getLesionDetail(String lesionId) =>
      throw UnimplementedError('Lesion detail is not implemented.');
  Future<OralLesion> createLesion({
    required String patientId,
    required String anatomicalSite,
    DateTime? observedAt,
    String? estimatedDuration,
    String? notes,
  });
  Future<OralLesion> updateLesion({
    required String lesionId,
    required String status,
    String? notes,
    DateTime? observedAt,
    String? estimatedDuration,
  }) => throw UnimplementedError('Lesion update is not implemented.');
}
