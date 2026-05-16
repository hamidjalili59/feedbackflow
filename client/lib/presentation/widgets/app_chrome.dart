import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({this.fallbackLocation, this.tooltip, super.key});

  final String? fallbackLocation;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip ?? context.l10n.t('back'),
      icon: Icon(
        context.l10n.textDirection == TextDirection.rtl
            ? Icons.arrow_forward_rounded
            : Icons.arrow_back_rounded,
      ),
      onPressed: () {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.maybePop();
          return;
        }
        final fallback = fallbackLocation;
        if (fallback != null && fallback.isNotEmpty) {
          context.go(fallback);
        }
      },
    );
  }
}

class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    return PopupMenuButton<ThemeMode>(
      tooltip: l10n.t('theme'),
      initialValue: mode,
      onSelected: controller.setThemeMode,
      icon: Icon(_iconFor(mode)),
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: ThemeMode.system,
              child: ListTile(
                leading: const Icon(Icons.brightness_auto_rounded),
                title: Text(l10n.t('systemTheme')),
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.light,
              child: ListTile(
                leading: const Icon(Icons.light_mode_rounded),
                title: Text(l10n.t('light')),
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.dark,
              child: ListTile(
                leading: const Icon(Icons.dark_mode_rounded),
                title: Text(l10n.t('dark')),
              ),
            ),
          ],
    );
  }

  IconData _iconFor(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.system => Icons.brightness_auto_rounded,
    };
  }
}

class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = ref.watch(localeControllerProvider);
    return PopupMenuButton<Locale>(
      tooltip: l10n.t('language'),
      initialValue: locale,
      onSelected: ref.read(localeControllerProvider.notifier).setLocale,
      icon: const Icon(Icons.language_rounded),
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: const Locale('fa'),
              child: ListTile(
                leading: const Text(
                  'فا',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                title: Text(l10n.t('persian')),
              ),
            ),
            PopupMenuItem(
              value: const Locale('en'),
              child: ListTile(
                leading: const Text(
                  'EN',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                title: Text(l10n.t('english')),
              ),
            ),
            PopupMenuItem(
              value: const Locale('zh'),
              child: ListTile(
                leading: const Text(
                  '中',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                title: Text(l10n.t('chinese')),
              ),
            ),
          ],
    );
  }
}

class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    required this.body,
    this.appBar,
    this.floatingActionButton,
    super.key,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: DecoratedBox(
        decoration: AppTheme.pageGradient(context),
        child: SafeArea(top: false, child: body),
      ),
    );
  }
}

class PageHeaderCard extends StatelessWidget {
  const PageHeaderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.badges = const <Widget>[],
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final List<Widget> badges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.72 : 0.96,
              ),
              scheme.tertiaryContainer.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.48 : 0.82,
              ),
            ],
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.42),
          ),
        ),
        padding: AppSpacing.cardLarge,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.32),
                ),
              ),
              child: Icon(icon, color: scheme.primary, size: 28),
            ),
            AppSpacing.gapHorizontalMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.82),
                    ),
                  ),
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(spacing: 8, runSpacing: 8, children: badges),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[AppSpacing.gapHorizontalSm, trailing!],
          ],
        ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    required this.child,
    this.padding = AppSpacing.card,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final content = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.48),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 12),
            color: Colors.black.withValues(alpha: dark ? 0.22 : 0.045),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
    return Card(
      child:
          onTap == null
              ? content
              : InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                onTap: onTap,
                child: content,
              ),
    );
  }
}

class AppInfoChip extends StatelessWidget {
  const AppInfoChip({required this.label, this.icon, this.minWidth, super.key});

  final String label;
  final IconData? icon;
  final double? minWidth;

  static const double height = 34;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth ?? 0,
        minHeight: height,
        maxHeight: height,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
