import '../entities/clinical_entities.dart';
import '../repositories/clinical_repository.dart';

class GetMembershipsUseCase {
  final ClinicalRepository _repository;
  const GetMembershipsUseCase(this._repository);

  Future<List<ClinicalWorkspace>> call() => _repository.getMemberships();
}

class DiscoverWorkspacesUseCase {
  final ClinicalRepository _repository;
  const DiscoverWorkspacesUseCase(this._repository);

  Future<List<ClinicalWorkspace>> call(String query) =>
      _repository.discoverWorkspaces(query);
}

class SelectWorkspaceUseCase {
  final ClinicalRepository _repository;
  const SelectWorkspaceUseCase(this._repository);

  void call(String? workspaceId) => _repository.setActiveWorkspace(workspaceId);
}

class SearchPatientsUseCase {
  final ClinicalRepository _repository;
  const SearchPatientsUseCase(this._repository);

  Future<List<Patient>> call(String query) => _repository.searchPatients(query);
}

class CreatePatientUseCase {
  final ClinicalRepository _repository;
  const CreatePatientUseCase(this._repository);

  Future<Patient> call({
    required String clinicalCode,
    required String fullName,
    String? identityDocument,
  }) => _repository.createPatient(
    clinicalCode: clinicalCode,
    fullName: fullName,
    identityDocument: identityDocument,
  );
}

class GetLesionsUseCase {
  final ClinicalRepository _repository;
  const GetLesionsUseCase(this._repository);

  Future<List<OralLesion>> call(String patientId) =>
      _repository.getLesions(patientId);
}

class CreateLesionUseCase {
  final ClinicalRepository _repository;
  const CreateLesionUseCase(this._repository);

  Future<OralLesion> call({
    required String patientId,
    required String anatomicalSite,
    required String temporalDescription,
    String? notes,
  }) => _repository.createLesion(
    patientId: patientId,
    anatomicalSite: anatomicalSite,
    temporalDescription: temporalDescription,
    notes: notes,
  );
}
