import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/theme/app_breakpoints.dart';
import '../../../presentation/theme/app_spacing.dart';
import '../../../presentation/widgets/directional_value_text.dart';
import '../../../presentation/widgets/app_chrome.dart';
import '../../../presentation/widgets/app_shell.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return AppShell(
      selected: AppDestination.profile,
      appBar: AdaptiveAppBar(title: Text(context.l10n.t('profile'))),
      body: auth.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            _SignedOutPanel(onSignIn: () => context.go('/login')),
        data: (session) {
          if (session == null) {
            return _SignedOutPanel(onSignIn: () => context.go('/login'));
          }
          return _ProfileBody(
            session: session,
            onSignOut: () => _confirmSignOut(context, ref),
          );
        },
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('signOut')),
        content: Text(context.l10n.t('signOutConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.t('signOut')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go('/login');
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.session, required this.onSignOut});

  final AuthSession session;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final user = session.user;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        context.isCompactWidth ? AppSpacing.xxl : AppSpacing.lg,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.contentMax,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeaderCard(
                  icon: Icons.person_rounded,
                  title: user.displayName,
                  subtitle: context.l10n.enumLabel(user.primaryRole.toJson()),
                ),
                const SizedBox(height: AppSpacing.md),
                SoftCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone_rounded),
                        title: Text(context.l10n.t('phoneNumber')),
                        subtitle: LtrValueText(user.phone),
                      ),
                      if (user.email != null && user.email!.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.alternate_email_rounded),
                          title: Text(context.l10n.t('email')),
                          subtitle: LtrValueText(user.email!),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SoftCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.language_rounded),
                        title: Text(context.l10n.t('language')),
                        trailing: const LanguageButton(),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.brightness_6_rounded),
                        title: Text(context.l10n.t('theme')),
                        trailing: const ThemeModeButton(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.4),
                    ),
                  ),
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(context.l10n.t('signOut')),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SignedOutPanel extends StatelessWidget {
  const _SignedOutPanel({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.t('signIn'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onSignIn,
              icon: const Icon(Icons.login_rounded),
              label: Text(context.l10n.t('signIn')),
            ),
          ],
        ),
      ),
    );
  }
}
