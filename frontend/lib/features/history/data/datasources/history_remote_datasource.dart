import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/features/history/data/models/analysis_model.dart';

class HistoryRemoteDataSource {
  final ApiService _apiService;

  const HistoryRemoteDataSource(this._apiService);

  Future<List<AnalysisModel>> getHistory() async {
    final data = await _apiService.getHistory();
    return data.map(AnalysisModel.fromJson).toList();
  }
}
