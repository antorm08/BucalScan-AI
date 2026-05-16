import 'dart:io';
import 'package:bucalscan_ai/data/models/prediction_result_model.dart';
import 'package:bucalscan_ai/data/services/api_service.dart';

class PredictionRepository {
  final ApiService _apiService;

  PredictionRepository(this._apiService);

  Future<PredictionResultModel> predictImage(
    File image, {
    int userId = 1,
    String? patientId,
    String? patientName,
  }) async {
    return _apiService.predictImage(
      image,
      userId: userId,
      patientId: patientId,
      patientName: patientName,
    );
  }
}
