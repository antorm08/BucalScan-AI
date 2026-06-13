import 'package:bucalscan_ai/features/dashboard/domain/entities/daily_summary.dart';

abstract class DashboardRepository {
  Future<DailySummary> getTodaySummary();
}
