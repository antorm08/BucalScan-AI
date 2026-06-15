import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/features/dashboard/data/models/daily_summary_model.dart';

class DashboardRemoteDataSource {
  final ApiService _apiService;

  const DashboardRemoteDataSource(this._apiService);

  Future<DailySummaryModel> getTodaySummary() async {
    final json = await _apiService.getTodaySummary();
    return DailySummaryModel.fromJson(json);
  }
}
