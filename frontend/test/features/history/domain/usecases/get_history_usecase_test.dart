import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';
import 'package:bucalscan_ai/features/history/domain/usecases/get_history_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockHistoryRepository mockRepository;
  late GetHistoryUseCase useCase;

  setUp(() {
    mockRepository = MockHistoryRepository();
    useCase = GetHistoryUseCase(mockRepository);
  });

  test('retorna la lista de análisis cuando el repositorio responde correctamente', () async {
    final analyses = [
      Analysis(
        id: 1,
        prediction: 'benign',
        confidence: 0.91,
        timestamp: DateTime(2026, 1, 1, 9),
      ),
    ];
    when(mockRepository.getHistory()).thenAnswer((_) async => analyses);

    final result = await useCase.call();

    expect(result, hasLength(1));
    expect(result.first.prediction, 'benign');
  });

  test('retorna una lista vacía cuando no hay análisis', () async {
    when(mockRepository.getHistory()).thenAnswer((_) async => []);

    final result = await useCase.call();

    expect(result, isEmpty);
  });

  test('propaga la excepción cuando el repositorio falla', () async {
    when(
      mockRepository.getHistory(),
    ).thenThrow(Exception('Error del servidor'));

    expect(() => useCase.call(), throwsException);
  });
}
