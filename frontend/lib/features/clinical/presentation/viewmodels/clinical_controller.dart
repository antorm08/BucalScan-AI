import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/clinical/di/clinical_providers.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/core/session/session_events.dart';

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
  int _generation = 0;

  @override
  ClinicalState build() {
    final subscription = SessionEvents().onWorkspaceAccessRevoked.listen((_) {
      _clearWorkspaceAccess();
    });
    ref.onDispose(subscription.cancel);
    return const ClinicalState();
  }

  void _clearWorkspaceAccess() {
    _generation++;
    ref.read(selectWorkspaceUseCaseProvider)(null);
    state = ClinicalState(workspaces: state.workspaces);
    loadWorkspaces();
  }

  Future<void> loadWorkspaces() async {
    final generation = ++_generation;
    final previous = state;
    state = ClinicalState(
      loading: true,
      workspaces: previous.workspaces,
      activeWorkspace: previous.activeWorkspace,
      patient: previous.patient,
      lesion: previous.lesion,
    );
    try {
      final workspaces = await ref.read(getMembershipsUseCaseProvider)();
      if (generation != _generation) return;
      final available = workspaces
          .where((workspace) => workspace.canEnter)
          .toList();
      final activeId = previous.activeWorkspace?.id;
      final preserved = activeId == null
          ? null
          : available
                .where((workspace) => workspace.id == activeId)
                .firstOrNull;
      if (preserved != null) {
        ref.read(selectWorkspaceUseCaseProvider)(preserved.id);
        state = ClinicalState(
          workspaces: workspaces,
          activeWorkspace: preserved,
          patient: previous.patient,
          lesion: previous.lesion,
        );
      } else if (activeId != null) {
        ref.read(selectWorkspaceUseCaseProvider)(null);
        state = ClinicalState(workspaces: workspaces);
      } else if (available.length == 1) {
        state = ClinicalState(workspaces: workspaces);
        selectWorkspace(available.single);
      } else {
        ref.read(selectWorkspaceUseCaseProvider)(null);
        state = ClinicalState(workspaces: workspaces);
      }
    } catch (error) {
      if (generation != _generation) return;
      state = ClinicalState(
        workspaces: previous.workspaces,
        activeWorkspace: previous.activeWorkspace,
        patient: previous.patient,
        lesion: previous.lesion,
        error: error.toString(),
      );
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

  void clearPatientSelection() {
    state = ClinicalState(
      workspaces: state.workspaces,
      activeWorkspace: state.activeWorkspace,
    );
  }

  void clearSession() {
    _generation++;
    ref.read(selectWorkspaceUseCaseProvider)(null);
    state = const ClinicalState();
  }
}

final clinicalControllerProvider =
    NotifierProvider<ClinicalController, ClinicalState>(ClinicalController.new);
