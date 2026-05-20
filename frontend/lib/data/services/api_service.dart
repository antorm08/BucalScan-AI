import 'dart:io';
import 'package:dio/dio.dart';
import 'package:bucalscan_ai/core/constants/app_constants.dart';
import 'package:bucalscan_ai/data/models/analysis_model.dart';
import 'package:bucalscan_ai/data/models/prediction_result_model.dart';

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

  Future<PredictionResultModel> predictImage(File image) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path),
      });

      final response = await _dio.post(
        '${AppConstants.apiVersion}/predict',
        data: formData,
      );

      return PredictionResultModel.fromJson(response.data);
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
      final response = await _dio.get(
        '${AppConstants.apiVersion}/auth/me',
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        _buildApiErrorMessage(
          e,
          fallback: 'No se pudo validar la sesion.',
        ),
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

  String _buildApiErrorMessage(DioException error, {required String fallback}) {
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
