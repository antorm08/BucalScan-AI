import 'package:bucalscan_ai/features/dashboard/di/dashboard_providers.dart';
import 'package:bucalscan_ai/features/dashboard/domain/entities/daily_summary.dart';
import 'package:bucalscan_ai/features/dashboard/presentation/viewmodels/summary_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockGetTodaySummaryUseCase mockGetTodaySummaryUseCase;
  late ProviderContainer container;

  setUp(() {
    mockGetTodaySummaryUseCase = MockGetTodaySummaryUseCase();
    container = ProviderContainer(
      overrides: [
        getTodaySummaryUseCaseProvider.overrideWithValue(
          mockGetTodaySummaryUseCase,
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test('fetchTodaySummary carga el resumen cuando la respuesta es correcta', () async {
    const summary = DailySummary(total: 3, benign: 2, malignant: 1);
    when(
      mockGetTodaySummaryUseCase.call(),
    ).thenAnswer((_) async => summary);

    await container.read(summaryViewModelProvider.notifier).fetchTodaySummary();

    final state = container.read(summaryViewModelProvider);
    expect(state.summary?.total, 3);
    expect(state.summary?.malignant, 1);
    expect(state.isEmpty, false);
    expect(state.error, isNull);
  });

  test('fetchTodaySummary setea error cuando el caso de uso falla', () async {
    when(
      mockGetTodaySummaryUseCase.call(),
    ).thenThrow(Exception('No se pudo cargar el resumen de hoy.'));

    await container.read(summaryViewModelProvider.notifier).fetchTodaySummary();

    final state = container.read(summaryViewModelProvider);
    expect(state.summary, isNull);
    expect(state.isEmpty, true);
    expect(state.isLoading, false);
    expect(state.error, isNotNull);
  });
}
