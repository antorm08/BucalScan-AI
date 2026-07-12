import 'dart:io';

import 'package:bucalscan_ai/features/prediction/di/prediction_providers.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_image_input.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_result.dart';
import 'package:bucalscan_ai/features/prediction/presentation/viewmodels/prediction_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockPredictImageUseCase mockPredictImageUseCase;
  late ProviderContainer container;
  late File tempImage;

  setUp(() async {
    mockPredictImageUseCase = MockPredictImageUseCase();
    container = ProviderContainer(
      overrides: [
        predictImageUseCaseProvider.overrideWithValue(mockPredictImageUseCase),
      ],
    );
    addTearDown(container.dispose);

    tempImage = File(
      '${Directory.systemTemp.path}/bucalscan-viewmodel-test.jpg',
    );
    await tempImage.writeAsBytes([1, 2, 3]);
    addTearDown(() {
      if (tempImage.existsSync()) {
        tempImage.deleteSync();
      }
    });
  });

  test(
    'predictImage guarda el resultado cuando el análisis es exitoso',
    () async {
      const result = PredictionResult(
        prediction: 'benign',
        confidence: 0.88,
        recommendation: 'Control periodico.',
      );

      when(mockPredictImageUseCase.call(any)).thenAnswer((_) async => result);

      await container
          .read(predictionViewModelProvider.notifier)
          .predictImage(
            tempImage,
            patientId: 'P-001',
            patientName: 'Paciente Prueba',
            consentToStore: true,
          );

      final state = container.read(predictionViewModelProvider);
      expect(state.result?.prediction, 'benign');
      expect(state.patientId, 'P-001');
      expect(state.isLoading, false);
      expect(state.error, isNull);

      final captured =
          verify(mockPredictImageUseCase.call(captureAny)).captured.single
              as PredictionImageInput;
      expect(captured.imagePath, tempImage.path);
      expect(captured.patientId, 'P-001');
      expect(captured.patientName, 'Paciente Prueba');
      expect(captured.consentToStore, true);
    },
  );

  test('predictImage setea error cuando el análisis falla', () async {
    when(
      mockPredictImageUseCase.call(any),
    ).thenThrow(Exception('No se pudo completar el analisis de la imagen.'));

    await container
        .read(predictionViewModelProvider.notifier)
        .predictImage(tempImage, consentToStore: false);

    final state = container.read(predictionViewModelProvider);
    expect(state.result, isNull);
    expect(state.isLoading, false);
    expect(state.error, isNotNull);
  });
}
