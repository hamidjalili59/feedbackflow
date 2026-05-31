import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/phone/phone_number_normalizer.dart';
import '../../../data/dto/dto.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/common/friendly_api_error_message.dart';
import '../../../presentation/theme/app_spacing.dart';
import '../../../presentation/theme/app_theme.dart';
import '../../../presentation/widgets/directional_value_text.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.redirectLocation, this.noticeKey});

  final String? redirectLocation;
  final String? noticeKey;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _passwordStep = false;
  bool _obscure = true;
  String? _normalizedPhone;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final loading = auth.isLoading;

    ref.listen<AsyncValue<AuthSession?>>(authControllerProvider, (
      previous,
      next,
    ) {
      final session = next.asData?.value;
      if (session != null) {
        HapticFeedback.mediumImpact();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted)
            context.go(_safeRedirectLocation(widget.redirectLocation));
        });
      }
      if (next.hasError && previous?.error != next.error) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_loginErrorMessage(next.error!, context))),
        );
      }
    });

    return Scaffold(
      body: DecoratedBox(
        decoration: AppTheme.pageGradient(context),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),
                    Text(
                      context.l10n.t('login.welcome'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _passwordStep
                          ? context.l10n.t('login.passwordSubtitle')
                          : context.l10n.t('login.phoneSubtitle'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF79809C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 72),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.04),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _passwordStep
                          ? _PasswordInput(
                              key: const ValueKey('password'),
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              obscure: _obscure,
                              phone: _normalizedPhone ?? '',
                              onBack: _backToPhone,
                              onToggle: () =>
                                  setState(() => _obscure = !_obscure),
                              onSubmit: _submit,
                            )
                          : _PhoneInput(
                              key: const ValueKey('phone'),
                              controller: _phoneController,
                              focusNode: _phoneFocus,
                              onSubmit: _continueToPassword,
                            ),
                    ),
                    if (auth.hasError) ...[
                      const SizedBox(height: 16),
                      _LoginError(
                        message: _loginErrorMessage(auth.error!, context),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: loading
                            ? null
                            : (_passwordStep ? _submit : _continueToPassword),
                        child: loading
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _passwordStep
                                    ? context.l10n.t('signIn')
                                    : context.l10n.t('continue'),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF91A8F7),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: loading ? null : _startGuestLogin,
                        child: Text(_guestButtonLabel),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _guestHelpText,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF858BA6),
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _loginErrorMessage(Object error, BuildContext context) {
    final code = FriendlyApiErrorMessage.errorCodeOf(error);
    if (code == ErrorCode.unauthorized && _passwordStep) {
      return context.l10n.t('login.invalidCredentials');
    }
    if (code == ErrorCode.validationError) {
      return context.l10n.t('login.invalidPhonePassword');
    }
    return FriendlyApiErrorMessage.from(error, context: context);
  }

  void _continueToPassword() {
    final normalized = PhoneNumberNormalizer.normalize(_phoneController.text);
    if (normalized.isEmpty) {
      _phoneFocus.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('login.enterPhone'))),
      );
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _normalizedPhone = normalized;
      _passwordStep = true;
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _passwordFocus.requestFocus(),
    );
  }

  void _backToPhone() {
    HapticFeedback.selectionClick();
    setState(() => _passwordStep = false);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _phoneFocus.requestFocus(),
    );
  }

  Future<void> _submit() async {
    if (!_passwordStep) {
      _continueToPassword();
      return;
    }
    final phone =
        _normalizedPhone ??
        PhoneNumberNormalizer.normalize(_phoneController.text);
    final password = _passwordController.text;
    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('login.phonePasswordRequired'))),
      );
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .login(phone: phone, password: password);
  }

  String get _guestButtonLabel =>
      _publicTokenFromRedirect(widget.redirectLocation) == null
      ? context.l10n.t('login.guestButton')
      : context.l10n.t('login.anonymousFormButton');

  String get _guestHelpText =>
      _publicTokenFromRedirect(widget.redirectLocation) == null
      ? context.l10n.t('login.guestHelp')
      : context.l10n.t('login.anonymousHelp');

  Future<void> _startGuestLogin() async {
    final publicToken = _publicTokenFromRedirect(widget.redirectLocation);
    if (publicToken != null) {
      // Public-form anonymous/guest answering is form-local. Do not call
      // authController.guestLogin here because that would overwrite the
      // user's existing access/refresh tokens and look like a logout.
      context.go(
        '/public/${Uri.encodeComponent(publicToken)}?respondent_mode=anonymous',
      );
      return;
    }

    final input = await showModalBottomSheet<_GuestLoginInput>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _GuestOrganizationSheet(),
    );
    if (!mounted || input == null) return;
    await ref
        .read(authControllerProvider.notifier)
        .guestLogin(
          organizationSlug: input.organizationSlug,
          displayName: input.displayName,
        );
  }
}

