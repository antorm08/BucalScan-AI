import 'package:oral_lesion_detector/data/models/analysis_model.dart';
import 'package:oral_lesion_detector/data/services/api_service.dart';

class HistoryRepository {
  final ApiService _apiService;

  HistoryRepository(this._apiService);

  Future<List<AnalysisModel>> getHistory(int userId) async {
    return _apiService.getHistory(userId);
  }
}
