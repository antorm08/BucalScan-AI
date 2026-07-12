import '../entities/clinical_entities.dart';

abstract class ClinicalRepository {
  Future<List<ClinicalWorkspace>> getMemberships();
  Future<List<ClinicalWorkspace>> discoverWorkspaces(String query);
  Future<List<Patient>> searchPatients(String query);
  Future<Patient> createPatient({
    required String clinicalCode,
    required String fullName,
    String? identityDocument,
  });
  Future<List<OralLesion>> getLesions(String patientId);
  Future<OralLesion> createLesion({
    required String patientId,
    required String anatomicalSite,
    required String temporalDescription,
    String? notes,
  });
}
