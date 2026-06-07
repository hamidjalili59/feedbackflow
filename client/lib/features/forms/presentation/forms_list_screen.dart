import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/forms/form_answer_draft_store.dart';
import '../../../data/dto/dto.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/theme/app_breakpoints.dart';
import '../../../presentation/theme/app_spacing.dart';
import '../../../presentation/widgets/app_chrome.dart';
import '../../../presentation/widgets/app_shell.dart';
import '../../../presentation/widgets/error_panel.dart';
import '../../../presentation/widgets/skeletons.dart';

class FormsListScreen extends ConsumerStatefulWidget {
  const FormsListScreen({super.key});

  @override
  ConsumerState<FormsListScreen> createState() => _FormsListScreenState();
}

class _FormsListScreenState extends ConsumerState<FormsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  String _tag = '';
  String _sortBy = 'updated_at';
  SortOrder _sortOrder = SortOrder.desc;

  @override
  void dispose() {
    _searchController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formsAsync = ref.watch(formsControllerProvider);
    final authSession = ref.watch(authControllerProvider).asData?.value;
    final canCreate = _canCreateForms(authSession);
    final parentMode = authSession?.user.primaryRole == UserRole.parent;
    final compact = context.isCompactWidth;
    return AppShell(
      selected: AppDestination.forms,
      showNavigation: !parentMode,
      appBar: AdaptiveAppBar(
        title: Text(context.l10n.t('forms')),
        leading: parentMode
            ? const Padding(
                padding: EdgeInsetsDirectional.only(start: 8),
                child: AppBackButton(fallbackLocation: '/dashboard'),
              )
            : null,
        primaryAction: canCreate
            ? Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: compact
                    ? IconButton.filledTonal(
                        tooltip: context.l10n.t('newForm'),
                        onPressed: () => context.push('/forms/new'),
                        icon: const Icon(Icons.add_rounded),
                      )
                    : FilledButton.icon(
                        onPressed: () => context.push('/forms/new'),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(context.l10n.t('newForm')),
                      ),
              )
            : null,
      ),
      floatingActionButton: compact && canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/forms/new'),
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.t('create')),
            )
          : null,
      body: formsAsync.when(
        loading: () => const _FormsListSkeleton(),
        error: (error, stackTrace) => ErrorPanel(
          error: error,
          titleOverride: context.l10n.t('couldNotLoadForms'),
          onRetry: () => ref.read(formsControllerProvider.notifier).refresh(),
          onSignIn: () => context.go('/login'),
        ),
        data: (response) {
          final forms = response.data ?? const <FormSummaryDto>[];
          final pagination = response.meta?.pagination;
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(formsControllerProvider.notifier).refresh(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.contentMax,
                ),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    compact ? 96 : AppSpacing.xxl,
                  ),
                  children: [
                    _FormsFilterBar(
                      searchController: _searchController,
                      categoryController: _categoryController,
                      selectedTag: _tag,
                      sortBy: _sortBy,
                      sortOrder: _sortOrder,
                      onTagChanged: (value) {
                        setState(() => _tag = value);
                        _applyFilters();
                      },
                      onSortByChanged: (value) {
                        setState(() => _sortBy = value);
                        _applyFilters();
                      },
                      onSortOrderChanged: (value) {
                        setState(() => _sortOrder = value);
                        _applyFilters();
                      },
                      onApply: _applyFilters,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (forms.isEmpty)
                      _EmptyForms(canCreate: canCreate)
                    else
                      for (final form in forms)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _FormCard(
                            form: form,
                            onTap: () {
                              final submissionId = form.mySubmissionId;
                              final destination =
                                  submissionId != null &&
                                      submissionId.trim().isNotEmpty
                                  ? '/forms/${form.id}?submission_id=${Uri.encodeComponent(submissionId)}'
                                  : '/forms/${form.id}';
                              context.push(destination);
                            },
                          ),
                        ),
                    if (pagination != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      _PaginationBar(
                        pagination: pagination,
                        onPage: (page) => ref
                            .read(formsControllerProvider.notifier)
                            .goToPage(page),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _applyFilters() {
    ref
        .read(formsControllerProvider.notifier)
        .applyFilters(
          search: _searchController.text,
          category: _categoryController.text,
          tag: _tag,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
        );
  }
}

class _FormsFilterBar extends StatefulWidget {
  const _FormsFilterBar({
    required this.searchController,
    required this.categoryController,
    required this.selectedTag,
    required this.sortBy,
    required this.sortOrder,
    required this.onTagChanged,
    required this.onSortByChanged,
    required this.onSortOrderChanged,
    required this.onApply,
  });

  final TextEditingController searchController;
  final TextEditingController categoryController;
  final String selectedTag;
  final String sortBy;
  final SortOrder sortOrder;
  final ValueChanged<String> onTagChanged;
  final ValueChanged<String> onSortByChanged;
  final ValueChanged<SortOrder> onSortOrderChanged;
  final VoidCallback onApply;

  @override
  State<_FormsFilterBar> createState() => _FormsFilterBarState();
}

class _FormsFilterBarState extends State<_FormsFilterBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompactWidth;
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Always visible: search.
          TextField(
            controller: widget.searchController,
            decoration: InputDecoration(
              labelText: context.l10n.t('search'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: compact
                  ? IconButton(
                      tooltip: _expanded
                          ? context.l10n.t('hideFilters')
                          : context.l10n.t('showFilters'),
                      icon: Icon(
                        _expanded ? Icons.tune_rounded : Icons.tune_outlined,
                      ),
                      onPressed: () => setState(() => _expanded = !_expanded),
                    )
                  : null,
            ),
            onSubmitted: (_) => widget.onApply(),
          ),
          if (compact && !_expanded)
            const SizedBox.shrink()
          else ...[
            const SizedBox(height: AppSpacing.sm),
            if (compact)
              _CompactFilters(
                categoryController: widget.categoryController,
                selectedTag: widget.selectedTag,
                sortBy: widget.sortBy,
                sortOrder: widget.sortOrder,
                onTagChanged: widget.onTagChanged,
                onSortByChanged: widget.onSortByChanged,
                onSortOrderChanged: widget.onSortOrderChanged,
                onApply: widget.onApply,
              )
            else
              _WideFilters(
                categoryController: widget.categoryController,
                selectedTag: widget.selectedTag,
                sortBy: widget.sortBy,
                sortOrder: widget.sortOrder,
                onTagChanged: widget.onTagChanged,
                onSortByChanged: widget.onSortByChanged,
                onSortOrderChanged: widget.onSortOrderChanged,
                onApply: widget.onApply,
              ),
          ],
        ],
      ),
    );
  }
}

