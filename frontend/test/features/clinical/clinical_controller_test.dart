import 'dart:async';

import 'package:bucalscan_ai/features/clinical/di/clinical_providers.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/domain/repositories/clinical_repository.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/clinical_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements ClinicalRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final requests = <Completer<List<ClinicalWorkspace>>>[];
  String? selectedWorkspace;

  @override
  Future<List<ClinicalWorkspace>> getMemberships() {
    final request = Completer<List<ClinicalWorkspace>>();
    requests.add(request);
    return request.future;
  }

  @override
  void setActiveWorkspace(String? workspaceId) {
    selectedWorkspace = workspaceId;
  }

  @override
  Future<List<ClinicalWorkspace>> discoverWorkspaces(String query) async => [];
  @override
  Future<List<Patient>> searchPatients(String query) async => [];
  @override
  Future<Patient> createPatient({
    required String clinicalCode,
    required String fullName,
    String? identityDocument,
  }) => throw UnimplementedError();
  @override
  Future<List<OralLesion>> getLesions(String patientId) async => [];
  @override
  Future<OralLesion> createLesion({
    required String patientId,
    required String anatomicalSite,
    required String temporalDescription,
    String? notes,
  }) => throw UnimplementedError();
}

const _workspace = ClinicalWorkspace(
  id: 'workspace-1',
  name: 'Clinica',
  type: 'clinic',
  status: 'active',
  membershipStatus: MembershipStatus.active,
);

void main() {
  test(
    'completion from a prior session cannot update the new session',
    () async {
      final repository = _Repository();
      final container = ProviderContainer(
        overrides: [clinicalRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(clinicalControllerProvider.notifier);

      final oldLoad = controller.loadWorkspaces();
      controller.clearSession();
      final newLoad = controller.loadWorkspaces();
      repository.requests[1].complete(const []);
      await newLoad;
      repository.requests[0].complete(const [_workspace]);
      await oldLoad;

      expect(container.read(clinicalControllerProvider).workspaces, isEmpty);
      expect(
        container.read(clinicalControllerProvider).activeWorkspace,
        isNull,
      );
      expect(repository.selectedWorkspace, isNull);
    },
  );

  test(
    'refresh preserves an active workspace only while it can be entered',
    () async {
      final repository = _Repository();
      final container = ProviderContainer(
        overrides: [clinicalRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(clinicalControllerProvider.notifier);

      final initial = controller.loadWorkspaces();
      repository.requests.single.complete(const [_workspace]);
      await initial;
      final refresh = controller.loadWorkspaces();
      repository.requests[1].complete(const [_workspace]);
      await refresh;
      expect(
        container.read(clinicalControllerProvider).activeWorkspace?.id,
        _workspace.id,
      );

      final removed = controller.loadWorkspaces();
      repository.requests[2].complete(const []);
      await removed;
      expect(
        container.read(clinicalControllerProvider).activeWorkspace,
        isNull,
      );
      expect(repository.selectedWorkspace, isNull);
    },
  );
}
