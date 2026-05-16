import 'package:web/web.dart' as web;

import 'token_store.dart';

/// Web implementation using localStorage.
///
/// localStorage is synchronous and survives page reloads, so there's no
/// race condition between saving a token and reading it back after a
/// route change.
class WebAuthTokenStore implements AuthTokenStore {
  static const _accessKey = 'feedbackflow.access_token';
  static const _refreshKey = 'feedbackflow.refresh_token';

  @override
  Future<String?> readAccessToken() async {
    return web.window.localStorage.getItem(_accessKey);
  }

  @override
  Future<String?> readRefreshToken() async {
    return web.window.localStorage.getItem(_refreshKey);
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    web.window.localStorage.setItem(_accessKey, accessToken);
    web.window.localStorage.setItem(_refreshKey, refreshToken);
  }

  @override
  Future<void> clear() async {
    web.window.localStorage.removeItem(_accessKey);
    web.window.localStorage.removeItem(_refreshKey);
  }
}

/// Web factory.
AuthTokenStore createPlatformTokenStore() => WebAuthTokenStore();
