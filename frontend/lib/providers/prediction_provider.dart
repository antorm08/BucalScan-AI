import 'dart:io';
import 'package:flutter/material.dart';
import 'package:oral_lesion_detector/models/prediction_result.dart';
import 'package:oral_lesion_detector/services/api_service.dart';

class PredictionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  PredictionResult? _lastResult;
  bool _isLoading = false;
  String? _error;

  PredictionResult? get lastResult => _lastResult;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> predictImage(File image) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lastResult = await _apiService.predictImage(image);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _lastResult = null;
    _error = null;
    notifyListeners();
  }
}
