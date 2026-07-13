import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';

enum HistorySort {
  evaluatedAt,
  confidence,
  patientName,
  modelVersion,
  lesionSite,
}

enum SortDirection { ascending, descending }

class HistoryCriteria {
  final String search;
  final String? modelLabel;
  final String? priorityCode;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final HistorySort sort;
  final SortDirection direction;
  final int pageSize;

  const HistoryCriteria({
    this.search = '',
    this.modelLabel,
    this.priorityCode,
    this.dateFrom,
    this.dateTo,
    this.sort = HistorySort.evaluatedAt,
    this.direction = SortDirection.descending,
    this.pageSize = 25,
  });

  bool get hasFilters =>
      search.trim().isNotEmpty ||
      modelLabel != null ||
      priorityCode != null ||
      dateFrom != null ||
      dateTo != null;

  String get queryKey => [
    search.trim().toLowerCase(),
    modelLabel ?? '',
    priorityCode ?? '',
    dateFrom?.toUtc().toIso8601String() ?? '',
    dateTo?.toUtc().toIso8601String() ?? '',
    sort.name,
    direction.name,
    pageSize,
  ].join('|');

  Map<String, dynamic> toQuery(int page) => {
    if (search.trim().isNotEmpty) 'search': search.trim(),
    if (modelLabel != null) 'model_label': modelLabel,
    if (priorityCode != null) 'priority': priorityCode,
    if (dateFrom != null) 'date_from': dateFrom!.toUtc().toIso8601String(),
    if (dateTo != null) 'date_to': dateTo!.toUtc().toIso8601String(),
    'sort_by': switch (sort) {
      HistorySort.evaluatedAt => 'evaluated_at',
      HistorySort.confidence => 'confidence',
      HistorySort.patientName => 'patient_name',
      HistorySort.modelVersion => 'model_version',
      HistorySort.lesionSite => 'lesion_site',
    },
    'sort_direction': direction == SortDirection.descending ? 'desc' : 'asc',
    'page': page,
    'page_size': pageSize,
  };

  HistoryCriteria copyWith({
    String? search,
    String? modelLabel,
    String? priorityCode,
    DateTime? dateFrom,
    DateTime? dateTo,
    HistorySort? sort,
    SortDirection? direction,
    bool clearModel = false,
    bool clearPriority = false,
    bool clearDates = false,
  }) => HistoryCriteria(
    search: search ?? this.search,
    modelLabel: clearModel ? null : modelLabel ?? this.modelLabel,
    priorityCode: clearPriority ? null : priorityCode ?? this.priorityCode,
    dateFrom: clearDates ? null : dateFrom ?? this.dateFrom,
    dateTo: clearDates ? null : dateTo ?? this.dateTo,
    sort: sort ?? this.sort,
    direction: direction ?? this.direction,
    pageSize: pageSize,
  );
}

class HistoryPage {
  final List<Analysis> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasNext;
  final bool priorityFilterEnabled;

  const HistoryPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasNext,
    required this.priorityFilterEnabled,
  });
}
