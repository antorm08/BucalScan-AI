import 'package:flutter/foundation.dart';
import 'package:bucalscan_ai/data/repositories/history_repository.dart';
import 'package:bucalscan_ai/domain/entities/analysis.dart';

class HistoryViewModel extends ChangeNotifier {
  final HistoryRepository _repository;

  HistoryViewModel(this._repository);

  final List<Analysis> _history = [];
  bool _isLoading = false;
  String? _error;
  String _filter = 'Todos';
  String _searchQuery = '';

  List<Analysis> get history => _filteredHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filter => _filter;
  String get searchQuery => _searchQuery;

  List<Analysis> get _filteredHistory {
    var filtered = List<Analysis>.from(_history);

    if (_filter != 'Todos') {
      filtered = filtered.where((a) {
        final pred = a.prediction.toLowerCase();
        if (_filter == 'Maligna') return pred == 'malignant';
        if (_filter == 'Benigna') return pred == 'benign';
        return true;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((a) {
        return a.prediction.toLowerCase().contains(query) ||
            a.timestamp.toString().toLowerCase().contains(query) ||
            a.id.toString().contains(query);
      }).toList();
    }

    return filtered;
  }

  Future<void> fetchHistory(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final models = await _repository.getHistory(userId);
      _history.clear();
      _history.addAll(models.map((m) {
        DateTime parsedTimestamp;
        try {
          parsedTimestamp = DateTime.parse(m.timestamp);
        } catch (_) {
          parsedTimestamp = DateTime.now();
        }
        return Analysis(
          id: m.id,
          prediction: m.prediction,
          confidence: m.confidence,
          timestamp: parsedTimestamp,
          imageUrl: m.imageUrl,
        );
      }));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clear() {
    _history.clear();
    _error = null;
    _filter = 'Todos';
    _searchQuery = '';
    notifyListeners();
  }
}
