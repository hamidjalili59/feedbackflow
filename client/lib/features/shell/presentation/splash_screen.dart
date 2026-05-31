import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/widgets/app_chrome.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hashPublicRoute = _publicRouteFromHash();
    if (hashPublicRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(hashPublicRoute);
      });
    }

    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<AuthSession?>>(authControllerProvider, (
      previous,
      next,
    ) {
      final data = next.asData;
      if (data != null) _routeFromAuthState(context, data.value);
    });

    final currentData = authState.asData;
    if (currentData != null) {
      _routeFromAuthState(context, currentData.value);
    }

    return GradientScaffold(
      appBar: AppBar(
        actions: const [
          LanguageButton(),
          ThemeModeButton(),
          SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fact_check_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              context.l10n.t('preparingApp'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  static String? _publicRouteFromHash() {
    final fragment = Uri.base.fragment;
    if (fragment.startsWith('/public/')) return fragment;
    return null;
  }

  static void _routeFromAuthState(BuildContext context, AuthSession? session) {
    if (_publicRouteFromHash() != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.go(session == null ? '/login' : '/dashboard');
    });
  }
}
