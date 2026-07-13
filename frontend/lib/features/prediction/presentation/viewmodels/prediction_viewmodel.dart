import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/prediction/di/prediction_providers.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_image_input.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_result.dart';

class PredictionState {
  final PredictionResult? result;
  final bool isLoading;
  final String? error;
  final String? analysisStatusMessage;
  final String? patientId;
  final String? patientName;
  final String? lesionId;

  const PredictionState({
    this.result,
    this.isLoading = false,
    this.error,
    this.analysisStatusMessage,
    this.patientId,
    this.patientName,
    this.lesionId,
  });

  PredictionState copyWith({
    PredictionResult? result,
    bool? isLoading,
    String? error,
    String? analysisStatusMessage,
    String? patientId,
    String? patientName,
    String? lesionId,
    bool clearResult = false,
    bool clearError = false,
    bool clearStatus = false,
    bool clearPatient = false,
  }) {
    return PredictionState(
      result: clearResult ? null : result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      analysisStatusMessage: clearStatus
          ? null
          : analysisStatusMessage ?? this.analysisStatusMessage,
      patientId: clearPatient ? null : patientId ?? this.patientId,
      patientName: clearPatient ? null : patientName ?? this.patientName,
      lesionId: clearPatient ? null : lesionId ?? this.lesionId,
    );
  }
}

class PredictionViewModel extends Notifier<PredictionState> {
  @override
  PredictionState build() {
    return const PredictionState();
  }

  Future<void> predictImage(
    File image, {
    String? patientId,
    String? patientName,
    required bool consentToStore,
    String? lesionId,
  }) async {
    final stopwatch = Stopwatch()..start();

    state = PredictionState(
      isLoading: true,
      patientId: patientId,
      patientName: patientName,
      lesionId: lesionId,
      analysisStatusMessage: 'Enviando imagen para analisis...',
    );

    try {
      final result = await ref.read(predictImageUseCaseProvider)(
        PredictionImageInput(
          imagePath: image.path,
          consentToStore: consentToStore,
          patientId: patientId,
          patientName: patientName,
          lesionId: lesionId,
        ),
      );
      state = state.copyWith(
        result: result,
        analysisStatusMessage: 'Procesando resultado...',
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      if (state.error == null) {
        const minimumLoadingDuration = Duration(milliseconds: 900);
        final remainingTime = minimumLoadingDuration - stopwatch.elapsed;
        if (remainingTime.inMilliseconds > 0) {
          await Future<void>.delayed(remainingTime);
        }
      }

      state = state.copyWith(isLoading: false, clearStatus: true);
    }
  }

  void clearResult() {
    state = const PredictionState();
  }
}

final predictionViewModelProvider =
    NotifierProvider<PredictionViewModel, PredictionState>(
      PredictionViewModel.new,
    );
