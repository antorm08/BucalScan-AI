import 'package:bucalscan_ai/data/models/analysis_model.dart';
import 'package:bucalscan_ai/data/services/api_service.dart';

class HistoryRepository {
  final ApiService _apiService;

  HistoryRepository(this._apiService);

  Future<List<AnalysisModel>> getHistory() async {
    return _apiService.getHistory();
  }
}
