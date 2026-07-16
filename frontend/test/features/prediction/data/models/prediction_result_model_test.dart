import 'package:bucalscan_ai/features/prediction/data/models/prediction_result_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PredictionResultModel.fromJson', () {
    test('convierte un JSON completo en un objeto correctamente', () {
      final json = {
        'prediction': 'benign',
        'confidence': 0.88,
        'recommendation': 'Control periodico.',
        'probabilities': {'benign': 0.88, 'malignant': 0.12},
        'processing_time_ms': 512.3,
        'heatmap_url': 'https://cdn.example.com/cam.png',
      };

      final model = PredictionResultModel.fromJson(json);

      expect(model.prediction, 'benign');
      expect(model.confidence, 0.88);
      expect(model.recommendation, 'Control periodico.');
      expect(model.probabilities, {'benign': 0.88, 'malignant': 0.12});
      expect(model.processingTimeMs, 512.3);
      expect(model.heatmapUrl, 'https://cdn.example.com/cam.png');
    });

    test('acepta claves alternativas class/score y label/probability', () {
      final json = {'class': 'malignant', 'score': 0.95};

      final model = PredictionResultModel.fromJson(json);

      expect(model.prediction, 'malignant');
      expect(model.confidence, 0.95);
    });

    test('usa recomendación por defecto cuando no viene en el JSON', () {
      final json = {'prediction': 'benign', 'confidence': 0.7};

      final model = PredictionResultModel.fromJson(json);

      expect(
        model.recommendation,
        'Consulte el resultado con un profesional de salud para una evaluacion clinica completa.',
      );
      expect(model.probabilities, isNull);
      expect(model.processingTimeMs, isNull);
    });

    test('lanza FormatException cuando falta la predicción', () {
      final json = {'confidence': 0.7};

      expect(
        () => PredictionResultModel.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('lanza FormatException cuando la confianza no es numérica', () {
      final json = {'prediction': 'benign', 'confidence': 'alta'};

      expect(
        () => PredictionResultModel.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('PredictionResultModel.toEntity', () {
    test('mapea todos los campos hacia PredictionResult', () {
      const model = PredictionResultModel(
        prediction: 'benign',
        confidence: 0.88,
        recommendation: 'Control periodico.',
        probabilities: {'benign': 0.88, 'malignant': 0.12},
        processingTimeMs: 512.3,
        heatmapUrl: 'https://cdn.example.com/cam.png',
      );

      final entity = model.toEntity();

      expect(entity.prediction, 'benign');
      expect(entity.confidence, 0.88);
      expect(entity.recommendation, 'Control periodico.');
      expect(entity.probabilities, {'benign': 0.88, 'malignant': 0.12});
      expect(entity.processingTimeMs, 512.3);
      expect(entity.heatmapUrl, 'https://cdn.example.com/cam.png');
    });
  });
}
