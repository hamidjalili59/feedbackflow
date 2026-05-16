import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

class ApiClientConfig {
  const ApiClientConfig({required this.baseUrl});

  final String baseUrl;
}

class AuthHeaderInterceptor extends QueuedInterceptor {
  AuthHeaderInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['skipAuth'] == true) {
      handler.next(options);
      return;
    }

    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }
}

Dio createDioClient({
  required ApiClientConfig config,
  required TokenStorage tokenStorage,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
      headers: const <String, dynamic>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      validateStatus: (_) => true,
    ),
  );

  dio.interceptors.add(AuthHeaderInterceptor(tokenStorage));
  return dio;
}
