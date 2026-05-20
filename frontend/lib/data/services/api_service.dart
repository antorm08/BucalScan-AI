import 'dart:io';
import 'package:dio/dio.dart';
import 'package:bucalscan_ai/core/constants/app_constants.dart';
import 'package:bucalscan_ai/data/models/analysis_model.dart';
import 'package:bucalscan_ai/data/models/daily_summary_model.dart';
import 'package:bucalscan_ai/data/models/prediction_result_model.dart';

class ApiService {
  final Dio _dio;

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

  Future<PredictionResultModel> predictImage(
    File image, {
    int userId = 1,
    String? patientId,
    String? patientName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path),
        'user_id': userId,
        if (patientId != null && patientId.isNotEmpty) 'patient_id': patientId,
        if (patientName != null && patientName.isNotEmpty) 'patient_name': patientName,
      });

      final response = await _dio.post(
        '${AppConstants.apiVersion}/predict',
        data: formData,
      );

      return PredictionResultModel.fromJson(response.data);
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

  Future<List<AnalysisModel>> getHistory(int userId) async {
    try {
      final response = await _dio.get(
        '${AppConstants.apiVersion}/history/$userId',
      );
      final List<dynamic> data = response.data;
      return data.map((json) => AnalysisModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(
        _buildApiErrorMessage(e, fallback: 'No se pudo cargar el historial.'),
      );
    }
  }

  Future<DailySummaryModel> getTodaySummary(int userId) async {
    try {
      final response = await _dio.get(
        '${AppConstants.apiVersion}/summary/today/$userId',
      );
      return DailySummaryModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        _buildApiErrorMessage(e, fallback: 'No se pudo cargar el resumen de hoy.'),
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
