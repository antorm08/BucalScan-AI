import 'package:bucalscan_ai/core/session/session_events.dart';
import 'package:bucalscan_ai/features/clinical/di/clinical_providers.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/domain/repositories/clinical_repository.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/clinical_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ClinicalRepository implements ClinicalRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  var memberships = const [
    ClinicalWorkspace(
      id: '1',
      name: 'Clinic',
      type: 'clinic',
      status: 'active',
      membershipStatus: MembershipStatus.active,
    ),
  ];
  String? selectedWorkspace;

  @override
  Future<List<ClinicalWorkspace>> getMemberships() async => memberships;
  @override
  void setActiveWorkspace(String? workspaceId) =>
      selectedWorkspace = workspaceId;
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
    DateTime? observedAt,
    String? estimatedDuration,
    String? notes,
  }) => throw UnimplementedError();
}

void main() {
  late _ClinicalRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _ClinicalRepository();
    container = ProviderContainer(
      overrides: [clinicalRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('clearPatientSelection preserves the active workspace', () async {
    final controller = container.read(clinicalControllerProvider.notifier);
    await controller.loadWorkspaces();
    controller.selectPatient(
      const Patient(id: 'p1', clinicalCode: 'P-1', fullName: 'Patient'),
    );

    controller.clearPatientSelection();

    final state = container.read(clinicalControllerProvider);
    expect(state.patient, isNull);
    expect(state.lesion, isNull);
    expect(state.activeWorkspace?.id, '1');
    expect(repository.selectedWorkspace, '1');
  });

  test(
    'workspace revocation clears clinical selection without auth expiry',
    () async {
      final controller = container.read(clinicalControllerProvider.notifier);
      await controller.loadWorkspaces();
      controller.selectPatient(
        const Patient(id: 'p1', clinicalCode: 'P-1', fullName: 'Patient'),
      );
      repository.memberships = const [
        ClinicalWorkspace(
          id: '1',
          name: 'Clinic',
          type: 'clinic',
          status: 'active',
          membershipStatus: MembershipStatus.inactive,
        ),
      ];

      SessionEvents().emitWorkspaceAccessRevoked();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(clinicalControllerProvider);
      expect(state.activeWorkspace, isNull);
      expect(state.patient, isNull);
      expect(
        state.workspaces.single.membershipStatus,
        MembershipStatus.inactive,
      );
      expect(repository.selectedWorkspace, isNull);
    },
  );
}
