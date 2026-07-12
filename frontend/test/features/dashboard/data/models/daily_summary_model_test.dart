import 'package:bucalscan_ai/features/dashboard/data/models/daily_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailySummaryModel.fromJson', () {
    test('convierte un JSON completo en un objeto correctamente', () {
      final json = {
        'total': 10,
        'benign': 7,
        'malignant': 3,
        'latest_analysis_at': '2026-01-01T10:00:00.000Z',
      };

      final model = DailySummaryModel.fromJson(json);

      expect(model.total, 10);
      expect(model.benign, 7);
      expect(model.malignant, 3);
      expect(model.latestAnalysisAt, '2026-01-01T10:00:00.000Z');
    });

    test('aplica valores por defecto cuando faltan campos', () {
      final model = DailySummaryModel.fromJson(<String, dynamic>{});

      expect(model.total, 0);
      expect(model.benign, 0);
      expect(model.malignant, 0);
      expect(model.latestAnalysisAt, isNull);
    });
  });

  group('DailySummaryModel.toEntity', () {
    test('parsea correctamente la fecha del último análisis', () {
      const model = DailySummaryModel(
        total: 3,
        benign: 2,
        malignant: 1,
        latestAnalysisAt: '2026-01-01T10:00:00.000Z',
      );

      final entity = model.toEntity();

      expect(entity.total, 3);
      expect(entity.benign, 2);
      expect(entity.malignant, 1);
      expect(
        entity.latestAnalysisAt,
        DateTime.parse('2026-01-01T10:00:00.000Z'),
      );
    });

    test('deja la fecha en null cuando latestAnalysisAt es null', () {
      const model = DailySummaryModel(total: 0, benign: 0, malignant: 0);

      final entity = model.toEntity();

      expect(entity.latestAnalysisAt, isNull);
    });

    test(
      'deja la fecha en null cuando latestAnalysisAt es una cadena vacía',
      () {
        const model = DailySummaryModel(
          total: 0,
          benign: 0,
          malignant: 0,
          latestAnalysisAt: '',
        );

        final entity = model.toEntity();

        expect(entity.latestAnalysisAt, isNull);
      },
    );
  });
}
