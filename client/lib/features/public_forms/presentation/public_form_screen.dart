import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../data/dto/dto.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/common/friendly_api_error_message.dart';
import '../../../presentation/widgets/app_chrome.dart';
import '../../../presentation/theme/app_spacing.dart';
import '../../../presentation/widgets/error_panel.dart';
import '../../../presentation/widgets/feedback_field_kit.dart';
import '../../../presentation/widgets/step_form_view.dart';

// Uses FeedbackFieldCard via FieldRenderer for the public feedback-sheet experience.

class PublicFormScreen extends ConsumerStatefulWidget {
  const PublicFormScreen({
    super.key,
    required this.publicToken,
    this.initialRespondentMode,
  });

  final String publicToken;
  final String? initialRespondentMode;

  @override
  ConsumerState<PublicFormScreen> createState() => _PublicFormScreenState();
}

class _PublicFormScreenState extends ConsumerState<PublicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accessFormKey = GlobalKey<FormState>();
  final _formPasswordController = TextEditingController();
  final _identityCodeController = TextEditingController();
  final _guestNameController = TextEditingController();
  final Map<String, Object?> _answers = <String, Object?>{};
  bool _validatingAccess = false;
  bool _submitting = false;
  String? _publicAccessToken;
  String? _respondentMode;
  String? _identityLabel;
  PublicSubmissionResponse? _submitted;
  bool _submittedByAuthenticated = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(publicFormProvider(widget.publicToken)));
  }

  @override
  void didUpdateWidget(covariant PublicFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.publicToken != widget.publicToken ||
        oldWidget.initialRespondentMode != widget.initialRespondentMode) {
      _resetEntryState();
      Future.microtask(() => ref.invalidate(publicFormProvider(widget.publicToken)));
    }
  }

  @override
  void dispose() {
    _formPasswordController.dispose();
    _identityCodeController.dispose();
    _guestNameController.dispose();
    super.dispose();
  }

  void _resetEntryState() {
    _formPasswordController.clear();
    _identityCodeController.clear();
    _answers.clear();
    _publicAccessToken = null;
    _respondentMode = null;
    _identityLabel = null;
    _submitted = null;
    _submittedByAuthenticated = false;
  }

  @override
  Widget build(BuildContext context) {
    final formAsync = ref.watch(publicFormProvider(widget.publicToken));
    final authAsync = ref.watch(authControllerProvider);
    final submitted = _submitted;

    return GradientScaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsetsDirectional.only(start: 8),
          child: AppBackButton(fallbackLocation: '/'),
        ),
        title: Text(context.l10n.t('publicForm')),
        actions: const [
          LanguageButton(),
          ThemeModeButton(),
          SizedBox(width: 12),
        ],
      ),
      body: formAsync.when(
        loading:
            () => LoadingPanel(message: context.l10n.t('loadingPublicForm')),
        error:
            (error, stackTrace) => ErrorPanel(
              error: error,
              onRetry:
                  () => ref.invalidate(publicFormProvider(widget.publicToken)),
              onBack:
                  () =>
                      Navigator.of(context).canPop()
                          ? Navigator.of(context).maybePop()
                          : context.go('/'),
            ),
        data: (form) {
          final session = authAsync.asData?.value;
          _respondentMode ??= _defaultRespondentMode(
            form,
            session != null,
            widget.initialRespondentMode,
          );
          final mode = _respondentMode ?? 'authenticated';

          if (session == null && mode == 'authenticated') {
            if (authAsync.isLoading) {
              return LoadingPanel(
                message: context.l10n.t('checkingAuthentication'),
              );
            }
            final loginLocation = _loginLocationForPublicForm(
              widget.publicToken,
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(loginLocation);
            });
            return _PublicAuthRequiredView(
              onSignIn: () => context.go(loginLocation),
            );
          }

          if (submitted != null) {
            return _SubmittedView(
              response: submitted,
              authenticated: _submittedByAuthenticated,
            );
          }
          if (_publicAccessToken == null && _needsEntryStep(form)) {
            return _PublicFormEntryGate(
              form: form,
              formKey: _accessFormKey,
              selectedMode: mode,
              formPasswordController: _formPasswordController,
              identityCodeController: _identityCodeController,
              guestNameController: _guestNameController,
              validating: _validatingAccess,
              identityLabel: _identityLabel,
              onModeChanged: (value) {
                if (value == 'authenticated' && session == null) {
                  context.go(_loginLocationForPublicForm(widget.publicToken));
                  return;
                }
                setState(() {
                  _respondentMode = value;
                  _publicAccessToken = null;
                  _identityLabel = null;
                });
              },
              onContinue: () => _validateEntry(form),
            );
          }
          return _LoadedPublicForm(
            formKey: _formKey,
            form: form,
            publicAccessToken: _publicAccessToken,
            submitting: _submitting,
            validatingAccess: _validatingAccess,
            answers: _answers,
            onAnswerChanged:
                (fieldId, value) => setState(() => _answers[fieldId] = value),
            onSubmit: () => _submit(form),
          );
        },
      ),
    );
  }

  Future<String?> _ensurePublicAccess(PublicFormDto form) async {
    final existing = _publicAccessToken;
    if (!_needsPublicAccessToken(form)) return existing;
    if (existing != null && existing.isNotEmpty) return existing;
    if (_validatingAccess) return null;

    setState(() => _validatingAccess = true);
    try {
      final response = await ref
          .read(publicFormsRepositoryProvider)
          .validatePublicFormAccess(
            publicToken: widget.publicToken,
            request: ValidatePublicFormAccessRequest(
              respondentMode: _respondentMode,
              formPassword:
                  _formPasswordController.text.trim().isEmpty
                      ? null
                      : _formPasswordController.text.trim(),
              identityCode:
                  _identityCodeController.text.trim().isEmpty
                      ? null
                      : _identityCodeController.text.trim(),
            ),
          );
      final token = response.accessToken;
      if (response.allowed && token != null && token.isNotEmpty) {
        if (mounted) {
          setState(() {
            _publicAccessToken = token;
            _identityLabel = response.identityLabel;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.t('publicAccessValidatedToast')),
            ),
          );
        }
        return token;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.reason ?? context.l10n.t('publicAccessNotAllowed'),
            ),
          ),
        );
      }
      return null;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FriendlyApiErrorMessage.from(error, context: context),
            ),
          ),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _validatingAccess = false);
    }
  }

  Future<void> _submit(PublicFormDto form) async {
    if (_formKey.currentState?.validate() != true) return;

    final missing = _firstMissingRequiredField(form.fields);
    if (missing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.l10n.t('answerRequiredField')} ${missing.label}',
          ),
        ),
      );
      return;
    }

    final publicAccessToken = await _ensurePublicAccess(form);
    if (!mounted) return;
    if (_needsPublicAccessToken(form) &&
        (publicAccessToken == null || publicAccessToken.isEmpty)) {
      return;
    }

    final answers = form.fields
        .where((field) => _fieldSubmitsAnswer(field.type))
        .where((field) => _answers.containsKey(field.id) || field.isRequired)
        .map(
          (field) =>
              AnswerInputDto(fieldId: field.id, value: _answers[field.id]),
        )
        .toList(growable: false);

    final isAuthenticated =
        ref.read(authControllerProvider).asData?.value != null;

    setState(() => _submitting = true);
    try {
      final response = await ref
          .read(publicFormsRepositoryProvider)
          .submitPublicForm(
            publicToken: widget.publicToken,
            request: PublicSubmissionRequest(
              anonymous: (_respondentMode ?? 'anonymous') == 'anonymous',
              respondentMode: _respondentMode,
              respondentName: _guestNameController.text.trim().isEmpty
                  ? null
                  : _guestNameController.text.trim(),
              publicAccessToken: publicAccessToken,
              answers: answers,
            ),
          );
      if (!mounted) return;
      setState(() {
        _submitted = response;
        _submittedByAuthenticated = isAuthenticated;
        _submitting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(FriendlyApiErrorMessage.from(error, context: context)),
        ),
      );
    }
  }

  Future<void> _validateEntry(PublicFormDto form) async {
    if (_accessFormKey.currentState?.validate() != true) return;
    await _ensurePublicAccess(form);
  }

  FormFieldDto? _firstMissingRequiredField(List<FormFieldDto> fields) {
    for (final field in fields) {
      if (!field.isRequired || !_fieldSubmitsAnswer(field.type)) continue;
      final value = _answers[field.id];
      if (field.type == FieldType.consentCheckbox ||
          field.type == FieldType.termsAcceptance) {
        if (value != true) return field;
        continue;
      }
      if (value == null) return field;
      if (value is String && value.trim().isEmpty) return field;
      if (value is Iterable && value.isEmpty) return field;
    }
    return null;
  }
}

