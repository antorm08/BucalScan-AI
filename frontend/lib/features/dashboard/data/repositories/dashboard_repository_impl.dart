import 'package:bucalscan_ai/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:bucalscan_ai/features/dashboard/domain/entities/daily_summary.dart';
import 'package:bucalscan_ai/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  const DashboardRepositoryImpl(this._remoteDataSource);

  @override
  Future<DailySummary> getTodaySummary() async {
    final model = await _remoteDataSource.getTodaySummary();
    return model.toEntity();
  }
}
