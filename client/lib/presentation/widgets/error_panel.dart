import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../common/friendly_api_error_message.dart';

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({
    required this.error,
    this.onRetry,
    this.onBack,
    this.onSignIn,
    this.titleOverride,
    super.key,
  });

  final Object error;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;
  final VoidCallback? onSignIn;
  final String? titleOverride;

  @override
  Widget build(BuildContext context) {
    final friendly = FriendlyApiErrorMessage.describe(error, context: context);
    final theme = Theme.of(context);
    final retry = friendly.canRetry ? onRetry : null;
    final signIn = friendly.shouldSignIn ? onSignIn : null;
    final back = friendly.shouldGoBack ? onBack : null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    friendly.icon,
                    size: 42,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  titleOverride ?? friendly.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  friendly.message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (back != null)
                      OutlinedButton.icon(
                        onPressed: back,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(context.l10n.t('back')),
                      ),
                    if (signIn != null)
                      FilledButton.icon(
                        onPressed: signIn,
                        icon: const Icon(Icons.login_rounded),
                        label: Text(context.l10n.t('signIn')),
                      ),
                    if (retry != null)
                      FilledButton.icon(
                        onPressed: retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(context.l10n.t('tryAgain')),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingPanel extends StatelessWidget {
  const LoadingPanel({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 14),
          Text(
            message ?? context.l10n.t('loading'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
