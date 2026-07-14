import 'package:bucalscan_ai/features/clinical/di/clinical_providers.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/domain/usecases/clinical_usecases.dart';
import 'package:bucalscan_ai/features/history/di/history_providers.dart';
import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';
import 'package:bucalscan_ai/features/history/domain/entities/history_query.dart';
import 'package:bucalscan_ai/features/history/domain/repositories/history_repository.dart';
import 'package:bucalscan_ai/features/history/presentation/views/history_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _patient = Patient(
  id: '10',
  workspaceId: '1',
  clinicalCode: 'P-10',
  fullName: 'Paciente Historial',
);
const _lesion = OralLesion(
  id: '20',
  patientId: '10',
  anatomicalSite: 'Lengua',
  status: 'active',
);
final _detail = LesionDetail(lesion: _lesion, evaluations: const []);

Analysis _analysis({
  String prediction = 'benign',
  int? patientId = 10,
  int? lesionId = 20,
}) => Analysis(
  id: 1,
  prediction: prediction,
  confidence: 0.8,
  timestamp: DateTime.utc(2026, 1, 1),
  patientId: 'P-10',
  patientName: 'Paciente Historial',
  patientRecordId: patientId,
  lesionId: lesionId,
  lesionSite: 'Lengua',
  clinicalObservations: 'Hallazgo de evaluación',
  professionalName: 'Dra. Historia',
  modelVersion: 'resnet-v1',
);

class _Repository implements HistoryRepository {
  final List<Analysis> first;
  final List<HistoryCriteria> seen = [];
  _Repository(this.first);

  @override
  Future<List<Analysis>> getHistory() async => first;

  @override
  Future<HistoryPage> getHistoryPage(
    HistoryCriteria criteria, {
    required int page,
  }) async {
    seen.add(criteria);
    return HistoryPage(
      items: first,
      page: page,
      pageSize: 25,
      total: first.length,
      hasNext: false,
      priorityFilterEnabled: true,
    );
  }
}

class _PatientUseCase implements GetPatientUseCase {
  final bool available;
  _PatientUseCase(this.available);

  @override
  Future<Patient> call(String id) async {
    if (!available) throw Exception('not found');
    return _patient;
  }
}

class _LesionUseCase implements GetLesionDetailUseCase {
  final bool available;
  _LesionUseCase(this.available);

  @override
  Future<LesionDetail> call(String id) async {
    if (!available) throw Exception('forbidden');
    return _detail;
  }
}

Widget _app(_Repository repository, {bool linksAvailable = true}) =>
    ProviderScope(
      overrides: [
        historyRepositoryProvider.overrideWithValue(repository),
        getPatientUseCaseProvider.overrideWithValue(
          _PatientUseCase(linksAvailable),
        ),
        getLesionDetailUseCaseProvider.overrideWithValue(
          _LesionUseCase(linksAvailable),
        ),
      ],
      child: const MaterialApp(home: HistoryTabView()),
    );

void main() {
  testWidgets(
    'renders unknown model labels neutrally and exposes detail provenance',
    (tester) async {
      await tester.pumpWidget(
        _app(_Repository([_analysis(prediction: 'unexpected')])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Salida desconocida'), findsOneWidget);
      expect(find.byKey(const Key('historyImage-1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('historyCard-1')));
      await tester.pumpAndSettle();
      expect(find.text('Salida no disponible'), findsOneWidget);
      expect(find.text('Hallazgo de evaluación'), findsOneWidget);
      expect(find.text('Dra. Historia'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Versión del modelo'),
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('historyDetailSheet')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('resnet-v1'), findsOneWidget);
    },
  );

  testWidgets('valid lesion link stays in navigation and opens lesion detail', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_Repository([_analysis()])));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('historyCard-1')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('openHistoryLesion')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('historyDetailSheet')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openHistoryLesion')));
    await tester.pumpAndSettle();

    expect(find.text('Seguimiento de lesión'), findsOneWidget);
  });

  testWidgets('stale patient link shows safe unavailable state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_Repository([_analysis()]), linksAvailable: false),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('historyCard-1')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('openHistoryPatient')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('historyDetailSheet')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openHistoryPatient')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'El registro no está disponible o ya no tienes acceso en el centro activo.',
      ),
      findsOneWidget,
    );
    expect(find.text('Ficha del paciente'), findsNothing);
  });

  testWidgets('hides model filters and clear returns to no filters', (
    tester,
  ) async {
    final repository = _Repository([_analysis()]);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.byType(FilterChip), findsNothing);
    expect(find.text('Todos los modelos'), findsNothing);
    await tester.enterText(find.byKey(const Key('historySearch')), 'Paciente');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('historyFilterSummary')), findsOneWidget);
    expect(repository.seen.last.search, 'Paciente');
    await tester.tap(find.byKey(const Key('clearHistoryFilters')));
    await tester.pumpAndSettle();
    expect(repository.seen.last.hasFilters, false);
  });
}
