import 'package:bucalscan_ai/features/history/di/history_providers.dart';
import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

final _analyses = [
  Analysis(
    id: 1,
    prediction: 'benign',
    confidence: 0.91,
    timestamp: DateTime(2026, 1, 1, 9),
    patientId: 'P-001',
    patientName: 'Paciente Benigno',
  ),
  Analysis(
    id: 2,
    prediction: 'malignant',
    confidence: 0.82,
    timestamp: DateTime(2026, 1, 1, 10),
    patientId: 'P-002',
    patientName: 'Paciente Maligno',
  ),
];

void main() {
  late MockGetHistoryUseCase mockGetHistoryUseCase;
  late ProviderContainer container;

  setUp(() {
    mockGetHistoryUseCase = MockGetHistoryUseCase();
    container = ProviderContainer(
      overrides: [
        getHistoryUseCaseProvider.overrideWithValue(mockGetHistoryUseCase),
      ],
    );
    addTearDown(container.dispose);
  });

  test('fetchHistory carga el historial cuando la respuesta es correcta', () async {
    when(mockGetHistoryUseCase.call()).thenAnswer((_) async => _analyses);

    await container.read(historyViewModelProvider.notifier).fetchHistory();

    final state = container.read(historyViewModelProvider);
    expect(state.allHistory, hasLength(2));
    expect(state.isLoading, false);
    expect(state.error, isNull);
    expect(state.hasAnyHistory, true);
  });

  test('fetchHistory setea error cuando el caso de uso falla', () async {
    when(
      mockGetHistoryUseCase.call(),
    ).thenThrow(Exception('Error de conexión'));

    await container.read(historyViewModelProvider.notifier).fetchHistory();

    final state = container.read(historyViewModelProvider);
    expect(state.allHistory, isEmpty);
    expect(state.isLoading, false);
    expect(state.error, isNotNull);
  });

  group('HistoryState.history (filtro y búsqueda)', () {
    test('filtro Maligna retorna solo análisis malignos', () {
      final state = HistoryState(allHistory: _analyses, filter: 'Maligna');

      expect(state.history, hasLength(1));
      expect(state.history.single.prediction, 'malignant');
    });

    test('filtro Benigna retorna solo análisis benignos', () {
      final state = HistoryState(allHistory: _analyses, filter: 'Benigna');

      expect(state.history, hasLength(1));
      expect(state.history.single.prediction, 'benign');
    });

    test('filtro Fecha ordena descendente por defecto', () {
      final state = HistoryState(allHistory: _analyses, filter: 'Fecha');

      expect(state.history.first.id, 2);
      expect(state.history.last.id, 1);
    });

    test('filtro Fecha ordena ascendente cuando dateSortDescending es false', () {
      final state = HistoryState(
        allHistory: _analyses,
        filter: 'Fecha',
        dateSortDescending: false,
      );

      expect(state.history.first.id, 1);
      expect(state.history.last.id, 2);
    });

    test('búsqueda con resultados filtra por nombre de paciente', () {
      final state = HistoryState(
        allHistory: _analyses,
        searchQuery: 'benigno',
      );

      expect(state.history, hasLength(1));
      expect(state.history.single.patientName, 'Paciente Benigno');
    });

    test('búsqueda sin resultados retorna una lista vacía', () {
      final state = HistoryState(allHistory: _analyses, searchQuery: 'xyz');

      expect(state.history, isEmpty);
    });

    test('hasActiveSearchOrFilter es true con búsqueda o filtro activo', () {
      const empty = HistoryState();
      final withSearch = empty.copyWith(searchQuery: 'benigno');
      final withFilter = empty.copyWith(filter: 'Maligna');

      expect(empty.hasActiveSearchOrFilter, false);
      expect(withSearch.hasActiveSearchOrFilter, true);
      expect(withFilter.hasActiveSearchOrFilter, true);
    });
  });

  test('setFilter("Fecha") invierte el orden si ya estaba en Fecha', () async {
    when(mockGetHistoryUseCase.call()).thenAnswer((_) async => _analyses);
    final notifier = container.read(historyViewModelProvider.notifier);
    await notifier.fetchHistory();

    notifier.setFilter('Fecha');
    expect(container.read(historyViewModelProvider).dateSortDescending, true);

    notifier.setFilter('Fecha');
    expect(
      container.read(historyViewModelProvider).dateSortDescending,
      false,
    );
  });
}
