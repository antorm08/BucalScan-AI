import 'package:bucalscan_ai/features/history/data/models/analysis_model.dart';
import 'package:bucalscan_ai/features/history/data/repositories/history_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockHistoryRemoteDataSource mockRemoteDataSource;
  late HistoryRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockHistoryRemoteDataSource();
    repository = HistoryRepositoryImpl(mockRemoteDataSource);
  });

  test('getHistory mapea la lista de modelos a entidades', () async {
    when(mockRemoteDataSource.getHistory()).thenAnswer(
      (_) async => const [
        AnalysisModel(
          id: 1,
          prediction: 'benign',
          confidence: 0.91,
          timestamp: '2026-01-01T09:00:00.000Z',
        ),
      ],
    );

    final result = await repository.getHistory();

    expect(result, hasLength(1));
    expect(result.first.prediction, 'benign');
    expect(result.first.timestamp, DateTime.parse('2026-01-01T09:00:00.000Z'));
  });

  test(
    'getHistory retorna una lista vacía cuando la fuente remota no tiene datos',
    () async {
      when(mockRemoteDataSource.getHistory()).thenAnswer((_) async => []);

      final result = await repository.getHistory();

      expect(result, isEmpty);
    },
  );

  test('propaga la excepción cuando la fuente remota falla', () async {
    when(
      mockRemoteDataSource.getHistory(),
    ).thenThrow(Exception('No se pudo cargar el historial.'));

    expect(() => repository.getHistory(), throwsException);
  });
}
