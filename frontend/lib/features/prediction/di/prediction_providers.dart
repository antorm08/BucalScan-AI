import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/prediction/data/datasources/prediction_remote_datasource.dart';
import 'package:bucalscan_ai/features/prediction/data/repositories/prediction_repository_impl.dart';
import 'package:bucalscan_ai/features/prediction/domain/repositories/prediction_repository.dart';
import 'package:bucalscan_ai/features/prediction/domain/usecases/predict_image_usecase.dart';

final predictionRemoteDataSourceProvider = Provider<PredictionRemoteDataSource>(
  (ref) {
    return PredictionRemoteDataSource(ref.watch(authApiServiceProvider));
  },
);

final predictionRepositoryProvider = Provider<PredictionRepository>((ref) {
  return PredictionRepositoryImpl(
    ref.watch(predictionRemoteDataSourceProvider),
  );
});

final predictImageUseCaseProvider = Provider<PredictImageUseCase>((ref) {
  return PredictImageUseCase(ref.watch(predictionRepositoryProvider));
});
