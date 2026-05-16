import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';
import 'smart_app_banner_stub.dart'
    if (dart.library.js_interop) 'smart_app_banner_web.dart';

/// A banner shown only on web that suggests opening the current page in the
/// native app via the `feedbackflow://` custom URL scheme.
///
/// On non-web platforms this widget renders nothing.
class SmartAppBanner extends StatefulWidget {
  const SmartAppBanner({super.key});

  @override
  State<SmartAppBanner> createState() => _SmartAppBannerState();
}

class _SmartAppBannerState extends State<SmartAppBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _dismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.phone_android_rounded,
                color: scheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.t('openInApp'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    context.l10n.t('openInAppSubtitle'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => openDeepLink(),
              child: Text(context.l10n.t('openApp')),
            ),
            const SizedBox(width: AppSpacing.xxs),
            IconButton(
              onPressed: () => setState(() => _dismissed = true),
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
