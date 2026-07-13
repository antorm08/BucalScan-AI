import 'dart:async';

import 'package:bucalscan_ai/features/history/di/history_providers.dart';
import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';
import 'package:bucalscan_ai/features/history/domain/entities/history_query.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryState {
  final List<Analysis> items;
  final HistoryCriteria criteria;
  final bool isLoading;
  final bool isRefreshing;
  final bool isAppending;
  final String? error;
  final int page;
  final int total;
  final bool hasNext;
  final bool priorityFilterEnabled;

  const HistoryState({
    this.items = const [],
    this.criteria = const HistoryCriteria(),
    this.isLoading = false,
    this.isRefreshing = false,
    this.isAppending = false,
    this.error,
    this.page = 0,
    this.total = 0,
    this.hasNext = false,
    this.priorityFilterEnabled = false,
  });

  List<Analysis> get history => items;
  List<Analysis> get allHistory => items;
  bool get hasAnyHistory => total > 0 || items.isNotEmpty;
  bool get hasActiveSearchOrFilter => criteria.hasFilters;
  String get searchQuery => criteria.search;
  bool get dateSortDescending => criteria.direction == SortDirection.descending;
  String get filter => switch (criteria.modelLabel) {
    'malignant' => 'Maligna',
    'benign' => 'Benigna',
    _ => criteria.sort == HistorySort.evaluatedAt ? 'Fecha' : 'Todos',
  };

  HistoryState copyWith({
    List<Analysis>? items,
    HistoryCriteria? criteria,
    bool? isLoading,
    bool? isRefreshing,
    bool? isAppending,
    String? error,
    int? page,
    int? total,
    bool? hasNext,
    bool? priorityFilterEnabled,
    bool clearError = false,
  }) => HistoryState(
    items: items ?? this.items,
    criteria: criteria ?? this.criteria,
    isLoading: isLoading ?? this.isLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isAppending: isAppending ?? this.isAppending,
    error: clearError ? null : error ?? this.error,
    page: page ?? this.page,
    total: total ?? this.total,
    hasNext: hasNext ?? this.hasNext,
    priorityFilterEnabled: priorityFilterEnabled ?? this.priorityFilterEnabled,
  );
}

class HistoryViewModel extends Notifier<HistoryState> {
  int _generation = 0;
  Timer? _searchDebounce;

  @override
  HistoryState build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return const HistoryState();
  }

  Future<void> fetchHistory() => refresh();

  Future<void> refresh() async {
    _searchDebounce?.cancel();
    final generation = ++_generation;
    final criteria = state.criteria;
    state = state.copyWith(
      isLoading: state.items.isEmpty,
      isRefreshing: state.items.isNotEmpty,
      isAppending: false,
      clearError: true,
    );
    await _requestFirst(criteria, generation);
  }

  Future<void> _replace(
    HistoryCriteria criteria, {
    bool debounce = false,
  }) async {
    _searchDebounce?.cancel();
    final generation = ++_generation;
    state = HistoryState(
      criteria: criteria,
      isLoading: true,
      priorityFilterEnabled: state.priorityFilterEnabled,
    );
    if (debounce) {
      _searchDebounce = Timer(
        const Duration(milliseconds: 350),
        () => _requestFirst(criteria, generation),
      );
      return;
    }
    await _requestFirst(criteria, generation);
  }

  Future<void> _requestFirst(HistoryCriteria criteria, int generation) async {
    try {
      final result = await ref.read(getHistoryPageUseCaseProvider)(
        criteria,
        page: 1,
      );
      if (generation != _generation ||
          criteria.queryKey != state.criteria.queryKey) {
        return;
      }
      state = state.copyWith(
        items: result.items,
        page: result.page,
        total: result.total,
        hasNext: result.hasNext,
        priorityFilterEnabled: result.priorityFilterEnabled,
        isLoading: false,
        isRefreshing: false,
        clearError: true,
      );
    } catch (_) {
      if (generation != _generation ||
          criteria.queryKey != state.criteria.queryKey) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: 'No se pudo cargar el historial. Intente nuevamente.',
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasNext ||
        state.isLoading ||
        state.isRefreshing ||
        state.isAppending) {
      return;
    }
    final generation = _generation;
    final criteria = state.criteria;
    final queryKey = criteria.queryKey;
    final nextPage = state.page + 1;
    state = state.copyWith(isAppending: true, clearError: true);
    try {
      final result = await ref.read(getHistoryPageUseCaseProvider)(
        criteria,
        page: nextPage,
      );
      if (generation != _generation ||
          queryKey != state.criteria.queryKey ||
          result.page != nextPage) {
        return;
      }
      final knownIds = state.items.map((item) => item.id).toSet();
      state = state.copyWith(
        items: [
          ...state.items,
          ...result.items.where((item) => knownIds.add(item.id)),
        ],
        page: result.page,
        total: result.total,
        hasNext: result.hasNext,
        priorityFilterEnabled: result.priorityFilterEnabled,
        isAppending: false,
      );
    } catch (_) {
      if (generation != _generation || queryKey != state.criteria.queryKey) {
        return;
      }
      state = state.copyWith(
        isAppending: false,
        error: 'No se pudieron cargar más resultados.',
      );
    }
  }

  void setSearchQuery(String query) {
    _replace(state.criteria.copyWith(search: query.trim()), debounce: true);
  }

  Future<void> setModelLabel(String? value) => _replace(
    state.criteria.copyWith(modelLabel: value, clearModel: value == null),
  );

  Future<void> setPriorityCode(String? value) => _replace(
    state.criteria.copyWith(priorityCode: value, clearPriority: value == null),
  );

  Future<void> setDateRange(DateTime? from, DateTime? to) {
    final utcFrom = from == null
        ? null
        : DateTime.utc(from.year, from.month, from.day);
    final utcTo = to == null
        ? null
        : DateTime.utc(to.year, to.month, to.day, 23, 59, 59, 999, 999);
    return _replace(
      state.criteria.copyWith(
        dateFrom: utcFrom,
        dateTo: utcTo,
        clearDates: from == null && to == null,
      ),
    );
  }

  Future<void> setSort(HistorySort sort, SortDirection direction) =>
      _replace(state.criteria.copyWith(sort: sort, direction: direction));

  Future<void> clearFilters() => _replace(const HistoryCriteria());

  void setFilter(String filter) {
    switch (filter) {
      case 'Maligna':
        setModelLabel('malignant');
        return;
      case 'Benigna':
        setModelLabel('benign');
        return;
      case 'Fecha':
        setSort(
          HistorySort.evaluatedAt,
          state.criteria.direction == SortDirection.descending
              ? SortDirection.ascending
              : SortDirection.descending,
        );
        return;
      default:
        setModelLabel(null);
        return;
    }
  }

  void clear() {
    _searchDebounce?.cancel();
    _generation++;
    state = const HistoryState();
  }
}

final historyViewModelProvider =
    NotifierProvider<HistoryViewModel, HistoryState>(HistoryViewModel.new);
