import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:bucalscan_ai/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:bucalscan_ai/features/dashboard/domain/entities/daily_summary.dart';
import 'package:bucalscan_ai/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:bucalscan_ai/features/dashboard/domain/usecases/get_today_summary_usecase.dart';
import 'package:bucalscan_ai/features/dashboard/presentation/viewmodels/summary_viewmodel.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((
  ref,
) {
  return DashboardRemoteDataSource(ref.watch(authApiServiceProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));
});

final getTodaySummaryUseCaseProvider = Provider<GetTodaySummaryUseCase>((ref) {
  return GetTodaySummaryUseCase(ref.watch(dashboardRepositoryProvider));
});

final summaryViewModelProvider = ChangeNotifierProvider<SummaryViewModel>((
  ref,
) {
  return SummaryViewModel(ref.watch(getTodaySummaryUseCaseProvider));
});

final dashboardSummaryControllerProvider =
    StateNotifierProvider<DashboardSummaryController, DashboardSummaryState>((
      ref,
    ) {
      return DashboardSummaryController(
        ref.watch(getTodaySummaryUseCaseProvider),
      );
    });

class DashboardSummaryState {
  final bool isLoading;
  final String? error;
  final DailySummary? summary;

  const DashboardSummaryState({
    this.isLoading = false,
    this.error,
    this.summary,
  });
}

class DashboardSummaryController extends StateNotifier<DashboardSummaryState> {
  final GetTodaySummaryUseCase _getTodaySummaryUseCase;

  DashboardSummaryController(this._getTodaySummaryUseCase)
    : super(const DashboardSummaryState());

  Future<void> fetchTodaySummary() async {
    state = const DashboardSummaryState(isLoading: true);
    try {
      final summary = await _getTodaySummaryUseCase();
      state = DashboardSummaryState(summary: summary);
    } catch (e) {
      state = DashboardSummaryState(error: e.toString());
    }
  }
}
