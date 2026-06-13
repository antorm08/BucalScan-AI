import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/features/dashboard/data/models/daily_summary_model.dart';

class DashboardRemoteDataSource {
  final ApiService _apiService;

  const DashboardRemoteDataSource(this._apiService);

  Future<DailySummaryModel> getTodaySummary() async {
    final model = await _apiService.getTodaySummary();
    return DailySummaryModel(
      total: model.total,
      benign: model.benign,
      malignant: model.malignant,
      latestAnalysisAt: model.latestAnalysisAt,
    );
  }
}
