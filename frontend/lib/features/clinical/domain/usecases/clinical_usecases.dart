import 'dart:typed_data';

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

class GetPatientUseCase {
  final ClinicalRepository _repository;
  const GetPatientUseCase(this._repository);

  Future<Patient> call(String patientId) => _repository.getPatient(patientId);
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
    DateTime? observedAt,
    String? estimatedDuration,
    String? notes,
  }) => _repository.createLesion(
    patientId: patientId,
    anatomicalSite: anatomicalSite,
    observedAt: observedAt,
    estimatedDuration: estimatedDuration,
    notes: notes,
  );
}

class GetLesionDetailUseCase {
  final ClinicalRepository _repository;
  const GetLesionDetailUseCase(this._repository);

  Future<LesionDetail> call(String lesionId) =>
      _repository.getLesionDetail(lesionId);
}

class UpdateLesionUseCase {
  final ClinicalRepository _repository;
  const UpdateLesionUseCase(this._repository);

  Future<OralLesion> call({
    required String lesionId,
    required String status,
    String? notes,
    DateTime? observedAt,
    String? estimatedDuration,
  }) => _repository.updateLesion(
    lesionId: lesionId,
    status: status,
    notes: notes,
    observedAt: observedAt,
    estimatedDuration: estimatedDuration,
  );
}

class ExportEvaluationPdfUseCase {
  final ClinicalRepository _repository;
  const ExportEvaluationPdfUseCase(this._repository);

  Future<Uint8List> call({
    required String lesionId,
    required String evaluationId,
  }) => _repository.exportEvaluationPdf(
    lesionId: lesionId,
    evaluationId: evaluationId,
  );
}
