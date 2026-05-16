import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../data/dto/dto.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/common/field_type_ui.dart' as field_ui;
import '../../../presentation/models/form_builder_models.dart';
import '../../../presentation/theme/app_breakpoints.dart';
import '../../../presentation/theme/app_spacing.dart';
import '../../../presentation/widgets/app_chrome.dart';

class CreateFormScreen extends ConsumerWidget {
  const CreateFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createFormControllerProvider);
    final controller = ref.read(createFormControllerProvider.notifier);
    final compact = context.isCompactWidth;

    ref.listen<CreateFormState>(createFormControllerProvider, (previous, next) {
      final previousCreatedId = previous?.createdForm?.id;
      final nextCreated = next.createdForm;
      if (nextCreated != null && !next.partialCreate && previousCreatedId != nextCreated.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.t('formCreated'))),
        );
        context.go('/forms/${nextCreated.id}/builder');
      }
      if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_localizedCreateFormError(context, next.errorMessage!)),
            action: next.createdForm == null
                ? null
                : SnackBarAction(
                    label: context.l10n.t('openDraft'),
                    onPressed: () => context.go('/forms/${next.createdForm!.id}/builder'),
                  ),
          ),
        );
      }
    });

    return GradientScaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.canSubmit ? () => controller.submit() : null,
        icon: state.isSubmitting
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_rounded),
        label: Text(state.isSubmitting ? context.l10n.t('creating') : context.l10n.t('createForm')),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            leading: const Padding(
              padding: EdgeInsetsDirectional.only(start: AppSpacing.xs),
              child: AppBackButton(fallbackLocation: '/forms'),
            ),
            title: Text(context.l10n.t('createForm')),
            actions: compact
                ? [
                    IconButton.filledTonal(
                      tooltip: context.l10n.t('addField'),
                      onPressed: state.isSubmitting
                          ? null
                          : () => _showFieldPicker(context, ref),
                      icon: const Icon(Icons.add_rounded),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ]
                : [
                    const LanguageButton(),
                    const ThemeModeButton(),
                    TextButton.icon(
                      onPressed: state.isSubmitting
                          ? null
                          : () => _showFieldPicker(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(context.l10n.t('addField')),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.contentMax),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? AppSpacing.md : AppSpacing.lg,
                    AppSpacing.xs,
                    compact ? AppSpacing.md : AppSpacing.lg,
                    AppSpacing.xxxl + AppSpacing.xxl, // FAB clearance
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 960;
                      final basics = _BasicsPanel(state: state, enabled: !state.isSubmitting);
                      final fields = _FieldsPanel(state: state, enabled: !state.isSubmitting);
                      return wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 4, child: basics),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(flex: 5, child: fields),
                              ],
                            )
                          : Column(
                              children: [
                                basics,
                                const SizedBox(height: AppSpacing.lg),
                                fields,
                              ],
                            );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _showFieldPicker(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<FieldType>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _FieldPickerSheet(),
    );
    if (selected != null) {
      ref.read(createFormControllerProvider.notifier).addField(selected);
    }
  }
}

class _BasicsPanel extends ConsumerWidget {
  const _BasicsPanel({required this.state, required this.enabled});

