import 'dart:io';
import 'package:dio/dio.dart';
import 'package:bucalscan_ai/core/constants/app_constants.dart';
import 'package:bucalscan_ai/data/models/analysis_model.dart';
import 'package:bucalscan_ai/data/models/prediction_result_model.dart';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

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
      throw Exception('Prediction failed: ${e.message}');
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
      throw Exception('Registration failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '${AppConstants.apiVersion}/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Login failed: ${e.message}');
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
      throw Exception('Failed to fetch history: ${e.message}');
    }
  }
}
