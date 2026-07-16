import 'dart:async';

import 'package:bucalscan_ai/core/session/user_sensitive_state.dart';
import 'package:bucalscan_ai/features/clinical/data/models/clinical_models.dart';
import 'package:bucalscan_ai/features/clinical/di/clinical_providers.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/domain/repositories/clinical_repository.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/clinical_controller.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/patient_follow_up_controller.dart';
import 'package:bucalscan_ai/features/clinical/presentation/views/lesion_detail_view.dart';
import 'package:bucalscan_ai/features/clinical/presentation/views/patient_detail_view.dart';
import 'package:bucalscan_ai/features/clinical/presentation/views/patient_lesion_picker.dart';
import 'package:bucalscan_ai/features/home/presentation/views/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _workspace = ClinicalWorkspace(
  id: 'workspace-1',
  name: 'Centro Norte',
  type: 'clinic',
  status: 'active',
  membershipStatus: MembershipStatus.active,
);
const _patient = Patient(
  id: 'patient-1',
  workspaceId: 'workspace-1',
  clinicalCode: 'P-001',
  fullName: 'Ana Pérez',
);
const _lesionOne = OralLesion(
  id: 'lesion-1',
  patientId: 'patient-1',
  anatomicalSite: 'Lengua',
  status: 'active',
  temporalDescription: 'Dos semanas',
);
const _lesionTwo = OralLesion(
  id: 'lesion-2',
  patientId: 'patient-1',
  anatomicalSite: 'Encía',
  status: 'monitoring',
  temporalDescription: 'Un mes',
);

class _FollowUpRepository implements ClinicalRepository {
  final List<Completer<List<Patient>>> searches = [];
  String? selectedWorkspace;
  List<OralLesion> lesions = const [_lesionOne, _lesionTwo];
  LesionDetail? detail;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void setActiveWorkspace(String? workspaceId) =>
      selectedWorkspace = workspaceId;

  @override
  Future<List<ClinicalWorkspace>> getMemberships() async => const [_workspace];

  @override
  Future<List<Patient>> searchPatients(String query) {
    final completer = Completer<List<Patient>>();
    searches.add(completer);
    return completer.future;
  }

  @override
  Future<Patient> getPatient(String patientId) async => _patient;

  @override
  Future<List<OralLesion>> getLesions(String patientId) async => lesions;

  @override
  Future<LesionDetail> getLesionDetail(String lesionId) async => detail!;
}

class _ImmediateFollowUpRepository extends _FollowUpRepository {
  @override
  Future<List<Patient>> searchPatients(String query) async => const [_patient];
}

class _CreatePatientRepository extends _FollowUpRepository {
  final created = Completer<Patient>();

  @override
  Future<Patient> createPatient({
    required String clinicalCode,
    required String fullName,
    String? identityDocument,
  }) => created.future;
}

class _CreateLesionRepository extends _FollowUpRepository {
  final created = Completer<OralLesion>();

  @override
  Future<OralLesion> createLesion({
    required String patientId,
    required String anatomicalSite,
    DateTime? observedAt,
    String? estimatedDuration,
    String? notes,
  }) => created.future;
}

Map<String, dynamic> _detailJson() => {
  'lesion': {
    'id': 1,
    'patient_id': 2,
    'anatomical_site': 'Lengua',
    'status': 'monitoring',
    'estimated_duration': 'dos semanas',
    'created_at': '2026-01-01T08:00:00',
  },
  'evaluations': [
    {
      'id': 20,
      'evaluated_at': '2026-02-02T10:00:00',
      'created_at': '2026-02-02T10:00:00',
      'clinical_observations': 'Sin cambios',
      'professional': {
        'id': 4,
        'full_name': 'Dra. Uno',
        'doctor_id': 'COL-4',
        'profession': 'Odontóloga',
      },
      'image': null,
      'prediction': {
        'id': 8,
        'label': 'benign',
        'confidence': 0.9,
        'probabilities': {'benign': 0.9, 'malignant': 0.1},
        'model_version': 'resnet50-v1',
        'processing_time_ms': 11,
        'heatmap_url': 'https://cdn.example.com/cam.png',
        'created_at': '2026-02-02T10:00:01',
      },
      'consent_attested_at': '2026-02-02T10:00:00',
    },
    {
      'id': 10,
      'evaluated_at': '2026-01-02T10:00:00',
      'created_at': '2026-01-02T10:00:00',
      'professional': {'id': 4, 'full_name': 'Dra. Uno', 'doctor_id': 'COL-4'},
    },
  ],
};

