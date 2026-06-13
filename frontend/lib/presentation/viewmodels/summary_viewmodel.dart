import 'package:flutter/foundation.dart';
import 'package:bucalscan_ai/features/dashboard/domain/entities/daily_summary.dart';
import 'package:bucalscan_ai/features/dashboard/domain/usecases/get_today_summary_usecase.dart';

class SummaryViewModel extends ChangeNotifier {
  final GetTodaySummaryUseCase _getTodaySummaryUseCase;

  SummaryViewModel(this._getTodaySummaryUseCase);

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
      _summary = await _getTodaySummaryUseCase();
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
