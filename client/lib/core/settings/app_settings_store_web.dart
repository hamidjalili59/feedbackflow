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
}

AppSettingsStore createPlatformSettingsStore() => WebAppSettingsStore();
