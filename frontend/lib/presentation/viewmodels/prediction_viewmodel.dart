import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:bucalscan_ai/data/repositories/prediction_repository.dart';
import 'package:bucalscan_ai/domain/entities/prediction_result.dart';

class PredictionViewModel extends ChangeNotifier {
  final PredictionRepository _repository;

  PredictionViewModel(this._repository);

  PredictionResult? _result;
  bool _isLoading = false;
  String? _error;

  PredictionResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> predictImage(File image) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final model = await _repository.predictImage(image);
      _result = PredictionResult(
        prediction: model.prediction,
        confidence: model.confidence,
        recommendation: model.recommendation,
        probabilities: model.probabilities,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _result = null;
    _error = null;
    notifyListeners();
  }
}
