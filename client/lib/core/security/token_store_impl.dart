import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_store.dart';

/// Native (Android/iOS/desktop) implementation using FlutterSecureStorage.
class NativeAuthTokenStore implements AuthTokenStore {
  NativeAuthTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'feedbackflow.access_token';
  static const _refreshKey = 'feedbackflow.refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

/// Default factory for non-web platforms.
AuthTokenStore createPlatformTokenStore() => NativeAuthTokenStore();
