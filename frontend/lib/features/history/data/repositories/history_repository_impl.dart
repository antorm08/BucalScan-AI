import 'package:bucalscan_ai/features/history/data/datasources/history_remote_datasource.dart';
import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';
import 'package:bucalscan_ai/features/history/domain/repositories/history_repository.dart';
import 'package:bucalscan_ai/features/history/domain/entities/history_query.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource _remoteDataSource;

  const HistoryRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Analysis>> getHistory() async {
    final models = await _remoteDataSource.getHistory();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<HistoryPage> getHistoryPage(
    HistoryCriteria criteria, {
    required int page,
  }) async =>
      (await _remoteDataSource.getHistoryPage(criteria, page: page)).toEntity();
}
