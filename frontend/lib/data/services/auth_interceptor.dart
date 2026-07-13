import 'dart:async';
import 'package:dio/dio.dart';
import 'package:bucalscan_ai/core/session/session_events.dart';
import 'auth_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final AuthStorageService _storage;

  AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    if (statusCode == 401) {
      await _storage.clear();
      SessionEvents().emitSessionExpired();
    }
    handler.next(err);
  }
}
