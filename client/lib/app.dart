import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'l10n/app_localizations.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/widgets/smart_app_banner.dart';

class FeedbackFlowApp extends ConsumerStatefulWidget {
  const FeedbackFlowApp({super.key});

  @override
  ConsumerState<FeedbackFlowApp> createState() => _FeedbackFlowAppState();
}

class _FeedbackFlowAppState extends ConsumerState<FeedbackFlowApp> {
  DateTime? _lastExitBackPress;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeControllerProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'FeedbackFlow',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light(locale),
      darkTheme: AppTheme.dark(locale),
      themeMode: ref.watch(themeControllerProvider),
      routerConfig: router,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
              PointerDeviceKind.invertedStylus,
            },
          ),
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) _handleSystemBack(context, router);
            },
            child: Directionality(
              textDirection: context.l10n.textDirection,
              child: Column(
                children: [
                  const SmartAppBanner(),
                  Expanded(child: child ?? const SizedBox.shrink()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleSystemBack(BuildContext context, GoRouter router) {
    final currentPath = router.routeInformationProvider.value.uri.path;
    final session = ref.read(authControllerProvider).asData?.value;
    if (session != null && currentPath != '/dashboard') {
      _lastExitBackPress = null;
      router.go('/dashboard');
      return;
    }

    final now = DateTime.now();
    final last = _lastExitBackPress;
    if (last == null || now.difference(last) > const Duration(seconds: 2)) {
      _lastExitBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('pressBackAgainToExit'))),
      );
      return;
    }
    SystemNavigator.pop();
  }
}
