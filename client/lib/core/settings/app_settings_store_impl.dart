import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_settings_store.dart';

class NativeAppSettingsStore implements AppSettingsStore {
  NativeAppSettingsStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _themeModeKey = 'feedbackflow.theme_mode';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readThemeMode() => _storage.read(key: _themeModeKey);

  @override
  Future<void> saveThemeMode(String value) =>
      _storage.write(key: _themeModeKey, value: value);

  @override
  Future<String?> readValue(String key) => _storage.read(key: key);

  @override
  Future<void> writeValue(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> deleteValue(String key) => _storage.delete(key: key);
}

AppSettingsStore createPlatformSettingsStore() => NativeAppSettingsStore();
