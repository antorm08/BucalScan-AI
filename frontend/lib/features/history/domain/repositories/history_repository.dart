import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';

abstract class HistoryRepository {
  Future<List<Analysis>> getHistory();
}