class _LoadedPublicForm extends StatelessWidget {
  const _LoadedPublicForm({
    required this.formKey,
    required this.form,
    required this.publicAccessToken,
    required this.submitting,
    required this.validatingAccess,
    required this.answers,
    required this.onAnswerChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final PublicFormDto form;
  final String? publicAccessToken;
  final bool submitting;
  final bool validatingAccess;
  final Map<String, Object?> answers;
  final void Function(String fieldId, Object? value) onAnswerChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final fields = [...form.fields]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return Form(
      key: formKey,
      child: StepFormView(
        formTitle: form.title,
        fields: fields,
        answers: answers,
        onAnswerChanged: onAnswerChanged,
        onSubmit: onSubmit,
        submitting: submitting,
      ),
    );
  }
}

class _PublicFormEntryGate extends StatelessWidget {
  const _PublicFormEntryGate({
    required this.form,
    required this.formKey,
    required this.selectedMode,
    required this.formPasswordController,
    required this.identityCodeController,
    required this.guestNameController,
    required this.validating,
    required this.identityLabel,
    required this.onModeChanged,
    required this.onContinue,
  });

  final PublicFormDto form;
  final GlobalKey<FormState> formKey;
  final String selectedMode;
  final TextEditingController formPasswordController;
  final TextEditingController identityCodeController;
  final TextEditingController guestNameController;
  final bool validating;
  final String? identityLabel;
  final ValueChanged<String> onModeChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modes = form.accessPolicy.respondentModes;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      form.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    AppSpacing.gapMd,
                    if (modes.length > 1) ...[
                      SegmentedButton<String>(
                        segments: [
                          if (modes.contains('anonymous'))
                            ButtonSegment(
                              value: 'anonymous',
                              icon: const Icon(Icons.visibility_off_outlined),
                              label: Text(context.l10n.t('anonymous')),
                            ),
                          if (modes.contains('guest'))
                            ButtonSegment(
                              value: 'guest',
                              icon: const Icon(Icons.person_outline_rounded),
                              label: Text(context.l10n.t('guest')),
                            ),
                          if (modes.contains('identity_code'))
                            ButtonSegment(
                              value: 'identity_code',
                              icon: const Icon(Icons.badge_outlined),
                              label: Text(context.l10n.t('identifiedGuest')),
                            ),
                          if (modes.contains('authenticated'))
                            ButtonSegment(
                              value: 'authenticated',
                              icon: const Icon(Icons.login_rounded),
                              label: Text(context.l10n.t('withAccount')),
                            ),
                        ],
                        selected: {selectedMode},
                        showSelectedIcon: false,
                        onSelectionChanged:
                            (values) => onModeChanged(values.first),
                      ),
                      AppSpacing.gapMd,
                    ],
                    if (form.accessPolicy.requiresFormPassword) ...[
                      TextFormField(
                        controller: formPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.t('formPassword'),
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                        ),
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? context.l10n.t('requiredField')
                                    : null,
                      ),
                      AppSpacing.gapMd,
                    ],
                    if (selectedMode == 'guest') ...[
                      TextFormField(
                        controller: guestNameController,
                        decoration: InputDecoration(
                          labelText: context.l10n.t('guestName'),
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? context.l10n.t('requiredField')
                                    : null,
                      ),
                      AppSpacing.gapMd,
                    ],
                    if (selectedMode == 'identity_code') ...[
                      TextFormField(
                        controller: identityCodeController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.t('identityCode'),
                          prefixIcon: const Icon(Icons.key_rounded),
                          helperText: identityLabel,
                        ),
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? context.l10n.t('requiredField')
                                    : null,
                      ),
                      AppSpacing.gapMd,
                    ],
                    FilledButton.icon(
                      onPressed: validating ? null : onContinue,
                      icon:
                          validating
                              ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.arrow_forward_rounded),
                      label: Text(context.l10n.t('continueAction')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Kept for future use when an intro page is added before the step-by-step flow.
// ignore: unused_element
class _PublicFormIntro extends StatelessWidget {
  const _PublicFormIntro({required this.form});

  final PublicFormDto form;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? const Color(0xFF171A2A)
                : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 26,
            offset: const Offset(0, 14),
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.20 : 0.055,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.topStart,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            form.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
          AppSpacing.gapXs,
          Text(
            (form.description ?? '').trim().isEmpty
                ? context.l10n.t('shareResponseBelow')
                : form.description!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          AppSpacing.gapMd,
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              FeedbackInfoChip(
                icon: Icons.list_alt_rounded,
                label: context.l10n.countFields(form.fields.length),
              ),
              FeedbackInfoChip(
                icon: Icons.shield_outlined,
                label: context.l10n.enumLabel(
                  form.publicProtection.level.toJson(),
                ),
              ),
              if (form.settings.allowAnonymousAnswers)
                FeedbackInfoChip(
                  icon: Icons.visibility_off_outlined,
                  label: context.l10n.t('anonymousAllowed'),
                ),
              if (form.settings.guestsCanAnswer)
                FeedbackInfoChip(
                  icon: Icons.person_outline_rounded,
                  label: context.l10n.t('guestAnswers'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _ProtectionCard extends StatelessWidget {
  const _ProtectionCard({required this.validated, required this.validating});

  final bool validated;
  final bool validating;

  @override
  Widget build(BuildContext context) {
    return FeedbackInlinePanel(
      icon: validated ? Icons.verified_rounded : Icons.shield_rounded,
      title:
          validated
              ? context.l10n.t('publicAccessValidated')
              : context.l10n.t('protectedPublicForm'),
      message:
          validated
              ? context.l10n.t('canSubmitNow')
              : context.l10n.t('publicAccessAutoCheck'),
      trailing:
          validating
              ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Icon(
                validated
                    ? Icons.check_circle_rounded
                    : Icons.lock_outline_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
    );
  }
}

class _SubmittedView extends StatelessWidget {
  const _SubmittedView({required this.response, required this.authenticated});

  final PublicSubmissionResponse response;
  final bool authenticated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final message =
        authenticated
            ? response.message
            : context.l10n.t('guestSubmissionSuccessAuthRequired');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 64,
                    color: scheme.primary,
                  ),
                  AppSpacing.gapMd,
                  Text(
                    context.l10n.t('responseSubmitted'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  AppSpacing.gapXs,
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (authenticated) {
                          context.go('/forms');
                        } else {
                          context.go(
                            '/login?redirect=${Uri.encodeComponent('/forms')}&notice=guestSubmissionSuccessAuthRequired',
                          );
                        }
                      },
                      icon: Icon(
                        authenticated
                            ? Icons.home_rounded
                            : Icons.login_rounded,
                      ),
                      label: Text(
                        authenticated
                            ? context.l10n.t('goToHome')
                            : context.l10n.t('signInToContinue'),
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
}

class _PublicAuthRequiredView extends StatelessWidget {
  const _PublicAuthRequiredView({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_person_rounded,
                    size: 56,
                    color: scheme.primary,
                  ),
                  AppSpacing.gapMd,
                  Text(
                    context.l10n.t('authRequiredForPublicForm'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  AppSpacing.gapXs,
                  Text(
                    context.l10n.t('authRequiredForPublicFormMessage'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onSignIn,
                      icon: const Icon(Icons.login_rounded),
                      label: Text(context.l10n.t('signIn')),
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
}

String _defaultRespondentMode(
  PublicFormDto form,
  bool isAuthenticated,
  String? requestedMode,
) {
  final modes = form.accessPolicy.respondentModes;
  final normalizedRequestedMode = requestedMode?.trim();

  // A public form can be answered anonymously/guest while the user keeps the
  // current app session. This is intentionally form-local and must not replace
  // the global AuthController tokens.
  if (normalizedRequestedMode != null &&
      normalizedRequestedMode.isNotEmpty &&
      modes.contains(normalizedRequestedMode)) {
    if (normalizedRequestedMode == 'authenticated' && !isAuthenticated) {
      return 'authenticated';
    }
    return normalizedRequestedMode;
  }

  if (isAuthenticated && modes.contains('authenticated')) {
    return 'authenticated';
  }
  if (modes.contains('anonymous')) return 'anonymous';
  if (modes.contains('guest')) return 'guest';
  if (modes.contains('identity_code')) return 'identity_code';
  return 'authenticated';
}

bool _needsEntryStep(PublicFormDto form) {
  return form.accessPolicy.requiresFormPassword ||
      form.accessPolicy.identityCodesEnabled ||
      form.accessPolicy.publicAccessValidationRequired ||
      form.accessPolicy.respondentModes.length > 1;
}

String _loginLocationForPublicForm(String publicToken) {
  final redirect = Uri.encodeComponent('/public/$publicToken');
  return '/login?redirect=$redirect&notice=authRequiredForPublicFormMessage';
}

bool _needsPublicAccessToken(PublicFormDto form) {
  return form.publicProtection.level != PublicProtectionLevel.none ||
      form.publicProtection.captchaEnabled ||
      form.publicProtection.emailVerificationEnabled ||
      form.publicProtection.phoneVerificationEnabled;
}

bool _fieldSubmitsAnswer(FieldType type) {
  return switch (type) {
    FieldType.sectionTitle ||
    FieldType.descriptionBlock ||
    FieldType.divider ||
    FieldType.pageBreak ||
    FieldType.scoreDisplay ||
    FieldType.hidden ||
    FieldType.calculated ||
    FieldType.conditionalLogic ||
    FieldType.unknown => false,
    _ => true,
  };
}
