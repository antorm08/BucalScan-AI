import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_image_input.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_result.dart';

abstract class PredictionRepository {
  Future<PredictionResult> predictImage(PredictionImageInput input);
}
