import 'package:flutter_test/flutter_test.dart';
import 'package:bucalscan_ai/core/constants/app_constants.dart';
import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/features/clinical/data/repositories/clinical_repository_impl.dart';

class _RecordingApiService extends ApiService {
  String? lastPath;
  Map<String, dynamic>? lastQuery;
  Map<String, dynamic>? lastPayload;

  @override
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
    bool workspaceScoped = false,
  }) async {
    lastPath = path;
    lastQuery = query;
    return [
      {
        'id': 'workspace-1',
        'name': 'Consultorio Central',
        'workspace_type': 'consultorio',
        'status': 'pending',
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> data, {
    bool workspaceScoped = false,
  }) async {
    lastPath = path;
    lastPayload = data;
    return {
      'id': 'lesion-1',
      'anatomical_site': data['anatomical_site'],
      'estimated_duration': data['estimated_duration'],
      'status': data['status'],
    };
  }
}

void main() {
  test(
    'workspace discovery uses public query contract and workspace_type',
    () async {
      final api = _RecordingApiService();
      final repository = ClinicalRepositoryImpl(api);

      final workspaces = await repository.discoverWorkspaces('central');

      expect(api.lastPath, ClinicalEndpoints.workspaces);
      expect(api.lastQuery, {'q': 'central'});
      expect(workspaces.single.type, 'consultorio');
      expect(workspaces.single.status, 'pending');
      expect(ClinicalEndpoints.memberships, '/api/v1/workspaces/mine');
    },
  );

  test('lesion creation sends estimated_duration', () async {
    final api = _RecordingApiService();
    final repository = ClinicalRepositoryImpl(api);

    await repository.createLesion(
      patientId: 'patient-1',
      anatomicalSite: 'lengua',
      estimatedDuration: 'dos semanas',
    );

    expect(api.lastPath, '/api/v1/patients/patient-1/lesions');
    expect(api.lastPayload?['estimated_duration'], 'dos semanas');
    expect(api.lastPayload?.containsKey('temporal_description'), isFalse);
  });
}
