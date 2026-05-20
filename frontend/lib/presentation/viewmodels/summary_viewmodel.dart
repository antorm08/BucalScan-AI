import 'package:flutter/foundation.dart';
import 'package:bucalscan_ai/data/repositories/summary_repository.dart';
import 'package:bucalscan_ai/domain/entities/daily_summary.dart';

class SummaryViewModel extends ChangeNotifier {
  final SummaryRepository _repository;

  SummaryViewModel(this._repository);

  DailySummary? _summary;
  bool _isLoading = false;
  String? _error;

  DailySummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => (_summary?.total ?? 0) == 0;

  Future<void> fetchTodaySummary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final model = await _repository.getTodaySummary();
      DateTime? latestAnalysisAt;
      if (model.latestAnalysisAt != null && model.latestAnalysisAt!.isNotEmpty) {
        try {
          latestAnalysisAt = DateTime.parse(model.latestAnalysisAt!);
        } catch (_) {
          latestAnalysisAt = null;
        }
      }

      _summary = DailySummary(
        total: model.total,
        benign: model.benign,
        malignant: model.malignant,
        latestAnalysisAt: latestAnalysisAt,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _summary = null;
    _error = null;
    notifyListeners();
  }
}
