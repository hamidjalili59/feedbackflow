import 'package:flutter/material.dart';
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

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isPasswordStep = false;
  String? _normalizedPhone;

  @override
  void dispose() {
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

    ref.listen<AsyncValue<AuthSession?>>(authControllerProvider, (
      previous,
      next,
    ) {
      final session = next.asData?.value;
      if (session != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go(_safeRedirectLocation(widget.redirectLocation));
          }
        });
        return;
      }
      if (next.hasError && previous?.error != next.error) {
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.narrowContentMax),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.fact_check_rounded,
                        size: 52,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        context.l10n.t('welcomeBack'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.t('loginSubtitle'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (widget.noticeKey != null) ...[
                        const SizedBox(height: 18),
                        _LoginNotice(
                          message: context.l10n.t(widget.noticeKey!),
                        ),
                      ],
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child:
                            _isPasswordStep
                                ? Column(
                                  key: const ValueKey('password-step'),
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _PhoneSummary(
                                      phone:
                                          _normalizedPhone ??
                                          PhoneNumberNormalizer.normalize(
                                            _phoneController.text,
                                          ),
                                      onEdit: loading ? null : _backToPhoneStep,
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocusNode,
                                      enabled: !loading,
                                      obscureText: true,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      decoration: InputDecoration(
                                        labelText: context.l10n.t('password'),
                                        prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                        ),
                                      ),
                                      onFieldSubmitted: (_) => _submit(),
                                    ),
                                  ],
                                )
                                : TextFormField(
                                  key: const ValueKey('phone-step'),
                                  controller: _phoneController,
                                  focusNode: _phoneFocusNode,
                                  enabled: !loading,
                                  keyboardType: TextInputType.phone,
                                  autofillHints: const [
                                    AutofillHints.telephoneNumber,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: context.l10n.t('phoneNumber'),
                                    hintText: '989315245654',
                                    helperText: context.l10n.t('phoneHelper'),
                                    prefixIcon: const Icon(
                                      Icons.phone_iphone_rounded,
                                    ),
                                  ),
                                  onFieldSubmitted:
                                      (_) => _continueToPasswordStep(),
                                ),
                      ),
                      if (auth.hasError) ...[
                        const SizedBox(height: 14),
                        Text(
                          FriendlyApiErrorMessage.from(
                            auth.error!,
                            context: context,
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: loading ? null : _submit,
                        icon:
                            loading
                                ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
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
                        ),
                      ),
                    ],
                  ),
                ),
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

    return ref
        .read(authControllerProvider.notifier)
        .login(
          phone:
              _normalizedPhone ??
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

class _LoginNotice extends StatelessWidget {
  const _LoginNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline_rounded, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _PhoneSummary extends StatelessWidget {
  const _PhoneSummary({required this.phone, required this.onEdit});

  final String phone;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_iphone_rounded, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              phone,
              textDirection: TextDirection.ltr,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(context.l10n.t('edit')),
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
