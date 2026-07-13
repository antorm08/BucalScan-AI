import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';
import 'package:bucalscan_ai/features/history/domain/repositories/history_repository.dart';
import 'package:bucalscan_ai/features/history/domain/entities/history_query.dart';

class GetHistoryUseCase {
  final HistoryRepository _repository;

  const GetHistoryUseCase(this._repository);

  Future<List<Analysis>> call() {
    return _repository.getHistory();
  }
}

class GetHistoryPageUseCase {
  final HistoryRepository _repository;

  const GetHistoryPageUseCase(this._repository);

  Future<HistoryPage> call(HistoryCriteria criteria, {required int page}) =>
      _repository.getHistoryPage(criteria, page: page);
}
