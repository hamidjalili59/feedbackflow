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
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late final RootBackButtonDispatcher _backButtonDispatcher;

  @override
  void initState() {
    super.initState();
    _backButtonDispatcher = _FeedbackFlowBackButtonDispatcher(
      ref: ref,
      router: () => ref.read(routerProvider),
      scaffoldMessengerKey: _scaffoldMessengerKey,
    );
  }

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
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: AppTheme.light(locale),
      darkTheme: AppTheme.dark(locale),
      themeMode: ref.watch(themeControllerProvider),
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      backButtonDispatcher: _backButtonDispatcher,
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
          child: Directionality(
            textDirection: context.l10n.textDirection,
            child: Column(
              children: [
                const SmartAppBanner(),
                Expanded(child: child ?? const SizedBox.shrink()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeedbackFlowBackButtonDispatcher extends RootBackButtonDispatcher {
  _FeedbackFlowBackButtonDispatcher({
    required this.ref,
    required this.router,
    required this.scaffoldMessengerKey,
  });

  final WidgetRef ref;
  final GoRouter Function() router;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  DateTime? _lastExitBackPress;

  @override
  Future<bool> didPopRoute() async {
    final handledByRouter = await invokeCallback(Future<bool>.value(false));
    if (handledByRouter) {
      _lastExitBackPress = null;
      return true;
    }

    final appRouter = router();
    final currentPath = appRouter.routeInformationProvider.value.uri.path;
    final session = ref.read(authControllerProvider).asData?.value;
    if (session != null && currentPath != '/dashboard') {
      _lastExitBackPress = null;
      appRouter.go('/dashboard');
      return true;
    }

    if (session == null && currentPath != '/login') {
      _lastExitBackPress = null;
      appRouter.go('/login');
      return true;
    }

    final now = DateTime.now();
    final last = _lastExitBackPress;
    if (last == null || now.difference(last) > const Duration(seconds: 2)) {
      _lastExitBackPress = now;
      _showExitBackSnackBar();
      return true;
    }

    await SystemNavigator.pop();
    return true;
  }

  void _showExitBackSnackBar() {
    final context = scaffoldMessengerKey.currentContext;
    if (context == null) return;
    scaffoldMessengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          showCloseIcon: true,
          content: Row(
            children: [
              const Icon(Icons.touch_app_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(context.l10n.t('pressBackAgainToExit'))),
            ],
          ),
        ),
      );
  }
}
