import 'package:bucalscan_ai/features/history/data/models/analysis_model.dart';
import 'package:bucalscan_ai/features/history/domain/entities/history_query.dart';

class HistoryPageModel {
  final List<AnalysisModel> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasNext;
  final bool priorityFilterEnabled;

  const HistoryPageModel({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasNext,
    required this.priorityFilterEnabled,
  });

  factory HistoryPageModel.fromJson(Object? data) {
    if (data is List) {
      final items = data
          .map(
            (item) =>
                AnalysisModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      return HistoryPageModel(
        items: items,
        page: 1,
        pageSize: items.length,
        total: items.length,
        hasNext: false,
        priorityFilterEnabled: false,
      );
    }
    final json = Map<String, dynamic>.from(data as Map);
    return HistoryPageModel(
      items: (json['items'] as List? ?? const [])
          .map(
            (item) =>
                AnalysisModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 25,
      total: json['total'] as int? ?? 0,
      hasNext: json['has_next'] as bool? ?? false,
      priorityFilterEnabled: json['priority_filter_enabled'] as bool? ?? false,
    );
  }

  HistoryPage toEntity() => HistoryPage(
    items: items.map((item) => item.toEntity()).toList(),
    page: page,
    pageSize: pageSize,
    total: total,
    hasNext: hasNext,
    priorityFilterEnabled: priorityFilterEnabled,
  );
}
