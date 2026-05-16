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
  String? _analysisStatusMessage;
  String? _patientId;
  String? _patientName;

  PredictionResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get analysisStatusMessage => _analysisStatusMessage;
  String? get patientId => _patientId;
  String? get patientName => _patientName;

  Future<void> predictImage(
    File image, {
    int userId = 1,
    String? patientId,
    String? patientName,
  }) async {
    final stopwatch = Stopwatch()..start();

    _isLoading = true;
    _result = null;
    _error = null;
    _patientId = patientId;
    _patientName = patientName;
    _analysisStatusMessage = 'Enviando imagen para analisis...';
    notifyListeners();

    try {
      final model = await _repository.predictImage(
        image,
        userId: userId,
        patientId: patientId,
        patientName: patientName,
      );
      _analysisStatusMessage = 'Procesando resultado...';
      _result = PredictionResult(
        prediction: model.prediction,
        confidence: model.confidence,
        recommendation: model.recommendation,
        probabilities: model.probabilities,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      if (_error == null) {
        const minimumLoadingDuration = Duration(milliseconds: 3500);
        final remainingTime = minimumLoadingDuration - stopwatch.elapsed;
        if (remainingTime.inMilliseconds > 0) {
          await Future<void>.delayed(remainingTime);
        }
      }

      _isLoading = false;
      _analysisStatusMessage = null;
      notifyListeners();
    }
  }

  void clearResult() {
    _result = null;
    _error = null;
    _patientId = null;
    _patientName = null;
    _analysisStatusMessage = null;
    notifyListeners();
  }
}