void main() {
  test(
    'lesion model parses complete payload and sorts timeline oldest first',
    () {
      final detail = LesionDetailModel.fromJson(_detailJson()).toEntity();

      expect(detail.evaluations.map((item) => item.id), ['10', '20']);
      expect(detail.evaluations.last.clinicalObservations, 'Sin cambios');
      expect(detail.evaluations.last.prediction?.modelVersion, 'resnet50-v1');
      expect(
        detail.evaluations.last.prediction?.heatmapUrl,
        'https://cdn.example.com/cam.png',
      );
      expect(
        detail.evaluations.last.prediction?.probabilities['malignant'],
        0.1,
      );
      expect(detail.evaluations.last.consentAttestedAt, isNotNull);
    },
  );

  test('newly created patient is inserted without a manual refresh', () {
    final repository = _ImmediateFollowUpRepository();
    final container = ProviderContainer(
      overrides: [clinicalRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    container
        .read(patientFollowUpControllerProvider.notifier)
        .registerCreatedPatient(_patient);

    expect(
      container.read(patientFollowUpControllerProvider).patients.single,
      _patient,
    );
  });

  testWidgets('patient form validates digits and shows progress while saving', (
    tester,
  ) async {
    final repository = _CreatePatientRepository();
    final container = ProviderContainer(
      overrides: [clinicalRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container
        .read(clinicalControllerProvider.notifier)
        .selectWorkspace(_workspace);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PatientLesionPicker()),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Registrar nuevo paciente'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('newPatientClinicalCode')),
      '123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre completo *'),
      'Ana',
    );
    await tester.enterText(
      find.byKey(const Key('newPatientDocument')),
      '123456',
    );
    await tester.tap(find.byKey(const Key('createPatientSubmit')));
    await tester.pump();

    expect(find.text('Ingrese exactamente 6 dígitos.'), findsOneWidget);
    expect(
      find.text('Ingrese al menos 7 dígitos o déjelo vacío.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('newPatientClinicalCode')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const Key('newPatientDocument')),
      '1234567',
    );
    await tester.tap(find.byKey(const Key('createPatientSubmit')));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const Key('createPatientSubmit')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    repository.created.complete(
      const Patient(
        id: 'patient-new',
        workspaceId: 'workspace-1',
        clinicalCode: '123456',
        fullName: 'Ana',
        identityDocument: '1234567',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paciente registrado correctamente.'), findsOneWidget);
    expect(
      container.read(patientFollowUpControllerProvider).patients.single.id,
      'patient-new',
    );
  });

  testWidgets('lesion form explains notes and shows progress while saving', (
    tester,
  ) async {
    final repository = _CreateLesionRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clinicalRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: PatientDetailView(
            patientId: _patient.id,
            onRepeatAnalysis: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addLesionButton')));
    await tester.pumpAndSettle();

    expect(find.text('Notas para seguimiento (opcional)'), findsOneWidget);
    expect(find.textContaining('evolución general'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sitio anatómico *'),
      'Labio',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Duración estimada'),
      'Una semana',
    );
    await tester.tap(find.byKey(const Key('registerLesionSubmit')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('registerLesionSubmit')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    repository.created.complete(
      const OralLesion(
        id: 'lesion-new',
        patientId: 'patient-1',
        anatomicalSite: 'Labio',
        status: 'active',
        estimatedDuration: 'Una semana',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lesión registrada correctamente.'), findsOneWidget);
    expect(find.byKey(const Key('lesion-lesion-new')), findsOneWidget);
  });

  test(
    'follow-up controller rejects an older patient search completion',
    () async {
      final repository = _FollowUpRepository();
      final container = ProviderContainer(
        overrides: [clinicalRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final clinical = container.read(clinicalControllerProvider.notifier);
      clinical.selectWorkspace(_workspace);
      final controller = container.read(
        patientFollowUpControllerProvider.notifier,
      );

      final oldSearch = controller.searchPatients('old');
      final newSearch = controller.searchPatients('new');
      repository.searches[1].complete(const [_patient]);
      await newSearch;
      repository.searches[0].complete(const []);
      await oldSearch;

      final state = container.read(patientFollowUpControllerProvider);
      expect(state.status, FollowUpStatus.data);
      expect(state.patients.single.id, _patient.id);
    },
  );

  testWidgets('patient detail renders multiple independent lesion cards', (
    tester,
  ) async {
    final repository = _FollowUpRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clinicalRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: PatientDetailView(
            patientId: _patient.id,
            onRepeatAnalysis: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lesion-lesion-1')), findsOneWidget);
    expect(find.byKey(const Key('lesion-lesion-2')), findsOneWidget);
    expect(find.text('Lengua'), findsOneWidget);
    expect(find.text('Encía'), findsOneWidget);
  });

  testWidgets('lesion timeline is chronological and repeat returns context', (
    tester,
  ) async {
    final repository = _FollowUpRepository()
      ..detail = LesionDetailModel.fromJson(_detailJson()).toEntity();
    Patient? repeatedPatient;
    OralLesion? repeatedLesion;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clinicalRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: LesionDetailView(
            patient: _patient,
            lesionId: '1',
            onRepeatAnalysis: (patient, lesion) {
              repeatedPatient = patient;
              repeatedLesion = lesion;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final oldPosition = tester
        .getTopLeft(find.byKey(const Key('evaluation-10')))
        .dy;
    final newPosition = tester
        .getTopLeft(find.byKey(const Key('evaluation-20')))
        .dy;
    expect(oldPosition, lessThan(newPosition));
    await tester.tap(find.byKey(const Key('repeatAnalysisButton')));
    await tester.pump();
    expect(repeatedPatient?.id, _patient.id);
    expect(repeatedLesion?.id, '1');
  });

  testWidgets('workspace reset clears workspace patient lesion and follow-up', (
    tester,
  ) async {
    final repository = _FollowUpRepository();
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clinicalRepositoryProvider.overrideWithValue(repository)],
        child: Consumer(
          builder: (context, ref, _) {
            return MaterialApp(
              home: Scaffold(
                body: TextButton(
                  onPressed: ref.resetWorkspaceSensitiveState,
                  child: const Text('Cambiar'),
                ),
              ),
            );
          },
        ),
      ),
    );
    container = ProviderScope.containerOf(tester.element(find.text('Cambiar')));
    container.read(clinicalControllerProvider.notifier)
      ..selectWorkspace(_workspace)
      ..selectPatient(_patient)
      ..selectLesion(_lesionOne);
    final search = container
        .read(patientFollowUpControllerProvider.notifier)
        .searchPatients();
    repository.searches.single.complete(const [_patient]);
    await search;

    await tester.tap(find.text('Cambiar'));
    await tester.pump();

    final clinical = container.read(clinicalControllerProvider);
    expect(clinical.activeWorkspace, isNull);
    expect(clinical.patient, isNull);
    expect(clinical.lesion, isNull);
    expect(repository.selectedWorkspace, isNull);
    expect(
      container.read(patientFollowUpControllerProvider).status,
      FollowUpStatus.initial,
    );
  });

  testWidgets('HomeView repeats analysis without pushing an unguarded home', (
    tester,
  ) async {
    final repository = _ImmediateFollowUpRepository()
      ..detail = const LesionDetail(
        lesion: _lesionOne,
        evaluations: <LesionEvaluation>[],
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clinicalRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: HomeView(initialIndex: 1)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('patient-patient-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lesion-lesion-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('repeatAnalysisButton')));
    await tester.pumpAndSettle();

    expect(find.byType(HomeView), findsOneWidget);
    expect(find.text('Captura guiada'), findsOneWidget);
    expect(find.byKey(const Key('selectedClinicalContext')), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(HomeView))).canPop(),
      isFalse,
    );
  });
}
