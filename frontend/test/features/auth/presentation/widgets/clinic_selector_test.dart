import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bucalscan_ai/features/auth/presentation/widgets/clinic_selector.dart';
import 'package:bucalscan_ai/features/clinical/di/clinical_providers.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/domain/repositories/clinical_repository.dart';

class _ClinicSearchRepository implements ClinicalRepository {
  static const active = ClinicalWorkspace(
    id: 'active-1',
    name: 'Clinica Activa',
    type: 'clinic',
    status: 'active',
    membershipStatus: MembershipStatus.pending,
  );
  static const pending = ClinicalWorkspace(
    id: 'pending-1',
    name: 'Clinica Pendiente',
    type: 'clinic',
    status: 'pending',
    membershipStatus: MembershipStatus.pending,
  );

  @override
  Future<List<ClinicalWorkspace>> discoverWorkspaces(String query) async => [
    active,
    pending,
  ];

  @override
  Future<List<ClinicalWorkspace>> getMemberships() =>
      throw UnimplementedError();
  @override
  Future<List<Patient>> searchPatients(String query) =>
      throw UnimplementedError();
  @override
  Future<Patient> createPatient({
    required String clinicalCode,
    required String fullName,
    String? identityDocument,
  }) => throw UnimplementedError();
  @override
  Future<List<OralLesion>> getLesions(String patientId) =>
      throw UnimplementedError();
  @override
  Future<OralLesion> createLesion({
    required String patientId,
    required String anatomicalSite,
    required String temporalDescription,
    String? notes,
  }) => throw UnimplementedError();
}

void main() {
  testWidgets('shows pending clinics but only selects an active clinic', (
    tester,
  ) async {
    ClinicalWorkspace? selected;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clinicalRepositoryProvider.overrideWithValue(
            _ClinicSearchRepository(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => ClinicSelector(
                selectedWorkspace: selected,
                onSelected: (value) => setState(() => selected = value),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('clinic-search-field')),
      'clinica',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Clinica Activa'), findsOneWidget);
    expect(find.text('Clinica Pendiente'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);

    await tester.tap(find.text('Clinica Pendiente'));
    await tester.pump();
    expect(selected, isNull);

    await tester.tap(find.text('Clinica Activa'));
    await tester.pump();
    expect(selected?.id, 'active-1');

    await tester.enterText(
      find.byKey(const Key('clinic-search-field')),
      'otra',
    );
    await tester.pump();
    expect(selected, isNull);
  });
}
