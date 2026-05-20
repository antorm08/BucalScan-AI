import 'package:bucalscan_ai/data/models/daily_summary_model.dart';
import 'package:bucalscan_ai/data/services/api_service.dart';

class SummaryRepository {
  final ApiService _apiService;

  SummaryRepository(this._apiService);

  Future<DailySummaryModel> getTodaySummary() async {
    return _apiService.getTodaySummary();
  }
}
