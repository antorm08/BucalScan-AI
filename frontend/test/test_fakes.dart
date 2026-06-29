import 'package:bucalscan_ai/features/auth/domain/entities/auth_session.dart';
import 'package:bucalscan_ai/features/auth/domain/entities/auth_user.dart';
import 'package:bucalscan_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:bucalscan_ai/features/dashboard/domain/entities/daily_summary.dart';
import 'package:bucalscan_ai/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';
import 'package:bucalscan_ai/features/history/domain/repositories/history_repository.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_image_input.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_result.dart';
import 'package:bucalscan_ai/features/prediction/domain/repositories/prediction_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.failLogin = false, this.hasToken = false});

  final bool failLogin;
  final bool hasToken;

  static const user = AuthUser(
    id: 1,
    fullName: 'Doctor Test',
    doctorId: 'DOC-001',
    medicalCenter: 'Hospital Central',
    email: 'doctor@hospital.org',
    role: 'doctor',
  );

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (failLogin) {
      throw Exception('Invalid credentials');
    }
    return const AuthSession(user: user, token: 'token');
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
  Future<bool> hasSessionToken() async => hasToken;

  @override
  Future<AuthUser?> getCachedUser() async => hasToken ? user : null;

  @override
  Future<void> logout() async {}
}

class FakeDashboardRepository implements DashboardRepository {
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

class FakeHistoryRepository implements HistoryRepository {
  @override
  Future<List<Analysis>> getHistory() async {
    return [
      Analysis(
        id: 1,
        prediction: 'benign',
        confidence: 0.91,
        timestamp: DateTime(2026, 1, 1, 9),
        patientId: 'P-001',
        patientName: 'Paciente Benigno',
      ),
      Analysis(
        id: 2,
        prediction: 'malignant',
        confidence: 0.82,
        timestamp: DateTime(2026, 1, 1, 10),
        patientId: 'P-002',
        patientName: 'Paciente Maligno',
      ),
    ];
  }
}

class FakePredictionRepository implements PredictionRepository {
  @override
  Future<PredictionResult> predictImage(PredictionImageInput input) async {
    return const PredictionResult(
      prediction: 'benign',
      confidence: 0.88,
      recommendation: 'Control periodico.',
    );
  }
}
