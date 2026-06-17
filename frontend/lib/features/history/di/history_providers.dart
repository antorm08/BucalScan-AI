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

class HistoryState {
  final List<Analysis> allHistory;
  final bool isLoading;
  final String? error;
  final String filter;
  final String searchQuery;
  final bool dateSortDescending;

  const HistoryState({
    this.allHistory = const [],
    this.isLoading = false,
    this.error,
    this.filter = 'Todos',
    this.searchQuery = '',
    this.dateSortDescending = true,
  });

  List<Analysis> get history {
    var filtered = List<Analysis>.from(allHistory);

    if (filter == 'Fecha') {
      filtered.sort((a, b) {
        final comparison = a.timestamp.compareTo(b.timestamp);
        return dateSortDescending ? -comparison : comparison;
      });
    }

    if (filter != 'Todos') {
      filtered = filtered.where((a) {
        final pred = a.prediction.toLowerCase();
        if (filter == 'Fecha') return true;
        if (filter == 'Maligna') return pred == 'malignant';
        if (filter == 'Benigna') return pred == 'benign';
        return true;
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((a) {
        return a.prediction.toLowerCase().contains(query) ||
            a.timestamp.toString().toLowerCase().contains(query) ||
            a.id.toString().contains(query) ||
            (a.patientId?.toLowerCase().contains(query) ?? false) ||
            (a.patientName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  bool get hasAnyHistory => allHistory.isNotEmpty;
  bool get hasActiveSearchOrFilter =>
      searchQuery.isNotEmpty || (filter != 'Todos' && filter != 'Fecha');

  HistoryState copyWith({
    List<Analysis>? allHistory,
    bool? isLoading,
    String? error,
    String? filter,
    String? searchQuery,
    bool? dateSortDescending,
    bool clearHistory = false,
    bool clearError = false,
  }) {
    return HistoryState(
      allHistory: clearHistory ? const [] : allHistory ?? this.allHistory,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      dateSortDescending: dateSortDescending ?? this.dateSortDescending,
    );
  }
}

class HistoryViewModel extends Notifier<HistoryState> {
  @override
  HistoryState build() {
    return const HistoryState();
  }

  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final analyses = await ref.read(getHistoryUseCaseProvider)();
      state = state.copyWith(allHistory: analyses, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(String filter) {
    if (filter == 'Fecha' && state.filter == 'Fecha') {
      state = state.copyWith(dateSortDescending: !state.dateSortDescending);
      return;
    }

    state = state.copyWith(
      filter: filter,
      dateSortDescending: filter == 'Fecha' ? true : state.dateSortDescending,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clear() {
    state = const HistoryState();
  }
}

final historyViewModelProvider =
    NotifierProvider<HistoryViewModel, HistoryState>(HistoryViewModel.new);
