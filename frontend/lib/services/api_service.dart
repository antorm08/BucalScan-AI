import 'dart:io';
import 'package:dio/dio.dart';
import 'package:oral_lesion_detector/models/prediction_result.dart';
import 'package:oral_lesion_detector/utils/constants.dart';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<PredictionResult> predictImage(File image) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path),
      });

      final response = await _dio.post(
        '${AppConstants.apiVersion}/predict',
        data: formData,
      );

      return PredictionResult.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Prediction failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '${AppConstants.apiVersion}/auth/register',
        data: {
          'full_name': fullName,
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

  Future<List<dynamic>> getHistory(int userId) async {
    try {
      final response = await _dio.get(
        '${AppConstants.apiVersion}/history/$userId',
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to fetch history: ${e.message}');
    }
  }
}
