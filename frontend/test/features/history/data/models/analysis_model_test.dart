import 'package:bucalscan_ai/features/history/data/models/analysis_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalysisModel.fromJson', () {
    test('convierte un JSON completo en un objeto correctamente', () {
      final json = {
        'id': 1,
        'prediction': 'malignant',
        'confidence': 0.87,
        'timestamp': '2026-01-01T09:00:00.000Z',
        'image_url': 'https://cdn.example.com/img.jpg',
        'patient_id': 'P-001',
        'patient_name': 'Paciente Prueba',
        'model_version': 'resnet50-v2',
        'processing_time_ms': 320.5,
        'created_by_id': 7,
        'created_by_name': 'Dr. Smith',
        'created_by_email': 'smith@hospital.org',
        'created_by_doctor_id': 'MD-001',
      };

      final model = AnalysisModel.fromJson(json);

      expect(model.id, 1);
      expect(model.prediction, 'malignant');
      expect(model.confidence, 0.87);
      expect(model.timestamp, '2026-01-01T09:00:00.000Z');
      expect(model.imageUrl, 'https://cdn.example.com/img.jpg');
      expect(model.patientId, 'P-001');
      expect(model.patientName, 'Paciente Prueba');
      expect(model.modelVersion, 'resnet50-v2');
      expect(model.processingTimeMs, 320.5);
      expect(model.createdById, 7);
      expect(model.createdByName, 'Dr. Smith');
      expect(model.createdByEmail, 'smith@hospital.org');
      expect(model.createdByDoctorId, 'MD-001');
    });

    test('acepta campos opcionales ausentes', () {
      final json = {
        'id': 2,
        'prediction': 'benign',
        'confidence': 0.5,
        'timestamp': '2026-01-01T09:00:00.000Z',
      };

      final model = AnalysisModel.fromJson(json);

      expect(model.imageUrl, isNull);
      expect(model.patientId, isNull);
      expect(model.processingTimeMs, isNull);
      expect(model.createdById, isNull);
    });
  });

  group('AnalysisModel.toEntity', () {
    test('mapea los campos y parsea el timestamp a DateTime', () {
      const model = AnalysisModel(
        id: 1,
        prediction: 'benign',
        confidence: 0.91,
        timestamp: '2026-01-01T09:00:00.000Z',
        patientId: 'P-001',
        patientName: 'Paciente Benigno',
      );

      final entity = model.toEntity();

      expect(entity.id, 1);
      expect(entity.prediction, 'benign');
      expect(entity.confidence, 0.91);
      expect(entity.timestamp, DateTime.parse('2026-01-01T09:00:00.000Z'));
      expect(entity.patientId, 'P-001');
      expect(entity.patientName, 'Paciente Benigno');
    });

    test('usa la fecha actual cuando el timestamp no es parseable', () {
      const model = AnalysisModel(
        id: 1,
        prediction: 'benign',
        confidence: 0.91,
        timestamp: 'fecha-invalida',
      );

      final before = DateTime.now();
      final entity = model.toEntity();
      final after = DateTime.now();

      expect(
        entity.timestamp.isAfter(before.subtract(const Duration(seconds: 5))),
        true,
      );
      expect(entity.timestamp.isBefore(after.add(const Duration(seconds: 1))), true);
    });
  });
}
