import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/features/history/data/models/analysis_model.dart';
import 'package:bucalscan_ai/features/history/data/models/history_page_model.dart';
import 'package:bucalscan_ai/features/history/domain/entities/history_query.dart';

class HistoryRemoteDataSource {
  final ApiService _apiService;

  const HistoryRemoteDataSource(this._apiService);

  Future<List<AnalysisModel>> getHistory() async {
    final data = await _apiService.getHistory();
    return data.map(AnalysisModel.fromJson).toList();
  }

  Future<HistoryPageModel> getHistoryPage(
    HistoryCriteria criteria, {
    required int page,
  }) async => HistoryPageModel.fromJson(
    await _apiService.getHistoryPage(criteria.toQuery(page)),
  );
}
