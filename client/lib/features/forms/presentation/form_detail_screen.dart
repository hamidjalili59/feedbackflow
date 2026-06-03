import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../data/dto/dto.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/common/field_type_ui.dart';
import '../../../presentation/common/friendly_api_error_message.dart';
import '../../../presentation/models/form_builder_models.dart';
import '../../../presentation/widgets/app_chrome.dart';
import '../../../presentation/widgets/error_panel.dart';
import '../../../presentation/widgets/feedback_field_kit.dart';
import '../../../presentation/widgets/field_renderer.dart';
import '../../../presentation/widgets/step_form_view.dart';
import '../../../presentation/theme/app_spacing.dart';

class FormDetailScreen extends ConsumerWidget {
  const FormDetailScreen({
    super.key,
    required this.formId,
    this.initialSection = FormWorkspaceSection.builder,
    this.reviewSubmissionId,
  });

  final String formId;
  final FormWorkspaceSection initialSection;
  final String? reviewSubmissionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(formDetailProvider(formId));
    final authAsync = ref.watch(authControllerProvider);
    return GradientScaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsetsDirectional.only(start: 8),
          child: AppBackButton(fallbackLocation: '/forms'),
        ),
        title: Text(context.l10n.t('formWorkspace')),
        actions: const [
          LanguageButton(),
          ThemeModeButton(),
          SizedBox(width: 12),
        ],
      ),
      body: detailAsync.when(
        loading: () =>
            LoadingPanel(message: context.l10n.t('loadingFormWorkspace')),
        error: (error, stackTrace) => ErrorPanel(
          error: error,
          onRetry: () => ref.invalidate(formDetailProvider(formId)),
          onBack: () => _returnToPreviousOrForms(context),
          onSignIn: () => context.go('/login'),
        ),
        data: (form) {
          final session = authAsync.asData?.value;
          final isCreator =
              session != null && form.creatorId == session.user.id;
          final isManager =
              session != null &&
              (session.user.primaryRole == UserRole.superAdmin ||
                  session.user.primaryRole == UserRole.ceo ||
                  session.user.primaryRole == UserRole.admin ||
                  session.user.primaryRole == UserRole.manager);
          final reviewSubmissionId = submissionIdForInitialReview(
            querySubmissionId: this.reviewSubmissionId,
            formSubmissionId: form.mySubmissionId,
            canReviewAnySubmission: isCreator || isManager,
          );
          if (reviewSubmissionId != null && reviewSubmissionId.isNotEmpty) {
            return _SubmissionReviewView(
              form: form,
              submissionId: reviewSubmissionId,
            );
          }

          // Creator always sees workspace from the forms list.
          if (isCreator) {
            return _FormWorkspaceView(form: form, section: initialSection);
          }

          // Admin/CEO/SuperAdmin/Manager: only see workspace if they
          // explicitly navigated to a workspace section (e.g. /forms/:id/builder).
          // From the plain /forms/:id route (initialSection == builder by default),
          // they see the respondent answer flow for published forms.
          if (isManager && initialSection != FormWorkspaceSection.builder) {
            // Explicitly navigated to settings/publish/results/etc.
            return _FormWorkspaceView(form: form, section: initialSection);
          }

          if (isManager && form.status == FormStatus.published) {
            // From forms list → answer the form like a respondent.
            return _RespondentFormView(form: form);
          }

          if (isManager) {
            // Non-published form → show workspace to manage it.
            return _FormWorkspaceView(form: form, section: initialSection);
          }

          // Regular users (teacher/parent/student) → answer flow.
          return _RespondentFormView(form: form);
        },
      ),
    );
  }
}

String? submissionIdForInitialReview({
  String? querySubmissionId,
  String? formSubmissionId,
  bool canReviewAnySubmission = false,
}) {
  final fromQuery = querySubmissionId?.trim();
  final fromForm = formSubmissionId?.trim();
  if (fromQuery != null &&
      fromQuery.isNotEmpty &&
      (canReviewAnySubmission || fromQuery == fromForm)) {
    return fromQuery;
  }
  if (fromForm != null && fromForm.isNotEmpty) return fromForm;
  return null;
}

enum FormWorkspaceSection {
  builder,
  preview,
  settings,
  assignments,
  publish,
  share,
  results,
}

extension FormWorkspaceSectionX on FormWorkspaceSection {
  String get wire => switch (this) {
    FormWorkspaceSection.builder => 'builder',
    FormWorkspaceSection.preview => 'preview',
    FormWorkspaceSection.settings => 'settings',
    FormWorkspaceSection.assignments => 'assignments',
    FormWorkspaceSection.publish => 'publish',
    FormWorkspaceSection.share => 'share',
    FormWorkspaceSection.results => 'results',
  };

  String get labelKey => switch (this) {
    FormWorkspaceSection.builder => 'builder',
    FormWorkspaceSection.preview => 'preview',
    FormWorkspaceSection.settings => 'settings',
    FormWorkspaceSection.assignments => 'assignments',
    FormWorkspaceSection.publish => 'publish',
    FormWorkspaceSection.share => 'share',
    FormWorkspaceSection.results => 'results',
  };

  String label(BuildContext context) => this == FormWorkspaceSection.assignments
      ? context.l10n.t('form.assignments')
      : context.l10n.t(labelKey);

  IconData get icon => switch (this) {
    FormWorkspaceSection.builder => Icons.construction_rounded,
    FormWorkspaceSection.preview => Icons.visibility_rounded,
    FormWorkspaceSection.settings => Icons.tune_rounded,
    FormWorkspaceSection.assignments => Icons.group_add_rounded,
    FormWorkspaceSection.publish => Icons.rocket_launch_rounded,
    FormWorkspaceSection.share => Icons.ios_share_rounded,
    FormWorkspaceSection.results => Icons.analytics_rounded,
  };
}

FormWorkspaceSection formWorkspaceSectionFromWire(String? value) {
  return FormWorkspaceSection.values.firstWhere(
    (section) => section.wire == value,
    orElse: () => FormWorkspaceSection.builder,
  );
}

/// View shown to regular respondents (non-managers). If the form is published,
/// they see the step-by-step answer flow. Otherwise they see a "not available" message.
class _RespondentFormView extends ConsumerStatefulWidget {
  const _RespondentFormView({
    super.key,
    required this.form,
    this.editSubmission,
  });

  final FormDetailDto form;
  final SubmissionDetailDto? editSubmission;

  @override
  ConsumerState<_RespondentFormView> createState() =>
      _RespondentFormViewState();
}

class _RespondentFormViewState extends ConsumerState<_RespondentFormView> {
  final Map<String, Object?> _answers = {};
  bool _submitting = false;
  bool _submitted = false;
  SubmissionDetailDto? _submittedSubmission;

