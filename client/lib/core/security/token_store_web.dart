// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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
    return html.window.localStorage[_accessKey];
  }

  @override
  Future<String?> readRefreshToken() async {
    return html.window.localStorage[_refreshKey];
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    html.window.localStorage[_accessKey] = accessToken;
    html.window.localStorage[_refreshKey] = refreshToken;
  }

  @override
  Future<void> clear() async {
    html.window.localStorage.remove(_accessKey);
    html.window.localStorage.remove(_refreshKey);
  }
}

/// Web factory.
AuthTokenStore createPlatformTokenStore() => WebAuthTokenStore();
