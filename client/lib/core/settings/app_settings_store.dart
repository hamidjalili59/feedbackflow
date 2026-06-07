import 'app_settings_store_impl.dart'
    if (dart.library.js_interop) 'app_settings_store_web.dart';

abstract class AppSettingsStore {
  Future<String?> readThemeMode();
  Future<void> saveThemeMode(String value);
  Future<String?> readValue(String key);
  Future<void> writeValue(String key, String value);
  Future<void> deleteValue(String key);
}

AppSettingsStore createSettingsStore() => createPlatformSettingsStore();