  @override
  void initState() {
    super.initState();
    final editSubmission = widget.editSubmission;
    if (editSubmission != null) {
      for (final answer in editSubmission.answers) {
        _answers[answer.fieldId] = answer.value;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (form.status != FormStatus.published) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 56, color: scheme.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.t('formUnavailable'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.t('formUnavailableMessage'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => _returnToPreviousOrForms(context),
                icon: Icon(appBackIcon(context)),
                label: Text(context.l10n.t('back')),
              ),
            ],
          ),
        ),
      );
    }

    final submittedSubmission = _submittedSubmission;
    if (_submitted && submittedSubmission != null) {
      return _SubmittedResponseView(
        form: form,
        submission: submittedSubmission,
        onEdit: form.settings.answersEditableAfterSubmission
            ? () {
                setState(() {
                  _submitted = false;
                  _submittedSubmission = null;
                });
              }
            : null,
      );
    }

    final editSubmission = widget.editSubmission;
    if (editSubmission != null) {
      final fields = [...form.fields]
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      return StepFormView(
        formTitle: form.title,
        fields: fields,
        answers: _answers,
        onAnswerChanged: (fieldId, value) =>
            setState(() => _answers[fieldId] = value),
        onSubmit: _submit,
        submitting: _submitting,
      );
    }

    final accessAsync = ref.watch(formAnswerAccessProvider(form.id));
    return accessAsync.when(
      loading: () =>
          LoadingPanel(message: context.l10n.t('form.checkingAnswerAccess')),
      error: (error, stackTrace) => ErrorPanel(
        error: error,
        onRetry: () => ref.invalidate(formAnswerAccessProvider(form.id)),
        onBack: () => _returnToPreviousOrForms(context),
      ),
      data: (access) {
        final submissionId = access.mySubmissionId?.trim();
        if (submissionId != null && submissionId.isNotEmpty) {
          return _SubmissionReviewView(form: form, submissionId: submissionId);
        }
        if (!access.allowed) {
          return _AnswerAccessBlockedView(form: form, access: access);
        }
        final fields = [...form.fields]
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

        return StepFormView(
          formTitle: form.title,
          fields: fields,
          answers: _answers,
          onAnswerChanged: (fieldId, value) =>
              setState(() => _answers[fieldId] = value),
          onSubmit: _submit,
          submitting: _submitting,
        );
      },
    );
  }

  Future<void> _submit() async {
    final missing = _firstMissingRequiredField(widget.form.fields);
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
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final answers = _answers.entries
          .where((e) => e.value != null)
          .map((e) => AnswerInputDto(fieldId: e.key, value: e.value))
          .toList();
      final editSubmission = widget.editSubmission;
      late final SubmissionDetailDto savedSubmission;
      if (editSubmission == null) {
        savedSubmission = await ref
            .read(submissionsRepositoryProvider)
            .createSubmission(
              id: widget.form.id,
              request: CreateSubmissionRequest(
                answers: answers,
                anonymous: false,
              ),
            );
      } else {
        savedSubmission = await ref
            .read(submissionsRepositoryProvider)
            .updateSubmission(
              id: editSubmission.id,
              request: UpdateSubmissionRequest(answers: answers),
            );
        ref.invalidate(submissionDetailProvider(editSubmission.id));
      }
      ref.invalidate(formAnswerAccessProvider(widget.form.id));
      ref.invalidate(formsControllerProvider);
      if (mounted) {
        setState(() {
          _submittedSubmission = savedSubmission;
          _submitted = true;
        });
      }
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              FriendlyApiErrorMessage.from(error, context: context),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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

class _SubmittedResponseView extends StatelessWidget {
  const _SubmittedResponseView({
    required this.form,
    required this.submission,
    this.onEdit,
  });

  final FormDetailDto form;
  final SubmissionDetailDto submission;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeader(
                  icon: Icons.check_circle_rounded,
                  title: context.l10n.t('submittedReviewTitle'),
                  message: context.l10n.t('submittedReviewMessage'),
                  trailing: onEdit == null
                      ? null
                      : FilledButton.tonalIcon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_rounded),
                          label: Text(context.l10n.t('editResponse')),
                        ),
                ),
                AppSpacing.gapLg,
                _SubmissionDetailContent(form: form, submission: submission),
                AppSpacing.gapLg,
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    onPressed: () => _returnToPreviousOrForms(context),
                    icon: const Icon(Icons.list_rounded),
                    label: Text(context.l10n.t('forms')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerAccessBlockedView extends StatelessWidget {
  const _AnswerAccessBlockedView({required this.form, required this.access});

  final FormDetailDto form;
  final FormAnswerAccessDto2 access;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final publicToken = form.publicToken;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SoftCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_person_rounded, size: 62, color: scheme.error),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.t('form.noAnswerAccessTitle'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  access.reason ?? context.l10n.t('form.noAnswerAccessMessage'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _returnToPreviousOrForms(context),
                      icon: const Icon(Icons.list_rounded),
                      label: Text(context.l10n.t('forms')),
                    ),
                    if (publicToken != null && publicToken.isNotEmpty)
                      FilledButton.icon(
                        onPressed: () => context.go('/public/$publicToken'),
                        icon: const Icon(Icons.public_rounded),
                        label: Text(context.l10n.t('form.openPublicLink')),
                      ),
                    if (access.canEditWorkspace)
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            context.go('/forms/${form.id}/settings'),
                        icon: const Icon(Icons.tune_rounded),
                        label: Text(context.l10n.t('form.manageForm')),
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

class _SubmissionReviewView extends ConsumerStatefulWidget {
  const _SubmissionReviewView({required this.form, required this.submissionId});

  final FormDetailDto form;
  final String submissionId;

  @override
  ConsumerState<_SubmissionReviewView> createState() =>
      _SubmissionReviewViewState();
}

class _SubmissionReviewViewState extends ConsumerState<_SubmissionReviewView> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(submissionDetailProvider(widget.submissionId));
    return detail.when(
      loading: () =>
          LoadingPanel(message: context.l10n.t('loadingSubmissionDetail')),
      error: (error, stackTrace) => ErrorPanel(
        error: error,
        onRetry: () =>
            ref.invalidate(submissionDetailProvider(widget.submissionId)),
        onBack: () => _returnToPreviousOrForms(context),
        onSignIn: () => context.go('/login'),
      ),
      data: (submission) {
        if (_editing) {
          return _RespondentFormView(
            key: ValueKey('edit-${submission.id}-${submission.updatedAt}'),
            form: widget.form,
            editSubmission: submission,
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionHeader(
                      icon: Icons.fact_check_rounded,
                      title: context.l10n.t('submittedReviewTitle'),
                      message: context.l10n.t('submittedReviewMessage'),
                      trailing:
                          widget.form.settings.answersEditableAfterSubmission
                          ? FilledButton.tonalIcon(
                              onPressed: () => setState(() => _editing = true),
                              icon: const Icon(Icons.edit_rounded),
                              label: Text(context.l10n.t('editResponse')),
                            )
                          : null,
                    ),
                    AppSpacing.gapLg,
                    _SubmissionDetailContent(
                      form: widget.form,
                      submission: submission,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FormWorkspaceView extends StatelessWidget {
  const _FormWorkspaceView({required this.form, required this.section});

  final FormDetailDto form;
  final FormWorkspaceSection section;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageHeaderCard(
                      icon: Icons.dynamic_form_rounded,
                      title: form.title,
                      subtitle: _headerSubtitle(form, context),
                      trailing: _StatusBadge(status: form.status),
                      badges: [
                        _MetaChip(
                          label: context.l10n.enumLabel(form.status.toJson()),
                          icon: Icons.flag_outlined,
                        ),
                        _MetaChip(
                          label: context.l10n.enumLabel(
                            form.visibilityMode.toJson(),
                          ),
                          icon: Icons.visibility_outlined,
                        ),
                        _MetaChip(
                          label: context.l10n.enumLabel(
                            form.publishMode.toJson(),
                          ),
                          icon: Icons.publish_outlined,
                        ),
                        _MetaChip(
                          label: context.l10n.enumLabel(
                            form.scoringMode.toJson(),
                          ),
                          icon: Icons.speed_outlined,
                        ),
                        if ((form.category ?? '').trim().isNotEmpty)
                          _MetaChip(
                            label: form.category!,
                            icon: Icons.folder_outlined,
                          ),
                        for (final tag in form.tags ?? const <String>[])
                          _MetaChip(label: tag, icon: Icons.sell_outlined),
                        _MetaChip(
                          label: context.l10n.countFields(form.fields.length),
                          icon: Icons.list_alt_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _WorkspaceNav(formId: form.id, selected: section),
                    const SizedBox(height: 16),
                    _SectionBody(form: form, section: section),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _headerSubtitle(FormDetailDto form, BuildContext context) {
    final l10n = context.l10n;
    final status = form.status;
    if (status == FormStatus.pendingReview) {
      return '⏳ ${l10n.t('waitingForApproval')}';
    }
    if (status == FormStatus.rejected) {
      return '❌ ${l10n.t('formRejected')}';
    }
    final description = (form.description ?? '').trim();
    if (description.isNotEmpty) return description;
    return l10n.t('workspaceHeaderFallback');
  }
}

class _WorkspaceNav extends StatelessWidget {
  const _WorkspaceNav({required this.formId, required this.selected});

  final String formId;
  final FormWorkspaceSection selected;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final section in FormWorkspaceSection.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  selected: selected == section,
                  avatar: Icon(section.icon, size: 18),
                  label: Text(section.label(context)),
                  onSelected: (_) =>
                      context.go('/forms/$formId/${section.wire}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.form, required this.section});

  final FormDetailDto form;
  final FormWorkspaceSection section;

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      FormWorkspaceSection.builder => _BuilderSection(form: form),
      FormWorkspaceSection.preview => _PreviewSection(form: form),
      FormWorkspaceSection.settings => _SettingsSection(form: form),
      FormWorkspaceSection.assignments => _AssignmentsSection(form: form),
      FormWorkspaceSection.publish => _PublishSection(form: form),
      FormWorkspaceSection.share => _ShareSection(form: form),
      FormWorkspaceSection.results => _ResultsSection(form: form),
    };
  }
}

class _BuilderSection extends ConsumerWidget {
  const _BuilderSection({required this.form});

  final FormDetailDto form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            icon: Icons.construction_rounded,
            title: context.l10n.t('builder'),
            message: context.l10n.t('builderMessage'),
            trailing: FilledButton.icon(
              onPressed: () => _pickAndAddField(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.t('addField')),
            ),
          ),
          AppSpacing.gapLg,
          if (form.fields.isEmpty)
            _EmptyActionPanel(
              icon: Icons.add_box_outlined,
              title: context.l10n.t('noFieldsYet'),
              message: context.l10n.t('addFirstQuestion'),
              actionLabel: context.l10n.t('addField'),
              onAction: () => _pickAndAddField(context, ref),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: form.fields.length,
              onReorder: (oldIndex, newIndex) =>
                  _reorderField(context, ref, oldIndex, newIndex),
              itemBuilder: (context, index) {
                final field = form.fields[index];
                return _EditableFieldTile(
                  key: ValueKey(field.id),
                  formId: form.id,
                  index: index,
                  field: field,
                  formScoringEnabled: form.scoringMode != ScoringMode.none,
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _pickAndAddField(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<FieldType>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _FieldPickerSheet(),
    );
    if (selected == null) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final draft = DraftFormField.forType(selected);
      await ref
          .read(fieldsRepositoryProvider)
          .createFormField(
            id: form.id,
            request: draft.toCreateRequest(orderIndex: form.fields.length),
          );
      ref.invalidate(formDetailProvider(form.id));
      ref.invalidate(formsControllerProvider);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.t('fieldAdded'))),
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

  Future<void> _reorderField(
    BuildContext context,
    WidgetRef ref,
    int oldIndex,
    int newIndex,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final fields = [...form.fields]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (oldIndex < 0 ||
        oldIndex >= fields.length ||
        target < 0 ||
        target >= fields.length) {
      return;
    }
    final moved = fields.removeAt(oldIndex);
    fields.insert(target, moved);
    try {
      for (var index = 0; index < fields.length; index++) {
        if (fields[index].orderIndex != index) {
          await ref
              .read(fieldsRepositoryProvider)
              .updateFormField(
                id: form.id,
                fieldId: fields[index].id,
                request: UpdateFormFieldRequest(orderIndex: index),
              );
        }
      }
      ref.invalidate(formDetailProvider(form.id));
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.t('fieldOrderSaved'))),
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

class _EditableFieldTile extends ConsumerWidget {
  const _EditableFieldTile({
    required super.key,
    required this.formId,
    required this.index,
    required this.field,
    required this.formScoringEnabled,
  });

  final String formId;
  final int index;
  final FormFieldDto field;
  final bool formScoringEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // todo: why doesn't use this?
    // final info = fieldTypeInfo(field.type);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.32),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: Text('${index + 1}'),
          ),
          title: Text(
            field.label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '${context.l10n.fieldType(field.type.toJson())}${field.isRequired ? ' • ${context.l10n.t('required')}' : ''}',
          ),
          trailing: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: context.l10n.t('editField'),
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => _editField(context, ref),
                ),
                IconButton(
                  tooltip: context.l10n.t('deleteField'),
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _deleteField(context, ref),
                ),
                const SizedBox(width: 24),
                // ReorderableDragStartListener(
                //   index: index,
                //   child: const Padding(
                //     padding: EdgeInsets.all(12),
                //     child: Icon(Icons.drag_handle_rounded),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editField(BuildContext context, WidgetRef ref) async {
    final request = await showDialog<UpdateFormFieldRequest>(
      context: context,
      builder: (context) => _FieldEditDialog(
        field: field,
        formScoringEnabled: formScoringEnabled,
      ),
    );
    if (request == null) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(fieldsRepositoryProvider)
          .updateFormField(id: formId, fieldId: field.id, request: request);
      ref.invalidate(formDetailProvider(formId));
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.t('fieldUpdated'))),
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

  Future<void> _deleteField(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('deleteField')),
        content: Text(
          '${context.l10n.t('deleteFieldQuestion')} ${field.label}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.t('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(fieldsRepositoryProvider)
          .deleteFormField(id: formId, fieldId: field.id);
      ref.invalidate(formDetailProvider(formId));
      ref.invalidate(formsControllerProvider);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.t('fieldDeleted'))),
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

class _FieldEditDialog extends StatefulWidget {
  const _FieldEditDialog({
    required this.field,
    required this.formScoringEnabled,
  });

  final FormFieldDto field;
  final bool formScoringEnabled;

  @override
  State<_FieldEditDialog> createState() => _FieldEditDialogState();
}

class _FieldEditDialogState extends State<_FieldEditDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _placeholderController;
  late final TextEditingController _optionsController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late final TextEditingController _stepController;
  late final TextEditingController _maxScoreController;
  late final TextEditingController _weightController;
  late bool _required;
  late bool _scoringEnabled;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.field.label);
    _descriptionController = TextEditingController(
      text: widget.field.description ?? '',
    );
    _placeholderController = TextEditingController(
      text: widget.field.placeholder ?? '',
    );
    _optionsController = TextEditingController(
      text: (widget.field.config.options ?? const <FieldOptionDto>[])
          .map((option) => option.label)
          .join('\n'),
    );
    _minController = TextEditingController(
      text: widget.field.config.min?.toString() ?? '',
    );
    _maxController = TextEditingController(
      text: widget.field.config.max?.toString() ?? '',
    );
    _stepController = TextEditingController(
      text: widget.field.config.step?.toString() ?? '',
    );
    _maxScoreController = TextEditingController(
      text: widget.field.scoringConfig.maxScore?.toString() ?? '1',
    );
    _weightController = TextEditingController(
      text: widget.field.scoringConfig.weight?.toString() ?? '1',
    );
    _required = widget.field.isRequired;
    _scoringEnabled = widget.field.scoringConfig.enabled == true;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _descriptionController.dispose();
    _placeholderController.dispose();
    _optionsController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _stepController.dispose();
    _maxScoreController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.t('editField')),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _labelController,
                decoration: InputDecoration(labelText: context.l10n.t('label')),
              ),
              AppSpacing.gapSm,
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: context.l10n.t('description'),
                ),
                maxLines: 2,
              ),
              AppSpacing.gapSm,
              TextField(
                controller: _placeholderController,
                decoration: InputDecoration(
                  labelText: context.l10n.t('placeholder'),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _required,
                onChanged: (value) => setState(() => _required = value),
                title: Text(context.l10n.t('required')),
              ),
              if (_fieldTypeUsesOptions(widget.field.type)) ...[
                AppSpacing.gapSm,
                TextField(
                  controller: _optionsController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: context.l10n.t('options'),
                    helperText: context.l10n.t('optionsHelper'),
                  ),
                ),
              ],
              if (_fieldTypeUsesRange(widget.field.type)) ...[
                AppSpacing.gapSm,
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: context.l10n.t('min'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _maxController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: context.l10n.t('max'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _stepController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: context.l10n.t('step'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (widget.formScoringEnabled &&
                  fieldTypeCanScore(widget.field.type)) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _scoringEnabled,
                  onChanged: (value) => setState(() => _scoringEnabled = value),
                  title: Text(context.l10n.t('enableFieldScoring')),
                ),
                if (_scoringEnabled)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _maxScoreController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: context.l10n.t('maxScore'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: context.l10n.t('weight'),
                          ),
                        ),
                      ),
                    ],
                  ),
              ] else if (fieldTypeCanScore(widget.field.type)) ...[
                const SizedBox(height: 8),
                _InlineNotice(
                  icon: Icons.info_outline_rounded,
                  title: context.l10n.t('scoringMode'),
                  message: context.l10n.t('enableFormScoringFirst'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: () {
            final label = _labelController.text.trim();
            if (label.isEmpty) return;
            Navigator.pop(
              context,
              UpdateFormFieldRequest(
                label: label,
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                placeholder: _placeholderController.text.trim().isEmpty
                    ? null
                    : _placeholderController.text.trim(),
                isRequired: _required,
                config: _buildConfig(),
                scoringConfig: _scoringEnabled && widget.formScoringEnabled
                    ? FieldScoringConfigDto(
                        enabled: true,
                        maxScore:
                            double.tryParse(_maxScoreController.text.trim()) ??
                            1,
                        weight:
                            double.tryParse(_weightController.text.trim()) ?? 1,
                        optionScores: widget.field.scoringConfig.optionScores,
                      )
                    : null,
              ),
            );
          },
          child: Text(context.l10n.t('save')),
        ),
      ],
    );
  }

  FieldConfigDto _buildConfig() {
    var config = widget.field.config;
    if (_fieldTypeUsesOptions(widget.field.type)) {
      config = config.copyWith(
        options: _optionDtosFromText(_optionsController.text),
      );
    }
    if (_fieldTypeUsesRange(widget.field.type)) {
      config = config.copyWith(
        min: _nullableDouble(_minController.text),
        max: _nullableDouble(_maxController.text),
        step: _nullableDouble(_stepController.text),
      );
    }
    return config;
  }
}

