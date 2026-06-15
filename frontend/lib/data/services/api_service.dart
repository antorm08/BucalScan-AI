import 'dart:io';
import 'package:dio/dio.dart';
import 'package:bucalscan_ai/core/constants/app_constants.dart';

class ApiService {
  final Dio _dio;

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

  Future<void> pingHealth() async {
    try {
      final options = Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 45),
      );

      await _dio.get('/health', options: options);
    } on DioException catch (e) {
      try {
        final fallbackOptions = Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 45),
        );
        await _dio.get('/', options: fallbackOptions);
        return;
      } on DioException {
        throw Exception(
          _buildApiErrorMessage(
            e,
            fallback: 'No se pudo preparar la conexion con el servidor.',
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> predictImage(
    File image, {
    String? patientId,
    String? patientName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path),
        if (patientId != null && patientId.isNotEmpty) 'patient_id': patientId,
        if (patientName != null && patientName.isNotEmpty)
          'patient_name': patientName,
      });

      final response = await _dio.post(
        '${AppConstants.apiVersion}/predict',
        data: formData,
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
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        _buildApiErrorMessage(e, fallback: 'No se pudo completar el registro.'),
      );
    }
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
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null && fullName.isNotEmpty) data['full_name'] = fullName;
      if (medicalCenter != null) data['medical_center'] = medicalCenter;
      if (email != null && email.isNotEmpty) data['email'] = email;

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
      return data.map((json) => Map<String, dynamic>.from(json as Map)).toList();
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
      return data.map((json) => Map<String, dynamic>.from(json as Map)).toList();
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

    if (data is Map<String, dynamic>) {
      final detail = data['detail'] ?? data['message'] ?? data['error'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    final message = error.message;
    if (message != null && message.trim().isNotEmpty) {
      return '$fallback $message';
    }

    return fallback;
  }
}
