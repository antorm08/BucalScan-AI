import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/prediction/data/datasources/prediction_remote_datasource.dart';
import 'package:bucalscan_ai/features/prediction/data/repositories/prediction_repository_impl.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_image_input.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_result.dart';
import 'package:bucalscan_ai/features/prediction/domain/repositories/prediction_repository.dart';
import 'package:bucalscan_ai/features/prediction/domain/usecases/predict_image_usecase.dart';

final predictionRemoteDataSourceProvider = Provider<PredictionRemoteDataSource>((ref) {
  return PredictionRemoteDataSource(ref.watch(authApiServiceProvider));
});

final predictionRepositoryProvider = Provider<PredictionRepository>((ref) {
  return PredictionRepositoryImpl(ref.watch(predictionRemoteDataSourceProvider));
});

final predictImageUseCaseProvider = Provider<PredictImageUseCase>((ref) {
  return PredictImageUseCase(ref.watch(predictionRepositoryProvider));
});

final predictionControllerProvider =
    StateNotifierProvider<PredictionController, PredictionState>((ref) {
      return PredictionController(ref.watch(predictImageUseCaseProvider));
    });

class PredictionState {
  final bool isLoading;
  final String? error;
  final PredictionResult? result;

  const PredictionState({this.isLoading = false, this.error, this.result});
}

class PredictionController extends StateNotifier<PredictionState> {
  final PredictImageUseCase _predictImageUseCase;

  PredictionController(this._predictImageUseCase)
    : super(const PredictionState());

  Future<void> predictImage(
    File image, {
    String? patientId,
    String? patientName,
  }) async {
    state = const PredictionState(isLoading: true);
    try {
      final result = await _predictImageUseCase(
        PredictionImageInput(
          imagePath: image.path,
          patientId: patientId,
          patientName: patientName,
        ),
      );
      state = PredictionState(result: result);
    } catch (e) {
      state = PredictionState(error: e.toString());
    }
  }
}