bool _fieldTypeUsesOptions(FieldType type) => switch (type) {
  FieldType.singleChoice ||
  FieldType.multipleChoice ||
  FieldType.dropdown ||
  FieldType.ranking ||
  FieldType.quizQuestion => true,
  _ => false,
};

bool _fieldTypeUsesRange(FieldType type) => switch (type) {
  FieldType.slider ||
  FieldType.nps ||
  FieldType.ratingStars ||
  FieldType.numericRating => true,
  _ => false,
};

List<FieldOptionDto> _optionDtosFromText(String text) {
  final labels = text
      .split('\n')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  return [
    for (var index = 0; index < labels.length; index++)
      FieldOptionDto(
        id: _fieldOptionId(labels[index], index),
        label: labels[index],
        value: _fieldOptionId(labels[index], index),
        orderIndex: index,
      ),
  ];
}

String _fieldOptionId(String label, int index) {
  final normalized = label
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? 'option-${index + 1}' : normalized;
}

double? _nullableDouble(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed);
}

class _PreviewSection extends StatefulWidget {
  const _PreviewSection({required this.form});

  final FormDetailDto form;

  @override
  State<_PreviewSection> createState() => _PreviewSectionState();
}

class _PreviewSectionState extends State<_PreviewSection> {
  final Map<String, Object?> _values = <String, Object?>{};