class _PhoneInput extends StatelessWidget {
  const _PhoneInput({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return _InputShell(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Text(
              '+98',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            Container(
              width: 1,
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFFE1E6F1),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹٠-٩+ ]')),
                ],
                decoration: InputDecoration.collapsed(
                  hintText: context.l10n.t('login.phoneHint'),
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
                onSubmitted: (_) => onSubmit(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  const _PasswordInput({
    required this.controller,
    required this.focusNode,
    required this.obscure,
    required this.phone,
    required this.onBack,
    required this.onToggle,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscure;
  final String phone;
  final VoidCallback onBack;
  final VoidCallback onToggle;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: LtrValueText(phone),
          ),
        ),
        const SizedBox(height: 8),
        _InputShell(
          child: Row(
            children: [
              IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscure,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration.collapsed(
                    hintText: context.l10n.t('login.passwordHint'),
                  ),
                  onSubmitted: (_) => onSubmit(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InputShell extends StatelessWidget {
  const _InputShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 12),
            color: Colors.black.withValues(alpha: 0.035),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _LoginError extends StatelessWidget {
  const _LoginError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.danger,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }
}

String _safeRedirectLocation(String? location) {
  if (location == null || location.trim().isEmpty) return '/dashboard';
  final uri = Uri.tryParse(location);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return '/dashboard';
  return location.startsWith('/') ? location : '/dashboard';
}

String? _publicTokenFromRedirect(String? location) {
  final safe = _safeRedirectLocation(location);
  final uri = Uri.tryParse(safe);
  if (uri == null || uri.pathSegments.length != 2) return null;
  if (uri.pathSegments.first != 'public') return null;
  final token = uri.pathSegments.last.trim();
  return token.isEmpty ? null : token;
}

class _GuestLoginInput {
  const _GuestLoginInput({
    required this.organizationSlug,
    required this.displayName,
  });

  final String organizationSlug;
  final String displayName;
}

class _GuestOrganizationSheet extends StatefulWidget {
  const _GuestOrganizationSheet();

  @override
  State<_GuestOrganizationSheet> createState() =>
      _GuestOrganizationSheetState();
}

class _GuestOrganizationSheetState extends State<_GuestOrganizationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _organizationController = TextEditingController();
  final _nameController = TextEditingController(text: '');

  @override
  void dispose() {
    _organizationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.t('guest.organizationTitle'),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.t('guest.organizationHelp'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _organizationController,
              textInputAction: TextInputAction.next,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              decoration: InputDecoration(
                labelText: context.l10n.t('guest.organizationCode'),
                hintText: context.l10n.t('guest.organizationHint'),
                prefixIcon: Icon(Icons.apartment_rounded),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty)
                  return context.l10n.t('guest.organizationRequired');
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: context.l10n.t('guest.displayName'),
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.login_rounded),
              label: Text(context.l10n.t('guest.signIn')),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(
      _GuestLoginInput(
        organizationSlug: _organizationController.text.trim(),
        displayName: _nameController.text.trim().isEmpty
            ? context.l10n.t('guest')
            : _nameController.text.trim(),
      ),
    );
  }
}
