import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'l10n/app_localizations.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/widgets/smart_app_banner.dart';

class FeedbackFlowApp extends ConsumerWidget {
  const FeedbackFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      title: 'FeedbackFlow',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light(locale),
      darkTheme: AppTheme.dark(locale),
      themeMode: ref.watch(themeControllerProvider),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        return Directionality(
          textDirection: context.l10n.textDirection,
          child: Column(
            children: [
              const SmartAppBanner(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        );
      },
    );
  }
}
