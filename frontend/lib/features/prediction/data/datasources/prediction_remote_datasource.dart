import 'dart:io';

import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/features/prediction/data/models/prediction_result_model.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_image_input.dart';

class PredictionRemoteDataSource {
  final ApiService _apiService;

  const PredictionRemoteDataSource(this._apiService);

  Future<PredictionResultModel> predictImage(PredictionImageInput input) async {
    final json = await _apiService.predictImage(
      File(input.imagePath),
      patientId: input.patientId,
      patientName: input.patientName,
    );
    return PredictionResultModel.fromJson(json);
  }
}
