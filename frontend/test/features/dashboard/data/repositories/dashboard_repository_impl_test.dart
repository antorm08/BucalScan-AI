import 'package:bucalscan_ai/features/dashboard/data/models/daily_summary_model.dart';
import 'package:bucalscan_ai/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockDashboardRemoteDataSource mockRemoteDataSource;
  late DashboardRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockDashboardRemoteDataSource();
    repository = DashboardRepositoryImpl(mockRemoteDataSource);
  });

  test(
    'getTodaySummary mapea el modelo a entidad cuando la respuesta es correcta',
    () async {
      when(mockRemoteDataSource.getTodaySummary()).thenAnswer(
        (_) async => const DailySummaryModel(total: 3, benign: 2, malignant: 1),
      );

      final result = await repository.getTodaySummary();

      expect(result.total, 3);
      expect(result.benign, 2);
      expect(result.malignant, 1);
    },
  );

  test('propaga la excepción cuando la fuente remota falla', () async {
    when(
      mockRemoteDataSource.getTodaySummary(),
    ).thenThrow(Exception('No se pudo cargar el resumen de hoy.'));

    expect(() => repository.getTodaySummary(), throwsException);
  });
}
