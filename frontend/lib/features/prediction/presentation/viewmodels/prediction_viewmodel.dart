import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_image_input.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_result.dart';
import 'package:bucalscan_ai/features/prediction/domain/usecases/predict_image_usecase.dart';

class PredictionViewModel extends ChangeNotifier {
  final PredictImageUseCase _predictImageUseCase;

  PredictionViewModel(this._predictImageUseCase);

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
    String? patientId,
    String? patientName,
    required bool consentToStore,
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
      final result = await _predictImageUseCase(
        PredictionImageInput(
          imagePath: image.path,
          consentToStore: consentToStore,
          patientId: patientId,
          patientName: patientName,
        ),
      );
      _analysisStatusMessage = 'Procesando resultado...';
      _result = result;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (_error == null) {
        const minimumLoadingDuration = Duration(milliseconds: 900);
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
