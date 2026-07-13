import 'package:bucalscan_ai/features/clinical/di/clinical_providers.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/clinical_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FollowUpStatus { initial, loading, data, empty, error }

enum FollowUpActionStatus { idle, updating, success, error }

class PatientFollowUpState {
  final FollowUpStatus status;
  final FollowUpActionStatus actionStatus;
  final List<Patient> patients;
  final Patient? patient;
  final List<OralLesion> lesions;
  final LesionDetail? lesionDetail;
  final String? error;
  final String? actionError;

  const PatientFollowUpState({
    this.status = FollowUpStatus.initial,
    this.actionStatus = FollowUpActionStatus.idle,
    this.patients = const [],
    this.patient,
    this.lesions = const [],
    this.lesionDetail,
    this.error,
    this.actionError,
  });

  PatientFollowUpState copyWith({
    FollowUpStatus? status,
    FollowUpActionStatus? actionStatus,
    List<Patient>? patients,
    Patient? patient,
    List<OralLesion>? lesions,
    LesionDetail? lesionDetail,
    String? error,
    String? actionError,
    bool clearDetail = false,
    bool clearError = false,
    bool clearActionError = false,
  }) => PatientFollowUpState(
    status: status ?? this.status,
    actionStatus: actionStatus ?? this.actionStatus,
    patients: patients ?? this.patients,
    patient: patient ?? this.patient,
    lesions: lesions ?? this.lesions,
    lesionDetail: clearDetail ? null : lesionDetail ?? this.lesionDetail,
    error: clearError ? null : error ?? this.error,
    actionError: clearActionError ? null : actionError ?? this.actionError,
  );
}

class PatientFollowUpController extends Notifier<PatientFollowUpState> {
  int _generation = 0;

  @override
  PatientFollowUpState build() => const PatientFollowUpState();

  String? get _workspaceId =>
      ref.read(clinicalControllerProvider).activeWorkspace?.id;

  bool _isCurrent(int generation, String? workspaceId) =>
      generation == _generation && workspaceId == _workspaceId;

  Future<void> searchPatients([String query = '']) async {
    final generation = ++_generation;
    final workspaceId = _workspaceId;
    state = state.copyWith(status: FollowUpStatus.loading, clearError: true);
    try {
      final patients = await ref.read(searchPatientsUseCaseProvider)(query);
      if (!_isCurrent(generation, workspaceId)) return;
      state = PatientFollowUpState(
        status: patients.isEmpty ? FollowUpStatus.empty : FollowUpStatus.data,
        patients: patients,
      );
    } catch (_) {
      if (!_isCurrent(generation, workspaceId)) return;
      state = state.copyWith(
        status: FollowUpStatus.error,
        error: 'No se pudieron cargar los pacientes.',
      );
    }
  }

  Future<void> loadPatient(String patientId) async {
    final generation = ++_generation;
    final workspaceId = _workspaceId;
    state = state.copyWith(
      status: FollowUpStatus.loading,
      clearDetail: true,
      clearError: true,
    );
    try {
      final values = await Future.wait([
        ref.read(getPatientUseCaseProvider)(patientId),
        ref.read(getLesionsUseCaseProvider)(patientId),
      ]);
      if (!_isCurrent(generation, workspaceId)) return;
      final patient = values[0] as Patient;
      final lesions = values[1] as List<OralLesion>;
      state = PatientFollowUpState(
        status: FollowUpStatus.data,
        patients: state.patients,
        patient: patient,
        lesions: lesions,
      );
    } catch (_) {
      if (!_isCurrent(generation, workspaceId)) return;
      state = state.copyWith(
        status: FollowUpStatus.error,
        error: 'No se pudo cargar la ficha del paciente.',
      );
    }
  }

  Future<void> loadLesion(String lesionId) async {
    final generation = ++_generation;
    final workspaceId = _workspaceId;
    state = state.copyWith(
      status: FollowUpStatus.loading,
      clearDetail: true,
      clearError: true,
    );
    try {
      final detail = await ref.read(getLesionDetailUseCaseProvider)(lesionId);
      if (!_isCurrent(generation, workspaceId)) return;
      state = state.copyWith(status: FollowUpStatus.data, lesionDetail: detail);
    } catch (_) {
      if (!_isCurrent(generation, workspaceId)) return;
      state = state.copyWith(
        status: FollowUpStatus.error,
        error: 'No se pudo cargar el seguimiento de la lesión.',
      );
    }
  }

  Future<bool> addLesion({
    required String anatomicalSite,
    required String temporalDescription,
    String? notes,
  }) async {
    final patient = state.patient;
    if (patient == null ||
        state.actionStatus == FollowUpActionStatus.updating) {
      return false;
    }
    final generation = _generation;
    final workspaceId = _workspaceId;
    state = state.copyWith(
      actionStatus: FollowUpActionStatus.updating,
      clearActionError: true,
    );
    try {
      final lesion = await ref.read(createLesionUseCaseProvider)(
        patientId: patient.id,
        anatomicalSite: anatomicalSite,
        temporalDescription: temporalDescription,
        notes: notes,
      );
      if (!_isCurrent(generation, workspaceId)) return false;
      state = state.copyWith(
        actionStatus: FollowUpActionStatus.success,
        lesions: [...state.lesions, lesion],
      );
      ref.read(clinicalControllerProvider.notifier).selectPatient(patient);
      ref.read(clinicalControllerProvider.notifier).selectLesion(lesion);
      return true;
    } catch (_) {
      if (!_isCurrent(generation, workspaceId)) return false;
      state = state.copyWith(
        actionStatus: FollowUpActionStatus.error,
        actionError: 'No se pudo registrar la lesión.',
      );
      return false;
    }
  }

  Future<bool> updateLesion({required String status, String? notes}) async {
    final detail = state.lesionDetail;
    if (detail == null || state.actionStatus == FollowUpActionStatus.updating) {
      return false;
    }
    final generation = _generation;
    final workspaceId = _workspaceId;
    state = state.copyWith(
      actionStatus: FollowUpActionStatus.updating,
      clearActionError: true,
    );
    try {
      final lesion = await ref.read(updateLesionUseCaseProvider)(
        lesionId: detail.lesion.id,
        status: status,
        notes: notes,
      );
      if (!_isCurrent(generation, workspaceId)) return false;
      state = state.copyWith(
        actionStatus: FollowUpActionStatus.success,
        lesionDetail: LesionDetail(
          lesion: lesion,
          evaluations: detail.evaluations,
        ),
        lesions: state.lesions
            .map((item) => item.id == lesion.id ? lesion : item)
            .toList(),
      );
      return true;
    } catch (_) {
      if (!_isCurrent(generation, workspaceId)) return false;
      state = state.copyWith(
        actionStatus: FollowUpActionStatus.error,
        actionError: 'No se pudieron actualizar la lesión y sus notas.',
      );
      return false;
    }
  }

  void clear() {
    _generation++;
    state = const PatientFollowUpState();
  }
}

final patientFollowUpControllerProvider =
    NotifierProvider<PatientFollowUpController, PatientFollowUpState>(
      PatientFollowUpController.new,
    );
