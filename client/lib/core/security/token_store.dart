import 'token_store_impl.dart'
    if (dart.library.js_interop) 'token_store_web.dart';

/// Platform-aware token store.
///
/// On web: uses localStorage (synchronous, no race conditions).
/// On mobile/desktop: uses FlutterSecureStorage (encrypted keychain/keystore).
abstract class AuthTokenStore {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens({required String accessToken, required String refreshToken});
  Future<void> clear();
}

/// Creates the appropriate token store for the current platform.
AuthTokenStore createTokenStore() => createPlatformTokenStore();
