import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/history/data/datasources/history_remote_datasource.dart';
import 'package:bucalscan_ai/features/history/data/repositories/history_repository_impl.dart';
import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';
import 'package:bucalscan_ai/features/history/domain/repositories/history_repository.dart';
import 'package:bucalscan_ai/features/history/domain/usecases/get_history_usecase.dart';

final historyRemoteDataSourceProvider = Provider<HistoryRemoteDataSource>((
  ref,
) {
  return HistoryRemoteDataSource(ref.watch(authApiServiceProvider));
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl(ref.watch(historyRemoteDataSourceProvider));
});

final getHistoryUseCaseProvider = Provider<GetHistoryUseCase>((ref) {
  return GetHistoryUseCase(ref.watch(historyRepositoryProvider));
});

final historyControllerProvider =
    StateNotifierProvider<HistoryController, HistoryState>((ref) {
      return HistoryController(ref.watch(getHistoryUseCaseProvider));
    });

class HistoryState {
  final bool isLoading;
  final String? error;
  final List<Analysis> analyses;

  const HistoryState({
    this.isLoading = false,
    this.error,
    this.analyses = const [],
  });
}

class HistoryController extends StateNotifier<HistoryState> {
  final GetHistoryUseCase _getHistoryUseCase;

  HistoryController(this._getHistoryUseCase) : super(const HistoryState());

  Future<void> fetchHistory() async {
    state = const HistoryState(isLoading: true);
    try {
      final analyses = await _getHistoryUseCase();
      state = HistoryState(analyses: analyses);
    } catch (e) {
      state = HistoryState(error: e.toString());
    }
  }
}
