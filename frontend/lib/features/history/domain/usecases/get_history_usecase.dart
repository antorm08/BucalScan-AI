import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';
import 'package:bucalscan_ai/features/history/domain/repositories/history_repository.dart';

class GetHistoryUseCase {
  final HistoryRepository _repository;

  const GetHistoryUseCase(this._repository);

  Future<List<Analysis>> call() {
    return _repository.getHistory();
  }
}
