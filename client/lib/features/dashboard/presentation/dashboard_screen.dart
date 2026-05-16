import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../data/dto/dto.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/common/friendly_api_error_message.dart';
import '../../../presentation/theme/app_breakpoints.dart';
import '../../../presentation/theme/app_spacing.dart';
import '../../../presentation/widgets/app_chrome.dart';
import '../../../presentation/widgets/app_shell.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final compact = context.isCompactWidth;
    return AppShell(
      selected: AppDestination.dashboard,
      appBar: AdaptiveAppBar(
        title: Text(context.l10n.t('dashboard')),
      ),
      body: auth.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) =>
                _DashboardError(onLogin: () => context.go('/login')),
        data: (session) {
          if (session == null) {
            return _DashboardError(onLogin: () => context.go('/login'));
          }
          return Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppBreakpoints.contentMax),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  compact ? 96 : AppSpacing.xxl,
                ),
                children: [
                  PageHeaderCard(
                    icon: Icons.dashboard_customize_outlined,
                    title: context.l10n.t('dashboard'),
                    subtitle:
                        '${session.user.displayName} · ${context.l10n.enumLabel(session.user.primaryRole.toJson())}',
                    trailing: compact
                        ? IconButton.filledTonal(
                            tooltip: context.l10n.t('forms'),
                            onPressed: () => context.go('/forms'),
                            icon: const Icon(Icons.article_outlined),
                          )
                        : FilledButton.icon(
                            onPressed: () => context.go('/forms'),
                            icon: const Icon(Icons.article_outlined),
                            label: Text(context.l10n.t('forms')),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _RoleActions(role: session.user.primaryRole),
                  const SizedBox(height: AppSpacing.sm),
                  const _DashboardAnalyticsCard(),
                  const SizedBox(height: AppSpacing.sm),
                  if (_creatableRoles(session.user.primaryRole).isNotEmpty)
                    _CreateUserCard(actorRole: session.user.primaryRole),
                  if (_isManagementRole(session.user.primaryRole)) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const _PendingApprovalCard(),
                    const SizedBox(height: AppSpacing.sm),
                    _UserManagementCard(actorRole: session.user.primaryRole),
                    const SizedBox(height: AppSpacing.sm),
                    const _FormManagementCard(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoleActions extends StatelessWidget {
  const _RoleActions({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final actions = switch (role) {
      UserRole.teacher => [
        _ActionItem(
          Icons.edit_note_rounded,
          context.l10n.t('createForm'),
          '/forms/new',
        ),
        _ActionItem(
          Icons.analytics_outlined,
          context.l10n.t('results'),
          '/forms',
        ),
      ],
      UserRole.manager ||
      UserRole.admin ||
      UserRole.ceo ||
      UserRole.superAdmin => [
        _ActionItem(
          Icons.fact_check_outlined,
          context.l10n.t('manageForms'),
          '/forms',
        ),
        _ActionItem(
          Icons.person_add_alt_rounded,
          context.l10n.t('addUser'),
          null,
        ),
      ],
      UserRole.parent || UserRole.student => [
        _ActionItem(
          Icons.assignment_turned_in_outlined,
          context.l10n.t('answerForms'),
          '/forms',
        ),
      ],
      _ => [
        _ActionItem(Icons.login_rounded, context.l10n.t('signIn'), '/login'),
      ],
    };
    return SoftCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final action in actions)
            ActionChip(
              avatar: Icon(action.icon, size: 18),
              label: Text(action.label),
              onPressed:
                  action.route == null ? null : () => context.go(action.route!),
            ),
        ],
      ),
    );
  }
}

class _ActionItem {
  const _ActionItem(this.icon, this.label, this.route);

  final IconData icon;
  final String label;
  final String? route;
}

class _DashboardAnalyticsCard extends ConsumerWidget {
  const _DashboardAnalyticsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(dashboardAnalyticsProvider);
    return SoftCard(
      child: analytics.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stackTrace) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CardHeader(
              icon: Icons.monitor_rounded,
              title: context.l10n.t('dashboardAnalytics'),
              action: IconButton(
                tooltip: context.l10n.t('refresh'),
                onPressed: () => ref.invalidate(dashboardAnalyticsProvider),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            const SizedBox(height: 10),
            Text(FriendlyApiErrorMessage.from(error, context: context)),
          ],
        ),
        data: (value) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CardHeader(
              icon: Icons.monitor_rounded,
              title: context.l10n.t('dashboardAnalytics'),
              action: IconButton(
                tooltip: context.l10n.t('refresh'),
                onPressed: () => ref.invalidate(dashboardAnalyticsProvider),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _DashboardMetric(context.l10n.t('totalForms'), '${value.totalForms}', Icons.article_outlined),
                _DashboardMetric(context.l10n.t('publishedForms'), '${value.publishedForms}', Icons.public_rounded),
                _DashboardMetric(context.l10n.t('totalUsers'), '${value.totalUsers}', Icons.people_alt_outlined),
                _DashboardMetric(context.l10n.t('totalSubmissions'), '${value.totalSubmissions}', Icons.inbox_rounded),
                _DashboardMetric(context.l10n.t('participationRate'), '${value.participationRate.toStringAsFixed(1)}%', Icons.how_to_reg_rounded),
                _DashboardMetric(context.l10n.t('todaySubmissions'), '${value.todaySubmissions}', Icons.today_rounded),
                _DashboardMetric(context.l10n.t('weekSubmissions'), '${value.weekSubmissions}', Icons.date_range_rounded),
                _DashboardMetric(context.l10n.t('monthSubmissions'), '${value.monthSubmissions}', Icons.calendar_month_rounded),
              ],
            ),
            const SizedBox(height: 14),
            _TrendLine(points: value.byDay),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 840;
                final panels = [
                  _BreakdownPanel(title: context.l10n.t('genderDistribution'), items: value.genderDistribution),
                  _BreakdownPanel(title: context.l10n.t('respondentModeDistribution'), items: value.respondentModeDistribution),
                  _BreakdownPanel(title: context.l10n.t('userRoleDistribution'), items: value.userRoleDistribution),
                  _BreakdownPanel(title: context.l10n.t('accessCodeDistribution'), items: value.accessCodeDistribution),
                ];
                if (!wide) {
                  return Column(
                    children: [
                      for (final panel in panels) ...[
                        panel,
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                }
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final panel in panels)
                      SizedBox(width: (constraints.maxWidth - 12) / 2, child: panel),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            _TopFormsPanel(forms: value.topForms),
          ],
        ),
      ),
    );
  }
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric(this.title, this.value, this.icon);

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Pick a width that fits 1, 2 or 3 columns depending on parent width.
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        double tileWidth;
        if (available >= 720) {
          tileWidth = (available - 24) / 3;
        } else if (available >= 380) {
          tileWidth = (available - 12) / 2;
        } else {
          tileWidth = available;
        }
        return SizedBox(
          width: tileWidth,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrendLine extends StatelessWidget {
  const _TrendLine({required this.points});

  final List<AnalyticsTimeseriesPointDto> points;

  @override
  Widget build(BuildContext context) {
    final max = points.fold<int>(0, (value, point) => point.count > value ? point.count : value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.t('submissionTrend'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final point in points.take(30))
                Expanded(
                  child: Tooltip(
                    message: '${point.date}: ${point.count}',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FractionallySizedBox(
                        heightFactor: max == 0 ? 0.02 : (point.count / max).clamp(0.02, 1.0),
                        alignment: Alignment.bottomCenter,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BreakdownPanel extends StatelessWidget {
  const _BreakdownPanel({required this.title, required this.items});

  final String title;
  final List<AnalyticsBucketDto> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(context.l10n.t('noDataYet'))
          else
            for (final item in items.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(_localizedBucket(context, item.key, item.label))),
                        Text('${item.count}  ${item.percentage.toStringAsFixed(0)}%'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: (item.percentage / 100).clamp(0, 1)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _TopFormsPanel extends StatelessWidget {
  const _TopFormsPanel({required this.forms});

  final List<DashboardTopFormDto> forms;

  @override
  Widget build(BuildContext context) {
    if (forms.isEmpty) return Text(context.l10n.t('noFormsYet'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.t('topForms'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        for (final form in forms)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.leaderboard_rounded),
            title: Text(form.title, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${context.l10n.t('totalSubmissions')}: ${form.submissions}'),
            onTap: () => context.go('/forms/${form.formId}/results'),
          ),
      ],
    );
  }
}

class _CreateUserCard extends ConsumerStatefulWidget {
  const _CreateUserCard({required this.actorRole});

  final UserRole actorRole;

  @override
  ConsumerState<_CreateUserCard> createState() => _CreateUserCardState();
}

class _CreateUserCardState extends ConsumerState<_CreateUserCard> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late UserRole _role = _creatableRoles(widget.actorRole).first;
  String? _gender;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roles = _creatableRoles(widget.actorRole);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.t('addUser'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: context.l10n.t('displayName'),
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phone,
            decoration: InputDecoration(
              labelText: context.l10n.t('phone'),
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _email,
            decoration: InputDecoration(
              labelText: context.l10n.t('email'),
              prefixIcon: const Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 10),
          _GenderDropdown(
            value: _gender,
            onChanged: (value) => setState(() => _gender = value),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: context.l10n.t('password'),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<UserRole>(
            initialValue: _role,
            decoration: InputDecoration(labelText: context.l10n.t('role')),
            items: [
              for (final role in roles)
                DropdownMenuItem(
                  value: role,
                  child: Text(context.l10n.enumLabel(role.toJson())),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _role = value);
            },
          ),
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: _saving ? null : _create,
              icon:
                  _saving
                      ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.person_add_alt_rounded),
              label: Text(
                _saving ? context.l10n.t('saving') : context.l10n.t('addUser'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(usersRepositoryProvider)
          .createUser(
            request: CreateUserRequest(
              phone: _phone.text.trim(),
              email: _email.text.trim().isEmpty ? null : _email.text.trim(),
              displayName: _name.text.trim(),
              gender: _gender,
              password: _password.text,
              primaryRole: _role,
            ),
          );
      _name.clear();
      _phone.clear();
      _email.clear();
      _password.clear();
      setState(() => _gender = null);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.t('userCreated'))),
        );
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
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _UserManagementCard extends ConsumerStatefulWidget {
  const _UserManagementCard({required this.actorRole});

  final UserRole actorRole;

  @override
  ConsumerState<_UserManagementCard> createState() =>
      _UserManagementCardState();
}

class _UserManagementCardState extends ConsumerState<_UserManagementCard> {
  final _search = TextEditingController();
  int _page = 1;
  late Future<ListResponse<UserSummaryDto>> _future = _load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            icon: Icons.manage_accounts_outlined,
            title: context.l10n.t('userManagement'),
            action: IconButton(
              tooltip: context.l10n.t('refresh'),
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: context.l10n.t('search'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  _page = 1;
                  _refresh();
                },
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
            onSubmitted: (_) {
              _page = 1;
              _refresh();
            },
          ),
          const SizedBox(height: 12),
          FutureBuilder<ListResponse<UserSummaryDto>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  FriendlyApiErrorMessage.from(
                    snapshot.error!,
                    context: context,
                  ),
                );
              }
              final users = snapshot.data?.data ?? const <UserSummaryDto>[];
              if (users.isEmpty) {
                return Text(context.l10n.t('noUsersFound'));
              }
              final meta = snapshot.data?.meta?.pagination;
              return Column(
                children: [
                  for (final user in users)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text(
                          user.displayName.characters.first.toUpperCase(),
                        ),
                      ),
                      title: Text(
                        user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${context.l10n.enumLabel(user.primaryRole.toJson())} · ${user.phone}${user.email == null ? '' : ' · ${user.email}'}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          Chip(label: Text(user.status)),
                          IconButton(
                            tooltip: context.l10n.t('edit'),
                            onPressed: () => _edit(user),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed:
                            _page > 1 ? () => _goToPage(_page - 1) : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Text('${context.l10n.t('page')} $_page'),
                      IconButton(
                        onPressed:
                            meta != null && _page < meta.totalPages
                                ? () => _goToPage(_page + 1)
                                : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<ListResponse<UserSummaryDto>> _load() {
    return ref
        .read(usersRepositoryProvider)
        .listUsers(
          page: _page,
          pageSize: 8,
          search: _search.text.trim().isEmpty ? null : _search.text.trim(),
          sortBy: 'display_name',
          sortOrder: SortOrder.asc,
        );
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  void _goToPage(int page) {
    setState(() {
      _page = page;
      _future = _load();
    });
  }

  Future<void> _edit(UserSummaryDto user) async {
    final result = await showDialog<UpdateUserRequest>(
      context: context,
      builder:
          (context) => _EditUserDialog(
            user: user,
            roles: _creatableRoles(widget.actorRole),
          ),
    );
    if (result == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(usersRepositoryProvider)
          .updateUser(id: user.id, request: result);
      _refresh();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.t('userUpdated'))),
        );
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
    }
  }
}

class _EditUserDialog extends StatefulWidget {
  const _EditUserDialog({required this.user, required this.roles});

  final UserSummaryDto user;
  final List<UserRole> roles;

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late UserRole _role = widget.user.primaryRole;
  late String _status = widget.user.status;
  late String? _gender = widget.user.gender;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.displayName);
    _phone = TextEditingController(text: widget.user.phone);
    _email = TextEditingController(text: widget.user.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roles = {...widget.roles, widget.user.primaryRole}.toList();
    final maxWidth =
        MediaQuery.sizeOf(context).width.clamp(280.0, 460.0);
    return AlertDialog(
      title: Text(context.l10n.t('editUser')),
      content: SizedBox(
        width: maxWidth,
        child: SingleChildScrollView(
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
                controller: _phone,
                decoration:
                    InputDecoration(labelText: context.l10n.t('phone')),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _email,
                decoration:
                    InputDecoration(labelText: context.l10n.t('email')),
              ),
              const SizedBox(height: AppSpacing.xs),
              _GenderDropdown(
                value: _gender,
                onChanged: (value) => setState(() => _gender = value),
              ),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration:
                    InputDecoration(labelText: context.l10n.t('role')),
                items: [
                  for (final role in roles)
                    DropdownMenuItem(
                      value: role,
                      child:
                          Text(context.l10n.enumLabel(role.toJson())),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _role = value);
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration:
                    InputDecoration(labelText: context.l10n.t('status')),
                items: [
                  for (final status in const [
                    'active',
                    'inactive',
                    'suspended',
                  ])
                    DropdownMenuItem(
                      value: status,
                      child: Text(context.l10n.t(status)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
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
            Navigator.pop(
              context,
              UpdateUserRequest(
                displayName: _name.text.trim(),
                phone: _phone.text.trim(),
                email: _email.text.trim().isEmpty ? null : _email.text.trim(),
                primaryRole: _role,
                gender: _gender,
                status: _status,
              ),
            );
          },
          child: Text(context.l10n.t('save')),
        ),
      ],
    );
  }
}

class _PendingApprovalCard extends ConsumerWidget {
  const _PendingApprovalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref
        .watch(formsRepositoryProvider)
        .listForms(page: 1, pageSize: 50, sortBy: 'updated_at', sortOrder: SortOrder.desc);
    return SoftCard(
      child: FutureBuilder<ListResponse<FormSummaryDto>>(
        future: future,
        builder: (context, snapshot) {
          final allForms = snapshot.data?.data ?? const <FormSummaryDto>[];
          final pending = allForms
              .where((f) => f.status == FormStatus.pendingReview)
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardHeader(
                icon: Icons.pending_actions_rounded,
                title: context.l10n.t('pendingApprovalForms'),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (pending.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    context.l10n.t('noFormsAwaitingApproval'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              else
                for (final form in pending)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.hourglass_top_rounded),
                    title: Text(
                      form.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${context.l10n.enumLabel(form.visibilityMode.toJson())} · ${context.l10n.countSubmissions(form.submissionsCount)}',
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        FilledButton.tonal(
                          onPressed: () => context.go('/forms/${form.id}/publish'),
                          child: Text(context.l10n.t('approve')),
                        ),
                      ],
                    ),
                    onTap: () => context.go('/forms/${form.id}'),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _FormManagementCard extends ConsumerWidget {
  const _FormManagementCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref
        .watch(formsRepositoryProvider)
        .listForms(
          page: 1,
          pageSize: 5,
          sortBy: 'updated',
          sortOrder: SortOrder.desc,
        );
    return SoftCard(
      child: FutureBuilder<ListResponse<FormSummaryDto>>(
        future: future,
        builder: (context, snapshot) {
          final forms = snapshot.data?.data ?? const <FormSummaryDto>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardHeader(
                icon: Icons.fact_check_outlined,
                title: context.l10n.t('formManagement'),
                action: TextButton.icon(
                  onPressed: () => context.go('/forms'),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(context.l10n.t('all')),
                ),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.hasError)
                Text(
                  FriendlyApiErrorMessage.from(
                    snapshot.error!,
                    context: context,
                  ),
                )
              else if (forms.isEmpty)
                Text(context.l10n.t('noFormsYet'))
              else
                for (final form in forms)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.article_outlined),
                    title: Text(
                      form.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      [
                        if (form.category != null) form.category!,
                        form.status.toJson(),
                      ].join(' · '),
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: context.l10n.t('settings'),
                          onPressed:
                              () => context.go('/forms/${form.id}/settings'),
                          icon: const Icon(Icons.tune_rounded),
                        ),
                        IconButton(
                          tooltip: context.l10n.t('editField'),
                          onPressed: () => context.go('/forms/${form.id}'),
                          icon: const Icon(Icons.edit_note_rounded),
                        ),
                      ],
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _GenderDropdown extends StatelessWidget {
  const _GenderDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: context.l10n.t('gender'),
        prefixIcon: const Icon(Icons.wc_rounded),
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(context.l10n.t('notSpecified')),
        ),
        DropdownMenuItem<String?>(
          value: 'male',
          child: Text(context.l10n.t('male')),
        ),
        DropdownMenuItem<String?>(
          value: 'female',
          child: Text(context.l10n.t('female')),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.title, this.action});

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onLogin,
        icon: const Icon(Icons.login_rounded),
        label: Text(context.l10n.t('signIn')),
      ),
    );
  }
}

List<UserRole> _creatableRoles(UserRole actor) => switch (actor) {
  UserRole.manager ||
  UserRole.admin => const [UserRole.teacher, UserRole.student],
  UserRole.ceo => const [UserRole.teacher, UserRole.student, UserRole.manager],
  UserRole.superAdmin => const [
    UserRole.teacher,
    UserRole.student,
    UserRole.manager,
    UserRole.ceo,
  ],
  _ => const <UserRole>[],
};

bool _isManagementRole(UserRole role) => switch (role) {
  UserRole.manager ||
  UserRole.admin ||
  UserRole.ceo ||
  UserRole.superAdmin => true,
  _ => false,
};

String _localizedBucket(BuildContext context, String key, String fallback) {
  const known = {
    'female',
    'male',
    'other',
    'prefer_not_to_say',
    'anonymous',
    'guest',
    'authenticated',
    'identity_code',
    'teacher',
    'student',
    'manager',
    'admin',
    'ceo',
    'super_admin',
    'parent',
    'no_code',
    'unlabeled_code',
    'unknown',
  };
  return known.contains(key) ? context.l10n.t(key) : fallback;
}
