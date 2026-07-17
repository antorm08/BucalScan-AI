import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:bucalscan_ai/core/constants/app_constants.dart';
import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/features/clinical/data/repositories/clinical_repository_impl.dart';

class _RecordingApiService extends ApiService {
  String? lastPath;
  Map<String, dynamic>? lastQuery;
  Map<String, dynamic>? lastPayload;
  bool? lastWorkspaceScoped;

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

  @override
  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> data, {
    bool workspaceScoped = false,
  }) async {
    lastPath = path;
    lastPayload = data;
    lastWorkspaceScoped = workspaceScoped;
    return {
      'id': 'lesion-1',
      'patient_id': 'patient-1',
      'anatomical_site': 'lengua',
      'status': data['status'],
      'clinical_notes': data['clinical_notes'],
      'observed_at': data['observed_at'],
      'estimated_duration': data['estimated_duration'],
    };
  }

  @override
  Future<Uint8List> getBytes(
    String path, {
    bool workspaceScoped = false,
  }) async {
    lastPath = path;
    lastWorkspaceScoped = workspaceScoped;
    return Uint8List.fromList([37, 80, 68, 70, 45]);
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

  test(
    'lesion update sends a date-only value and supports clearing it',
    () async {
      final api = _RecordingApiService();
      final repository = ClinicalRepositoryImpl(api);

      final updated = await repository.updateLesion(
        lesionId: 'lesion-1',
        status: 'monitoring',
        observedAt: DateTime(2026, 7, 6),
        estimatedDuration: 'tres semanas',
        notes: 'Sin cambios relevantes',
      );

      expect(api.lastPath, '/api/v1/lesions/lesion-1');
      expect(api.lastWorkspaceScoped, isTrue);
      expect(api.lastPayload?['observed_at'], '2026-07-06');
      expect(updated.observedAt, DateTime(2026, 7, 6));

      await repository.updateLesion(
        lesionId: 'lesion-1',
        status: 'monitoring',
        observedAt: null,
        estimatedDuration: 'tres semanas',
      );
      expect(api.lastPayload?.containsKey('observed_at'), isTrue);
      expect(api.lastPayload?['observed_at'], isNull);
    },
  );

  test('evaluation report uses workspace-scoped binary endpoint', () async {
    final api = _RecordingApiService();
    final repository = ClinicalRepositoryImpl(api);

    final bytes = await repository.exportEvaluationPdf(
      lesionId: 'lesion-1',
      evaluationId: 'evaluation-9',
    );

    expect(
      api.lastPath,
      '/api/v1/lesions/lesion-1/evaluations/evaluation-9/report.pdf',
    );
    expect(api.lastWorkspaceScoped, isTrue);
    expect(bytes, [37, 80, 68, 70, 45]);
  });
}
