import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/prediction/di/prediction_providers.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_image_input.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_result.dart';

enum AnalysisAttemptStatus {
  idle,
  contextReady,
  imageReady,
  submitting,
  succeeded,
  failed,
}

class AnalysisAttemptSnapshot {
  final String imagePath;
  final String patientId;
  final String patientName;
  final String lesionId;
  final String clinicalCode;
  final String lesionSite;
  final String? clinicalObservations;
  final Map<String, String>? assessment;
  final bool consentToStore;

  const AnalysisAttemptSnapshot({
    required this.imagePath,
    required this.patientId,
    required this.patientName,
    required this.lesionId,
    required this.clinicalCode,
    required this.lesionSite,
    required this.consentToStore,
    this.clinicalObservations,
    this.assessment,
  });
}

class PredictionState {
  final PredictionResult? result;
  final bool isLoading;
  final String? error;
  final String? analysisStatusMessage;
  final String? patientId;
  final String? patientName;
  final String? lesionId;
  final AnalysisAttemptStatus status;
  final AnalysisAttemptSnapshot? attempt;
  final String? clinicalCode;
  final String? lesionSite;

  const PredictionState({
    this.result,
    this.isLoading = false,
    this.error,
    this.analysisStatusMessage,
    this.patientId,
    this.patientName,
    this.lesionId,
    this.status = AnalysisAttemptStatus.idle,
    this.attempt,
    this.clinicalCode,
    this.lesionSite,
  });

  PredictionState copyWith({
    PredictionResult? result,
    bool? isLoading,
    String? error,
    String? analysisStatusMessage,
    String? patientId,
    String? patientName,
    String? lesionId,
    String? clinicalCode,
    String? lesionSite,
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
      status: result != null
          ? AnalysisAttemptStatus.succeeded
          : error != null
          ? AnalysisAttemptStatus.failed
          : isLoading == true
          ? AnalysisAttemptStatus.submitting
          : status,
      attempt: attempt,
      clinicalCode: clearPatient ? null : clinicalCode ?? this.clinicalCode,
      lesionSite: clearPatient ? null : lesionSite ?? this.lesionSite,
    );
  }
}

class PredictionViewModel extends Notifier<PredictionState> {
  int _generation = 0;

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
    String? clinicalObservations,
    Map<String, String>? assessment,
    String? clinicalCode,
    String? lesionSite,
  }) async {
    if (state.status == AnalysisAttemptStatus.submitting) return;
    final generation = ++_generation;
    final stopwatch = Stopwatch()..start();

    final attempt = AnalysisAttemptSnapshot(
      imagePath: image.path,
      patientId: patientId ?? '',
      patientName: patientName ?? '',
      lesionId: lesionId ?? '',
      consentToStore: consentToStore,
      clinicalObservations: clinicalObservations,
      assessment: assessment == null ? null : Map.unmodifiable(assessment),
      clinicalCode: clinicalCode ?? '',
      lesionSite: lesionSite ?? '',
    );
    state = PredictionState(
      isLoading: true,
      patientId: patientId,
      patientName: patientName,
      lesionId: lesionId,
      analysisStatusMessage: 'Enviando imagen para analisis...',
      status: AnalysisAttemptStatus.submitting,
      attempt: attempt,
      clinicalCode: clinicalCode,
      lesionSite: lesionSite,
    );

    try {
      final result = await ref.read(predictImageUseCaseProvider)(
        PredictionImageInput(
          imagePath: image.path,
          consentToStore: consentToStore,
          patientId: patientId,
          patientName: patientName,
          lesionId: lesionId,
          clinicalObservations: clinicalObservations,
          assessment: assessment,
        ),
      );
      if (generation != _generation) return;
      state = state.copyWith(
        result: result,
        analysisStatusMessage: 'Procesando resultado...',
      );
    } catch (e) {
      if (generation != _generation) return;
      state = state.copyWith(error: e.toString());
    } finally {
      if (generation == _generation) {
        if (state.error == null) {
          const minimumLoadingDuration = Duration(milliseconds: 900);
          final remainingTime = minimumLoadingDuration - stopwatch.elapsed;
          if (remainingTime.inMilliseconds > 0) {
            await Future<void>.delayed(remainingTime);
          }
        }

        if (generation == _generation) {
          state = state.copyWith(isLoading: false, clearStatus: true);
        }
      }
    }
  }

  void clearResult() {
    _generation++;
    state = const PredictionState();
  }

  void prepareContext({
    required String patientId,
    required String patientName,
    required String lesionId,
    String? clinicalCode,
    String? lesionSite,
  }) {
    _generation++;
    state = PredictionState(
      patientId: patientId,
      patientName: patientName,
      lesionId: lesionId,
      clinicalCode: clinicalCode,
      lesionSite: lesionSite,
      status: AnalysisAttemptStatus.contextReady,
    );
  }

  void prepareImage() {
    if (state.status != AnalysisAttemptStatus.contextReady &&
        state.status != AnalysisAttemptStatus.imageReady) {
      return;
    }
    state = PredictionState(
      patientId: state.patientId,
      patientName: state.patientName,
      lesionId: state.lesionId,
      clinicalCode: state.clinicalCode,
      lesionSite: state.lesionSite,
      status: AnalysisAttemptStatus.imageReady,
    );
  }

  Future<void> retry() async {
    final attempt = state.attempt;
    if (attempt == null) return;
    await predictImage(
      File(attempt.imagePath),
      patientId: attempt.patientId,
      patientName: attempt.patientName,
      lesionId: attempt.lesionId,
      consentToStore: attempt.consentToStore,
      clinicalObservations: attempt.clinicalObservations,
      assessment: attempt.assessment,
      clinicalCode: attempt.clinicalCode,
      lesionSite: attempt.lesionSite,
    );
  }
}

final predictionViewModelProvider =
    NotifierProvider<PredictionViewModel, PredictionState>(
      PredictionViewModel.new,
    );
