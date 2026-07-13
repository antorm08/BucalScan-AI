import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bucalscan_ai/data/services/auth_interceptor.dart';
import 'package:bucalscan_ai/data/services/auth_storage_service.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_image_input.dart';

class _MemoryAuthStorage extends AuthStorageService {
  int clearCount = 0;

  @override
  Future<String?> getToken() async => 'token';

  @override
  Future<void> clear() async {
    clearCount++;
  }
}

class _RecordingErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException error) {}
}

DioException _responseError(int status) => DioException(
  requestOptions: RequestOptions(path: '/clinical'),
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
      );

      expect(input.patientId, 'patient-1');
      expect(input.lesionId, 'lesion-1');
      expect(input.consentToStore, isTrue);
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
}
