import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:bucalscan_ai/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:bucalscan_ai/features/dashboard/domain/entities/daily_summary.dart';
import 'package:bucalscan_ai/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:bucalscan_ai/features/dashboard/domain/usecases/get_today_summary_usecase.dart';

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

class SummaryState {
  final DailySummary? summary;
  final bool isLoading;
  final String? error;

  const SummaryState({this.summary, this.isLoading = false, this.error});

  bool get isEmpty => (summary?.total ?? 0) == 0;

  SummaryState copyWith({
    DailySummary? summary,
    bool? isLoading,
    String? error,
    bool clearSummary = false,
    bool clearError = false,
  }) {
    return SummaryState(
      summary: clearSummary ? null : summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class SummaryViewModel extends Notifier<SummaryState> {
  @override
  SummaryState build() {
    return const SummaryState();
  }

  Future<void> fetchTodaySummary() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final summary = await ref.read(getTodaySummaryUseCaseProvider)();
      state = SummaryState(summary: summary);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const SummaryState();
  }
}

final summaryViewModelProvider =
    NotifierProvider<SummaryViewModel, SummaryState>(SummaryViewModel.new);
