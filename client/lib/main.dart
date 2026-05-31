import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'app/dependencies.dart';
import 'app/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  const configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  final String baseUrl;
  if (configuredBaseUrl.isNotEmpty) {
    // Explicitly provided via --dart-define=API_BASE_URL=...
    baseUrl = configuredBaseUrl;
  } else if (kIsWeb) {
    // On web: if served by the Rust backend, origin is the API.
    // If served by Flutter dev server (port 3000/random), redirect to 8080.
    final origin = Uri.base.origin;
    final devPorts = {'3000', '5000', '8000'};
    final port = Uri.base.port.toString();
    if (devPorts.contains(port) ||
        Uri.base.host == 'localhost' && port != '8080') {
      baseUrl = 'http://localhost:8080';
    } else {
      baseUrl = origin;
    }
  } else {
    // Mobile / desktop local development
    baseUrl = 'http://localhost:8080';
  }

  final dependencies = AppDependencies.create(baseUrl: baseUrl);

  runApp(
    ProviderScope(
      overrides: [appDependenciesProvider.overrideWithValue(dependencies)],
      child: const FeedbackFlowApp(),
    ),
  );
}
