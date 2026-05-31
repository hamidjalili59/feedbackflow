import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
}

class TokenStorage {
  TokenStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'feedbackflow.access_token';
  static const _refreshTokenKey = 'feedbackflow.refresh_token';
  static const _tokenTypeKey = 'feedbackflow.token_type';
  static const _expiresInKey = 'feedbackflow.expires_in';

  final FlutterSecureStorage _secureStorage;

  Future<void> save(TokenPair pair) async {
    await _secureStorage.write(key: _accessTokenKey, value: pair.accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: pair.refreshToken);
    await _secureStorage.write(key: _tokenTypeKey, value: pair.tokenType);
    await _secureStorage.write(
      key: _expiresInKey,
      value: pair.expiresIn.toString(),
    );
  }

  Future<TokenPair?> read() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (accessToken == null || refreshToken == null) return null;
    final tokenType = await _secureStorage.read(key: _tokenTypeKey) ?? 'Bearer';
    final expiresInRaw = await _secureStorage.read(key: _expiresInKey);
    return TokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
      expiresIn: int.tryParse(expiresInRaw ?? '') ?? 0,
    );
  }

  Future<String?> readAccessToken() async =>
      _secureStorage.read(key: _accessTokenKey);
  Future<String?> readRefreshToken() async =>
      _secureStorage.read(key: _refreshTokenKey);

  Future<void> clear() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _tokenTypeKey);
    await _secureStorage.delete(key: _expiresInKey);
  }
}
