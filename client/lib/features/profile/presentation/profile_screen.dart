import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../data/dto/dto.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/theme/app_breakpoints.dart';
import '../../../presentation/theme/app_spacing.dart';
import '../../../presentation/common/friendly_api_error_message.dart';
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

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.session, required this.onSignOut});

  final AuthSession session;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = session.user;
    final avatarUrl = _visibleAvatarUrl(user.profile);
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
                  trailing: _ProfileAvatar(
                    displayName: user.displayName,
                    avatarUrl: avatarUrl,
                    radius: 34,
                  ),
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
                      ListTile(
                        leading: const Icon(Icons.image_outlined),
                        title: Text(context.l10n.t('avatar')),
                        subtitle: Text(
                          avatarUrl == null || avatarUrl.isEmpty
                              ? context.l10n.t('avatarFallbackInitials')
                              : avatarUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton.filledTonal(
                          tooltip: context.l10n.t('edit'),
                          onPressed: () => _editProfile(context, ref, user),
                          icon: const Icon(Icons.edit_rounded),
                        ),
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

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    UserDetailDto user,
  ) async {
    final request = await showDialog<UpdateUserProfileRequest>(
      context: context,
      builder: (context) => _EditProfileDialog(user: user),
    );
    if (request == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(request);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.t('profileUpdated'))),
        );
      }
    } catch (error) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              FriendlyApiErrorMessage.from(error, context: context),
            ),
          ),
        );
      }
    }
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.user});

  final UserDetailDto user;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  String? _avatarDataUrl;
  bool _pickingAvatar = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.displayName);
    _email = TextEditingController(text: widget.user.email ?? '');
    _avatarDataUrl = widget.user.profile.avatarUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.t('editProfile')),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width.clamp(280.0, 440.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: context.l10n.t('displayName'),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: context.l10n.t('email')),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                _ProfileAvatar(
                  displayName: widget.user.displayName,
                  avatarUrl: _avatarDataUrl,
                  radius: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _pickingAvatar ? null : _pickAvatar,
                        icon: _pickingAvatar
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_rounded),
                        label: Text(context.l10n.t('avatarUpload')),
                      ),
                      if (_avatarDataUrl != null &&
                          _avatarDataUrl!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _avatarDataUrl = null),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(context.l10n.t('removeAvatar')),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              context.l10n.t('avatarUploadHint'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: () {
            final current = widget.user.profile;
            Navigator.pop(
              context,
              UpdateUserProfileRequest(
                displayName: _name.text.trim(),
                email: _email.text.trim().isEmpty ? null : _email.text.trim(),
                profile: UserProfileDto(
                  phone: current.phone,
                  avatarUrl: _avatarDataUrl,
                  locale: current.locale,
                  timezone: current.timezone,
                  metadata: current.metadata,
                ),
              ),
            );
          },
          child: Text(context.l10n.t('save')),
        ),
      ],
    );
  }

  Future<void> _pickAvatar() async {
    setState(() => _pickingAvatar = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      final file = result?.files.single;
      final bytes = file?.bytes;
      if (bytes == null || bytes.isEmpty) return;
      if (bytes.length > 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.t('avatarTooLarge'))),
        );
        return;
      }
      final mime = _avatarMimeType(file?.extension);
      setState(
        () => _avatarDataUrl = 'data:$mime;base64,${base64Encode(bytes)}',
      );
    } finally {
      if (mounted) setState(() => _pickingAvatar = false);
    }
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.displayName,
    required this.avatarUrl,
    this.radius = 24,
  });

  final String displayName;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(displayName);
    return CircleAvatar(
      radius: radius,
      backgroundImage: _avatarImageProvider(avatarUrl),
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? Text(initials, style: const TextStyle(fontWeight: FontWeight.w900))
          : null,
    );
  }
}

ImageProvider<Object>? _avatarImageProvider(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.isEmpty) return null;
  final bytes = _decodeDataUrl(avatarUrl);
  if (bytes != null) return MemoryImage(bytes);
  return NetworkImage(avatarUrl);
}

Uint8List? _decodeDataUrl(String value) {
  final match = RegExp(r'^data:image/[^;]+;base64,(.+)$').firstMatch(value);
  if (match == null) return null;
  try {
    return base64Decode(match.group(1)!);
  } catch (_) {
    return null;
  }
}

String _avatarMimeType(String? extension) => switch (extension?.toLowerCase()) {
  'jpg' || 'jpeg' => 'image/jpeg',
  'webp' => 'image/webp',
  'gif' => 'image/gif',
  _ => 'image/png',
};

String? _visibleAvatarUrl(UserProfileDto profile) {
  final metadata = profile.metadata;
  if (metadata is Map && metadata['avatar_banned'] == true) return null;
  return profile.avatarUrl;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  final first = parts.first.characters.first;
  final second = parts.length > 1 ? parts.last.characters.first : '';
  return (first + second).toUpperCase();
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
