import 'dart:async';

import 'package:dio/dio.dart';

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
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
        validateStatus: (status) => status != null && status < 600,
        headers: const {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      _BearerTokenInterceptor(tokenStore),
      _TokenRefreshInterceptor(dio, tokenStore),
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

  static AuthTokenStore defaultTokenStore() {
    return createTokenStore();
  }
}

class _BearerTokenInterceptor extends Interceptor {
  _BearerTokenInterceptor(this._tokenStore);

  final AuthTokenStore _tokenStore;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublicAuthPath(options.path)) {
      final token = await _tokenStore.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        options.extra[_sentStoredAuthHeader] = true;
      }
    }
    handler.next(options);
  }
}

/// Intercepts 401 responses and attempts to refresh the access token
/// using the stored refresh token. If refresh succeeds, the original
/// request is retried transparently. If refresh fails, the tokens are
/// cleared and the error propagates (forcing re-login).
class _TokenRefreshInterceptor extends Interceptor {
  _TokenRefreshInterceptor(this._dio, this._tokenStore);

  final Dio _dio;
  final AuthTokenStore _tokenStore;

  /// Guards concurrent refresh attempts — only one refresh call at a time.
  Completer<bool>? _refreshCompleter;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final statusCode = response.statusCode;
    if (statusCode != 401 || _isPublicAuthPath(response.requestOptions.path)) {
      handler.next(response);
      return;
    }

    // Attempt token refresh
    final refreshed = await _tryRefresh();
    if (!refreshed) {
      handler.next(response);
      return;
    }

    // Retry the original request with the new access token
    try {
      final opts = response.requestOptions;
      final token = await _tokenStore.readAccessToken();
      if (token != null && token.isNotEmpty) {
        opts.headers['Authorization'] = 'Bearer $token';
      }
      final retryResponse = await _dio.fetch(opts);
      handler.resolve(retryResponse);
    } catch (e) {
      if (e is DioException) {
        handler.reject(e);
      } else {
        handler.reject(
          DioException(requestOptions: response.requestOptions, error: e),
        );
      }
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    if (statusCode != 401 || _isPublicAuthPath(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    final refreshed = await _tryRefresh();
    if (!refreshed) {
      handler.next(err);
      return;
    }

    // Retry the original request with the new access token
    try {
      final opts = err.requestOptions;
      final token = await _tokenStore.readAccessToken();
      if (token != null && token.isNotEmpty) {
        opts.headers['Authorization'] = 'Bearer $token';
      }
      final retryResponse = await _dio.fetch(opts);
      handler.resolve(retryResponse);
    } catch (e) {
      if (e is DioException) {
        handler.next(e);
      } else {
        handler.next(
          DioException(requestOptions: err.requestOptions, error: e),
        );
      }
    }
  }

  Future<bool> _tryRefresh() async {
    // If another request is already refreshing, wait for it.
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    try {
      final refreshToken = await _tokenStore.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }

      // Use a separate Dio instance to avoid interceptor loops.
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {'Accept': 'application/json'},
        ),
      );

      final response = await refreshDio.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data;
      if (data == null || response.statusCode != 200) {
        await _tokenStore.clear();
        _refreshCompleter!.complete(false);
        return false;
      }

      // The server wraps in an envelope: { success: true, data: { ... } }
      final envelope = data['data'] as Map<String, dynamic>?;
      final newAccessToken =
          (envelope?['access_token'] ?? data['access_token']) as String?;
      final newRefreshToken =
          (envelope?['refresh_token'] ?? data['refresh_token']) as String?;

      if (newAccessToken == null || newRefreshToken == null) {
        await _tokenStore.clear();
        _refreshCompleter!.complete(false);
        return false;
      }

      await _tokenStore.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      _refreshCompleter!.complete(true);
      return true;
    } catch (_) {
      await _tokenStore.clear();
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }
}

class _ApiEnvelopeInterceptor extends Interceptor {
  _ApiEnvelopeInterceptor(this._tokenStore);

  final AuthTokenStore _tokenStore;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final failure = _failureFromResponse(response);
    if (failure == null) {
      handler.next(response);
      return;
    }

    if (_shouldClearStoredSession(response.requestOptions, failure)) {
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
    if (_shouldClearStoredSession(err.requestOptions, failure)) {
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

const _sentStoredAuthHeader = 'feedbackflow.sentStoredAuthHeader';

bool _isPublicAuthPath(String path) {
  return path.contains('/api/v1/auth/login') ||
      path.contains('/api/v1/auth/guest') ||
      path.contains('/api/v1/auth/register') ||
      path.contains('/api/v1/auth/refresh') ||
      path.contains('/api/v1/public/');
}

bool _shouldClearStoredSession(RequestOptions options, ApiFailure failure) {
  if (!failure.isAuthFailure) return false;

  // Public form gates use their own access token/password flow. An
  // INVALID_TOKEN there is local to the form and must not log out the app.
  return options.extra[_sentStoredAuthHeader] == true ||
      !_isPublicAuthPath(options.path);
}
