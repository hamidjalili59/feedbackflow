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
  final baseUrl =
      configuredBaseUrl.isNotEmpty
          ? configuredBaseUrl
          : kIsWeb
          ? Uri.base.origin
          : 'http://localhost:8080';

  final dependencies = AppDependencies.create(baseUrl: baseUrl);

  runApp(
    ProviderScope(
      overrides: [appDependenciesProvider.overrideWithValue(dependencies)],
      child: const FeedbackFlowApp(),
    ),
  );
}
