import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/auth/di/auth_viewmodel_provider.dart';
import 'package:bucalscan_ai/features/auth/domain/entities/auth_session.dart';
import 'package:bucalscan_ai/features/auth/domain/entities/auth_user.dart';
import 'package:bucalscan_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:bucalscan_ai/features/dashboard/di/dashboard_providers.dart';
import 'package:bucalscan_ai/features/dashboard/domain/entities/daily_summary.dart';
import 'package:bucalscan_ai/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:bucalscan_ai/features/history/di/history_providers.dart';
import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';
import 'package:bucalscan_ai/features/history/domain/repositories/history_repository.dart';
import 'package:bucalscan_ai/features/prediction/di/prediction_providers.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_image_input.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_result.dart';
import 'package:bucalscan_ai/features/prediction/domain/repositories/prediction_repository.dart';

void main() {
  test('auth controller stores logged in user', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(authViewModelProvider.notifier)
        .login(email: 'doctor@hospital.org', password: 'secret123');

    final state = container.read(authViewModelProvider);
    expect(success, isTrue);
    expect(state.currentUser?.email, 'doctor@hospital.org');
    expect(state.isAuthenticated, isTrue);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
  });

  test('summary controller loads today summary', () async {
    final container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(
          _FakeDashboardRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(summaryViewModelProvider.notifier).fetchTodaySummary();

    final state = container.read(summaryViewModelProvider);
    expect(state.summary?.total, 3);
    expect(state.summary?.malignant, 1);
    expect(state.isEmpty, isFalse);
    expect(state.error, isNull);
  });

  test('history controller filters malignant analyses', () async {
    final container = ProviderContainer(
      overrides: [
        historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(historyViewModelProvider.notifier).fetchHistory();
    container.read(historyViewModelProvider.notifier).setFilter('Maligna');

    final state = container.read(historyViewModelProvider);
    expect(state.history, hasLength(1));
    expect(state.history.single.prediction, 'malignant');
    expect(state.hasAnyHistory, isTrue);
    expect(state.hasActiveSearchOrFilter, isTrue);
  });

  test('prediction controller stores prediction result', () async {
    final container = ProviderContainer(
      overrides: [
        predictionRepositoryProvider.overrideWithValue(
          _FakePredictionRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final tempImage = File('${Directory.systemTemp.path}/bucalscan-test.jpg');
    await tempImage.writeAsBytes([1, 2, 3]);
    addTearDown(() {
      if (tempImage.existsSync()) {
        tempImage.deleteSync();
      }
    });

    await container
        .read(predictionViewModelProvider.notifier)
        .predictImage(
          tempImage,
          patientId: 'P-001',
          patientName: 'Paciente Prueba',
          consentToStore: true,
        );

    final state = container.read(predictionViewModelProvider);
    expect(state.result?.prediction, 'benign');
    expect(state.patientId, 'P-001');
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
  });
}

class _FakeAuthRepository implements AuthRepository {
  static const user = AuthUser(
    id: 1,
    fullName: 'Doctor Test',
    doctorId: 'DOC-001',
    email: 'doctor@hospital.org',
    role: 'doctor',
  );

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return AuthSession(user: user, token: 'token');
  }

  @override
  Future<void> register({
    required String fullName,
    required String doctorId,
    String? medicalCenter,
    required String email,
    required String password,
  }) async {}

  @override
  Future<AuthUser> getCurrentUser() async => user;

  @override
  Future<bool> hasSessionToken() async => true;

  @override
  Future<AuthUser?> getCachedUser() async => user;

  @override
  Future<void> logout() async {}
}

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DailySummary> getTodaySummary() async {
    return DailySummary(
      total: 3,
      benign: 2,
      malignant: 1,
      latestAnalysisAt: DateTime(2026, 1, 1, 10),
    );
  }
}

class _FakeHistoryRepository implements HistoryRepository {
  @override
  Future<List<Analysis>> getHistory() async {
    return [
      Analysis(
        id: 1,
        prediction: 'benign',
        confidence: 0.91,
        timestamp: DateTime(2026, 1, 1, 9),
      ),
      Analysis(
        id: 2,
        prediction: 'malignant',
        confidence: 0.82,
        timestamp: DateTime(2026, 1, 1, 10),
      ),
    ];
  }
}

class _FakePredictionRepository implements PredictionRepository {
  @override
  Future<PredictionResult> predictImage(PredictionImageInput input) async {
    return const PredictionResult(
      prediction: 'benign',
      confidence: 0.88,
      recommendation: 'Control periodico.',
    );
  }
}
