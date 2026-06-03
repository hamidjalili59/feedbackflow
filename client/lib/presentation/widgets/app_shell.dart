import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_chrome.dart';

/// Navigation destinations available from the global app shell.
enum AppDestination { dashboard, forms, profile }

extension AppDestinationX on AppDestination {
  String labelKey(BuildContext context) => switch (this) {
    AppDestination.dashboard => 'dashboard',
    AppDestination.forms => 'forms',
    AppDestination.profile => 'profile',
  };

  IconData get outlinedIcon => switch (this) {
    AppDestination.dashboard => Icons.dashboard_outlined,
    AppDestination.forms => Icons.article_outlined,
    AppDestination.profile => Icons.person_outline_rounded,
  };

  IconData get filledIcon => switch (this) {
    AppDestination.dashboard => Icons.dashboard_rounded,
    AppDestination.forms => Icons.article_rounded,
    AppDestination.profile => Icons.person_rounded,
  };

  String get path => switch (this) {
    AppDestination.dashboard => '/dashboard',
    AppDestination.forms => '/forms',
    AppDestination.profile => '/profile',
  };
}

/// Single source of truth for the responsive app chrome.
///
/// - Compact (< 600 dp): bottom navigation bar
/// - Medium  (600–905 dp): collapsed navigation rail (icons only)
/// - Expanded (>= 905 dp): expanded navigation rail (icons + labels)
class AppShell extends ConsumerWidget {
  const AppShell({
    required this.body,
    required this.selected,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.showNavigation = true,
    super.key,
  });

  final Widget body;
  final AppDestination selected;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool showNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showNavigation) {
      return Scaffold(
        extendBodyBehindAppBar: false,
        appBar: appBar,
        body: DecoratedBox(
          decoration: AppTheme.pageGradient(context),
          child: SafeArea(top: false, child: body),
        ),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      );
    }

    final size = context.windowSize;
    final isCompact = size.isCompact;

    if (isCompact) {
      return _CompactScaffold(
        appBar: appBar,
        body: body,
        selected: selected,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      );
    }

    return _RailScaffold(
      appBar: appBar,
      body: body,
      selected: selected,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      extended: size.isExpandedOrUp,
    );
  }
}

class _CompactScaffold extends StatelessWidget {
  const _CompactScaffold({
    required this.appBar,
    required this.body,
    required this.selected,
    required this.floatingActionButton,
    required this.floatingActionButtonLocation,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final AppDestination selected;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: appBar,
      body: DecoratedBox(
        decoration: AppTheme.pageGradient(context),
        child: SafeArea(top: false, child: body),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: _AppBottomNav(selected: selected),
    );
  }
}

class _AppBottomNav extends StatelessWidget {
  const _AppBottomNav({required this.selected});

  final AppDestination selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: NavigationBar(
        selectedIndex: selected.index,
        onDestinationSelected: (index) =>
            _onSelected(context, AppDestination.values[index]),
        destinations: [
          for (final dest in AppDestination.values)
            NavigationDestination(
              icon: Icon(dest.outlinedIcon),
              selectedIcon: Icon(dest.filledIcon),
              label: context.l10n.t(dest.labelKey(context)),
            ),
        ],
      ),
    );
  }
}

class _RailScaffold extends StatelessWidget {
  const _RailScaffold({
    required this.appBar,
    required this.body,
    required this.selected,
    required this.floatingActionButton,
    required this.floatingActionButtonLocation,
    required this.extended,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final AppDestination selected;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: appBar,
      body: DecoratedBox(
        decoration: AppTheme.pageGradient(context),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    end: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                child: NavigationRail(
                  extended: extended,
                  minExtendedWidth: 220,
                  selectedIndex: selected.index,
                  onDestinationSelected: (index) =>
                      _onSelected(context, AppDestination.values[index]),
                  labelType: extended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: [
                    for (final dest in AppDestination.values)
                      NavigationRailDestination(
                        icon: Icon(dest.outlinedIcon),
                        selectedIcon: Icon(dest.filledIcon),
                        label: Text(context.l10n.t(dest.labelKey(context))),
                      ),
                  ],
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

void _onSelected(BuildContext context, AppDestination dest) {
  HapticFeedback.selectionClick();
  final current = GoRouterState.of(context).matchedLocation;
  if (current == dest.path) return;
  context.go(dest.path);
}

/// AppBar variant that adapts to compact screens by collapsing locale & theme
/// switchers into an overflow menu.
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdaptiveAppBar({
    required this.title,
    this.leading,
    this.primaryAction,
    this.extraActions = const <Widget>[],
    super.key,
  });

  final Widget title;
  final Widget? leading;

  /// A single high-priority action shown directly on compact AppBars.
  final Widget? primaryAction;

  /// Lower priority actions visible on medium+ screens. On compact screens
  /// they collapse into a menu.
  final List<Widget> extraActions;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompactWidth;
    final actions = <Widget>[
      if (compact) ...[
        ?primaryAction,
        const _OverflowMenu(),
        const SizedBox(width: AppSpacing.xs),
      ] else ...[
        ...extraActions,
        const LanguageButton(),
        const ThemeModeButton(),
        if (primaryAction != null) ...[
          const SizedBox(width: AppSpacing.xs),
          primaryAction!,
        ],
        const SizedBox(width: AppSpacing.sm),
      ],
    ];
    return AppBar(
      leading: leading,
      title: title,
      titleSpacing: AppSpacing.sm,
      actions: actions,
    );
  }
}

class _OverflowMenu extends ConsumerWidget {
  const _OverflowMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: context.l10n.t('more'),
      icon: const Icon(Icons.more_vert_rounded),
      onPressed: () => _showAppOptionsSheet(context, ref),
    );
  }
}

Future<void> _showAppOptionsSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.t('language'),
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xs),
              _LanguageOptions(
                onPicked: () => Navigator.of(sheetContext).pop(),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.t('theme'),
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xs),
              _ThemeOptions(onPicked: () => Navigator.of(sheetContext).pop()),
            ],
          ),
        ),
      );
    },
  );
}

class _LanguageOptions extends ConsumerWidget {
  const _LanguageOptions({required this.onPicked});

  final VoidCallback onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeControllerProvider);
    final controller = ref.read(localeControllerProvider.notifier);
    Widget tile(Locale locale, String label, String short) {
      final selected = current.languageCode == locale.languageCode;
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: Text(
            short,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        title: Text(label),
        trailing: selected
            ? Icon(
                Icons.check_rounded,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: () {
          controller.setLocale(locale);
          onPicked();
        },
      );
    }

    return Column(
      children: [
        tile(const Locale('fa'), context.l10n.t('persian'), 'فا'),
        tile(const Locale('en'), context.l10n.t('english'), 'EN'),
        tile(const Locale('zh'), context.l10n.t('chinese'), '中'),
      ],
    );
  }
}

class _ThemeOptions extends ConsumerWidget {
  const _ThemeOptions({required this.onPicked});

  final VoidCallback onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    Widget tile(ThemeMode mode, IconData icon, String label) {
      final selected = current == mode;
      return ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: selected
            ? Icon(
                Icons.check_rounded,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: () {
          controller.setThemeMode(mode);
          onPicked();
        },
      );
    }

    return Column(
      children: [
        tile(
          ThemeMode.system,
          Icons.brightness_auto_rounded,
          context.l10n.t('systemTheme'),
        ),
        tile(
          ThemeMode.light,
          Icons.light_mode_rounded,
          context.l10n.t('light'),
        ),
        tile(ThemeMode.dark, Icons.dark_mode_rounded, context.l10n.t('dark')),
      ],
    );
  }
}
