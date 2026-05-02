import 'dart:io';
import 'package:oral_lesion_detector/data/models/prediction_result_model.dart';
import 'package:oral_lesion_detector/data/services/api_service.dart';

class PredictionRepository {
  final ApiService _apiService;

  PredictionRepository(this._apiService);

  Future<PredictionResultModel> predictImage(File image) async {
    return _apiService.predictImage(image);
  }
}
