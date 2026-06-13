import 'package:bucalscan_ai/features/dashboard/domain/entities/daily_summary.dart';
import 'package:bucalscan_ai/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetTodaySummaryUseCase {
  final DashboardRepository _repository;

  const GetTodaySummaryUseCase(this._repository);

  Future<DailySummary> call() {
    return _repository.getTodaySummary();
  }
}