  final CreateFormState state;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(createFormControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeroCard(),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: context.l10n.t('formType'),
          subtitle: context.l10n.t('formTypeSubtitle'),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final template in FormTemplateCatalog.presets)
                _TemplateTile(
                  template: template,
                  selected: template.type == state.selectedTemplate,
                  enabled: enabled,
                  onTap: () => controller.selectTemplate(template.type),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: context.l10n.t('basics'),
          subtitle: context.l10n.t('basicsSubtitle'),
          child: Column(
            children: [
              TextFormField(
                key: ValueKey('title-${state.selectedTemplate}'),
                initialValue: state.title,
                enabled: enabled,
                decoration: InputDecoration(
                  labelText: context.l10n.t('title'),
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                ),
                onChanged: controller.changeTitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: ValueKey('description-${state.selectedTemplate}'),
                initialValue: state.description,
                enabled: enabled,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: context.l10n.t('description'),
                  prefixIcon: const Icon(Icons.description_rounded),
                ),
                onChanged: controller.changeDescription,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: ValueKey('category-${state.selectedTemplate}'),
                initialValue: state.category,
                enabled: enabled,
                decoration: InputDecoration(
                  labelText: context.l10n.t('category'),
                  prefixIcon: const Icon(Icons.folder_outlined),
                ),
                onChanged: controller.changeCategory,
              ),
              const SizedBox(height: AppSpacing.sm),
              _TagInput(
                enabled: enabled,
                tags: state.tags,
                onChanged: controller.setTags,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: context.l10n.t('settings'),
          subtitle: context.l10n.t('settingsSubtitle'),
          child: Column(
            children: [
              _EnumDropdown<ScoringMode>(
                label: context.l10n.t('scoringMode'),
                value: state.scoringMode,
                values: const [
                  ScoringMode.none,
                  ScoringMode.quiz,
                  ScoringMode.satisfaction,
                  ScoringMode.riskAssessment,
                  ScoringMode.weighted,
                  ScoringMode.custom,
                ],
                labelFor: (value) => context.l10n.enumLabel(value.toJson()),
                onChanged: enabled ? controller.changeScoring : null,
              ),
              const SizedBox(height: AppSpacing.xs),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: state.allowAnonymousAnswers,
                onChanged: enabled ? (value) => controller.changeSettings(allowAnonymousAnswers: value) : null,
                title: Text(context.l10n.t('allowAnonymousAnswers')),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: state.guestsCanAnswer,
                onChanged: enabled ? (value) => controller.changeSettings(guestsCanAnswer: value) : null,
                title: Text(context.l10n.t('guestsCanAnswer')),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: state.oneSubmissionPerUser,
                onChanged: enabled ? (value) => controller.changeSettings(oneSubmissionPerUser: value) : null,
                title: Text(context.l10n.t('oneSubmissionPerUser')),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: state.answersEditableAfterSubmission,
                onChanged: enabled ? (value) => controller.changeSettings(answersEditableAfterSubmission: value) : null,
                title: Text(context.l10n.t('answersEditableAfterSubmission')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldsPanel extends ConsumerWidget {
  const _FieldsPanel({required this.state, required this.enabled});

  final CreateFormState state;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(createFormControllerProvider.notifier);
    return _SectionCard(
      title: context.l10n.t('fields'),
      subtitle:
          '${context.l10n.countFields(state.fields.length)} ${context.l10n.t('fieldsWillCreate')}',
      trailing: FilledButton.tonalIcon(
        onPressed: enabled
            ? () => CreateFormScreen._showFieldPicker(context, ref)
            : null,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.t('add')),
      ),
      child: state.fields.isEmpty
          ? const _EmptyFields()
          : ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: controller.moveField,
              itemCount: state.fields.length,
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                elevation: 4,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                child: child,
              ),
              itemBuilder: (context, index) {
                final field = state.fields[index];
                final isLast = index == state.fields.length - 1;
                return _ReorderableFieldItem(
                  key: ValueKey(field.draftId),
                  index: index,
                  field: field,
                  enabled: enabled,
                  isLast: isLast,
                  formScoringEnabled:
                      state.scoringMode != ScoringMode.none,
                  onChanged: controller.changeField,
                  onRemove: () => controller.removeField(field.draftId),
                );
              },
            ),
    );
  }
}

/// Wrapper widget for each field item in the ReorderableListView.
///
/// This is the direct child of the list — it must be a single widget with a
/// key. The divider is rendered below the card as part of this widget's
/// bottom margin area so it doesn't interfere with drag proxy sizing.
class _ReorderableFieldItem extends StatelessWidget {
  const _ReorderableFieldItem({
    required super.key,
    required this.index,
    required this.field,
    required this.enabled,
    required this.isLast,
    required this.formScoringEnabled,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final DraftFormField field;
  final bool enabled;
  final bool isLast;
  final bool formScoringEnabled;
  final ValueChanged<DraftFormField> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DraftFieldCard(
            index: index,
            field: field,
            enabled: enabled,
            formScoringEnabled: formScoringEnabled,
            onChanged: onChanged,
            onRemove: onRemove,
          ),
          if (!isLast) ...[
            const SizedBox(height: AppSpacing.sm),
            const _FieldDivider(),
          ],
        ],
      ),
    );
  }
}

/// Visual separator between consecutive draft field cards.
class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lineColor = scheme.outlineVariant.withValues(alpha: 0.55);
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, lineColor],
                ),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest
                    .withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: lineColor),
              ),
              child: Icon(
                Icons.more_vert_rounded,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [lineColor, Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftFieldCard extends StatelessWidget {
  const _DraftFieldCard({
    required this.index,
    required this.field,
    required this.enabled,
    required this.formScoringEnabled,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final DraftFormField field;
  final bool enabled;
  final bool formScoringEnabled;
  final ValueChanged<DraftFormField> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final typeInfo = field_ui.fieldTypeInfo(field.type);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row: order badge, type info, drag handle, delete.
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              border: Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(typeInfo.icon, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeInfo.localizedLabel(context),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        typeInfo.localizedDescription(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.t('removeField'),
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
                ReorderableDragStartListener(
                  index: index,
                  enabled: enabled,
                  child: Tooltip(
                    message: context.l10n.t('reorder'),
                    child: const Padding(
                      padding: EdgeInsets.all(AppSpacing.xs),
                      child: Icon(Icons.drag_indicator_rounded),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EnumDropdown<FieldType>(
                  label: context.l10n.t('fieldType'),
                  value: field.type,
                  values: field_ui.fieldTypeCatalog
                      .map((item) => item.type)
                      .toList(growable: false),
                  labelFor: (value) => context.l10n.fieldType(value.toJson()),
                  onChanged:
                      enabled ? (value) => onChanged(field.changeType(value)) : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: ValueKey('label-${field.draftId}-${field.type}'),
                  initialValue: field.label,
                  enabled: enabled,
                  decoration:
                      InputDecoration(labelText: context.l10n.t('label')),
                  onChanged: (value) =>
                      onChanged(field.copyWith(label: value)),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: ValueKey(
                      'description-${field.draftId}-${field.type}'),
                  initialValue: field.description,
                  enabled: enabled,
                  decoration: InputDecoration(
                      labelText: context.l10n.t('descriptionStaticText')),
                  onChanged: (value) =>
                      onChanged(field.copyWith(description: value)),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: ValueKey(
                      'placeholder-${field.draftId}-${field.type}'),
                  initialValue: field.placeholder,
                  enabled: enabled &&
                      !field_ui.fieldTypeIsInformational(field.type),
                  decoration: InputDecoration(
                      labelText: context.l10n.t('placeholder')),
                  onChanged: (value) =>
                      onChanged(field.copyWith(placeholder: value)),
                ),
                const SizedBox(height: AppSpacing.xs),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: field.isRequired,
                  onChanged: enabled &&
                          !field_ui.fieldTypeIsInformational(field.type)
                      ? (value) =>
                          onChanged(field.copyWith(isRequired: value))
                      : null,
                  title: Text(context.l10n.t('required')),
                ),
                if (field_ui.fieldTypeUsesOptions(field.type) ||
                    field_ui.fieldTypeUsesMatrix(field.type)) ...[
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    key: ValueKey('options-${field.draftId}-${field.type}'),
                    initialValue: field.options.join('\n'),
                    enabled: enabled,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: context.l10n.t('options'),
                      helperText: context.l10n.t('optionsHelper'),
                    ),
                    onChanged: (value) => onChanged(
                      field.copyWith(
                        options: value
                            .split('\n')
                            .map((item) => item.trim())
                            .where((item) => item.isNotEmpty)
                            .toList(growable: false),
                      ),
                    ),
                  ),
                ],
                if (field_ui.fieldTypeUsesRange(field.type)) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _NumberField(
                          label: context.l10n.t('min'),
                          value: field.min,
                          enabled: enabled,
                          onChanged: (value) =>
                              onChanged(field.copyWith(min: value)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _NumberField(
                          label: context.l10n.t('max'),
                          value: field.max,
                          enabled: enabled,
                          onChanged: (value) =>
                              onChanged(field.copyWith(max: value)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _NumberField(
                          label: context.l10n.t('step'),
                          value: field.step,
                          enabled: enabled,
                          onChanged: (value) =>
                              onChanged(field.copyWith(step: value)),
                        ),
                      ),
                    ],
                  ),
                ],
                if (fieldTypeCanScore(field.type)) ...[
                  const SizedBox(height: AppSpacing.xs),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: field.scoringEnabled && formScoringEnabled,
                    onChanged: enabled && formScoringEnabled
                        ? (value) =>
                            onChanged(field.copyWith(scoringEnabled: value))
                        : null,
                    title: Text(context.l10n.t('enableFieldScoring')),
                    subtitle: formScoringEnabled
                        ? null
                        : Text(context.l10n.t('enableFormScoringFirst')),
                  ),
                  if (field.scoringEnabled && formScoringEnabled)
                    Row(
                      children: [
                        Expanded(
                          child: _NumberField(
                            label: context.l10n.t('maxScore'),
                            value: field.maxScore,
                            enabled: enabled,
                            onChanged: (value) => onChanged(
                                field.copyWith(maxScore: value ?? 1)),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _NumberField(
                            label: context.l10n.t('weight'),
                            value: field.weight,
                            enabled: enabled,
                            onChanged: (value) => onChanged(
                                field.copyWith(weight: value ?? 1)),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagInput extends StatefulWidget {
  const _TagInput({required this.enabled, required this.tags, required this.onChanged});

  final bool enabled;
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<_TagInput> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final future = ref.watch(formsRepositoryProvider).listFormTags(search: _query.trim().isEmpty ? null : _query.trim());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              enabled: widget.enabled,
              decoration: InputDecoration(
                labelText: context.l10n.t('tags'),
                helperText: context.l10n.t('tagsHelper'),
                prefixIcon: const Icon(Icons.sell_outlined),
                suffixIcon: IconButton(
                  tooltip: context.l10n.t('add'),
                  onPressed: widget.enabled ? _addCurrent : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
              onChanged: (value) => setState(() => _query = value),
              onSubmitted: (_) => _addCurrent(),
            ),
            if (widget.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in widget.tags)
                    InputChip(
                      label: Text(tag),
                      onDeleted: widget.enabled ? () => _remove(tag) : null,
                    ),
                ],
              ),
            ],
            FutureBuilder<List<String>>(
              future: future,
              builder: (context, snapshot) {
                final suggestions = (snapshot.data ?? const <String>[])
                    .where((tag) => !widget.tags.contains(tag))
                    .take(8)
                    .toList(growable: false);
                if (suggestions.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in suggestions)
                        ActionChip(
                          label: Text(tag),
                          avatar: const Icon(Icons.sell_outlined, size: 16),
                          onPressed: widget.enabled ? () => _add(tag) : null,
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _addCurrent() {
    _add(_controller.text);
    _controller.clear();
    setState(() => _query = '');
  }

  void _add(String value) {
    final clean = value.trim().replaceFirst(RegExp(r'^#+'), '').toLowerCase();
    if (clean.isEmpty || widget.tags.contains(clean)) return;
    widget.onChanged([...widget.tags, clean]);
  }

  void _remove(String value) {
    widget.onChanged(widget.tags.where((tag) => tag != value).toList(growable: false));
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome_rounded,
                color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.t('modernFormBuilder'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.t('modernFormBuilderSubtitle'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle, required this.child, this.trailing});

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.template, required this.selected, required this.enabled, required this.onTap});

  final FormTemplatePreset template;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // On compact screens use full-width tiles (one per row); on larger
    // screens fall back to a fixed compact width that wraps nicely.
    final compact = context.isCompactWidth;
    final tileWidth = compact ? double.infinity : 180.0;
    return SizedBox(
      width: tileWidth,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.dashboard_customize_outlined,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _templateName(context, template.type),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                _templateSubtitle(context, template.type),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFields extends StatelessWidget {
  const _EmptyFields();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        children: [
          Icon(Icons.add_task_rounded,
              size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.t('noFieldsYet'),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            context.l10n.t('addFieldsPicker'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldPickerSheet extends StatelessWidget {
  const _FieldPickerSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.84,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(context.l10n.t('chooseField'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            for (final category in field_ui.FieldTypeCategory.values) ...[
              ListTile(
                leading: Icon(_categoryIcon(category)),
                title: Text(category.localizedLabel(context), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final info in field_ui.fieldTypeCatalog.where((item) => item.category == category))
                    ActionChip(
                      avatar: Icon(info.icon, size: 18),
                      label: Text(info.localizedLabel(context)),
                      onPressed: () => Navigator.of(context).pop(info.type),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

class _EnumDropdown<T> extends StatelessWidget {
  const _EnumDropdown({required this.label, required this.value, required this.values, required this.labelFor, required this.onChanged});

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final item in values) DropdownMenuItem<T>(value: item, child: Text(labelFor(item))),
      ],
      onChanged: onChanged == null ? null : (value) {
        if (value != null) onChanged!(value);
      },
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.value, required this.enabled, required this.onChanged});

  final String label;
  final double? value;
  final bool enabled;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      onChanged: (value) => onChanged(value.trim().isEmpty ? null : double.tryParse(value)),
    );
  }
}


String _templateName(BuildContext context, FormTemplateType type) => switch (type) {
      FormTemplateType.blank => context.l10n.t('template.blank'),
      FormTemplateType.feedbackSurvey => context.l10n.t('template.feedbackSurvey'),
      FormTemplateType.quiz => context.l10n.t('template.quiz'),
      FormTemplateType.registration => context.l10n.t('template.registration'),
      FormTemplateType.consent => context.l10n.t('template.consent'),
      FormTemplateType.riskAssessment => context.l10n.t('template.riskAssessment'),
    };

String _templateSubtitle(BuildContext context, FormTemplateType type) => switch (type) {
      FormTemplateType.blank => context.l10n.t('template.blank.subtitle'),
      FormTemplateType.feedbackSurvey => context.l10n.t('template.feedbackSurvey.subtitle'),
      FormTemplateType.quiz => context.l10n.t('template.quiz.subtitle'),
      FormTemplateType.registration => context.l10n.t('template.registration.subtitle'),
      FormTemplateType.consent => context.l10n.t('template.consent.subtitle'),
      FormTemplateType.riskAssessment => context.l10n.t('template.riskAssessment.subtitle'),
    };

IconData _categoryIcon(field_ui.FieldTypeCategory category) {
  return switch (category) {
    field_ui.FieldTypeCategory.essentials => Icons.text_fields_rounded,
    field_ui.FieldTypeCategory.choices => Icons.checklist_rounded,
    field_ui.FieldTypeCategory.ratings => Icons.star_rate_rounded,
    field_ui.FieldTypeCategory.layout => Icons.view_agenda_rounded,
    field_ui.FieldTypeCategory.advanced => Icons.tune_rounded,
  };
}

String _localizedCreateFormError(BuildContext context, String message) {
  final trimmed = message.trim();
  final lower = trimmed.toLowerCase();
  if (lower.contains('permission') || lower.contains('forbidden') || lower.contains('access')) {
    return context.l10n.t('permissionMessage');
  }
  if (lower.contains('validation') || lower.contains('invalid') || lower.contains('required')) {
    return context.l10n.t('fieldRequired');
  }
  if (lower.contains('token') || lower.contains('unauthorized') || lower.contains('expired')) {
    return context.l10n.t('sessionExpiredMessage');
  }
  if (lower.contains('rate')) {
    return context.l10n.t('rateLimited');
  }
  return trimmed.isEmpty ? context.l10n.t('somethingWentWrong') : trimmed;
}
