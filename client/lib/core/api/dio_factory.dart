import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/api/api_exceptions.dart';
import '../security/token_store.dart';

class ApiDioFactory {
  const ApiDioFactory._();

  static Dio create({
    required String baseUrl,
    required AuthTokenStore tokenStore,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        validateStatus: (status) => status != null && status < 600,
        headers: const {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      _BearerTokenInterceptor(tokenStore),
      _ApiEnvelopeInterceptor(tokenStore),
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
        error: true,
      ),
    ]);
    return dio;
  }

  static AuthTokenStore defaultTokenStore() => AuthTokenStore(const FlutterSecureStorage());
}

class _BearerTokenInterceptor extends Interceptor {
  _BearerTokenInterceptor(this._tokenStore);

  final AuthTokenStore _tokenStore;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final path = options.path;
    final isPublicAuth = path.contains('/api/v1/auth/login') ||
        path.contains('/api/v1/auth/register') ||
        path.contains('/api/v1/auth/refresh') ||
        path.contains('/api/v1/public/');
    if (!isPublicAuth) {
      final token = await _tokenStore.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}

class _ApiEnvelopeInterceptor extends Interceptor {
  _ApiEnvelopeInterceptor(this._tokenStore);

  final AuthTokenStore _tokenStore;

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) async {
    final failure = _failureFromResponse(response);
    if (failure == null) {
      handler.next(response);
      return;
    }

    if (failure.isAuthFailure) {
      await _tokenStore.clear();
    }

    handler.reject(
      DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: failure,
        message: failure.message,
      ),
      true,
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final failure = ApiFailure.tryRead(err) ?? _failureFromDioError(err);
    if (failure.isAuthFailure) {
      await _tokenStore.clear();
    }

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: failure,
        message: failure.message,
        stackTrace: err.stackTrace,
      ),
    );
  }

  ApiFailure? _failureFromResponse(Response<dynamic> response) {
    final data = response.data;
    final statusCode = response.statusCode;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['success'] == false || statusCode != null && statusCode >= 400) {
        return ApiFailure.fromEnvelope(map, statusCode: statusCode);
      }
    }

    if (statusCode != null && statusCode >= 400) {
      return ApiFailure.fromError(null, statusCode: statusCode);
    }

    return null;
  }

  ApiFailure _failureFromDioError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiFailure.timeout();
      case DioExceptionType.connectionError:
        return ApiFailure.network(message: err.message);
      case DioExceptionType.cancel:
        return ApiFailure.cancelled();
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return ApiFailure.unexpected(
          err.message ?? err,
          statusCode: err.response?.statusCode,
        );
    }
  }
}
