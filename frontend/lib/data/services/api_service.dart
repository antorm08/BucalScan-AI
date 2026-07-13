// ignore_for_file: use_null_aware_elements

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:bucalscan_ai/core/constants/app_constants.dart';

class ApiService {
  final Dio _dio;
  String? _activeWorkspaceId;

  ApiService({List<Interceptor> interceptors = const []})
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      ) {
    if (interceptors.isNotEmpty) {
      _dio.interceptors.addAll(interceptors);
    }
  }

  void setActiveWorkspace(String? workspaceId) {
    _activeWorkspaceId = workspaceId;
  }

  Options _workspaceOptions() => Options(
    headers: {
      if (_activeWorkspaceId != null) 'X-Workspace-ID': _activeWorkspaceId,
    },
  );

  Future<void> pingReadiness() async {
    try {
      final options = Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 45),
      );

      await _dio.get(AppConstants.readinessEndpoint, options: options);
    } on DioException catch (e) {
      throw Exception(
        _buildApiErrorMessage(
          e,
          fallback: 'El servicio de analisis aun no esta disponible.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> predictImage(
    File image, {
    String? patientId,
    String? patientName,
    required bool consentToStore,
    String? lesionId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path),
        'consent_to_store': consentToStore.toString(),
        if (lesionId != null) 'lesion_id': lesionId,
        if (patientId != null && patientId.isNotEmpty) 'patient_id': patientId,
        if (patientName != null && patientName.isNotEmpty)
          'patient_name': patientName,
      });

      final response = await _dio.post(
        '${AppConstants.apiVersion}/predict',
        data: formData,
        options: _workspaceOptions(),
      );

      return Map<String, dynamic>.from(response.data as Map);
    } on FormatException {
      throw Exception(
        'La respuesta del servidor no incluyo todos los datos esperados del analisis.',
      );
    } on DioException catch (e) {
      throw Exception(
        _buildApiErrorMessage(
          e,
          fallback: 'No se pudo completar el analisis de la imagen.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String doctorId,
    String? medicalCenter,
    required String email,
    required String password,
    required String profession,
    String? specialty,
    String? workspaceChoice,
    String? workspaceId,
    String? workspaceName,
    String? workspaceType,
  }) async {
    try {
      final response = await _dio.post(
        '${AppConstants.apiVersion}/auth/register',
        data: {
          'full_name': fullName,
          'doctor_id': doctorId,
          if (medicalCenter != null && medicalCenter.isNotEmpty)
            'medical_center': medicalCenter,
          'email': email,
          'password': password,
          'profession': profession,
          if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
          if (workspaceChoice != null) 'workspace_choice': workspaceChoice,
          if (workspaceId != null) 'workspace_id': workspaceId,
          if (workspaceName != null) 'workspace_name': workspaceName,
          if (workspaceType != null) 'workspace_type': workspaceType,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        _buildApiErrorMessage(e, fallback: 'No se pudo completar el registro.'),
      );
    }
  }

  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
    bool workspaceScoped = false,
  }) async {
    final response = await _dio.get(
      path,
      queryParameters: query,
      options: workspaceScoped ? _workspaceOptions() : null,
    );
    final raw = response.data is Map
        ? ((response.data as Map)['items'] ?? (response.data as Map)['data'])
        : response.data;
    return (raw as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> data, {
    bool workspaceScoped = false,
  }) async {
    final response = await _dio.post(
      path,
      data: data,
      options: workspaceScoped ? _workspaceOptions() : null,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '${AppConstants.apiVersion}/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        _buildApiErrorMessage(e, fallback: 'No se pudo iniciar sesion.'),
      );
    }
  }

  Future<Map<String, dynamic>> me() async {
    try {
      final response = await _dio.get('${AppConstants.apiVersion}/auth/me');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        _buildApiErrorMessage(e, fallback: 'No se pudo validar la sesion.'),
      );
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? medicalCenter,
    String? email,
    String? profession,
    String? specialty,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null && fullName.isNotEmpty) data['full_name'] = fullName;
      if (medicalCenter != null) data['medical_center'] = medicalCenter;
      if (email != null && email.isNotEmpty) data['email'] = email;
      if (profession != null) data['profession'] = profession;
      if (specialty != null) data['specialty'] = specialty;

      final response = await _dio.put(
        '${AppConstants.apiVersion}/auth/me',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        _buildApiErrorMessage(e, fallback: 'No se pudo actualizar el perfil.'),
      );
    }
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final response = await _dio.get('${AppConstants.apiVersion}/history');
      final List<dynamic> data = response.data;
      return data
          .map((json) => Map<String, dynamic>.from(json as Map))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _buildApiErrorMessage(e, fallback: 'No se pudo cargar el historial.'),
      );
    }
  }

  Future<Map<String, dynamic>> getTodaySummary() async {
    try {
      final response = await _dio.get(
        '${AppConstants.apiVersion}/summary/today',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(
        _buildApiErrorMessage(
          e,
          fallback: 'No se pudo cargar el resumen de hoy.',
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      final response = await _dio.get('${AppConstants.apiVersion}/admin/users');
      final List<dynamic> data = response.data;
      return data
          .map((json) => Map<String, dynamic>.from(json as Map))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _buildApiErrorMessage(
          e,
          fallback: 'No se pudo cargar la gestión de usuarios.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> updateAdminUserStatus({
    required int userId,
    required String status,
  }) async {
    try {
      final response = await _dio.patch(
        '${AppConstants.apiVersion}/admin/users/$userId/status',
        data: {'status': status},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(
        _buildApiErrorMessage(e, fallback: 'No se pudo actualizar el usuario.'),
      );
    }
  }

  Future<Map<String, dynamic>> getAdminSummary() => _adminMap(
    'summary',
    fallback: 'No se pudo cargar el resumen administrativo.',
  );

  Future<List<Map<String, dynamic>>> getAdminWorkspaceRequests() => _adminList(
    'workspaces?status=pending',
    fallback: 'No se pudieron cargar los centros pendientes.',
  );

  Future<List<Map<String, dynamic>>> getAdminMembershipRequests() => _adminList(
    'memberships?status=pending',
    fallback: 'No se pudieron cargar los accesos pendientes.',
  );

  Future<void> decideAdminWorkspace(int id, {required bool approve}) async {
    await _adminPost(
      'workspaces/$id/${approve ? 'approve' : 'reject'}',
      fallback: 'No se pudo resolver el centro.',
    );
  }

  Future<void> decideAdminMembership(
    int id, {
    required bool approve,
    String role = 'professional',
  }) async {
    await _adminPost(
      'memberships/$id/${approve ? 'approve' : 'reject'}',
      data: approve ? {'role': role} : null,
      fallback: 'No se pudo resolver el acceso.',
    );
  }

  Future<Map<String, dynamic>> _adminMap(
    String path, {
    required String fallback,
  }) async {
    try {
      final response = await _dio.get('${AppConstants.apiVersion}/admin/$path');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_buildApiErrorMessage(e, fallback: fallback));
    }
  }

  Future<List<Map<String, dynamic>>> _adminList(
    String path, {
    required String fallback,
  }) async {
    try {
      final response = await _dio.get('${AppConstants.apiVersion}/admin/$path');
      return (response.data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } on DioException catch (e) {
      throw Exception(_buildApiErrorMessage(e, fallback: fallback));
    }
  }

  Future<void> _adminPost(
    String path, {
    Map<String, dynamic>? data,
    required String fallback,
  }) async {
    try {
      await _dio.post('${AppConstants.apiVersion}/admin/$path', data: data);
    } on DioException catch (e) {
      throw Exception(_buildApiErrorMessage(e, fallback: fallback));
    }
  }

  String _buildApiErrorMessage(DioException error, {required String fallback}) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'El servidor de analisis no respondio a tiempo. Intente nuevamente.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar con el servidor de analisis.';
    }

    final data = error.response?.data;

    if (error.response?.statusCode == 403) {
      return 'No tiene permiso para realizar esta accion en el espacio de trabajo activo.';
    }

    if (data is Map<String, dynamic>) {
      final detail = data['detail'] ?? data['message'] ?? data['error'];
      if (detail is String && detail.trim().isNotEmpty) {
        return _translateServerMessage(detail);
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return _translateServerMessage(data);
    }

    final message = error.message;
    if (message != null && message.trim().isNotEmpty) {
      return '$fallback $message';
    }

    return fallback;
  }

  String _translateServerMessage(String message) {
    final normalized = message.toLowerCase();

    if (normalized.contains('model inference failed') ||
        normalized.contains('model file not loaded')) {
      return 'No se pudo procesar la imagen porque el modelo de análisis no está disponible en el servidor. Intente nuevamente más tarde.';
    }

    if (normalized.contains('invalid or expired token') ||
        normalized.contains('not authenticated')) {
      return 'Tu sesión expiró. Inicia sesión nuevamente.';
    }

    if (normalized.contains('invalid credentials')) {
      return 'Usuario y clave incorrectos.';
    }

    return message;
  }
}
