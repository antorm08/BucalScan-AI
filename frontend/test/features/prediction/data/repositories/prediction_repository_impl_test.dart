import 'package:bucalscan_ai/features/prediction/data/models/prediction_result_model.dart';
import 'package:bucalscan_ai/features/prediction/data/repositories/prediction_repository_impl.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_image_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockPredictionRemoteDataSource mockRemoteDataSource;
  late PredictionRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockPredictionRemoteDataSource();
    repository = PredictionRepositoryImpl(mockRemoteDataSource);
  });

  test(
    'predictImage mapea el modelo a entidad cuando la respuesta es correcta',
    () async {
      const input = PredictionImageInput(
        imagePath: '/tmp/image.jpg',
        consentToStore: true,
      );
      when(mockRemoteDataSource.predictImage(input)).thenAnswer(
        (_) async => const PredictionResultModel(
          prediction: 'benign',
          confidence: 0.88,
          recommendation: 'Control periodico.',
        ),
      );

      final result = await repository.predictImage(input);

      expect(result.prediction, 'benign');
      expect(result.confidence, 0.88);
    },
  );

  test('propaga la excepción cuando la fuente remota falla', () async {
    const input = PredictionImageInput(
      imagePath: '/tmp/image.jpg',
      consentToStore: false,
    );
    when(
      mockRemoteDataSource.predictImage(input),
    ).thenThrow(Exception('No se pudo completar el analisis de la imagen.'));

    expect(() => repository.predictImage(input), throwsException);
  });
}
