import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/clinical/di/clinical_providers.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';

class ClinicalState {
  final bool loading;
  final List<ClinicalWorkspace> workspaces;
  final ClinicalWorkspace? activeWorkspace;
  final Patient? patient;
  final OralLesion? lesion;
  final String? error;

  const ClinicalState({
    this.loading = false,
    this.workspaces = const [],
    this.activeWorkspace,
    this.patient,
    this.lesion,
    this.error,
  });
}

class ClinicalController extends Notifier<ClinicalState> {
  @override
  ClinicalState build() => const ClinicalState();

  Future<void> loadWorkspaces() async {
    state = ClinicalState(loading: true, workspaces: state.workspaces);
    try {
      final workspaces = await ref.read(getMembershipsUseCaseProvider)();
      final available = workspaces
          .where((workspace) => workspace.canEnter)
          .toList();
      if (available.length == 1) {
        selectWorkspace(available.single);
      } else {
        state = ClinicalState(workspaces: workspaces);
      }
    } catch (error) {
      state = ClinicalState(error: error.toString());
    }
  }

  void selectWorkspace(ClinicalWorkspace workspace) {
    if (!workspace.canEnter) return;
    ref.read(selectWorkspaceUseCaseProvider)(workspace.id);
    state = ClinicalState(
      workspaces: state.workspaces,
      activeWorkspace: workspace,
    );
  }

  void selectPatient(Patient patient) {
    state = ClinicalState(
      workspaces: state.workspaces,
      activeWorkspace: state.activeWorkspace,
      patient: patient,
    );
  }

  void selectLesion(OralLesion lesion) {
    state = ClinicalState(
      workspaces: state.workspaces,
      activeWorkspace: state.activeWorkspace,
      patient: state.patient,
      lesion: lesion,
    );
  }

  void clearSession() {
    ref.read(selectWorkspaceUseCaseProvider)(null);
    state = const ClinicalState();
  }
}

final clinicalControllerProvider =
    NotifierProvider<ClinicalController, ClinicalState>(ClinicalController.new);
