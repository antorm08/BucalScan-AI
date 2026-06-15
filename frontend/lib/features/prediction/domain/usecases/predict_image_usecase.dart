import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_image_input.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_result.dart';
import 'package:bucalscan_ai/features/prediction/domain/repositories/prediction_repository.dart';

class PredictImageUseCase {
  final PredictionRepository _repository;

  const PredictImageUseCase(this._repository);

  Future<PredictionResult> call(PredictionImageInput input) {
    return _repository.predictImage(input);
  }
}
