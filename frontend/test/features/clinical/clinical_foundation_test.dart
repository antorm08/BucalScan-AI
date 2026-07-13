import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bucalscan_ai/data/services/auth_interceptor.dart';
import 'package:bucalscan_ai/data/services/auth_storage_service.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_image_input.dart';

class _MemoryAuthStorage extends AuthStorageService {
  int clearCount = 0;
  String? token = 'token';

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> clear() async {
    clearCount++;
    token = null;
  }
}

class _RecordingErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException error) {}
}

DioException _responseError(int status, {String token = 'token'}) =>
    DioException(
      requestOptions: RequestOptions(
        path: '/clinical',
        headers: {'Authorization': 'Bearer $token'},
      ),
      response: Response<void>(
        requestOptions: RequestOptions(path: '/clinical'),
        statusCode: status,
      ),
    );

void main() {
  test('only active approved workspace can be selected', () {
    const active = ClinicalWorkspace(
      id: '1',
      name: 'Clinica',
      type: 'clinic',
      status: 'active',
      membershipStatus: MembershipStatus.active,
    );
    const pending = ClinicalWorkspace(
      id: '2',
      name: 'Consultorio pendiente',
      type: 'clinic',
      status: 'pending',
      membershipStatus: MembershipStatus.pending,
    );

    expect(active.canEnter, isTrue);
    expect(pending.canEnter, isFalse);
  });

  test(
    'analysis input persists patient lesion and professional attestation',
    () {
      const input = PredictionImageInput(
        imagePath: 'lesion.jpg',
        patientId: 'patient-1',
        lesionId: 'lesion-1',
        consentToStore: true,
        clinicalObservations: 'Borde regular',
      );

      expect(input.patientId, 'patient-1');
      expect(input.lesionId, 'lesion-1');
      expect(input.consentToStore, isTrue);
      expect(input.clinicalObservations, 'Borde regular');
    },
  );

  test('401 clears session while 403 preserves it', () async {
    final storage = _MemoryAuthStorage();
    final interceptor = AuthInterceptor(storage);

    interceptor.onError(_responseError(403), _RecordingErrorHandler());
    await Future<void>.delayed(Duration.zero);
    expect(storage.clearCount, 0);

    interceptor.onError(_responseError(401), _RecordingErrorHandler());
    await Future<void>.delayed(Duration.zero);
    expect(storage.clearCount, 1);
  });

  test('stale 401 cannot clear or expire a newer authentication', () async {
    final storage = _MemoryAuthStorage()..token = 'new-token';
    final interceptor = AuthInterceptor(storage);

    interceptor.onError(
      _responseError(401, token: 'old-token'),
      _RecordingErrorHandler(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(storage.token, 'new-token');
    expect(storage.clearCount, 0);
  });
}