class _WideFilters extends StatelessWidget {
  const _WideFilters({
    required this.categoryController,
    required this.selectedTag,
    required this.sortBy,
    required this.sortOrder,
    required this.onTagChanged,
    required this.onSortByChanged,
    required this.onSortOrderChanged,
    required this.onApply,
  });

  final TextEditingController categoryController;
  final String selectedTag;
  final String sortBy;
  final SortOrder sortOrder;
  final ValueChanged<String> onTagChanged;
  final ValueChanged<String> onSortByChanged;
  final ValueChanged<SortOrder> onSortOrderChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: context.l10n.t('category'),
                  prefixIcon: const Icon(Icons.folder_outlined),
                ),
                onSubmitted: (_) => onApply(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _TagSuggestionFilter(
                selectedTag: selectedTag,
                onChanged: onTagChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: sortBy,
                decoration: InputDecoration(labelText: context.l10n.t('sort')),
                items: _sortItems(context),
                onChanged: (value) {
                  if (value != null) onSortByChanged(value);
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SegmentedButton<SortOrder>(
              segments: [
                ButtonSegment(
                  value: SortOrder.desc,
                  icon: const Icon(Icons.south_rounded),
                  label: Text(context.l10n.t('desc')),
                ),
                ButtonSegment(
                  value: SortOrder.asc,
                  icon: const Icon(Icons.north_rounded),
                  label: Text(context.l10n.t('asc')),
                ),
              ],
              selected: {sortOrder},
              onSelectionChanged: (values) => onSortOrderChanged(values.first),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.tune_rounded),
              label: Text(context.l10n.t('apply')),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactFilters extends StatelessWidget {
  const _CompactFilters({
    required this.categoryController,
    required this.selectedTag,
    required this.sortBy,
    required this.sortOrder,
    required this.onTagChanged,
    required this.onSortByChanged,
    required this.onSortOrderChanged,
    required this.onApply,
  });

  final TextEditingController categoryController;
  final String selectedTag;
  final String sortBy;
  final SortOrder sortOrder;
  final ValueChanged<String> onTagChanged;
  final ValueChanged<String> onSortByChanged;
  final ValueChanged<SortOrder> onSortOrderChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: categoryController,
          decoration: InputDecoration(
            labelText: context.l10n.t('category'),
            prefixIcon: const Icon(Icons.folder_outlined),
          ),
          onSubmitted: (_) => onApply(),
        ),
        const SizedBox(height: AppSpacing.sm),
        _TagSuggestionFilter(selectedTag: selectedTag, onChanged: onTagChanged),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: sortBy,
          decoration: InputDecoration(labelText: context.l10n.t('sort')),
          items: _sortItems(context),
          onChanged: (value) {
            if (value != null) onSortByChanged(value);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<SortOrder>(
          segments: [
            ButtonSegment(
              value: SortOrder.desc,
              icon: const Icon(Icons.south_rounded),
              label: Text(context.l10n.t('desc')),
            ),
            ButtonSegment(
              value: SortOrder.asc,
              icon: const Icon(Icons.north_rounded),
              label: Text(context.l10n.t('asc')),
            ),
          ],
          selected: {sortOrder},
          onSelectionChanged: (values) => onSortOrderChanged(values.first),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          onPressed: onApply,
          icon: const Icon(Icons.tune_rounded),
          label: Text(context.l10n.t('apply')),
        ),
      ],
    );
  }
}

