import 'dart:async';
import 'package:dio/dio.dart';
import 'package:bucalscan_ai/core/session/session_events.dart';
import 'auth_storage_service.dart';

class AuthInterceptor extends Interceptor {
  static const _requestTokenKey = 'authRequestToken';
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
      options.extra[_requestTokenKey] = token;
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
      final failedToken =
          err.requestOptions.extra[_requestTokenKey] as String? ??
          _bearerToken(err.requestOptions.headers['Authorization']);
      final currentToken = await _storage.getToken();
      if (failedToken != null && failedToken == currentToken) {
        await _storage.clear();
        SessionEvents().emitSessionExpired();
      }
    }
    handler.next(err);
  }

  String? _bearerToken(Object? authorization) {
    final value = authorization?.toString();
    if (value == null || !value.startsWith('Bearer ')) return null;
    return value.substring('Bearer '.length);
  }
}
