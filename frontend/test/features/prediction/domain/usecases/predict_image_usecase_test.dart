import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_image_input.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_result.dart';
import 'package:bucalscan_ai/features/prediction/domain/usecases/predict_image_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockPredictionRepository mockRepository;
  late PredictImageUseCase useCase;

  setUp(() {
    mockRepository = MockPredictionRepository();
    useCase = PredictImageUseCase(mockRepository);
  });

  test('delega en el repositorio y retorna el resultado del análisis', () async {
    const input = PredictionImageInput(
      imagePath: '/tmp/image.jpg',
      consentToStore: true,
      patientId: 'P-001',
      patientName: 'Paciente Prueba',
    );
    const result = PredictionResult(
      prediction: 'benign',
      confidence: 0.88,
      recommendation: 'Control periodico.',
    );

    when(mockRepository.predictImage(input)).thenAnswer((_) async => result);

    final response = await useCase.call(input);

    expect(response.prediction, 'benign');
    verify(mockRepository.predictImage(input)).called(1);
  });

  test('propaga la excepción cuando el análisis falla', () async {
    const input = PredictionImageInput(
      imagePath: '/tmp/image.jpg',
      consentToStore: false,
    );

    when(
      mockRepository.predictImage(input),
    ).thenThrow(Exception('No se pudo completar el analisis de la imagen.'));

    expect(() => useCase.call(input), throwsException);
  });
}
