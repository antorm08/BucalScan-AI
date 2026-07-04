import 'package:bucalscan_ai/features/dashboard/domain/entities/daily_summary.dart';
import 'package:bucalscan_ai/features/dashboard/domain/usecases/get_today_summary_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockDashboardRepository mockRepository;
  late GetTodaySummaryUseCase useCase;

  setUp(() {
    mockRepository = MockDashboardRepository();
    useCase = GetTodaySummaryUseCase(mockRepository);
  });

  test('retorna el resumen del día cuando el repositorio responde correctamente', () async {
    const summary = DailySummary(total: 3, benign: 2, malignant: 1);
    when(mockRepository.getTodaySummary()).thenAnswer((_) async => summary);

    final result = await useCase.call();

    expect(result.total, 3);
    expect(result.malignant, 1);
    verify(mockRepository.getTodaySummary()).called(1);
  });

  test('propaga la excepción cuando el repositorio falla', () async {
    when(
      mockRepository.getTodaySummary(),
    ).thenThrow(Exception('Error de conexión'));

    expect(() => useCase.call(), throwsException);
  });
}
