import 'package:web/web.dart' as web;

import 'app_settings_store.dart';

class WebAppSettingsStore implements AppSettingsStore {
  static const _themeModeKey = 'feedbackflow.theme_mode';

  @override
  Future<String?> readThemeMode() async {
    return web.window.localStorage.getItem(_themeModeKey);
  }

  @override
  Future<void> saveThemeMode(String value) async {
    web.window.localStorage.setItem(_themeModeKey, value);
  }

  @override
  Future<String?> readValue(String key) async {
    return web.window.localStorage.getItem(key);
  }

  @override
  Future<void> writeValue(String key, String value) async {
    web.window.localStorage.setItem(key, value);
  }

  @override
  Future<void> deleteValue(String key) async {
    web.window.localStorage.removeItem(key);
  }
}

AppSettingsStore createPlatformSettingsStore() => WebAppSettingsStore();