  @override
  Widget build(BuildContext context) {
    final fields = [...widget.form.fields]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            icon: Icons.visibility_rounded,
            title: context.l10n.t('respondentPreview'),
            message: context.l10n.t('respondentPreviewSubtitle'),
          ),
          AppSpacing.gapLg,
          if (fields.isEmpty)
            _EmptyStateMessage(
              icon: Icons.view_agenda_outlined,
              title: context.l10n.t('nothingToPreviewYet'),
              message: context.l10n.t('addFieldsToPreview'),
            )
          else
            FeedbackSheetFrame(
              children: [
                for (var index = 0; index < fields.length; index++) ...[
                  FieldRenderer(
                    index: index,
                    field: fields[index],
                    values: _values,
                    onChanged: (value) =>
                        setState(() => _values[fields[index].id] = value),
                  ),
                  if (index != fields.length - 1) AppSpacing.gapMd,
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatefulWidget {
  const _SettingsSection({required this.form});

  final FormDetailDto form;

  @override
  State<_SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<_SettingsSection> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _tagsController;
  late VisibilityMode _visibilityMode;
  late ScoringMode _scoringMode;
  late bool _allowAnonymous;
  late bool _guestCanAnswer;
  late bool _oneSubmissionPerUser;
  late bool _editableAfterSubmission;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final form = widget.form;
    _titleController = TextEditingController(text: form.title);
    _descriptionController = TextEditingController(
      text: form.description ?? '',
    );
    _categoryController = TextEditingController(text: form.category ?? '');
    _tagsController = TextEditingController(
      text: (form.tags ?? const <String>[]).join(', '),
    );
    _visibilityMode = form.visibility.mode;
    _scoringMode = form.scoringMode;
    _allowAnonymous = form.settings.allowAnonymousAnswers;
    _guestCanAnswer = form.settings.guestsCanAnswer;
    _oneSubmissionPerUser = form.settings.oneSubmissionPerUser;
    _editableAfterSubmission = form.settings.answersEditableAfterSubmission;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHeader(
                icon: Icons.tune_rounded,
                title: context.l10n.t('settings'),
                message: context.l10n.t('settingsMessage'),
                trailing: FilledButton.icon(
                  onPressed: _saving ? null : () => _save(ref),
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _saving
                        ? context.l10n.t('saving')
                        : context.l10n.t('saveSettings'),
                  ),
                ),
              ),
              AppSpacing.gapLg,
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: context.l10n.t('title'),
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
              ),
              AppSpacing.gapSm,
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.l10n.t('description'),
                  prefixIcon: const Icon(Icons.description_rounded),
                ),
              ),
              AppSpacing.gapSm,
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: context.l10n.t('category'),
                  prefixIcon: const Icon(Icons.folder_outlined),
                ),
              ),
              AppSpacing.gapSm,
              TextField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: context.l10n.t('tags'),
                  helperText: context.l10n.t('tagsCommaHelper'),
                  prefixIcon: const Icon(Icons.sell_outlined),
                ),
              ),
              const SizedBox(height: 16),
              _EnumDropdown<ScoringMode>(
                label: context.l10n.t('scoringMode'),
                value: _scoringMode,
                values: const [
                  ScoringMode.none,
                  ScoringMode.quiz,
                  ScoringMode.satisfaction,
                  ScoringMode.riskAssessment,
                  ScoringMode.weighted,
                  ScoringMode.custom,
                ],
                labelFor: (value) => context.l10n.enumLabel(value.toJson()),
                onChanged: (value) => setState(() => _scoringMode = value),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _allowAnonymous,
                onChanged: (value) => setState(() => _allowAnonymous = value),
                title: Text(context.l10n.t('allowAnonymousAnswers')),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _guestCanAnswer,
                onChanged: (value) => setState(() => _guestCanAnswer = value),
                title: Text(context.l10n.t('guestsCanAnswer')),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _oneSubmissionPerUser,
                onChanged: (value) =>
                    setState(() => _oneSubmissionPerUser = value),
                title: Text(context.l10n.t('oneSubmissionPerUser')),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _editableAfterSubmission,
                onChanged: (value) =>
                    setState(() => _editableAfterSubmission = value),
                title: Text(context.l10n.t('answersEditableAfterSubmission')),
              ),
              AppSpacing.gapMd,
              _AccessCodesPanel(formId: widget.form.id),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save(WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      await ref
          .read(formsRepositoryProvider)
          .updateForm(
            id: widget.form.id,
            request: UpdateFormRequest(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              category: _categoryController.text.trim().isEmpty
                  ? null
                  : _categoryController.text.trim(),
              tags: _tagsController.text
                  .split(',')
                  .map(
                    (tag) => tag
                        .trim()
                        .replaceFirst(RegExp(r'^#+'), '')
                        .toLowerCase(),
                  )
                  .where((tag) => tag.isNotEmpty)
                  .toSet()
                  .toList(growable: false),
              settings: _settings(),
              visibility: _visibility(),
              scoringMode: _scoringMode,
              scoringConfig:
                  widget.form.scoringConfig ?? const <String, Object?>{},
            ),
          );
      ref.invalidate(formDetailProvider(widget.form.id));
      ref.invalidate(formsControllerProvider);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.t('settingsSaved'))),
        );
      }
    } catch (error) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(FriendlyApiErrorMessage.from(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  FormSettingsDto _settings() {
    return FormSettingsDto(
      allowAnonymousAnswers: _allowAnonymous,
      oneSubmissionPerUser: _oneSubmissionPerUser,
      answersEditableAfterSubmission: _editableAfterSubmission,
      startAt: widget.form.settings.startAt,
      endAt: widget.form.settings.endAt,
      maxSubmissions: widget.form.settings.maxSubmissions,
      submissionCooldownSeconds: widget.form.settings.submissionCooldownSeconds,
      submissionMode: _allowAnonymous
          ? SubmissionMode.anonymousSubmission
          : _editableAfterSubmission
          ? SubmissionMode.editableSubmission
          : _oneSubmissionPerUser
          ? SubmissionMode.singleSubmission
          : SubmissionMode.multipleSubmissions,
      answerVisibility: _allowAnonymous
          ? AnswerVisibility.anonymous
          : widget.form.settings.answerVisibility,
      guestsCanAnswer: _guestCanAnswer,
      metadata: widget.form.settings.metadata ?? const <String, Object?>{},
    );
  }

  FormVisibilityDto _visibility() {
    final current = widget.form.visibility;
    return FormVisibilityDto(
      mode: _visibilityMode,
      canSee: current.canSee ?? const <AudienceRuleDto>[],
      canAnswer: current.canAnswer ?? const <AudienceRuleDto>[],
      cannotSee: current.cannotSee ?? const <AudienceRuleDto>[],
      cannotAnswer: current.cannotAnswer ?? const <AudienceRuleDto>[],
      guestCanAnswer: _guestCanAnswer,
      anonymousAllowed: _allowAnonymous,
      metadata: current.metadata ?? const <String, Object?>{},
    );
  }
}

class _AssignmentsSection extends ConsumerStatefulWidget {
  const _AssignmentsSection({required this.form});

  final FormDetailDto form;

  @override
  ConsumerState<_AssignmentsSection> createState() =>
      _AssignmentsSectionState();
}

class _AssignmentsSectionState extends ConsumerState<_AssignmentsSection> {
  final List<_AssignmentDraft> _drafts = [];
  String? _loadedSignature;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(formAssignmentsProvider(widget.form.id));
    final session = ref.watch(authControllerProvider).asData?.value;
    final canManage = _canManageAssignments(session?.user.primaryRole);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            icon: Icons.group_add_rounded,
            title: context.l10n.t('form.assignmentsTitle'),
            message: context.l10n.t('form.assignmentsDescription'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canManage) ...[
                  FilledButton.icon(
                    onPressed: _saving ? null : _addDraft,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(context.l10n.t('add')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(context.l10n.t('save')),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton.filledTonal(
                  tooltip: context.l10n.t('refresh'),
                  onPressed: () =>
                      ref.invalidate(formAssignmentsProvider(widget.form.id)),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          AppSpacing.gapLg,
          _InlineNotice(
            icon: Icons.info_outline_rounded,
            title: context.l10n.t('form.assignmentModelTitle'),
            message: context.l10n.t('form.assignmentModelDescription'),
          ),
          AppSpacing.gapMd,
          assignmentsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => _InlineNotice(
              icon: Icons.error_outline_rounded,
              title: context.l10n.t('form.assignmentLoadError'),
              message: FriendlyApiErrorMessage.from(error, context: context),
            ),
            data: (assignments) {
              _syncDrafts(assignments);
              if (!canManage && assignments.isEmpty) {
                return _EmptyStateMessage(
                  icon: Icons.group_off_rounded,
                  title: context.l10n.t('form.noAssignmentsTitle'),
                  message: context.l10n.t('form.noAssignmentsDescription'),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (canManage)
                    for (var i = 0; i < _drafts.length; i++) ...[
                      _AssignmentEditorCard(
                        key: ValueKey(_drafts[i].id),
                        draft: _drafts[i],
                        onChanged: (draft) =>
                            setState(() => _drafts[i] = draft),
                        onDelete: () => setState(() => _drafts.removeAt(i)),
                      ),
                      if (i != _drafts.length - 1) AppSpacing.gapSm,
                    ]
                  else
                    for (final assignment in assignments) ...[
                      _AssignmentTile(assignment: assignment),
                      if (assignment != assignments.last) AppSpacing.gapSm,
                    ],
                  if (canManage && _drafts.isEmpty)
                    _EmptyStateMessage(
                      icon: Icons.group_off_rounded,
                      title: context.l10n.t('form.noAssignmentsTitle'),
                      message: context.l10n.t('form.noAssignmentsDescription'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _syncDrafts(List<FormAssignmentDto2> assignments) {
    final signature = assignments
        .map(
          (assignment) =>
              '${assignment.id}:${assignment.audienceType}:${assignment.audienceRole?.toJson()}:${assignment.audienceUserId}:${assignment.audienceGroupId}:${assignment.audienceSegmentId}:${assignment.canSee}:${assignment.canAnswer}:${assignment.label}',
        )
        .join('|');
    if (_loadedSignature == signature) return;
    _loadedSignature = signature;
    _drafts
      ..clear()
      ..addAll(assignments.map(_AssignmentDraft.fromDto));
  }

  void _addDraft() {
    setState(() {
      _drafts.add(
        _AssignmentDraft(
          id: 'new-${DateTime.now().microsecondsSinceEpoch}',
          audienceType: 'role',
          audienceRole: UserRole.teacher,
          canSee: true,
          canAnswer: true,
        ),
      );
    });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(analyticsRepositoryProvider)
          .setFormAssignments(
            id: widget.form.id,
            request: SetFormAssignmentsRequest2(
              assignments: _drafts.map((draft) => draft.toInput()).toList(),
            ),
          );
      ref.invalidate(formAssignmentsProvider(widget.form.id));
      if (!mounted) return;
      setState(() {
        _loadedSignature = null;
        _syncDrafts(saved);
      });
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.t('settingsSaved'))),
      );
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              FriendlyApiErrorMessage.from(error, context: context),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

bool _canManageAssignments(UserRole? role) {
  return role == UserRole.manager ||
      role == UserRole.admin ||
      role == UserRole.ceo ||
      role == UserRole.superAdmin;
}

class _AssignmentDraft {
  const _AssignmentDraft({
    required this.id,
    required this.audienceType,
    this.audienceUserId,
    this.audienceRole,
    this.audienceGroupId,
    this.audienceSegmentId,
    this.label,
    required this.canSee,
    required this.canAnswer,
  });

  final String id;
  final String audienceType;
  final String? audienceUserId;
  final UserRole? audienceRole;
  final String? audienceGroupId;
  final String? audienceSegmentId;
  final String? label;
  final bool canSee;
  final bool canAnswer;

  factory _AssignmentDraft.fromDto(FormAssignmentDto2 dto) {
    return _AssignmentDraft(
      id: dto.id,
      audienceType: dto.audienceType,
      audienceUserId: dto.audienceUserId,
      audienceRole: dto.audienceRole,
      audienceGroupId: dto.audienceGroupId,
      audienceSegmentId: dto.audienceSegmentId,
      label: dto.label,
      canSee: dto.canSee,
      canAnswer: dto.canAnswer,
    );
  }

  _AssignmentDraft copyWith({
    String? audienceType,
    String? audienceUserId,
    UserRole? audienceRole,
    String? audienceGroupId,
    String? audienceSegmentId,
    String? label,
    bool? canSee,
    bool? canAnswer,
    bool clearTargetIds = false,
  }) {
    return _AssignmentDraft(
      id: id,
      audienceType: audienceType ?? this.audienceType,
      audienceUserId: clearTargetIds
          ? null
          : audienceUserId ?? this.audienceUserId,
      audienceRole: clearTargetIds ? null : audienceRole ?? this.audienceRole,
      audienceGroupId: clearTargetIds
          ? null
          : audienceGroupId ?? this.audienceGroupId,
      audienceSegmentId: clearTargetIds
          ? null
          : audienceSegmentId ?? this.audienceSegmentId,
      label: label ?? this.label,
      canSee: canSee ?? this.canSee,
      canAnswer: canAnswer ?? this.canAnswer,
    );
  }

  FormAssignmentInputDto2 toInput() {
    return FormAssignmentInputDto2(
      audienceType: audienceType,
      audienceUserId: audienceType == 'user' ? audienceUserId : null,
      audienceRole: audienceType == 'role' ? audienceRole : null,
      audienceGroupId:
          (audienceType == 'group' ||
              audienceType == 'class' ||
              audienceType == 'department')
          ? audienceGroupId
          : null,
      audienceSegmentId: audienceType == 'segment' ? audienceSegmentId : null,
      label: label,
      canSee: canSee,
      canAnswer: canAnswer,
    );
  }
}

class _AssignmentEditorCard extends StatelessWidget {
  const _AssignmentEditorCard({
    required this.draft,
    required this.onChanged,
    required this.onDelete,
    super.key,
  });

  final _AssignmentDraft draft;
  final ValueChanged<_AssignmentDraft> onChanged;
  final VoidCallback onDelete;

  static const _audienceTypes = [
    'role',
    'user',
    'group',
    'class',
    'department',
    'organization',
    'segment',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.56),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _audienceTypes.contains(draft.audienceType)
                      ? draft.audienceType
                      : 'role',
                  decoration: InputDecoration(
                    labelText: context.l10n.t('form.assignmentAudienceType'),
                    prefixIcon: const Icon(Icons.group_add_rounded),
                  ),
                  items: [
                    for (final type in _audienceTypes)
                      DropdownMenuItem(
                        value: type,
                        child: Text(_assignmentTypeLabel(context, type)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    onChanged(
                      _AssignmentDraft(
                        id: draft.id,
                        audienceType: value,
                        audienceRole: value == 'role'
                            ? draft.audienceRole ?? UserRole.teacher
                            : null,
                        label: draft.label,
                        canSee: draft.canSee,
                        canAnswer: draft.canAnswer,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                tooltip: context.l10n.t('delete'),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          AppSpacing.gapSm,
          if (draft.audienceType == 'role')
            DropdownButtonFormField<UserRole>(
              initialValue: draft.audienceRole ?? UserRole.teacher,
              decoration: InputDecoration(
                labelText: context.l10n.t('role'),
                prefixIcon: const Icon(Icons.badge_rounded),
              ),
              items:
                  const [
                        UserRole.parent,
                        UserRole.teacher,
                        UserRole.manager,
                        UserRole.admin,
                        UserRole.ceo,
                      ]
                      .map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(context.l10n.enumLabel(role.toJson())),
                        ),
                      )
                      .toList(),
              onChanged: (role) {
                if (role != null) onChanged(draft.copyWith(audienceRole: role));
              },
            )
          else if (_targetIdLabelKey(draft.audienceType) != null)
            TextFormField(
              initialValue: _targetId(draft),
              decoration: InputDecoration(
                labelText: context.l10n.t(
                  _targetIdLabelKey(draft.audienceType)!,
                ),
                helperText: context.l10n.t('form.assignmentTargetIdHelper'),
                prefixIcon: const Icon(Icons.tag_rounded),
              ),
              onChanged: (value) => onChanged(_withTargetId(draft, value)),
            )
          else
            _InlineNotice(
              icon: Icons.apartment_rounded,
              title: context.l10n.t('assignment.organization'),
              message: context.l10n.t('assignment.organizationAudience'),
            ),
          AppSpacing.gapSm,
          TextFormField(
            initialValue: draft.label,
            decoration: InputDecoration(
              labelText: context.l10n.t('form.assignmentLabel'),
              prefixIcon: const Icon(Icons.label_outline_rounded),
            ),
            onChanged: (value) => onChanged(draft.copyWith(label: value)),
          ),
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              FilterChip(
                selected: draft.canSee,
                avatar: const Icon(Icons.visibility_rounded, size: 18),
                label: Text(context.l10n.t('form.canView')),
                onSelected: (value) => onChanged(draft.copyWith(canSee: value)),
              ),
              FilterChip(
                selected: draft.canAnswer,
                avatar: const Icon(Icons.edit_rounded, size: 18),
                label: Text(context.l10n.t('form.canRespond')),
                onSelected: (value) =>
                    onChanged(draft.copyWith(canAnswer: value)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({required this.assignment});

  final FormAssignmentDto2 assignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canAnswer = assignment.canAnswer;
    final canSee = assignment.canSee;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.56),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _assignmentIcon(assignment),
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.label?.trim().isNotEmpty == true
                      ? assignment.label!.trim()
                      : _assignmentAudienceTitle(context, assignment),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _assignmentAudienceSubtitle(context, assignment),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Wrap(
            spacing: 6,
            children: [
              _TinyStatusChip(
                label: context.l10n.t('form.canView'),
                active: canSee,
                icon: canSee
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
              _TinyStatusChip(
                label: context.l10n.t('form.canRespond'),
                active: canAnswer,
                icon: canAnswer ? Icons.edit_rounded : Icons.block_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TinyStatusChip extends StatelessWidget {
  const _TinyStatusChip({
    required this.label,
    required this.active,
    required this.icon,
  });

  final String label;
  final bool active;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.primary : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _assignmentIcon(FormAssignmentDto2 assignment) {
  switch (assignment.audienceType) {
    case 'user':
      return Icons.person_rounded;
    case 'role':
      return Icons.badge_rounded;
    case 'group':
      return Icons.groups_rounded;
    case 'organization':
      return Icons.apartment_rounded;
    case 'segment':
      return Icons.filter_alt_rounded;
    default:
      return Icons.group_add_rounded;
  }
}

String _assignmentTypeLabel(BuildContext context, String type) {
  return switch (type) {
    'user' => context.l10n.t('assignment.user'),
    'role' => context.l10n.t('assignment.roleSpecific'),
    'group' => context.l10n.t('assignment.group'),
    'class' => context.l10n.t('assignment.class'),
    'department' => context.l10n.t('assignment.department'),
    'organization' => context.l10n.t('assignment.organization'),
    'segment' => context.l10n.t('assignment.segment'),
    _ => type,
  };
}

String? _targetIdLabelKey(String type) {
  return switch (type) {
    'user' => 'assignment.userIdLabel',
    'group' => 'assignment.groupIdLabel',
    'class' => 'assignment.classIdLabel',
    'department' => 'assignment.departmentIdLabel',
    'segment' => 'assignment.segmentIdLabel',
    _ => null,
  };
}

String? _targetId(_AssignmentDraft draft) {
  return switch (draft.audienceType) {
    'user' => draft.audienceUserId,
    'group' || 'class' || 'department' => draft.audienceGroupId,
    'segment' => draft.audienceSegmentId,
    _ => null,
  };
}

_AssignmentDraft _withTargetId(_AssignmentDraft draft, String value) {
  final normalized = value.trim().isEmpty ? null : value.trim();
  return switch (draft.audienceType) {
    'user' => draft.copyWith(audienceUserId: normalized),
    'group' ||
    'class' ||
    'department' => draft.copyWith(audienceGroupId: normalized),
    'segment' => draft.copyWith(audienceSegmentId: normalized),
    _ => draft,
  };
}

String _assignmentAudienceTitle(
  BuildContext context,
  FormAssignmentDto2 assignment,
) {
  switch (assignment.audienceType) {
    case 'user':
      return context.l10n.t('assignment.user');
    case 'role':
      final role = assignment.audienceRole;
      return role == null
          ? context.l10n.t('assignment.roleSpecific')
          : context.l10n
                .t('assignment.roleValue')
                .replaceAll('{role}', context.l10n.enumLabel(role.toJson()));
    case 'group':
      return context.l10n.t('assignment.group');
    case 'class':
      return context.l10n.t('assignment.class');
    case 'department':
      return context.l10n.t('assignment.department');
    case 'organization':
      return context.l10n.t('assignment.organization');
    case 'segment':
      return context.l10n.t('assignment.segment');
    default:
      return assignment.audienceType;
  }
}

String _assignmentAudienceSubtitle(
  BuildContext context,
  FormAssignmentDto2 assignment,
) {
  switch (assignment.audienceType) {
    case 'user':
      return assignment.audienceUserId == null
          ? context.l10n.t('assignment.userAudience')
          : context.l10n
                .t('assignment.userId')
                .replaceAll('{id}', _shortId(assignment.audienceUserId!));
    case 'role':
      final role = assignment.audienceRole;
      return role == null
          ? context.l10n.t('assignment.allRoleUsers')
          : context.l10n
                .t('assignment.allRoleUsersValue')
                .replaceAll('{role}', context.l10n.enumLabel(role.toJson()));
    case 'group':
    case 'class':
    case 'department':
      return assignment.audienceGroupId == null
          ? context.l10n.t('assignment.groupAudience')
          : context.l10n
                .t('assignment.groupId')
                .replaceAll('{id}', _shortId(assignment.audienceGroupId!));
    case 'organization':
      return context.l10n.t('assignment.organizationAudience');
    case 'segment':
      return assignment.audienceSegmentId == null
          ? context.l10n.t('assignment.segmentAudience')
          : context.l10n
                .t('assignment.segmentId')
                .replaceAll('{id}', _shortId(assignment.audienceSegmentId!));
    default:
      return context.l10n
          .t('assignment.type')
          .replaceAll('{type}', assignment.audienceType);
  }
}

class _AccessCodesPanel extends ConsumerStatefulWidget {
  const _AccessCodesPanel({required this.formId});

  final String formId;

  @override
  ConsumerState<_AccessCodesPanel> createState() => _AccessCodesPanelState();
}

class _AccessCodesPanelState extends ConsumerState<_AccessCodesPanel> {
  final _sharedController = TextEditingController();
  final _identityController = TextEditingController();
  bool _clearShared = false;
  bool _saving = false;
  late Future<FormAccessCodesResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _sharedController.dispose();
    _identityController.dispose();
    super.dispose();
  }

  Future<FormAccessCodesResponse> _load() {
    return ref
        .read(formsRepositoryProvider)
        .listFormAccessCodes(id: widget.formId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FormAccessCodesResponse>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return FeedbackInlinePanel(
          icon: Icons.key_rounded,
          title: context.l10n.t('formAccessCodes'),
          message: data == null
              ? context.l10n.t('loading')
              : context.l10n.t('formAccessCodesMessage'),
          trailing: TextButton.icon(
            onPressed: snapshot.connectionState == ConnectionState.waiting
                ? null
                : () => _openEditor(data),
            icon: const Icon(Icons.edit_rounded),
            label: Text(context.l10n.t('edit')),
          ),
        );
      },
    );
  }

  Future<void> _openEditor(FormAccessCodesResponse? current) async {
    _sharedController.clear();
    _identityController.clear();
    _clearShared = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.t('formAccessCodes'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  AppSpacing.gapMd,
                  if (current?.sharedPassword != null)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _clearShared,
                      onChanged: (value) =>
                          setSheetState(() => _clearShared = value ?? false),
                      title: Text(context.l10n.t('clearFormPassword')),
                    ),
                  TextField(
                    controller: _sharedController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: context.l10n.t('newFormPasswordOptional'),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                    ),
                  ),
                  AppSpacing.gapMd,
                  TextField(
                    controller: _identityController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: context.l10n.t('identityCodes'),
                      helperText: context.l10n.t('identityCodesHelper'),
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ),
                  AppSpacing.gapMd,
                  FilledButton.icon(
                    onPressed: _saving ? null : () => _save(context),
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(context.l10n.t('save')),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _save(BuildContext sheetContext) async {
    final sheetNavigator = Navigator.of(sheetContext);
    final identityCodes = _identityController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && line.contains(':'))
        .map((line) {
          final separator = line.indexOf(':');
          return FormAccessCodeInputDto(
            label: line.substring(0, separator).trim(),
            code: line.substring(separator + 1).trim(),
            enabled: true,
          );
        })
        .where((code) => code.label.isNotEmpty && code.code.isNotEmpty)
        .toList(growable: false);

    setState(() => _saving = true);
    try {
      await ref
          .read(formsRepositoryProvider)
          .setFormAccessCodes(
            id: widget.formId,
            request: SetFormAccessCodesRequest(
              sharedPassword: _sharedController.text.trim().isEmpty
                  ? null
                  : SharedFormPasswordInputDto(
                      code: _sharedController.text.trim(),
                      enabled: true,
                    ),
              clearSharedPassword: _clearShared,
              identityCodes: identityCodes,
            ),
          );
      if (!mounted) return;
      setState(() => _future = _load());
      sheetNavigator.pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.t('settingsSaved'))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(FriendlyApiErrorMessage.from(error, context: context)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PublishSection extends StatefulWidget {
  const _PublishSection({required this.form});

  final FormDetailDto form;

  @override
  State<_PublishSection> createState() => _PublishSectionState();
}

class _PublishSectionState extends State<_PublishSection> {
  PublishMode _mode = PublishMode.organization;
  late VisibilityMode _visibilityMode;
  Set<UserRole> _selectedRoles = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.form.publishMode;
    _visibilityMode = widget.form.visibility.mode;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHeader(
                icon: Icons.rocket_launch_rounded,
                title: context.l10n.t('publishWorkflow'),
                message: context.l10n.t('publishMessage'),
              ),
              AppSpacing.gapLg,
              _StatusGuidance(form: widget.form),
              AppSpacing.gapLg,
              _AccessModeExplainer(
                icon: Icons.visibility_rounded,
                title: context.l10n.t('visibility'),
                message: context.l10n.t('visibilityModeHelp'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _EnumDropdown<VisibilityMode>(
                label: context.l10n.t('visibility'),
                value: _visibilityMode,
                values: const [
                  VisibilityMode.private,
                  VisibilityMode.organization,
                  VisibilityMode.selectedRoles,
                  VisibilityMode.subordinates,
                  VisibilityMode.publicLink,
                ],
                labelFor: (value) => context.l10n.enumLabel(value.toJson()),
                onChanged: (value) => setState(() => _visibilityMode = value),
              ),
              AppSpacing.gapMd,
              _AccessModeExplainer(
                icon: Icons.rocket_launch_rounded,
                title: context.l10n.t('publishMode'),
                message: context.l10n.t('publishModeHelp'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _EnumDropdown<PublishMode>(
                label: context.l10n.t('publishMode'),
                value: _mode,
                values: const [
                  PublishMode.private,
                  PublishMode.organization,
                  PublishMode.subordinates,
                  PublishMode.roleBased,
                  PublishMode.publicLink,
                ],
                labelFor: (value) => context.l10n.enumLabel(value.toJson()),
                onChanged: (value) => setState(() => _mode = value),
              ),
              if (_mode == PublishMode.roleBased) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.t('selectTargetRoles'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xs),
                _RoleMultiSelect(
                  selected: _selectedRoles,
                  onChanged: (roles) => setState(() => _selectedRoles = roles),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _publish(ref),
                    icon: const Icon(Icons.publish_rounded),
                    label: Text(context.l10n.t('publish')),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _submitForApproval(ref),
                    icon: const Icon(Icons.fact_check_rounded),
                    label: Text(context.l10n.t('submitForApproval')),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy || widget.form.status == FormStatus.closed
                        ? null
                        : () => _close(ref),
                    icon: const Icon(Icons.lock_rounded),
                    label: Text(context.l10n.t('close')),
                  ),
                  TextButton.icon(
                    onPressed:
                        _busy || widget.form.status == FormStatus.archived
                        ? null
                        : () => _archive(ref),
                    icon: const Icon(Icons.archive_rounded),
                    label: Text(context.l10n.t('enum.archived')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _publish(WidgetRef ref) async {
    await _runAction(
      ref,
      successMessage: _mode == PublishMode.publicLink
          ? context.l10n.t('publishedShareHint')
          : context.l10n.t('formPublished'),
      action: () => ref
          .read(formsRepositoryProvider)
          .publishForm(
            id: widget.form.id,
            request: PublishFormRequest(
              publishMode: _mode,
              visibility: _visibilityWithMode(
                widget.form.visibility,
                _visibilityMode,
              ),
              publicProtection: widget.form.publicProtection,
            ),
          ),
    );
    if (mounted && _mode == PublishMode.publicLink) {
      context.go('/forms/${widget.form.id}/share');
    }
  }

  Future<void> _submitForApproval(WidgetRef ref) async {
    await _runAction(
      ref,
      successMessage: context.l10n.t('submittedForApproval'),
      action: () => ref
          .read(formsRepositoryProvider)
          .submitFormForApproval(
            id: widget.form.id,
            request: SubmitForApprovalRequest(
              note: context.l10n.t('submittedFromClient'),
            ),
          ),
    );
  }

  Future<void> _close(WidgetRef ref) async {
    final l10n = context.l10n;
    final reason = await _reasonDialog(
      context,
      title: l10n.t('closeForm'),
      hint: l10n.t('optionalReason'),
    );
    if (reason == null) return;
    await _runAction(
      ref,
      successMessage: l10n.t('formClosedToast'),
      action: () => ref
          .read(formsRepositoryProvider)
          .closeForm(
            id: widget.form.id,
            request: CloseFormRequest(reason: reason.isEmpty ? null : reason),
          ),
    );
  }

  Future<void> _archive(WidgetRef ref) async {
    final l10n = context.l10n;
    final reason = await _reasonDialog(
      context,
      title: l10n.t('archiveForm'),
      hint: l10n.t('optionalReason'),
    );
    if (reason == null) return;
    if (context.mounted) {
      await _runAction(
        ref,
        successMessage: l10n.t('formArchivedToast'),
        action: () => ref
            .read(formsRepositoryProvider)
            .archiveForm(
              id: widget.form.id,
              request: ArchiveFormRequest(
                reason: reason.isEmpty ? null : reason,
              ),
            ),
      );
    }
  }

  Future<void> _runAction(
    WidgetRef ref, {
    required String successMessage,
    required Future<FormDetailDto> Function() action,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(formDetailProvider(widget.form.id));
      ref.invalidate(formsControllerProvider);
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _AccessModeExplainer extends StatelessWidget {
  const _AccessModeExplainer({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareSection extends StatelessWidget {
  const _ShareSection({required this.form});

  final FormDetailDto form;

  @override
  Widget build(BuildContext context) {
    final token = form.publicToken;
    final publicPath = token == null ? null : '/public/$token';
    final publicUrl = token == null ? null : _buildPublicShareUrl(token);
    final copyValue = publicUrl ?? publicPath;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            icon: Icons.ios_share_rounded,
            title: context.l10n.t('share'),
            message: context.l10n.t('shareMessage'),
          ),
          AppSpacing.gapLg,
          if (token == null)
            _EmptyActionPanel(
              icon: Icons.link_off_rounded,
              title: context.l10n.t('noPublicLinkYet'),
              message: context.l10n.t('publishPublicLinkHint'),
              actionLabel: context.l10n.t('goToPublish'),
              onAction: () => context.go('/forms/${form.id}/publish'),
            )
          else ...[
            _InlineNotice(
              icon: publicUrl == null
                  ? Icons.info_outline_rounded
                  : Icons.verified_rounded,
              title: publicUrl == null
                  ? context.l10n.t('relativePublicLinkTitle')
                  : context.l10n.t('publicLinkReady'),
              message: publicUrl == null
                  ? context.l10n.t('publicBaseUrlMissing')
                  : context.l10n.t('publicLinkReadyMessage'),
            ),
            AppSpacing.gapMd,
            TextField(
              readOnly: true,
              controller: TextEditingController(text: copyValue ?? ''),
              decoration: InputDecoration(
                labelText: publicUrl == null
                    ? context.l10n.t('publicPath')
                    : context.l10n.t('publicUrl'),
                prefixIcon: const Icon(Icons.link_rounded),
              ),
            ),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                FilledButton.icon(
                  onPressed: copyValue == null
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: copyValue));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.t('publicLinkCopied')),
                            ),
                          );
                        },
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(context.l10n.t('copyLink')),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/public/$token'),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(context.l10n.t('openPublicForm')),
                ),
              ],
            ),
            AppSpacing.gapSm,
            Text(
              context.l10n.t('publicLinkServerNote'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String? _buildPublicShareUrl(String token) {
  const configuredBase = String.fromEnvironment(
    'PUBLIC_APP_BASE_URL',
    defaultValue: '',
  );
  final configured = configuredBase.trim();
  if (configured.isNotEmpty) return _joinUrl(configured, '/public/$token');

  final base = Uri.base;
  final isHttp = base.scheme == 'http' || base.scheme == 'https';
  if (isHttp && base.host.isNotEmpty) {
    return base
        .replace(
          path: '/public/$token',
          queryParameters: const <String, String>{},
          fragment: '',
        )
        .toString();
  }

  // Do not generate file:///public/... links. On mobile/desktop there is no browser
  // origin, so the deployer must pass --dart-define=PUBLIC_APP_BASE_URL=https://app.example.com.
  return null;
}

String _joinUrl(String base, String path) {
  final normalizedBase = base.endsWith('/')
      ? base.substring(0, base.length - 1)
      : base;
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return '$normalizedBase$normalizedPath';
}

class _RoleMultiSelect extends StatelessWidget {
  const _RoleMultiSelect({required this.selected, required this.onChanged});

  final Set<UserRole> selected;
  final ValueChanged<Set<UserRole>> onChanged;

  static const _selectableRoles = [
    UserRole.teacher,
    UserRole.parent,
    UserRole.student,
    UserRole.manager,
    UserRole.admin,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final role in _selectableRoles)
          FilterChip(
            selected: selected.contains(role),
            label: Text(context.l10n.enumLabel(role.toJson())),
            onSelected: (value) {
              final next = {...selected};
              if (value) {
                next.add(role);
              } else {
                next.remove(role);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class _ResultsSection extends ConsumerWidget {
  const _ResultsSection({required this.form});

  final FormDetailDto form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(formAnalyticsProvider(form.id));
    final submissions = ref.watch(submissionsProvider(form.id));
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            icon: Icons.analytics_rounded,
            title: context.l10n.t('results'),
            message: context.l10n.t('resultsMessage'),
            trailing: IconButton.filledTonal(
              tooltip: context.l10n.t('refresh'),
              onPressed: () {
                ref.invalidate(formAnalyticsProvider(form.id));
                ref.invalidate(submissionsProvider(form.id));
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          AppSpacing.gapLg,
          analytics.when(
            loading: () =>
                LoadingPanel(message: context.l10n.t('loadingResults')),
            error: (error, stackTrace) => ErrorPanel(
              error: error,
              onRetry: () => ref.invalidate(formAnalyticsProvider(form.id)),
              onBack: () => context.go('/forms'),
              onSignIn: () => context.go('/login'),
            ),
            data: (value) => _AnalyticsOverview(analytics: value),
          ),
          AppSpacing.gapLg,
          submissions.when(
            loading: () =>
                LoadingPanel(message: context.l10n.t('loadingSubmissions')),
            error: (error, stackTrace) => ErrorPanel(
              error: error,
              onRetry: () => ref.invalidate(submissionsProvider(form.id)),
              onBack: () => context.go('/forms'),
              onSignIn: () => context.go('/login'),
            ),
            data: (value) => _SubmissionsPanel(form: form, response: value),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsOverview extends StatelessWidget {
  const _AnalyticsOverview({required this.analytics});

  final FormAnalyticsDto analytics;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _MetricCard(
        title: context.l10n.t('totalSubmissions'),
        value: '${analytics.submissions.total}',
        icon: Icons.inbox_rounded,
      ),
      _MetricCard(
        title: context.l10n.t('validSubmissions'),
        value: '${analytics.submissions.valid}',
        icon: Icons.verified_rounded,
      ),
      _MetricCard(
        title: context.l10n.t('anonymousSubmissions'),
        value: '${analytics.submissions.anonymous}',
        icon: Icons.visibility_off_rounded,
      ),
      _MetricCard(
        title: context.l10n.t('completionRate'),
        value: '${analytics.completion.completionRate.toStringAsFixed(1)}%',
        icon: Icons.task_alt_rounded,
      ),
      _MetricCard(
        title: context.l10n.t('averageScore'),
        value: analytics.score.averageScore.toStringAsFixed(1),
        icon: Icons.stacked_line_chart_rounded,
      ),
      _MetricCard(
        title: context.l10n.t('averagePercentage'),
        value: '${analytics.score.averagePercentage.toStringAsFixed(1)}%',
        icon: Icons.percent_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResponsiveCardGrid(children: cards),
        AppSpacing.gapLg,
        _FieldAnalyticsPanel(fields: analytics.fields),
      ],
    );
  }
}

class _FieldAnalyticsPanel extends StatelessWidget {
  const _FieldAnalyticsPanel({required this.fields});

  final List<FieldAnalyticsDto> fields;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (fields.isEmpty) {
      return _InlineNotice(
        icon: Icons.query_stats_rounded,
        title: context.l10n.t('fieldAnalytics'),
        message: context.l10n.t('noFieldAnalyticsYet'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.t('fieldAnalytics'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final field in fields)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.46),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics_outlined, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${context.l10n.t('responseCount')}: ${field.responseCount}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (field.summary != null)
                  Tooltip(
                    message: _formatJsonLike(field.summary),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SubmissionsPanel extends StatelessWidget {
  const _SubmissionsPanel({required this.form, required this.response});

  final FormDetailDto form;
  final ListResponse<SubmissionSummaryDto> response;

  @override
  Widget build(BuildContext context) {
    final items = response.data ?? const <SubmissionSummaryDto>[];
    final total = response.meta?.pagination.totalItems ?? items.length;
    if (items.isEmpty) {
      return _EmptyStateMessage(
        icon: Icons.hourglass_empty_rounded,
        title: context.l10n.t('noSubmissionsYet'),
        message: context.l10n.t('publishAndShareHint'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.t('latestSubmissions'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              context.l10n
                  .t('showingSubmissions')
                  .replaceAll('{shown}', '${items.length}')
                  .replaceAll('{total}', '$total'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final submission in items)
          _SubmissionSummaryTile(form: form, submission: submission),
      ],
    );
  }
}

class _SubmissionSummaryTile extends StatelessWidget {
  const _SubmissionSummaryTile({required this.form, required this.submission});

  final FormDetailDto form;
  final SubmissionSummaryDto submission;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final respondent = _submissionRespondentLabel(context, submission);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.46),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: const Icon(Icons.receipt_long_rounded),
        ),
        title: Text(
          '${context.l10n.t('submission')} ${_shortId(submission.id)}',
        ),
        subtitle: Text(
          '${context.l10n.t('submitted')} ${_formatDateTime(submission.submittedAt)}\n$respondent',
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              label: Text(
                '${submission.score.percentageScore.toStringAsFixed(0)}%',
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _showSubmissionDetailSheet(
                context,
                form: form,
                submissionId: submission.id,
              ),
              icon: const Icon(Icons.visibility_rounded),
              label: Text(context.l10n.t('viewDetails')),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showSubmissionDetailSheet(
  BuildContext context, {
  required FormDetailDto form,
  required String submissionId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) =>
        _SubmissionDetailSheet(form: form, submissionId: submissionId),
  );
}

class _SubmissionDetailSheet extends ConsumerWidget {
  const _SubmissionDetailSheet({
    required this.form,
    required this.submissionId,
  });

  final FormDetailDto form;
  final String submissionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(submissionDetailProvider(submissionId));
    return Directionality(
      textDirection: context.l10n.textDirection,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          top: 8,
        ),
        child: detail.when(
          loading: () =>
              LoadingPanel(message: context.l10n.t('loadingSubmissionDetail')),
          error: (error, stackTrace) => ErrorPanel(
            error: error,
            onRetry: () =>
                ref.invalidate(submissionDetailProvider(submissionId)),
            onBack: () => Navigator.of(context).maybePop(),
            onSignIn: () => context.go('/login'),
          ),
          data: (submission) =>
              _SubmissionDetailContent(form: form, submission: submission),
        ),
      ),
    );
  }
}

class _SubmissionDetailContent extends StatelessWidget {
  const _SubmissionDetailContent({
    required this.form,
    required this.submission,
  });

  final FormDetailDto form;
  final SubmissionDetailDto submission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fieldsById = {for (final field in form.fields) field.id: field};

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Header ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.assignment_turned_in_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.t('submissionDetail'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _formatDateTime(submission.submittedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _submissionDetailRespondentLabel(context, submission),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- Score summary ---
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primaryContainer.withValues(alpha: 0.7),
                  scheme.tertiaryContainer.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                _ScoreBadge(
                  label: context.l10n.t('score'),
                  value: submission.score.totalScore.toStringAsFixed(1),
                  icon: Icons.score_rounded,
                  scheme: scheme,
                  theme: theme,
                ),
                const SizedBox(width: AppSpacing.sm),
                _ScoreBadge(
                  label: context.l10n.t('percentage'),
                  value:
                      '${submission.score.percentageScore.toStringAsFixed(0)}%',
                  icon: Icons.percent_rounded,
                  scheme: scheme,
                  theme: theme,
                ),
                const SizedBox(width: AppSpacing.sm),
                _ScoreBadge(
                  label: submission.anonymous
                      ? context.l10n.t('anonymous')
                      : context.l10n.t('identified'),
                  value: submission.anonymous
                      ? context.l10n.t('yes')
                      : context.l10n.t('no'),
                  icon: submission.anonymous
                      ? Icons.visibility_off_rounded
                      : Icons.person_rounded,
                  scheme: scheme,
                  theme: theme,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // --- Answers ---
          Text(
            context.l10n.t('answers'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < submission.answers.length; i++) ...[
            _AnswerTile(
              index: i,
              label:
                  fieldsById[submission.answers[i].fieldId]?.label ??
                  submission.answers[i].fieldId,
              value: submission.answers[i].value,
              scheme: scheme,
              theme: theme,
            ),
            if (i < submission.answers.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.scheme,
    required this.theme,
  });

  final String label;
  final String value;
  final IconData icon;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: scheme.onPrimaryContainer, size: 22),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.onPrimaryContainer,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.index,
    required this.label,
    required this.value,
    required this.scheme,
    required this.theme,
  });

  final int index;
  final String label;
  final Object? value;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(
                  _formatAnswerValue(value),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatAnswerValue(Object? value) {
  if (value == null) return '—';
  if (value is String) return value.isEmpty ? '—' : value;
  if (value is num) return value.toString();
  if (value is bool) return value ? '✓' : '✗';
  if (value is List) {
    if (value.isEmpty) return '—';
    return value.map((e) => e.toString()).join(', ');
  }
  return value.toString();
}

class _ResponsiveCardGrid extends StatelessWidget {
  const _ResponsiveCardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: columns,
          childAspectRatio: columns == 1 ? 4.2 : 3.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}

String _formatDateTime(DateTime value) =>
    value.toLocal().toString().split('.').first;

String _shortId(String value) =>
    value.length <= 8 ? value : value.substring(0, 8);

String _submissionRespondentLabel(
  BuildContext context,
  SubmissionSummaryDto submission,
) {
  final mode = _localizedRespondentMode(context, submission.respondentMode);
  final label = submission.respondentLabel?.trim();
  if (label != null && label.isNotEmpty) {
    return '${context.l10n.t('respondent')}: $mode - $label';
  }
  if (submission.respondentUserId != null) {
    return '${context.l10n.t('respondent')}: $mode - ${_shortId(submission.respondentUserId!)}';
  }
  return '${context.l10n.t('respondent')}: $mode';
}

String _submissionDetailRespondentLabel(
  BuildContext context,
  SubmissionDetailDto submission,
) {
  final mode = _localizedRespondentMode(context, submission.respondentMode);
  final label = submission.respondentLabel?.trim();
  if (label != null && label.isNotEmpty) {
    return '${context.l10n.t('respondent')}: $mode - $label';
  }
  if (submission.respondentUserId != null) {
    return '${context.l10n.t('respondent')}: $mode - ${_shortId(submission.respondentUserId!)}';
  }
  return '${context.l10n.t('respondent')}: $mode';
}

String _localizedRespondentMode(BuildContext context, String mode) {
  switch (mode) {
    case 'anonymous':
    case 'guest':
    case 'authenticated':
    case 'identity_code':
      return context.l10n.t(mode);
    default:
      return mode;
  }
}

String _formatJsonLike(Object? value) {
  if (value == null) return '—';
  if (value is List) return value.map(_formatJsonLike).join(', ');
  if (value is Map) {
    if (value.isEmpty) return '{}';
    return value.entries
        .map((entry) => '${entry.key}: ${_formatJsonLike(entry.value)}')
        .join(', ');
  }
  return value.toString();
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.message,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class _StatusGuidance extends StatelessWidget {
  const _StatusGuidance({required this.form});

  final FormDetailDto form;

  @override
  Widget build(BuildContext context) {
    final (icon, title, message) = switch (form.status) {
      FormStatus.published => (
        Icons.check_circle_rounded,
        context.l10n.t('enum.published'),
        context.l10n.t('statusPublishedMessage'),
      ),
      FormStatus.pendingReview => (
        Icons.rate_review_rounded,
        context.l10n.t('enum.pending_review'),
        context.l10n.t('statusPendingMessage'),
      ),
      FormStatus.closed => (
        Icons.lock_rounded,
        context.l10n.t('enum.closed'),
        context.l10n.t('statusClosedMessage'),
      ),
      FormStatus.archived => (
        Icons.archive_rounded,
        context.l10n.t('enum.archived'),
        context.l10n.t('statusArchivedMessage'),
      ),
      _ => (
        Icons.edit_note_rounded,
        context.l10n.t('draftWorkflow'),
        context.l10n.t('statusDraftMessage'),
      ),
    };
    return _InlineNotice(icon: icon, title: title, message: message);
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.52),
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyActionPanel extends StatelessWidget {
  const _EmptyActionPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _EmptyStateMessage(
      icon: icon,
      title: title,
      message: message,
      action: FilledButton.icon(
        onPressed: onAction,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(actionLabel),
      ),
    );
  }
}

class _EmptyStateMessage extends StatelessWidget {
  const _EmptyStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: scheme.primary),
          AppSpacing.gapSm,
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class _FieldPickerSheet extends StatelessWidget {
  const _FieldPickerSheet();

  @override
  Widget build(BuildContext context) {
    final types = FieldType.values
        .where((type) => type != FieldType.unknown)
        .toList(growable: false);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.t('addField'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            AppSpacing.gapSm,
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 230,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 82,
                ),
                itemCount: types.length,
                itemBuilder: (context, index) {
                  final type = types[index];
                  final info = fieldTypeInfo(type);
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => Navigator.pop(context, type),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(info.icon),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                info.localizedLabel(context),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnumDropdown<T> extends StatelessWidget {
  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values
          .map(
            (value) =>
                DropdownMenuItem<T>(value: value, child: Text(labelFor(value))),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final FormStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final published = status == FormStatus.published;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: published
            ? scheme.primary
            : scheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.l10n.enumLabel(status.toJson()),
        style: TextStyle(
          color: published ? scheme.onPrimary : scheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppInfoChip(icon: icon, label: label);
  }
}

Future<String?> _reasonDialog(
  BuildContext context, {
  required String title,
  required String hint,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: hint),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(context.l10n.t('continue')),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

FormVisibilityDto _safeVisibility(FormVisibilityDto visibility) {
  return FormVisibilityDto(
    mode: visibility.mode,
    canSee: visibility.canSee ?? const <AudienceRuleDto>[],
    canAnswer: visibility.canAnswer ?? const <AudienceRuleDto>[],
    cannotSee: visibility.cannotSee ?? const <AudienceRuleDto>[],
    cannotAnswer: visibility.cannotAnswer ?? const <AudienceRuleDto>[],
    guestCanAnswer: visibility.guestCanAnswer,
    anonymousAllowed: visibility.anonymousAllowed,
    metadata: visibility.metadata ?? const <String, Object?>{},
  );
}

FormVisibilityDto _visibilityWithMode(
  FormVisibilityDto visibility,
  VisibilityMode mode,
) {
  final safe = _safeVisibility(visibility);
  return FormVisibilityDto(
    mode: mode,
    canSee: safe.canSee,
    canAnswer: safe.canAnswer,
    cannotSee: safe.cannotSee,
    cannotAnswer: safe.cannotAnswer,
    guestCanAnswer: safe.guestCanAnswer,
    anonymousAllowed: safe.anonymousAllowed,
    metadata: safe.metadata,
  );
}

bool _fieldSubmitsAnswer(FieldType type) {
  return switch (type) {
    FieldType.sectionTitle ||
    FieldType.descriptionBlock ||
    FieldType.divider ||
    FieldType.pageBreak ||
    FieldType.scoreDisplay ||
    FieldType.calculated ||
    FieldType.hidden ||
    FieldType.conditionalLogic ||
    FieldType.unknown => false,
    _ => true,
  };
}

void _returnToPreviousOrForms(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.maybePop();
    return;
  }
  context.go('/forms');
}
