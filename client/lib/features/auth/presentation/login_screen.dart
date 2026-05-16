import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/phone/phone_number_normalizer.dart';
import '../../../presentation/common/friendly_api_error_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/theme/app_breakpoints.dart';
import '../../../presentation/theme/app_spacing.dart';
import '../../../presentation/widgets/app_chrome.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.redirectLocation, this.noticeKey});

  final String? redirectLocation;
  final String? noticeKey;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isPasswordStep = false;
  bool _obscurePassword = true;
  String? _normalizedPhone;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final loading = auth.isLoading;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    ref.listen<AsyncValue<AuthSession?>>(authControllerProvider, (
      previous,
      next,
    ) {
      final session = next.asData?.value;
      if (session != null) {
        HapticFeedback.mediumImpact();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go(_safeRedirectLocation(widget.redirectLocation));
          }
        });
        return;
      }
      if (next.hasError && previous?.error != next.error) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FriendlyApiErrorMessage.from(next.error!, context: context),
            ),
          ),
        );
      }
    });

    return GradientScaffold(
      appBar: AppBar(
        title: Text(context.l10n.t('app.name')),
        actions: const [
          LanguageButton(),
          ThemeModeButton(),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.narrowContentMax,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Hero header ---
                  _LoginHero(dark: dark, scheme: scheme, theme: theme),
                  const SizedBox(height: AppSpacing.xl),

                  // --- Form card ---
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.xxl,
                      ),
                      child: AutofillGroup(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.noticeKey != null) ...[
                              _LoginNotice(
                                message: context.l10n.t(widget.noticeKey!),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],

                            // --- Step content ---
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.08),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: _isPasswordStep
                                  ? _PasswordStep(
                                      key: const ValueKey('password-step'),
                                      phone: _normalizedPhone ??
                                          PhoneNumberNormalizer.normalize(
                                            _phoneController.text,
                                          ),
                                      controller: _passwordController,
                                      focusNode: _passwordFocusNode,
                                      loading: loading,
                                      obscure: _obscurePassword,
                                      onToggleObscure: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      onEdit: _backToPhoneStep,
                                      onSubmit: _submit,
                                    )
                                  : _PhoneStep(
                                      key: const ValueKey('phone-step'),
                                      controller: _phoneController,
                                      focusNode: _phoneFocusNode,
                                      loading: loading,
                                      onSubmit: _continueToPasswordStep,
                                    ),
                            ),

                            // --- Error ---
                            if (auth.hasError) ...[
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: scheme.errorContainer
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: scheme.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        FriendlyApiErrorMessage.from(
                                          auth.error!,
                                          context: context,
                                        ),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: scheme.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // --- Submit button ---
                            const SizedBox(height: AppSpacing.xl),
                            SizedBox(
                              height: 54,
                              child: FilledButton.icon(
                                onPressed: loading ? null : _submit,
                                icon: loading
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        _isPasswordStep
                                            ? Icons.login_rounded
                                            : Icons.arrow_forward_rounded,
                                      ),
                                label: Text(
                                  loading
                                      ? context.l10n.t('signingIn')
                                      : _isPasswordStep
                                          ? context.l10n.t('signIn')
                                          : context.l10n.t('continue'),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _continueToPasswordStep() {
    final phone = PhoneNumberNormalizer.normalize(_phoneController.text);
    if (!PhoneNumberNormalizer.isLikelyValid(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('invalidPhoneNumber'))),
      );
      return Future<void>.value();
    }

    HapticFeedback.selectionClick();
    setState(() {
      _normalizedPhone = phone;
      _isPasswordStep = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _passwordFocusNode.requestFocus();
    });
    return Future<void>.value();
  }

  Future<void> _submit() {
    if (!_isPasswordStep) return _continueToPasswordStep();

    return ref.read(authControllerProvider.notifier).login(
          phone: _normalizedPhone ??
              PhoneNumberNormalizer.normalize(_phoneController.text),
          password: _passwordController.text,
        );
  }

  void _backToPhoneStep() {
    setState(() {
      _isPasswordStep = false;
      _normalizedPhone = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _phoneFocusNode.requestFocus();
    });
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _LoginHero extends StatelessWidget {
  const _LoginHero({
    required this.dark,
    required this.scheme,
    required this.theme,
  });

  final bool dark;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [
                  scheme.primaryContainer.withValues(alpha: 0.7),
                  scheme.tertiaryContainer.withValues(alpha: 0.5),
                ]
              : [
                  scheme.primaryContainer,
                  scheme.tertiaryContainer.withValues(alpha: 0.7),
                ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  color: scheme.primary.withValues(alpha: 0.15),
                ),
              ],
            ),
            child: Icon(
              Icons.fact_check_rounded,
              size: 32,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.t('welcomeBack'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.t('loginSubtitle'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.t('phoneNumber'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 58,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            enabled: !loading,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: InputDecoration(
              hintText: '+98 9xx xxx xxxx',
              hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.4),
                    letterSpacing: 1.2,
                  ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 10),
                child: Icon(Icons.phone_iphone_rounded, size: 22),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
            onFieldSubmitted: (_) => onSubmit(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.t('phoneHelper'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _PasswordStep extends StatelessWidget {
  const _PasswordStep({
    super.key,
    required this.phone,
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.obscure,
    required this.onToggleObscure,
    required this.onEdit,
    required this.onSubmit,
  });

  final String phone;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onEdit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone summary chip
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.phone_iphone_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  phone,
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                ),
              ),
              TextButton(
                onPressed: loading ? null : onEdit,
                child: Text(context.l10n.t('edit')),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Password field
        Text(
          context.l10n.t('password'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 58,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            enabled: !loading,
            obscureText: obscure,
            autofillHints: const [AutofillHints.password],
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 10),
                child: Icon(Icons.lock_outline_rounded, size: 22),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              suffixIcon: IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              ),
            ),
            onFieldSubmitted: (_) => onSubmit(),
          ),
        ),
      ],
    );
  }
}

class _LoginNotice extends StatelessWidget {
  const _LoginNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: scheme.primary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

String _safeRedirectLocation(String? value) {
  if (value == null || value.trim().isEmpty) return '/forms';
  final trimmed = value.trim();
  if (!trimmed.startsWith('/') || trimmed.startsWith('//')) return '/forms';
  if (trimmed.startsWith('/login')) return '/forms';
  return trimmed;
}