List<DropdownMenuItem<String>> _sortItems(BuildContext context) {
  return [
    DropdownMenuItem(
      value: 'updated_at',
      child: Text(context.l10n.t('updated')),
    ),
    DropdownMenuItem(
      value: 'created_at',
      child: Text(context.l10n.t('created')),
    ),
    DropdownMenuItem(value: 'title', child: Text(context.l10n.t('title'))),
    DropdownMenuItem(
      value: 'category',
      child: Text(context.l10n.t('category')),
    ),
    DropdownMenuItem(
      value: 'submissions_count',
      child: Text(context.l10n.t('submissions')),
    ),
  ];
}

class _TagSuggestionFilter extends ConsumerWidget {
  const _TagSuggestionFilter({
    required this.selectedTag,
    required this.onChanged,
  });

  final String selectedTag;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<String>>(
      future: ref.watch(formsRepositoryProvider).listFormTags(),
      builder: (context, snapshot) {
        final tags = snapshot.data ?? const <String>[];
        return DropdownButtonFormField<String>(
          initialValue: selectedTag.isEmpty ? '' : selectedTag,
          decoration: InputDecoration(labelText: context.l10n.t('tags')),
          items: [
            DropdownMenuItem(value: '', child: Text(context.l10n.t('all'))),
            for (final tag in tags)
              DropdownMenuItem(value: tag, child: Text(tag)),
          ],
          onChanged: (value) => onChanged(value ?? ''),
        );
      },
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.pagination, required this.onPage});

  final PaginationMeta pagination;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: pagination.hasPrevious
                ? () => onPage(pagination.page - 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${pagination.page} / ${pagination.totalPages == 0 ? 1 : pagination.totalPages}',
            ),
          ),
          IconButton(
            onPressed: pagination.hasNext
                ? () => onPage(pagination.page + 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends ConsumerWidget {
  const _FormCard({required this.form, required this.onTap});

  final FormSummaryDto form;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answered =
        form.mySubmissionId != null && form.mySubmissionId!.trim().isNotEmpty;
    return FutureBuilder<FormAnswerDraft?>(
      future: answered
          ? Future<FormAnswerDraft?>.value(null)
          : ref
                .watch(formAnswerDraftStoreProvider)
                .read(FormAnswerDraftStore.formKey(form.id)),
      builder: (context, snapshot) {
        final draft = snapshot.data;
        final progress = answered ? 1.0 : draft?.completion ?? 0.0;
        return _FormCardContent(
          form: form,
          progress: progress,
          answered: answered,
          onTap: onTap,
        );
      },
    );
  }
}

class _FormCardContent extends StatelessWidget {
  const _FormCardContent({
    required this.form,
    required this.progress,
    required this.answered,
    required this.onTap,
  });

  final FormSummaryDto form;
  final double progress;
  final bool answered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final compact = context.isCompactWidth;
    final percent = (progress * 100).round().clamp(0, 100);
    final active = progress > 0 && progress < 1;
    return SoftCard(
      onTap: onTap,
      padding: EdgeInsets.fromLTRB(
        compact ? AppSpacing.sm : AppSpacing.md,
        compact ? AppSpacing.sm : 18,
        compact ? AppSpacing.sm : AppSpacing.md,
        compact ? AppSpacing.sm : 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: answered
                      ? scheme.primaryContainer
                      : active
                      ? scheme.secondaryContainer.withValues(alpha: 0.88)
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.84),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  answered
                      ? Icons.check_rounded
                      : active
                      ? Icons.edit_note_rounded
                      : Icons.article_outlined,
                  color: answered
                      ? scheme.onPrimaryContainer
                      : active
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _formSubtitle(context, form),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$percent%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(appForwardIcon(context), color: scheme.onSurfaceVariant),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 7,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: scheme.surfaceContainerHighest,
                color: answered
                    ? scheme.primary
                    : active
                    ? scheme.secondary
                    : scheme.primary.withValues(alpha: 0.34),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _StatusBadge(status: form.status.toJson()),
                    if (answered)
                      _MetaChip(
                        icon: Icons.check_circle_rounded,
                        label: context.l10n.t('submittedReviewTitle'),
                        translate: false,
                      )
                    else if (active)
                      _MetaChip(
                        icon: Icons.schedule_rounded,
                        label: context.l10n.t('status.inProgress'),
                        translate: false,
                      ),
                    _MetaChip(
                      icon: Icons.how_to_reg_outlined,
                      label: context.l10n.countSubmissions(
                        form.submissionsCount,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((form.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              form.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (!compact &&
              (((form.category ?? '').trim().isNotEmpty) ||
                  (form.tags ?? const <String>[]).isNotEmpty)) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if ((form.category ?? '').trim().isNotEmpty)
                  _MetaChip(
                    icon: Icons.folder_outlined,
                    label: form.category!,
                    translate: false,
                  ),
                for (final tag in (form.tags ?? const <String>[]).take(3))
                  _MetaChip(
                    icon: Icons.sell_outlined,
                    label: tag,
                    translate: false,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _formSubtitle(BuildContext context, FormSummaryDto form) {
  final category = (form.category ?? '').trim();
  if (category.isNotEmpty) return '$category - ${_dateLabel(form.updatedAt)}';
  return '${context.l10n.t('updated')} - ${_dateLabel(form.updatedAt)}';
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.l10n.enumLabel(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onTertiaryContainer,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.translate = true,
  });

  final IconData icon;
  final String label;
  final bool translate;

  @override
  Widget build(BuildContext context) {
    return AppInfoChip(
      icon: icon,
      label: translate ? context.l10n.enumLabel(label) : label,
    );
  }
}

class _EmptyForms extends StatelessWidget {
  const _EmptyForms({required this.canCreate});

  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 48),
          PageHeaderCard(
            icon: Icons.assignment_outlined,
            title: context.l10n.t('createFirstForm'),
            subtitle: context.l10n.t('createFirstFormSubtitle'),
            trailing: canCreate
                ? FilledButton.icon(
                    onPressed: () => context.push('/forms/new'),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(context.l10n.t('create')),
                  )
                : null,
          ),
          const SizedBox(height: 18),
          SoftCard(
            child: Column(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.t('getStartedTitle'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.t('getStartedSubtitle'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

String _dateLabel(DateTime date) {
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

class _FormsListSkeleton extends StatelessWidget {
  const _FormsListSkeleton();

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompactWidth;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMax),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            compact ? 96 : AppSpacing.xxl,
          ),
          children: const [
            SkeletonBlock(height: 64, radius: 24),
            SizedBox(height: AppSpacing.sm),
            FormCardSkeleton(),
            SizedBox(height: AppSpacing.sm),
            FormCardSkeleton(),
            SizedBox(height: AppSpacing.sm),
            FormCardSkeleton(),
          ],
        ),
      ),
    );
  }
}

bool _canCreateForms(AuthSession? session) {
  final role = session?.user.primaryRole;
  return role == UserRole.teacher ||
      role == UserRole.manager ||
      role == UserRole.admin ||
      role == UserRole.ceo ||
      role == UserRole.superAdmin;
}
