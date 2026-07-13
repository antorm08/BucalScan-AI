import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';
import 'package:bucalscan_ai/features/history/domain/entities/history_query.dart';

abstract class HistoryRepository {
  Future<List<Analysis>> getHistory();

  Future<HistoryPage> getHistoryPage(
    HistoryCriteria criteria, {
    required int page,
  }) async {
    final items = await getHistory();
    return HistoryPage(
      items: items,
      page: 1,
      pageSize: items.length,
      total: items.length,
      hasNext: false,
      priorityFilterEnabled: false,
    );
  }
}
