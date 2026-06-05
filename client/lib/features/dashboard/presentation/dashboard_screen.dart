import 'dart:math' as math;
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../data/dto/dto.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/phone/phone_number_normalizer.dart';
import '../../../presentation/common/friendly_api_error_message.dart';
import '../../../presentation/theme/app_breakpoints.dart';
import '../../../presentation/theme/app_spacing.dart';
import '../../../presentation/theme/app_theme.dart';
import '../../../presentation/widgets/app_chrome.dart';
import '../../../presentation/widgets/app_shell.dart';
import '../../../presentation/widgets/directional_value_text.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, this.initialChildId, this.childProgressId});

  final String? initialChildId;
  final String? childProgressId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const GradientScaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => GradientScaffold(
        body: _DashboardError(onLogin: () => context.go('/login')),
      ),
      data: (session) {
        if (session == null) {
          return GradientScaffold(
            body: _DashboardError(onLogin: () => context.go('/login')),
          );
        }
        if (session.user.primaryRole == UserRole.parent) {
          return GradientScaffold(
            body: _ExperienceDashboard(
              key: ValueKey(
                '${session.user.id}:${childProgressId ?? initialChildId ?? ''}',
              ),
              session: session,
              initialChildId: childProgressId ?? initialChildId,
              parentProgressMode: childProgressId != null,
            ),
          );
        }
        return AppShell(
          selected: AppDestination.dashboard,
          appBar: AdaptiveAppBar(
            title: Text(context.l10n.t('dashboard')),
            primaryAction: IconButton.filledTonal(
              tooltip: context.l10n.t('dashboard.formsTooltip'),
              onPressed: () => context.go('/forms'),
              icon: const Icon(Icons.article_outlined),
            ),
          ),
          body: _ExperienceDashboard(
            key: ValueKey('${session.user.id}:${initialChildId ?? ''}'),
            session: session,
            initialChildId: initialChildId,
          ),
        );
      },
    );
  }
}

class _ParentAppFrame extends StatelessWidget {
  const _ParentAppFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF3F6FA),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final maxWidth = availableWidth < 480
                ? 393.0
                : availableWidth < AppBreakpoints.medium
                ? 640.0
                : 1040.0;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ExperienceDashboard extends ConsumerStatefulWidget {
  const _ExperienceDashboard({
    required this.session,
    this.initialChildId,
    this.parentProgressMode = false,
    super.key,
  });

  final AuthSession session;
  final String? initialChildId;
  final bool parentProgressMode;

  @override
  ConsumerState<_ExperienceDashboard> createState() =>
      _ExperienceDashboardState();
}

class _ExperienceDashboardState extends ConsumerState<_ExperienceDashboard> {
  String _period = 'this_month';
  late String? _selectedChildId = widget.initialChildId;
  int _userListVersion = 0;

  DashboardQueryInput get _query => DashboardQueryInput(
    period: _period,
    compare: 'previous_period',
    childId: _selectedChildId,
    cacheUserId: widget.session.user.id,
  );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dashboardExperienceProvider(_query));
    final compact = context.isCompactWidth;
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _DashboardLoadFallback(
        error: error,
        onRetry: () => ref.invalidate(dashboardExperienceProvider(_query)),
      ),
      data: (dashboard) {
        final role = dashboard.role == UserRole.unknown
            ? widget.session.user.primaryRole
            : dashboard.role;
        if (role == UserRole.parent) {
          return widget.parentProgressMode
              ? _ParentStudentProgressDashboard(
                  dashboard: dashboard,
                  period: _period,
                  onPeriodChanged: (value) => setState(() => _period = value),
                )
              : _ParentHomeDashboard(
                  user: widget.session.user,
                  dashboard: dashboard,
                );
        }
        final management = _isManagementRole(role);
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(dashboardExperienceProvider(_query)),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: ListView(
                padding: EdgeInsets.fromLTRB(18, 8, 18, compact ? 104 : 40),
                children: [
                  _DashboardTopBar(
                    user: widget.session.user,
                    role: role,
                    period: _period,
                    onPeriodChanged: (value) => setState(() => _period = value),
                  ),
                  const SizedBox(height: 16),
                  if (role == UserRole.parent) ...[
                    _ParentChildrenHero(
                      dashboard: dashboard,
                      selectedChildId:
                          dashboard.selectedChildId ?? _selectedChildId,
                      onChildSelected: (childId) {
                        setState(() => _selectedChildId = childId);
                        context.go(
                          '/dashboard?child_id=${Uri.encodeComponent(childId)}',
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _ParentSurveyArea(dashboard: dashboard),
                  ] else if (role == UserRole.student) ...[
                    _StudentHero(
                      dashboard: dashboard,
                      user: widget.session.user,
                    ),
                    const SizedBox(height: 16),
                    _ParentSurveyArea(dashboard: dashboard),
                  ] else if (role == UserRole.teacher) ...[
                    _TeacherHero(dashboard: dashboard),
                    const SizedBox(height: 16),
                    _OperationalCards(dashboard: dashboard, role: role),
                  ] else ...[
                    _ManagementHero(dashboard: dashboard, role: role),
                    const SizedBox(height: 16),
                    _OperationalCards(dashboard: dashboard, role: role),
                  ],
                  const SizedBox(height: 16),
                  _ResponsiveTwoColumn(
                    left: _DynamicMetricsGrid(metrics: dashboard.metrics),
                    right: _SurveyStatusAndCalendar(
                      dashboard: dashboard,
                      cacheUserId: widget.session.user.id,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ResponsiveTwoColumn(
                    left: _LatestSurveysCard(surveys: dashboard.latestSurveys),
                    right: _ActivitiesCard(items: dashboard.activities),
                  ),
                  if (management &&
                      (dashboard.rankings.isNotEmpty ||
                          dashboard.activities.isNotEmpty)) ...[
                    const SizedBox(height: 16),
                    _RankingsAndAlerts(dashboard: dashboard),
                  ],
                  if (management) ...[
                    const SizedBox(height: 16),
                    _ManagementConfigurationRow(role: role),
                    const SizedBox(height: 16),
                    _CreateUserCard(
                      actorRole: role,
                      onCreated: () {
                        setState(() => _userListVersion++);
                        ref.invalidate(dashboardExperienceProvider(_query));
                      },
                    ),
                    const SizedBox(height: 16),
                    const _AudienceGroupsCard(),
                    const SizedBox(height: 16),
                    _UserManagementCard(
                      key: ValueKey('users-$_userListVersion'),
                      actorRole: role,
                    ),
                    const SizedBox(height: 16),
                    const _PendingApprovalCard(),
                    const SizedBox(height: 16),
                    const _FormManagementCard(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ParentHomeDashboard extends StatelessWidget {
  const _ParentHomeDashboard({required this.user, required this.dashboard});

  final UserDetailDto user;
  final DashboardResponseDto2 dashboard;

  @override
  Widget build(BuildContext context) {
    final surveys = dashboard.latestSurveys
        .where((survey) => survey.mySubmissionId == null)
        .take(2)
        .toList();
    final children = dashboard.children;
    final activities = dashboard.activities.take(2).toList();
    return _ParentAppFrame(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final padding = wide
              ? const EdgeInsets.fromLTRB(32, 40, 32, 48)
              : const EdgeInsets.fromLTRB(20, 32, 20, 36);
          return ListView(
            padding: padding,
            children: wide
                ? _buildWideLayout(context, children, surveys, activities)
                : _buildCompactLayout(context, children, surveys, activities),
          );
        },
      ),
    );
  }

  List<Widget> _buildCompactLayout(
    BuildContext context,
    List<ChildProfileDto2> children,
    List<SurveyCardDto2> surveys,
    List<ActivityFeedItemDto2> activities,
  ) {
    return [
      _ParentHomeHeader(user: user),
      const SizedBox(height: 22),
      _ParentChildrenList(
        children: children,
        onChildTap: (child) => _openChildProgress(context, child),
      ),
      const SizedBox(height: 34),
      _ParentNewSurveysSection(surveys: surveys),
      const SizedBox(height: 38),
      _ParentSurveyOverviewSection(summary: dashboard.surveySummary),
      const SizedBox(height: 34),
      _ParentActivitiesSection(activities: activities),
    ];
  }

  List<Widget> _buildWideLayout(
    BuildContext context,
    List<ChildProfileDto2> children,
    List<SurveyCardDto2> surveys,
    List<ActivityFeedItemDto2> activities,
  ) {
    return [
      Column(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: _ParentHomeHeader(user: user),
          ),
          const SizedBox(height: 24),
          _ParentChildrenList(
            children: children,
            onChildTap: (child) => _openChildProgress(context, child),
          ),
        ],
      ),
      const SizedBox(height: 34),
      Row(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: _ParentNewSurveysSection(surveys: surveys)),
          const SizedBox(width: 28),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                _ParentSurveyOverviewSection(summary: dashboard.surveySummary),
                const SizedBox(height: 34),
                _ParentActivitiesSection(activities: activities),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  void _openChildProgress(BuildContext context, ChildProfileDto2 child) {
    context.go('/dashboard/children/${Uri.encodeComponent(child.id)}');
  }
}

class _ParentNewSurveysSection extends StatelessWidget {
  const _ParentNewSurveysSection({required this.surveys});

  final List<SurveyCardDto2> surveys;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ParentSectionHeader(
          title: context.l10n.t('dashboard.newSurvey'),
          actionLabel: context.l10n.t('dashboard.seeAllSurveys'),
          onAction: () => context.go('/forms'),
        ),
        const SizedBox(height: 18),
        if (surveys.isEmpty)
          _ParentEmptyCard(message: context.l10n.t('dashboard.noNewSurveys'))
        else
          for (var i = 0; i < surveys.length; i++) ...[
            _ParentSurveyActionCard(survey: surveys[i]),
            if (i != surveys.length - 1) const SizedBox(height: 22),
          ],
      ],
    );
  }
}

class _ParentSurveyOverviewSection extends StatelessWidget {
  const _ParentSurveyOverviewSection({required this.summary});

  final SurveyStatusSummaryDto2 summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ParentSectionHeader(title: context.l10n.t('dashboard.surveyOverview')),
        const SizedBox(height: 18),
        _ParentSurveyOverview(summary: summary),
      ],
    );
  }
}

class _ParentActivitiesSection extends StatelessWidget {
  const _ParentActivitiesSection({required this.activities});

  final List<ActivityFeedItemDto2> activities;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ParentSectionHeader(
          title: context.l10n.t('dashboard.latestActivities'),
        ),
        const SizedBox(height: 18),
        if (activities.isEmpty)
          _ParentEmptyCard(message: context.l10n.t('dashboard.noActivities'))
        else
          for (final item in activities) _ParentActivityCard(item: item),
      ],
    );
  }
}

class _ParentHomeHeader extends StatelessWidget {
  const _ParentHomeHeader({required this.user});

  final UserDetailDto user;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.go('/profile'),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFFFD8C2),
            backgroundImage: _dashboardAvatarImageProvider(
              _visibleDashboardAvatarUrl(user.profile),
            ),
            child: _visibleDashboardAvatarUrl(user.profile) == null
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _initials(user.displayName).trim(),
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.t('dashboard.parentGreeting'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF747A9A),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user.displayName,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParentChildrenList extends StatelessWidget {
  const _ParentChildrenList({required this.children, required this.onChildTap});

  final List<ChildProfileDto2> children;
  final ValueChanged<ChildProfileDto2> onChildTap;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return _ParentEmptyCard(
        message: context.l10n.t('dashboard.noChildrenForParent'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          _ParentStudentCard(
            child: children[i],
            onProfileTap: () => onChildTap(children[i]),
            onStudentTap: () => onChildTap(children[i]),
          ),
          if (i != children.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ParentStudentCard extends StatelessWidget {
  const _ParentStudentCard({
    required this.child,
    required this.onProfileTap,
    required this.onStudentTap,
  });

  final ChildProfileDto2 child;
  final VoidCallback onProfileTap;
  final VoidCallback onStudentTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onStudentTap,
      child: _ParentWhiteCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Flex(
          direction: compact ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: compact
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.center,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onProfileTap,
                icon: Icon(appBackIcon(context), size: 18),
                label: Text(context.l10n.t('dashboard.viewProfile')),
              ),
            ),
            SizedBox(width: compact ? 0 : 12, height: compact ? 12 : 0),
            Flexible(
              fit: compact ? FlexFit.loose : FlexFit.tight,
              child: Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          child.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        if ([child.className, child.gradeLabel]
                            .whereType<String>()
                            .where((value) => value.trim().isNotEmpty)
                            .join(' - ')
                            .isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            [child.className, child.gradeLabel]
                                .whereType<String>()
                                .where((value) => value.trim().isNotEmpty)
                                .join(' - '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF747A9A),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE8EEFF),
                    backgroundImage: _dashboardAvatarImageProvider(
                      child.avatarUrl,
                    ),
                    child: child.avatarUrl == null || child.avatarUrl!.isEmpty
                        ? Text(
                            _initials(child.displayName),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentSectionHeader extends StatelessWidget {
  const _ParentSectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.ltr,
      children: [
        if (actionLabel != null)
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
        const Spacer(),
        Text(
          title,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ParentSurveyActionCard extends StatelessWidget {
  const _ParentSurveyActionCard({required this.survey});

  final SurveyCardDto2 survey;

  @override
  Widget build(BuildContext context) {
    final destination = _surveyDestination(survey);
    final answered =
        survey.mySubmissionId != null && survey.mySubmissionId!.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.push(destination),
      child: _ParentWhiteCard(
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    survey.title,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    survey.dateLabel ??
                        context.l10n
                            .t('questionCount')
                            .replaceAll('{count}', '${survey.questionCount}'),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF747A9A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 98,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF436BFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => context.push(destination),
                child: Text(
                  answered
                      ? context.l10n.t('viewResult')
                      : context.l10n.t('start'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentSurveyOverview extends StatelessWidget {
  const _ParentSurveyOverview({required this.summary});

  final SurveyStatusSummaryDto2 summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.ltr,
      children: [
        Expanded(
          child: _ParentCountCard(
            label: context.l10n.t('status.pending'),
            value: summary.pending + summary.newItems,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ParentCountCard(
            label: context.l10n.t('status.inProgress'),
            value: summary.inProgress,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ParentCountCard(
            label: context.l10n.t('status.completed'),
            value: summary.completed,
          ),
        ),
      ],
    );
  }
}

class _ParentCountCard extends StatelessWidget {
  const _ParentCountCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return _ParentWhiteCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF747A9A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentActivityCard extends StatelessWidget {
  const _ParentActivityCard({required this.item});

  final ActivityFeedItemDto2 item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _ParentWhiteCard(
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            Text(
              _localizedTimeAgo(context, item),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8C90A9)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if ((item.subtitle ?? '').isNotEmpty)
                    Text(
                      item.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF747A9A),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentStudentProgressDashboard extends StatelessWidget {
  const _ParentStudentProgressDashboard({
    required this.dashboard,
    required this.period,
    required this.onPeriodChanged,
  });

  final DashboardResponseDto2 dashboard;
  final String period;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final child = dashboard.children.firstWhere(
      (item) => item.id == dashboard.selectedChildId,
      orElse: () => dashboard.children.isEmpty
          ? const ChildProfileDto2(id: '', displayName: '')
          : dashboard.children.first,
    );
    return _ParentAppFrame(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 20 : 32,
              compact ? 24 : 34,
              compact ? 20 : 32,
              42,
            ),
            children: [
              _ParentProgressHeader(
                title: context.l10n
                    .t('dashboard.studentProgressTitle')
                    .replaceAll('{name}', child.displayName),
                period: period,
                onPeriodChanged: onPeriodChanged,
              ),
              const SizedBox(height: 24),
              _ParentWhiteCard(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.t('dashboard.activityParticipation'),
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: compact ? 168 : 190,
                      child: _DashboardLineChart(
                        chart: dashboard.charts.isNotEmpty
                            ? dashboard.charts.first
                            : null,
                        prominent: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _ParentDataScopeNotice(dashboard: dashboard),
              const SizedBox(height: 14),
              _ParentMetricGrid(metrics: dashboard.metrics),
              const SizedBox(height: 32),
              _ParentSectionHeader(
                title: context.l10n.t('dashboard.latestSurveys'),
              ),
              const SizedBox(height: 18),
              if (dashboard.latestSurveys.isEmpty)
                _ParentEmptyCard(
                  message: context.l10n.t('dashboard.noNewSurveys'),
                )
              else
                for (final survey in dashboard.latestSurveys.take(3)) ...[
                  _ParentSurveyResultCard(survey: survey),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _ParentDataScopeNotice extends StatelessWidget {
  const _ParentDataScopeNotice({required this.dashboard});

  final DashboardResponseDto2 dashboard;

  @override
  Widget build(BuildContext context) {
    final scopedFormCount = dashboard.metadata['metric_form_count'];
    final count = scopedFormCount is num ? scopedFormCount.toInt() : null;
    final message = count == null
        ? context.l10n.t('dashboard.dataScopeCurrentAccount')
        : count == 0
        ? context.l10n.t('dashboard.dataScopeNoStudentForms')
        : context.l10n
              .t('dashboard.dataScopeSelectedStudent')
              .replaceAll('{count}', '$count');
    return _ParentWhiteCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF436BFF)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF696D91),
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentProgressHeader extends StatelessWidget {
  const _ParentProgressHeader({
    required this.title,
    required this.period,
    required this.onPeriodChanged,
  });

  final String title;
  final String period;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final titleWidget = Text(
          title,
          textAlign: TextAlign.start,
          maxLines: compact ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF696D91),
            fontWeight: FontWeight.w900,
          ),
        );
        final controls = Row(
          textDirection: TextDirection.ltr,
          children: [
            IconButton.filled(
              onPressed: () => context.go('/dashboard'),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.ink,
                foregroundColor: Colors.white,
              ),
              icon: Icon(appBackChevronIcon(context)),
            ),
            const Spacer(),
            _ParentPeriodPill(value: period, onChanged: onPeriodChanged),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [controls, const SizedBox(height: 16), titleWidget],
          );
        }

        return Row(
          textDirection: TextDirection.ltr,
          children: [
            IconButton.filled(
              onPressed: () => context.go('/dashboard'),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.ink,
                foregroundColor: Colors.white,
              ),
              icon: Icon(appBackIcon(context)),
            ),
            const SizedBox(width: 18),
            _ParentPeriodPill(value: period, onChanged: onPeriodChanged),
            const Spacer(),
            Expanded(flex: 2, child: titleWidget),
          ],
        );
      },
    );
  }
}

class _ParentMetricGrid extends StatelessWidget {
  const _ParentMetricGrid({required this.metrics});

  final List<DashboardMetricValueDto2> metrics;

  @override
  Widget build(BuildContext context) {
    final visible = metrics.take(4).toList();
    if (visible.isEmpty) {
      return _ParentEmptyCard(message: context.l10n.t('dashboard.noMetrics'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 430;
        final width = twoColumns
            ? (constraints.maxWidth - 22) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 22,
          runSpacing: 22,
          children: [
            for (final metric in visible)
              SizedBox(
                width: width,
                height: 124,
                child: _ParentMetricCard(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _ParentMetricCard extends StatelessWidget {
  const _ParentMetricCard({required this.metric});

  final DashboardMetricValueDto2 metric;

  @override
  Widget build(BuildContext context) {
    final status = _metricStatus(metric);
    final color = status == null ? null : _statusColor(status);
    return _ParentWhiteCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.title,
            textAlign: TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            metric.displayValue,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          if (status != null && color != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(context, status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ParentSurveyResultCard extends StatelessWidget {
  const _ParentSurveyResultCard({required this.survey});

  final SurveyCardDto2 survey;

  @override
  Widget build(BuildContext context) {
    final destination = _surveyDestination(survey);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.push(destination),
      child: _ParentWhiteCard(
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            Text(
              survey.mySubmissionId == null
                  ? context.l10n.t('start')
                  : survey.progress.toStringAsFixed(0),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            if (survey.mySubmissionId != null)
              Text(
                context.l10n.t('dashboard.responses'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF747A9A)),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    survey.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    survey.dateLabel ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF747A9A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentPeriodPill extends StatelessWidget {
  const _ParentPeriodPill({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.expand_more_rounded, size: 18),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: const Color(0xFF747A9A),
            fontWeight: FontWeight.w800,
          ),
          items: [
            DropdownMenuItem(
              value: 'this_month',
              child: Text(context.l10n.t('period.this_month')),
            ),
            DropdownMenuItem(
              value: 'last_month',
              child: Text(context.l10n.t('period.last_month')),
            ),
            DropdownMenuItem(
              value: 'last_3_months',
              child: Text(context.l10n.t('period.last_3_months')),
            ),
            DropdownMenuItem(
              value: 'this_year',
              child: Text(context.l10n.t('period.this_year')),
            ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _ParentWhiteCard extends StatelessWidget {
  const _ParentWhiteCard({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 12),
            color: Colors.black.withValues(alpha: 0.035),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ParentEmptyCard extends StatelessWidget {
  const _ParentEmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _ParentWhiteCard(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF747A9A),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({
    required this.user,
    required this.role,
    required this.period,
    required this.onPeriodChanged,
  });

  final UserDetailDto user;
  final UserRole role;
  final String period;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final roleLabel = _roleLabel(context, role);
    final title = role == UserRole.parent
        ? context.l10n.t('dashboard.parentTitle')
        : role == UserRole.student
        ? context.l10n.t('dashboard.studentTitle')
        : role == UserRole.teacher
        ? context.l10n.t('dashboard.teacherTitle')
        : context.l10n.t('dashboard.roleTitle').replaceAll('{role}', roleLabel);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF5F6388),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${user.displayName} · ${_roleLabel(context, role)}',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
        _PeriodDropdown(value: period, onChanged: onPeriodChanged),
        // const SizedBox(width: 12),
        // IconButton.filled(
        //   onPressed: () {
        //     final navigator = Navigator.of(context);
        //     if (navigator.canPop()) navigator.maybePop();
        //   },
        //   style: IconButton.styleFrom(
        //     backgroundColor: AppTheme.ink,
        //     foregroundColor: Colors.white,
        //   ),
        //   icon: Icon(
        //     context.l10n.textDirection == TextDirection.rtl
        //         ? Icons.chevron_right_rounded
        //         : Icons.chevron_left_rounded,
        //   ),
        // ),
      ],
    );
  }
}

class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.expand_more_rounded, size: 18),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF747A9A),
          ),
          items: [
            DropdownMenuItem(
              value: 'this_month',
              child: Text(context.l10n.t('period.this_month')),
            ),
            DropdownMenuItem(
              value: 'last_month',
              child: Text(context.l10n.t('period.last_month')),
            ),
            DropdownMenuItem(
              value: 'last_3_months',
              child: Text(context.l10n.t('period.last_3_months')),
            ),
            DropdownMenuItem(
              value: 'this_year',
              child: Text(context.l10n.t('period.this_year')),
            ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _ParentChildrenHero extends StatelessWidget {
  const _ParentChildrenHero({
    required this.dashboard,
    required this.selectedChildId,
    required this.onChildSelected,
  });

  final DashboardResponseDto2 dashboard;
  final String? selectedChildId;
  final ValueChanged<String> onChildSelected;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title: context.l10n.t('dashboard.parentChildren')),
          const SizedBox(height: 12),
          if (dashboard.children.isEmpty)
            _EmptyTiny(message: context.l10n.t('dashboard.noChildrenForParent'))
          else
            for (final child in dashboard.children) ...[
              _ChildCard(
                child: child,
                selected: child.id == selectedChildId,
                onTap: () => onChildSelected(child.id),
              ),
              if (child != dashboard.children.last) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _StudentHero extends StatelessWidget {
  const _StudentHero({required this.dashboard, required this.user});

  final DashboardResponseDto2 dashboard;
  final UserDetailDto user;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StudentProfileCard(user: user),
          const SizedBox(height: 18),
          _SectionTitle(
            title: context.l10n.t('dashboard.activity.student'),
            trailing: _ChartLegend(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 176,
            child: _DashboardLineChart(
              chart: dashboard.charts.isNotEmpty
                  ? dashboard.charts.first
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherHero extends StatelessWidget {
  const _TeacherHero({required this.dashboard});

  final DashboardResponseDto2 dashboard;

  @override
  Widget build(BuildContext context) {
    final chart = dashboard.charts.isNotEmpty ? dashboard.charts.first : null;
    return _SoftPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            title: context.l10n.t('dashboard.teacherSurveyParticipation'),
            trailing: _ChartLegend(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: _DashboardLineChart(chart: chart, prominent: true),
          ),
        ],
      ),
    );
  }
}

class _ManagementHero extends StatelessWidget {
  const _ManagementHero({required this.dashboard, required this.role});

  final DashboardResponseDto2 dashboard;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final chart = dashboard.charts.isNotEmpty ? dashboard.charts.first : null;
    return _SoftPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            title: role == UserRole.ceo || role == UserRole.superAdmin
                ? context.l10n.t('dashboard.organizationParticipation')
                : context.l10n.t('dashboard.surveyParticipation'),
            trailing: _ChartLegend(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 210,
            child: _DashboardLineChart(chart: chart, prominent: true),
          ),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.child,
    required this.selected,
    required this.onTap,
  });

  final ChildProfileDto2 child;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.35);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: const Color(0xFFFFE2C1),
              backgroundImage: child.avatarUrl == null
                  ? null
                  : NetworkImage(child.avatarUrl!),
              child: child.avatarUrl == null
                  ? Text(
                      _initials(child.displayName),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.displayName,
                    textAlign: TextAlign.start,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [child.gradeLabel, child.className]
                        .whereType<String>()
                        .where((e) => e.isNotEmpty)
                        .join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              )
            else
              TextButton(
                onPressed: onTap,
                child: Text(context.l10n.t('dashboard.selectStudent')),
              ),
          ],
        ),
      ),
    );
  }
}

class _StudentProfileCard extends StatelessWidget {
  const _StudentProfileCard({required this.user});

  final UserDetailDto user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: Color(0xFFE8EEFF),
            child: Text('🎓', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  textAlign: TextAlign.start,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.t('dashboard.studentSubtitle'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go('/profile'),
            child: Text(context.l10n.t('dashboard.viewProfile')),
          ),
        ],
      ),
    );
  }
}

class _ParentSurveyArea extends StatelessWidget {
  const _ParentSurveyArea({required this.dashboard});

  final DashboardResponseDto2 dashboard;

  @override
  Widget build(BuildContext context) {
    return _ResponsiveTwoColumn(
      left: _NewSurveyCard(surveys: dashboard.latestSurveys),
      right: _SurveySummaryCards(summary: dashboard.surveySummary),
    );
  }
}

class _NewSurveyCard extends StatelessWidget {
  const _NewSurveyCard({required this.surveys});

  final List<SurveyCardDto2> surveys;

  @override
  Widget build(BuildContext context) {
    final fresh = surveys
        .where((s) => s.status == 'new' || s.status == 'pending')
        .take(2)
        .toList();
    return _SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TextButton(
                onPressed: () => context.go('/forms'),
                child: Text(context.l10n.t('seeAll')),
              ),
              const Spacer(),
              _SectionTitle(title: context.l10n.t('dashboard.newSurvey')),
            ],
          ),
          const SizedBox(height: 12),
          if (fresh.isEmpty)
            _EmptyTiny(message: context.l10n.t('dashboard.noNewSurveys'))
          else
            for (final survey in fresh) ...[
              _SurveyTile(survey: survey, primary: true),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _SurveySummaryCards extends StatelessWidget {
  const _SurveySummaryCards({required this.summary});

  final SurveyStatusSummaryDto2 summary;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title: context.l10n.t('dashboard.surveyOverview')),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatusMini(
                  label: context.l10n.t('status.completed'),
                  value: summary.completed,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatusMini(
                  label: context.l10n.t('status.inProgress'),
                  value: summary.inProgress,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatusMini(
                  label: context.l10n.t('status.pending'),
                  value: summary.pending + summary.newItems,
                  color: const Color(0xFF8C90A9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusMini extends StatelessWidget {
  const _StatusMini({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationalCards extends StatelessWidget {
  const _OperationalCards({required this.dashboard, required this.role});

  final DashboardResponseDto2 dashboard;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final summary = dashboard.surveySummary;
    return _ResponsiveTwoColumn(
      left: _SoftPanel(
        child: _BigNumberTile(
          title: context.l10n.t('dashboard.participationCount'),
          value: '${summary.completed}',
          subtitle: role == UserRole.teacher
              ? context.l10n.t('dashboard.teacherParticipationSubtitle')
              : context.l10n.t('dashboard.participationSubtitle'),
          trend: dashboard.metrics.isNotEmpty
              ? dashboard.metrics.first.trend
              : null,
        ),
      ),
      right: _SoftPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(title: context.l10n.t('dashboard.alerts')),
            const SizedBox(height: 10),
            if (dashboard.activities.isEmpty)
              _EmptyTiny(message: context.l10n.t('dashboard.noAlerts'))
            else
              for (final item in dashboard.activities.take(2))
                _ActivityRow(item: item),
          ],
        ),
      ),
    );
  }
}

class _BigNumberTile extends StatelessWidget {
  const _BigNumberTile({
    required this.title,
    required this.value,
    required this.subtitle,
    this.trend,
  });

  final String title;
  final String value;
  final String subtitle;
  final double? trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFE9F8EF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.trending_up_rounded,
            color: AppTheme.success,
            size: 30,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                ),
              ),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (trend != null) _TrendBadge(value: trend!),
      ],
    );
  }
}

class _DynamicMetricsGrid extends StatelessWidget {
  const _DynamicMetricsGrid({required this.metrics});

  final List<DashboardMetricValueDto2> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return _SoftPanel(
        child: _EmptyTiny(message: context.l10n.t('dashboard.noMetrics')),
      );
    }
    final visible = metrics;
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth > 430;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final metric in visible.take(8))
              SizedBox(
                width: twoColumns
                    ? (constraints.maxWidth - 14) / 2
                    : constraints.maxWidth,
                child: _MetricCard(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final DashboardMetricValueDto2 metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _metricStatus(metric);
    final statusColor = status == null ? null : _statusColor(status);
    return _SoftPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MetricMenuDot(metric: metric),
              const Spacer(),
              Text(
                metric.title,
                textAlign: TextAlign.start,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _metricSubtitle(context, metric),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.numericDisplayValue,
                  textAlign: TextAlign.start,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          if (status != null && statusColor != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(context, status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SurveyStatusAndCalendar extends ConsumerWidget {
  const _SurveyStatusAndCalendar({
    required this.dashboard,
    required this.cacheUserId,
  });

  final DashboardResponseDto2 dashboard;
  final String cacheUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarQuery = CalendarQueryInput(
      period: dashboard.period,
      childId: dashboard.selectedChildId,
      cacheUserId: cacheUserId,
    );
    final calendar = ref.watch(surveyCalendarProvider(calendarQuery));
    return _SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          calendar.when(
            loading: () => Row(
              children: [
                _SectionTitle(
                  title: context.l10n.t('dashboard.surveyCalendar'),
                ),
                const Spacer(),
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
            error: (error, _) => Row(
              children: [
                _SectionTitle(
                  title: context.l10n.t('dashboard.surveyCalendar'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: context.l10n.t('tryAgain'),
                  onPressed: () =>
                      ref.invalidate(surveyCalendarProvider(calendarQuery)),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            data: (value) => Row(
              children: [
                _SectionTitle(
                  title: context.l10n.t('dashboard.surveyCalendar'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: value.days.isEmpty
                      ? null
                      : () => _showCalendarSheet(context, value),
                  child: Text(context.l10n.t('seeAll')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          calendar.when(
            loading: () => const SizedBox(
              height: 74,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _EmptyTiny(
              message: FriendlyApiErrorMessage.from(error, context: context),
            ),
            data: (value) {
              final visibleDays = value.days
                  .where((day) => day.count > 0 || day.highlight)
                  .take(14)
                  .toList();
              final days = visibleDays.isEmpty
                  ? value.days.take(14).toList()
                  : visibleDays;
              if (days.isEmpty) {
                return _EmptyTiny(
                  message: context.l10n.t('dashboard.noScheduledSurveys'),
                );
              }
              return _CalendarStrip(
                days: days,
                onDayTap: (day) => _showCalendarDaySheet(context, day),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarStrip extends StatelessWidget {
  const _CalendarStrip({required this.days, required this.onDayTap});

  final List<CalendarDayDto2> days;
  final ValueChanged<CalendarDayDto2> onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        children: [
          for (final day in days)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onDayTap(day),
                child: Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: day.count > 0 ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: day.count > 0
                          ? AppTheme.primary
                          : const Color(0xFFE4E9F3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        day.weekday ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: day.count > 0
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        day.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: day.count > 0 ? Colors.white : AppTheme.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: day.count > 0
                              ? Colors.white
                              : const Color(0xFFD8DDE8),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _showCalendarSheet(BuildContext context, CalendarResponseDto2 calendar) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final days = calendar.days;
      return SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (context, controller) => Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.t('dashboard.calendarAllDays'),
                  textAlign: TextAlign.right,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: days.length,
                    itemBuilder: (context, index) => _CalendarDayRow(
                      day: days[index],
                      onTap: () => _showCalendarDaySheet(context, days[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _showCalendarDaySheet(BuildContext context, CalendarDayDto2 day) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${day.weekday ?? ''} ${day.label}',
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (day.surveys.isEmpty)
              _EmptyTiny(message: context.l10n.t('dashboard.noSurveysOnDay'))
            else
              for (final survey in day.surveys) ...[
                _CalendarSurveyRow(survey: survey),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    ),
  );
}

class _CalendarDayRow extends StatelessWidget {
  const _CalendarDayRow({required this.day, required this.onTap});

  final CalendarDayDto2 day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4E9F3)),
        ),
        child: Row(
          children: [
            Text(
              context.l10n.t('itemCount').replaceAll('{count}', '${day.count}'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: day.count > 0
                    ? AppTheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  day.date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${day.weekday ?? ''} ${day.label}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarSurveyRow extends StatelessWidget {
  const _CalendarSurveyRow({required this.survey});

  final CalendarSurveyDto2 survey;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: survey.formId.isEmpty
          ? null
          : () => context.push('/forms/${survey.formId}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _StatusPill(status: survey.status),
            const Spacer(),
            Expanded(
              flex: 2,
              child: Text(
                survey.title,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => AppTheme.success,
      'closed' => AppTheme.danger,
      'pending' => AppTheme.warning,
      _ => AppTheme.primary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _surveyStatusLabel(context, status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LatestSurveysCard extends StatelessWidget {
  const _LatestSurveysCard({required this.surveys});

  final List<SurveyCardDto2> surveys;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TextButton(
                onPressed: () => context.go('/forms'),
                child: Text(context.l10n.t('seeAll')),
              ),
              const Spacer(),
              _SectionTitle(title: context.l10n.t('dashboard.latestSurveys')),
            ],
          ),
          const SizedBox(height: 12),
          if (surveys.isEmpty)
            _EmptyTiny(message: context.l10n.t('dashboard.noSurveysAvailable'))
          else
            for (final survey in surveys.take(4)) ...[
              _SurveyTile(survey: survey),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

String _surveyDestination(SurveyCardDto2 survey) {
  final submissionId = survey.mySubmissionId?.trim();
  if (submissionId != null && submissionId.isNotEmpty) {
    return '/forms/${survey.formId}?submission_id=${Uri.encodeComponent(submissionId)}';
  }
  return '/forms/${survey.formId}';
}

class _SurveyTile extends StatelessWidget {
  const _SurveyTile({required this.survey, this.primary = false});

  final SurveyCardDto2 survey;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed =
        survey.mySubmissionId != null || survey.status == 'completed';
    final destination = _surveyDestination(survey);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(destination),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: completed
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.28)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: completed
              ? Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.26),
                )
              : null,
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    survey.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if ((survey.dateLabel ?? survey.description ?? '').isNotEmpty)
                    Text(
                      completed
                          ? context.l10n.t('submittedReviewMessage')
                          : survey.dateLabel ?? survey.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: primary ? 106 : 92,
              child: Align(
                alignment: Alignment.centerLeft,
                child: primary
                    ? FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () => context.push(destination),
                        child: Text(
                          completed
                              ? context.l10n.t('viewResult')
                              : context.l10n.t('start'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : _StatusPill(
                        status: completed ? 'completed' : survey.status,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivitiesCard extends StatelessWidget {
  const _ActivitiesCard({required this.items});

  final List<ActivityFeedItemDto2> items;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title: context.l10n.t('dashboard.latestActivities')),
          const SizedBox(height: 12),
          if (items.isEmpty)
            _EmptyTiny(message: context.l10n.t('dashboard.noActivities'))
          else
            for (final item in items.take(5)) _ActivityRow(item: item),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final ActivityFeedItemDto2 item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            _localizedTimeAgo(context, item),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if ((item.subtitle ?? '').isNotEmpty)
                  Text(
                    item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              size: 18,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

String _localizedTimeAgo(BuildContext context, ActivityFeedItemDto2 item) {
  final createdAt = DateTime.tryParse(item.createdAt ?? '');
  if (createdAt == null) return item.timeAgo ?? '';
  final delta = DateTime.now().difference(createdAt.toLocal());
  if (delta.inMinutes < 60) {
    return context.l10n
        .t('time.minutesAgo')
        .replaceAll('{count}', '${math.max(1, delta.inMinutes)}');
  }
  if (delta.inHours < 24) {
    return context.l10n
        .t('time.hoursAgo')
        .replaceAll('{count}', '${delta.inHours}');
  }
  return context.l10n
      .t('time.daysAgo')
      .replaceAll('{count}', '${delta.inDays}');
}

class _RankingsAndAlerts extends ConsumerWidget {
  const _RankingsAndAlerts({required this.dashboard});

  final DashboardResponseDto2 dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestRanking = dashboard.rankings.isNotEmpty
        ? dashboard.rankings.first
        : null;
    final worstRanking = dashboard.rankings.length > 1
        ? dashboard.rankings[1]
        : null;
    return _ResponsiveTwoColumn(
      left: _SoftPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(title: context.l10n.t('dashboard.topSatisfaction')),
            const SizedBox(height: 12),
            if (bestRanking == null || bestRanking.items.isEmpty)
              _EmptyTiny(message: context.l10n.t('dashboard.rankingNotReady'))
            else
              for (final item in bestRanking.items.take(5))
                _RankingRow(item: item),
          ],
        ),
      ),
      right: _SoftPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(
              title: context.l10n.t('dashboard.lowestSatisfaction'),
            ),
            const SizedBox(height: 12),
            if (worstRanking == null || worstRanking.items.isEmpty)
              _EmptyTiny(message: context.l10n.t('dashboard.rankingNotReady'))
            else
              for (final item in worstRanking.items.take(5))
                _RankingRow(item: item),
          ],
        ),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.item});

  final RankingItemDto2 item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            '${item.score.toStringAsFixed(0)}٪',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              if ((item.subtitle ?? '').isNotEmpty)
                Text(
                  item.subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE8EEFF),
            child: Text(
              '${item.rank}',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementConfigurationRow extends ConsumerWidget {
  const _ManagementConfigurationRow({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(metricDefinitionsProvider);
    final segments = ref.watch(audienceSegmentsProvider);
    return _ResponsiveTwoColumn(
      left: _MetricManagementPanel(metrics: metrics),
      right: _SoftPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.groups_2_rounded, color: AppTheme.primary),
                const SizedBox(width: 8),
                _SectionTitle(
                  title: context.l10n.t('dashboard.targetSegments'),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  tooltip: 'افزودن بخش مخاطبان',
                  onPressed: () => _showSegmentDialog(context, ref),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            segments.when(
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) =>
                  Text(FriendlyApiErrorMessage.from(error, context: context)),
              data: (value) => _ManagementList(
                empty: context.l10n.t('dashboard.noSegmentsDefined'),
                items: [
                  for (final segment
                      in value.data ?? const <AudienceSegmentDto2>[])
                    _ManagementListItem(
                      title: segment.name,
                      subtitle: '${segment.slug} · ${segment.segmentType}',
                      trailing: context.l10n
                          .t('dashboard.segmentMemberCount')
                          .replaceAll('{count}', '${segment.memberCount}'),
                      actions: [
                        IconButton(
                          tooltip: 'اعضا',
                          onPressed: () =>
                              _showSegmentMembersDialog(context, ref, segment),
                          icon: const Icon(Icons.group_add_outlined),
                        ),
                        IconButton(
                          tooltip: segment.enabled
                              ? 'غیرفعال کردن'
                              : 'فعال کردن',
                          onPressed: () =>
                              _toggleSegment(context, ref, segment),
                          icon: Icon(
                            segment.enabled
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.t('delete'),
                          onPressed: () =>
                              _deleteSegment(context, ref, segment),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.t('dashboard.segmentListHint'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricManagementPanel extends ConsumerStatefulWidget {
  const _MetricManagementPanel({required this.metrics});

  final AsyncValue<ListResponse<MetricDefinitionDto2>> metrics;

  @override
  ConsumerState<_MetricManagementPanel> createState() =>
      _MetricManagementPanelState();
}

class _MetricManagementPanelState
    extends ConsumerState<_MetricManagementPanel> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: AppTheme.primary),
              const SizedBox(width: 8),
              _SectionTitle(title: context.l10n.t('dashboard.dynamicMetrics')),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: context.l10n.t('addMetric'),
                onPressed: _busy ? null : _createMetric,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          widget.metrics.when(
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) =>
                Text(FriendlyApiErrorMessage.from(error, context: context)),
            data: (value) {
              final items = value.data ?? const <MetricDefinitionDto2>[];
              if (items.isEmpty) {
                return _EmptyTiny(
                  message: context.l10n.t('dashboard.noMetricsDefined'),
                );
              }
              return Column(
                children: [
                  for (final metric in items.take(8))
                    _MetricManagementTile(
                      metric: metric,
                      busy: _busy,
                      onEdit: () => _editMetric(metric),
                      onMappings: () => _manageMappings(metric),
                      onToggle: (enabled) => _updateMetric(
                        metric,
                        <String, dynamic>{'enabled': enabled},
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.t('dashboard.metricPanelHint'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createMetric() async {
    final result = await _showMetricDialog(context);
    if (result == null) return;
    await _runMetricAction(
      () => ref.read(analyticsRepositoryProvider).createMetric(request: result),
    );
  }

  Future<void> _editMetric(MetricDefinitionDto2 metric) async {
    final result = await _showMetricDialog(context, metric: metric);
    if (result == null) return;
    await _updateMetric(metric, result);
  }

  Future<void> _manageMappings(MetricDefinitionDto2 metric) async {
    await _showMetricMappingsDialog(context, ref, metric);
    ref.invalidate(metricDefinitionsProvider);
    ref.invalidate(dashboardExperienceProvider);
    ref.invalidate(metricTimeseriesProvider);
  }

  Future<void> _updateMetric(
    MetricDefinitionDto2 metric,
    Map<String, dynamic> request,
  ) async {
    await _runMetricAction(
      () => ref
          .read(analyticsRepositoryProvider)
          .updateMetric(id: metric.id, request: request),
    );
  }

  Future<void> _runMetricAction(Future<Object?> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(metricDefinitionsProvider);
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
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _MetricManagementTile extends StatelessWidget {
  const _MetricManagementTile({
    required this.metric,
    required this.busy,
    required this.onEdit,
    required this.onMappings,
    required this.onToggle,
  });

  final MetricDefinitionDto2 metric;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onMappings;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Switch(value: metric.enabled, onChanged: busy ? null : onToggle),
          PopupMenuButton<String>(
            tooltip: 'عملیات شاخص',
            enabled: !busy,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'mappings') onMappings();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('ویرایش شاخص'),
                ),
              ),
              PopupMenuItem(
                value: 'mappings',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.account_tree_outlined),
                  title: Text('اتصال داده‌ها'),
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                metric.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${_metricTypeLabel(metric.metricType)} - ${metric.mappingCount} اتصال',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<Map<String, dynamic>?> _showMetricDialog(
  BuildContext context, {
  MetricDefinitionDto2? metric,
}) {
  final keyController = TextEditingController(text: metric?.key ?? '');
  final titleController = TextEditingController(text: metric?.title ?? '');
  final descriptionController = TextEditingController(
    text: metric?.description ?? '',
  );
  var type = metric?.metricType ?? 'score';
  var enabled = metric?.enabled ?? true;
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(
          metric == null
              ? context.l10n.t('addMetric')
              : context.l10n.t('editMetric'),
        ),
        content: SizedBox(
          width: MediaQuery.sizeOf(context).width.clamp(280.0, 460.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: context.l10n.t('title')),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: context.l10n.t('description'),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: InputDecoration(
                  labelText: context.l10n.t('metricType'),
                ),
                items: const [
                  DropdownMenuItem(value: 'score', child: Text('امتیازی')),
                  DropdownMenuItem(value: 'percentage', child: Text('درصدی')),
                  DropdownMenuItem(value: 'rating', child: Text('رتبه‌ای')),
                  DropdownMenuItem(value: 'count', child: Text('شمارشی')),
                  DropdownMenuItem(value: 'label', child: Text('برچسبی')),
                  DropdownMenuItem(value: 'custom', child: Text('سفارشی')),
                ],
                onChanged: metric == null
                    ? (value) => setState(() => type = value ?? type)
                    : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.t('enabled')),
                value: enabled,
                onChanged: (value) => setState(() => enabled = value),
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
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              final key = keyController.text.trim().isEmpty
                  ? _generatedMetricKey(title)
                  : keyController.text.trim();
              Navigator.pop(context, <String, dynamic>{
                if (metric == null) 'key': key,
                'title': title,
                'description': descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                if (metric == null) 'metric_type': type,
                'enabled': enabled,
              });
            },
            child: Text(context.l10n.t('save')),
          ),
        ],
      ),
    ),
  ).whenComplete(() {
    keyController.dispose();
    titleController.dispose();
    descriptionController.dispose();
  });
}

String _generatedMetricKey(String title) {
  final normalized = title
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (normalized.isNotEmpty) return normalized;
  return 'metric_${DateTime.now().millisecondsSinceEpoch}';
}

Map<String, Object?> _parseJsonObject(String input) {
  final text = input.trim();
  if (text.isEmpty) return const <String, Object?>{};
  final decoded = jsonDecode(text);
  if (decoded is Map) return Map<String, Object?>.from(decoded);
  throw const FormatException('Expected a JSON object');
}

List<String> _phonesFromText(String input) => input
    .split(RegExp(r'[\s,;]+'))
    .map((item) => item.trim())
    .where((item) => item.isNotEmpty)
    .map(PhoneNumberNormalizer.normalize)
    .where(PhoneNumberNormalizer.isLikelyValid)
    .toList(growable: false);

Future<String> _resolveUserIdByPhone(WidgetRef ref, String phone) async {
  final normalized = PhoneNumberNormalizer.normalize(phone);
  if (!PhoneNumberNormalizer.isLikelyValid(normalized)) {
    throw FormatException('شماره موبایل معتبر نیست: $phone');
  }
  final response = await ref
      .read(usersRepositoryProvider)
      .listUsers(page: 1, pageSize: 10, search: normalized);
  final users = response.data ?? const <UserSummaryDto>[];
  final exact = users.where((user) => user.phone == normalized).toList();
  if (exact.length == 1) return exact.single.id;
  if (users.length == 1) return users.single.id;
  if (users.isEmpty) {
    throw StateError('کاربری با شماره $normalized پیدا نشد.');
  }
  throw StateError(
    'برای شماره $normalized چند کاربر پیدا شد؛ شماره را دقیق‌تر وارد کنید.',
  );
}

Future<List<String>> _resolveUserIdsByPhones(
  WidgetRef ref,
  String input,
) async {
  final phones = _phonesFromText(input);
  final ids = <String>[];
  for (final phone in phones) {
    final id = await _resolveUserIdByPhone(ref, phone);
    if (!ids.contains(id)) ids.add(id);
  }
  return ids;
}

Future<void> _showMetricMappingsDialog(
  BuildContext context,
  WidgetRef ref,
  MetricDefinitionDto2 metric,
) async {
  final repo = ref.read(analyticsRepositoryProvider);
  final formsRepo = ref.read(formsRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  final mappings = await repo.listMetricMappings(id: metric.id);
  final draftMappings = mappings
      .map(MetricMappingInputDto2.fromMapping)
      .toList(growable: true);
  var formId = mappings.isNotEmpty ? mappings.first.formId : null;
  var fieldId = mappings.isNotEmpty ? mappings.first.fieldId : null;
  var sourceType = mappings.isNotEmpty
      ? mappings.first.sourceType
      : 'submission_percentage';
  var weight = mappings.isNotEmpty ? mappings.first.weight : 1.0;
  var enabled = mappings.isEmpty || mappings.first.enabled;
  List<FormSummaryDto> forms = const <FormSummaryDto>[];
  FormDetailDto? selectedForm;
  try {
    forms =
        (await formsRepo.listForms(
          page: 1,
          pageSize: 100,
          sortBy: 'updated_at',
        )).data ??
        const <FormSummaryDto>[];
    if (formId != null && formId.isNotEmpty) {
      selectedForm = await formsRepo.getForm(id: formId);
    }
  } catch (_) {}
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('اتصال داده‌ها: ${metric.title}'),
        content: SizedBox(
          width: MediaQuery.sizeOf(context).width.clamp(320.0, 560.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (draftMappings.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('${draftMappings.length} اتصال آماده ذخیره'),
                  ),
                for (var index = 0; index < draftMappings.length; index++)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: IconButton(
                      tooltip: 'حذف اتصال',
                      onPressed: () => setState(() {
                        draftMappings.removeAt(index);
                      }),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                    title: Text(
                      _metricSourceTypeLabel(draftMappings[index].sourceType),
                    ),
                    subtitle: Text(
                      [
                        if (draftMappings[index].formId != null)
                          'فرم: ${draftMappings[index].formId}',
                        if (draftMappings[index].fieldId != null)
                          'فیلد: ${draftMappings[index].fieldId}',
                        'وزن: ${draftMappings[index].weight}',
                        draftMappings[index].enabled ? 'فعال' : 'غیرفعال',
                      ].join(' - '),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                const Divider(height: 22),
                DropdownButtonFormField<String>(
                  initialValue: sourceType,
                  decoration: const InputDecoration(labelText: 'منبع داده'),
                  items: const [
                    DropdownMenuItem(
                      value: 'field_answer',
                      child: Text('پاسخ یک فیلد'),
                    ),
                    DropdownMenuItem(
                      value: 'submission_score',
                      child: Text('امتیاز پاسخ'),
                    ),
                    DropdownMenuItem(
                      value: 'submission_percentage',
                      child: Text('درصد امتیاز پاسخ'),
                    ),
                    DropdownMenuItem(
                      value: 'submission_count',
                      child: Text('تعداد پاسخ‌ها'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => sourceType = value ?? sourceType),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: forms.any((form) => form.id == formId)
                      ? formId
                      : null,
                  decoration: const InputDecoration(labelText: 'محدوده فرم'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('همه فرم‌ها'),
                    ),
                    for (final form in forms)
                      DropdownMenuItem(value: form.id, child: Text(form.title)),
                  ],
                  onChanged: (value) async {
                    formId = value == null || value.isEmpty ? null : value;
                    selectedForm = null;
                    fieldId = null;
                    setState(() {});
                    if (formId != null) {
                      selectedForm = await formsRepo.getForm(id: formId!);
                      if (context.mounted) setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 8),
                if (sourceType == 'field_answer')
                  DropdownButtonFormField<String>(
                    initialValue: fieldId?.isEmpty == true ? null : fieldId,
                    decoration: const InputDecoration(labelText: 'فیلد'),
                    items: [
                      for (final field in selectedForm?.fields ?? const [])
                        DropdownMenuItem(
                          value: field.id,
                          child: Text(field.label),
                        ),
                    ],
                    onChanged: (value) => setState(() => fieldId = value),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: weight.toString(),
                  decoration: const InputDecoration(labelText: 'وزن'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      weight = double.tryParse(value.trim()) ?? weight,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('فعال'),
                  value: enabled,
                  onChanged: (value) => setState(() => enabled = value),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (sourceType == 'field_answer' &&
                          (fieldId == null || fieldId!.isEmpty)) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('ابتدا یک فیلد انتخاب کنید.'),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        draftMappings.add(
                          MetricMappingInputDto2(
                            formId: formId,
                            fieldId: sourceType == 'field_answer'
                                ? fieldId
                                : null,
                            sourceType: sourceType,
                            weight: weight,
                            enabled: enabled,
                          ),
                        );
                      });
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('افزودن اتصال'),
                  ),
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
            onPressed: () async {
              await repo.setMetricMappings(
                id: metric.id,
                request: SetMetricMappingsRequest2(mappings: draftMappings),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(context.l10n.t('save')),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showSegmentDialog(BuildContext context, WidgetRef ref) async {
  final name = TextEditingController();
  final slug = TextEditingController();
  final description = TextEditingController();
  final members = TextEditingController();
  var segmentType = 'static';
  var enabled = true;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('افزودن بخش مخاطبان'),
        content: SizedBox(
          width: MediaQuery.sizeOf(context).width.clamp(320.0, 520.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: context.l10n.t('title'),
                  ),
                ),
                TextField(
                  controller: slug,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'شناسه داخلی'),
                ),
                TextField(
                  controller: description,
                  decoration: InputDecoration(
                    labelText: context.l10n.t('description'),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: segmentType,
                  decoration: const InputDecoration(labelText: 'نوع'),
                  items: const [
                    DropdownMenuItem(value: 'static', child: Text('ثابت')),
                    DropdownMenuItem(value: 'dynamic', child: Text('داینامیک')),
                    DropdownMenuItem(value: 'event', child: Text('رویداد')),
                    DropdownMenuItem(value: 'camp', child: Text('کمپ')),
                    DropdownMenuItem(value: 'cohort', child: Text('دوره')),
                    DropdownMenuItem(value: 'custom', child: Text('سفارشی')),
                  ],
                  onChanged: (value) =>
                      setState(() => segmentType = value ?? segmentType),
                ),
                TextField(
                  controller: members,
                  minLines: 2,
                  maxLines: 4,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'شماره موبایل اعضا',
                    helperText: 'شماره‌ها را با ویرگول یا خط جدید جدا کنید',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('فعال'),
                  value: enabled,
                  onChanged: (value) => setState(() => enabled = value),
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
            onPressed: () async {
              final segmentName = name.text.trim();
              if (segmentName.isEmpty) return;
              final memberUserIds = await _resolveUserIdsByPhones(
                ref,
                members.text,
              );
              await ref
                  .read(analyticsRepositoryProvider)
                  .createAudienceSegment(
                    request: CreateAudienceSegmentRequest2(
                      name: segmentName,
                      slug: slug.text.trim().isEmpty ? null : slug.text.trim(),
                      description: description.text.trim().isEmpty
                          ? null
                          : description.text.trim(),
                      segmentType: segmentType,
                      enabled: enabled,
                      memberUserIds: memberUserIds,
                    ),
                  );
              ref.invalidate(audienceSegmentsProvider);
              ref.invalidate(dashboardExperienceProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(context.l10n.t('save')),
          ),
        ],
      ),
    ),
  ).whenComplete(() {
    name.dispose();
    slug.dispose();
    description.dispose();
    members.dispose();
  });
}

Future<void> _toggleSegment(
  BuildContext context,
  WidgetRef ref,
  AudienceSegmentDto2 segment,
) async {
  await ref
      .read(analyticsRepositoryProvider)
      .updateAudienceSegment(
        id: segment.id,
        request: UpdateAudienceSegmentRequest2(enabled: !segment.enabled),
      );
  ref.invalidate(audienceSegmentsProvider);
  ref.invalidate(dashboardExperienceProvider);
}

Future<void> _deleteSegment(
  BuildContext context,
  WidgetRef ref,
  AudienceSegmentDto2 segment,
) async {
  await ref
      .read(analyticsRepositoryProvider)
      .deleteAudienceSegment(id: segment.id);
  ref.invalidate(audienceSegmentsProvider);
  ref.invalidate(dashboardExperienceProvider);
}

Future<void> _showSegmentMembersDialog(
  BuildContext context,
  WidgetRef ref,
  AudienceSegmentDto2 segment,
) async {
  final repo = ref.read(analyticsRepositoryProvider);
  final current = await repo.listAudienceSegmentMembers(id: segment.id);
  if (!context.mounted) return;
  final phones = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('اعضای بخش مخاطبان: ${segment.name}'),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width.clamp(320.0, 520.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (current.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  current.map((member) => member.displayName).join('، '),
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: phones,
              minLines: 8,
              maxLines: 12,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'شماره موبایل اعضا',
                helperText:
                    'برای جایگزینی اعضا، شماره‌ها را با ویرگول یا خط جدید وارد کنید',
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
          onPressed: () async {
            final userIds = await _resolveUserIdsByPhones(ref, phones.text);
            await repo.setAudienceSegmentMembers(
              id: segment.id,
              request: SetAudienceSegmentMembersRequest2(userIds: userIds),
            );
            ref.invalidate(audienceSegmentsProvider);
            ref.invalidate(dashboardExperienceProvider);
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(context.l10n.t('save')),
        ),
      ],
    ),
  ).whenComplete(phones.dispose);
}

Future<void> _showFormAssignmentsDialog(
  BuildContext context,
  WidgetRef ref,
  FormSummaryDto form,
) async {
  final repo = ref.read(analyticsRepositoryProvider);
  final current = await repo.listFormAssignments(id: form.id);
  final groups =
      (await repo.listAudienceGroups(page: 1, pageSize: 100)).data ??
      const <AudienceGroupOptionDto2>[];
  final segments =
      (await repo.listAudienceSegments(
        page: 1,
        pageSize: 100,
        enabled: true,
      )).data ??
      const <AudienceSegmentDto2>[];
  if (!context.mounted) return;
  var audienceType = 'role';
  var role = UserRole.student;
  final targetPhone = TextEditingController();
  String? selectedGroupId;
  String? selectedSegmentId;
  final label = TextEditingController();
  var canSee = true;
  var canAnswer = true;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('هدف‌گیری فرم: ${form.title}'),
        content: SizedBox(
          width: MediaQuery.sizeOf(context).width.clamp(320.0, 560.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (current.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${current.length} هدف‌گیری فعلی'),
                  ),
                DropdownButtonFormField<String>(
                  initialValue: audienceType,
                  decoration: const InputDecoration(labelText: 'نوع مخاطب'),
                  items: const [
                    DropdownMenuItem(value: 'role', child: Text('نقش')),
                    DropdownMenuItem(value: 'user', child: Text('کاربر')),
                    DropdownMenuItem(value: 'group', child: Text('گروه')),
                    DropdownMenuItem(value: 'class', child: Text('کلاس')),
                    DropdownMenuItem(
                      value: 'department',
                      child: Text('دپارتمان'),
                    ),
                    DropdownMenuItem(
                      value: 'segment',
                      child: Text('بخش مخاطبان'),
                    ),
                    DropdownMenuItem(
                      value: 'organization',
                      child: Text('سازمان'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    audienceType = value ?? audienceType;
                    selectedGroupId = null;
                    selectedSegmentId = null;
                  }),
                ),
                if (audienceType == 'role')
                  DropdownButtonFormField<UserRole>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'نقش'),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.student,
                        child: Text('دانش‌آموز'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.parent,
                        child: Text('والد'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.teacher,
                        child: Text('معلم'),
                      ),
                    ],
                    onChanged: (value) => setState(() => role = value ?? role),
                  )
                else if (audienceType != 'organization')
                  if (audienceType == 'user')
                    TextField(
                      controller: targetPhone,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'شماره موبایل کاربر',
                      ),
                    )
                  else if (audienceType == 'segment')
                    DropdownButtonFormField<String>(
                      initialValue: selectedSegmentId,
                      decoration: const InputDecoration(
                        labelText: 'بخش مخاطبان',
                      ),
                      items: [
                        for (final segment in segments)
                          DropdownMenuItem(
                            value: segment.id,
                            child: Text(segment.name),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => selectedSegmentId = value),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedGroupId,
                      decoration: InputDecoration(
                        labelText: audienceType == 'class'
                            ? 'کلاس'
                            : audienceType == 'department'
                            ? 'دپارتمان'
                            : 'گروه',
                      ),
                      items: [
                        for (final group in groups.where(
                          (group) =>
                              audienceType == 'group' ||
                              group.groupType == audienceType,
                        ))
                          DropdownMenuItem(
                            value: group.id,
                            child: Text(group.name),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => selectedGroupId = value),
                    ),
                TextField(
                  controller: label,
                  decoration: const InputDecoration(labelText: 'برچسب'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('اجازه مشاهده'),
                  value: canSee,
                  onChanged: (value) =>
                      setState(() => canSee = value ?? canSee),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('اجازه پاسخ‌دهی'),
                  value: canAnswer,
                  onChanged: (value) =>
                      setState(() => canAnswer = value ?? canAnswer),
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
            onPressed: () async {
              final userId = audienceType == 'user'
                  ? await _resolveUserIdByPhone(ref, targetPhone.text)
                  : null;
              final newAssignment = FormAssignmentInputDto2(
                audienceType: audienceType,
                audienceRole: audienceType == 'role' ? role : null,
                audienceUserId: userId,
                audienceGroupId:
                    ['group', 'class', 'department'].contains(audienceType)
                    ? selectedGroupId
                    : null,
                audienceSegmentId: audienceType == 'segment'
                    ? selectedSegmentId
                    : null,
                label: label.text.trim().isEmpty ? null : label.text.trim(),
                canSee: canSee,
                canAnswer: canAnswer,
              );
              await repo.setFormAssignments(
                id: form.id,
                request: SetFormAssignmentsRequest2(
                  assignments: [
                    for (final assignment in current)
                      FormAssignmentInputDto2.fromAssignment(assignment),
                    newAssignment,
                  ],
                ),
              );
              ref.invalidate(formAssignmentsProvider(form.id));
              ref.invalidate(dashboardExperienceProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('افزودن هدف‌گیری'),
          ),
        ],
      ),
    ),
  ).whenComplete(() {
    targetPhone.dispose();
    label.dispose();
  });
}

Future<void> _showActivityRulesDialog(
  BuildContext context,
  WidgetRef ref,
  FormSummaryDto form,
) async {
  final repo = ref.read(activitiesRepositoryProvider);
  final existing = await repo.listActivityRules(id: form.id, pageSize: 50);
  if (!context.mounted) return;
  var trigger = ActivityTriggerType.submissionCreated;
  var action = ActivityActionType.createActivity;
  var enabled = true;
  final condition = TextEditingController(text: '{}');
  final title = TextEditingController(text: 'Feedback follow-up');
  final description = TextEditingController();
  final assignedToPhone = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('قواعد فعالیت: ${form.title}'),
        content: SizedBox(
          width: MediaQuery.sizeOf(context).width.clamp(320.0, 560.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((existing.data ?? const <ActivityRuleDto>[]).isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${existing.data!.length} قاعده فعلی'),
                  ),
                DropdownButtonFormField<ActivityTriggerType>(
                  initialValue: trigger,
                  decoration: const InputDecoration(labelText: 'محرک'),
                  items: ActivityTriggerType.values
                      .where((value) => value != ActivityTriggerType.unknown)
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_activityTriggerLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => trigger = value ?? trigger),
                ),
                TextField(
                  controller: condition,
                  minLines: 2,
                  maxLines: 4,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'شرط JSON',
                    helperText:
                        'برای آستانه امتیاز از نمونه {"threshold":50} استفاده کنید',
                  ),
                ),
                DropdownButtonFormField<ActivityActionType>(
                  initialValue: action,
                  decoration: const InputDecoration(labelText: 'عملیات'),
                  items: ActivityActionType.values
                      .where((value) => value != ActivityActionType.unknown)
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_activityActionLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => action = value ?? action),
                ),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'عنوان فعالیت'),
                ),
                TextField(
                  controller: description,
                  decoration: InputDecoration(
                    labelText: context.l10n.t('description'),
                  ),
                ),
                TextField(
                  controller: assignedToPhone,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'شماره موبایل کاربر مسئول',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('فعال'),
                  value: enabled,
                  onChanged: (value) => setState(() => enabled = value),
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
            onPressed: () async {
              final assigneePhone = assignedToPhone.text.trim();
              final assignedToUserId = assigneePhone.isEmpty
                  ? null
                  : await _resolveUserIdByPhone(ref, assigneePhone);
              final config = <String, Object?>{
                'title': title.text.trim().isEmpty
                    ? 'Feedback follow-up'
                    : title.text.trim(),
              };
              if (description.text.trim().isNotEmpty) {
                config['description'] = description.text.trim();
              }
              if (assignedToUserId != null) {
                config['assigned_to_user_id'] = assignedToUserId;
              }
              await repo.createActivityRule(
                id: form.id,
                request: CreateActivityRuleRequest(
                  triggerType: trigger,
                  condition: _parseJsonObject(condition.text),
                  actionType: action,
                  actionConfig: config,
                  enabled: enabled,
                ),
              );
              ref.invalidate(activitiesProvider);
              ref.invalidate(dashboardExperienceProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(context.l10n.t('save')),
          ),
        ],
      ),
    ),
  ).whenComplete(() {
    condition.dispose();
    title.dispose();
    description.dispose();
    assignedToPhone.dispose();
  });
}

class _ManagementList extends StatelessWidget {
  const _ManagementList({required this.items, required this.empty});

  final List<_ManagementListItem> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _EmptyTiny(message: empty);
    return Column(children: items.take(5).toList());
  }
}

class _ManagementListItem extends StatelessWidget {
  const _ManagementListItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.actions = const <Widget>[],
  });

  final String title;
  final String subtitle;
  final String trailing;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            trailing,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 8),
            Wrap(spacing: 4, children: actions),
          ],
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResponsiveTwoColumn extends StatelessWidget {
  const _ResponsiveTwoColumn({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(children: [left, const SizedBox(height: 16), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      title,
      textAlign: TextAlign.end,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w900,
        color: AppTheme.ink,
      ),
    );
    if (trailing == null) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: titleWidget,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [trailing!, const SizedBox(width: 8), titleWidget],
    );
  }
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF161C30)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 14),
            color: Colors.black.withValues(alpha: dark ? 0.18 : 0.045),
          ),
        ],
      ),
      child: child,
    );
  }
}

String _metricSubtitle(BuildContext context, DashboardMetricValueDto2 metric) {
  final description = metric.display['description']?.toString().trim();
  if (description != null && description.isNotEmpty) return description;
  final source = _friendlyMetricSource(context, metric);
  return source.isEmpty
      ? context.l10n.t('dashboard.metricDefaultDescription')
      : source;
}

String _friendlyMetricSource(
  BuildContext context,
  DashboardMetricValueDto2 metric,
) {
  final raw = metric.display['source']?.toString().trim();
  if (raw == null ||
      raw.isEmpty ||
      raw == 'metric_definitions + metric_mappings') {
    return context.l10n.t('metric.source.dynamicMappings');
  }
  if (raw == 'submission_count') {
    return context.l10n.t('metric.source.submissionCount');
  }
  if (raw == 'submission_percentage') {
    return 'میانگین درصد امتیاز پاسخ‌ها';
  }
  if (raw == 'submission_score') {
    return 'میانگین امتیاز پاسخ‌ها';
  }
  if (raw == 'field_answer') {
    return context.l10n.t('metric.source.fieldAnswers');
  }
  return raw;
}

String _metricTypeLabel(String type) => switch (type) {
  'score' => 'امتیازی',
  'percentage' => 'درصدی',
  'rating' => 'رتبه‌ای',
  'count' => 'شمارشی',
  'label' => 'برچسبی',
  'custom' => 'سفارشی',
  _ => 'سفارشی',
};

String _metricSourceTypeLabel(String sourceType) => switch (sourceType) {
  'field_answer' => 'پاسخ یک فیلد',
  'submission_score' => 'امتیاز پاسخ',
  'submission_percentage' => 'درصد امتیاز پاسخ',
  'submission_count' => 'تعداد پاسخ‌ها',
  _ => 'منبع سفارشی',
};

String _activityTriggerLabel(ActivityTriggerType trigger) => switch (trigger) {
  ActivityTriggerType.submissionCreated => 'ثبت پاسخ جدید',
  ActivityTriggerType.scoreAbove => 'امتیاز بالاتر از حد',
  ActivityTriggerType.scoreBelow => 'امتیاز پایین‌تر از حد',
  ActivityTriggerType.answerEquals => 'برابر بودن پاسخ',
  ActivityTriggerType.answerContains => 'شامل بودن پاسخ',
  ActivityTriggerType.npsLow => 'رضایت پایین',
  ActivityTriggerType.npsHigh => 'رضایت بالا',
  ActivityTriggerType.submissionCountReached =>
    'رسیدن تعداد پاسخ‌ها به حد مشخص',
  ActivityTriggerType.formClosed => 'بسته شدن فرم',
  ActivityTriggerType.unknown => 'نامشخص',
};

String _activityActionLabel(ActivityActionType action) => switch (action) {
  ActivityActionType.createActivity => 'ایجاد فعالیت پیگیری',
  ActivityActionType.notifyUser => 'اطلاع‌رسانی به کاربر',
  ActivityActionType.notifyManager => 'اطلاع‌رسانی به مدیر',
  ActivityActionType.sendEmail => 'ارسال ایمیل',
  ActivityActionType.sendWebhook => 'ارسال وب‌هوک',
  ActivityActionType.markSubmission => 'علامت‌گذاری پاسخ',
  ActivityActionType.assignFollowUp => 'ارجاع پیگیری',
  ActivityActionType.unknown => 'نامشخص',
};

class _MetricMenuDot extends StatelessWidget {
  const _MetricMenuDot({required this.metric});

  final DashboardMetricValueDto2 metric;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: context.l10n.t('dashboard.metricActions'),
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 22,
        color: Color(0xFF1B1F3A),
      ),
      onSelected: (value) {
        switch (value) {
          case 'details':
            _showMetricDetails(context, metric);
            break;
          case 'chart':
            _showMetricChartInfo(context, metric);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'details',
          child: Text(context.l10n.t('dashboard.metricDetails')),
        ),
        PopupMenuItem(
          value: 'chart',
          child: Text(context.l10n.t('dashboard.metricChartAndFormula')),
        ),
      ],
    );
  }
}

void _showMetricDetails(BuildContext context, DashboardMetricValueDto2 metric) {
  final display = metric.display;
  final description = display['description']?.toString();
  final unit = metric.unit ?? display['unit']?.toString();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                metric.title,
                textAlign: TextAlign.start,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description?.isNotEmpty == true
                    ? description!
                    : context.l10n.t('dashboard.metricDefaultDescription'),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 14),
              _MetricInfoRow(
                label: context.l10n.t('metric.currentValue'),
                value: metric.displayValue,
              ),
              _MetricInfoRow(
                label: context.l10n.t('metric.unit'),
                value: unit?.isNotEmpty == true ? unit! : '-',
              ),
              _MetricInfoRow(
                label: context.l10n.t('metric.status'),
                value: _metricStatus(metric) == null
                    ? '-'
                    : _statusLabel(context, _metricStatus(metric)!),
              ),
              _MetricInfoRow(
                label: context.l10n.t('metric.source'),
                value: _friendlyMetricSource(context, metric),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showMetricChartInfo(
  BuildContext context,
  DashboardMetricValueDto2 metric,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n
                  .t('metric.chartTitle')
                  .replaceAll('{title}', metric.title),
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n
                  .t('metric.chartDescription')
                  .replaceAll('{key}', metric.title),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: Consumer(
                builder: (context, ref, _) {
                  final async = ref.watch(metricTimeseriesProvider(metric.key));
                  return async.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => _EmptyTiny(
                      message: FriendlyApiErrorMessage.from(
                        error,
                        context: context,
                      ),
                    ),
                    data: (chart) =>
                        _DashboardLineChart(chart: chart, prominent: true),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check_rounded),
              label: Text(context.l10n.t('close')),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MetricInfoRow extends StatelessWidget {
  const _MetricInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final positive = value >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: (positive ? AppTheme.success : AppTheme.danger).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 14,
            color: positive ? AppTheme.success : AppTheme.danger,
          ),
          Text(
            value.abs().toStringAsFixed(0),
            style: TextStyle(
              color: positive ? AppTheme.success : AppTheme.danger,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendItem(
          color: const Color(0xFF3ACB82),
          label: context.l10n.t('chart.legend.current'),
        ),
        const SizedBox(width: 10),
        _LegendItem(
          color: const Color(0xFF23A7FF),
          label: context.l10n.t('chart.legend.previous'),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DashboardLineChart extends StatelessWidget {
  const _DashboardLineChart({this.chart, this.prominent = false});

  final TimeseriesResponseDto2? chart;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final series = chart?.series ?? const <TimeseriesSeriesDto2>[];
    if (series.isEmpty || series.every((item) => item.points.isEmpty)) {
      return Center(child: _EmptyTiny(message: context.l10n.t('chart.noData')));
    }
    return CustomPaint(
      painter: _LineChartPainter(
        series: series,
        prominent: prominent,
        textDirection: Directionality.of(context),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.series,
    required this.prominent,
    required this.textDirection,
  });

  final List<TimeseriesSeriesDto2> series;
  final bool prominent;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xFFE7ECF4)
      ..strokeWidth = 1;
    final labelPainter = TextPainter(
      textDirection: textDirection,
      textAlign: TextAlign.center,
    );
    final topPad = 10.0;
    final bottomPad = 30.0;
    final leftPad = 28.0;
    final rightPad = 6.0;
    final chartRect = Rect.fromLTWH(
      leftPad,
      topPad,
      size.width - leftPad - rightPad,
      size.height - topPad - bottomPad,
    );
    for (var i = 0; i < 5; i++) {
      final y = chartRect.top + chartRect.height * i / 4;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        axisPaint,
      );
    }
    final allPoints = series.expand((s) => s.points).toList();
    final maxValue = math.max(
      100.0,
      allPoints.fold<double>(0, (p, e) => math.max(p, e.value)),
    );
    final colors = [
      const Color(0xFF3ACB82),
      const Color(0xFF23A7FF),
      AppTheme.warning,
    ];
    for (var si = 0; si < series.length; si++) {
      final points = series[si].points;
      if (points.isEmpty) continue;
      final color = colors[si % colors.length];
      final path = Path();
      final area = Path();
      for (var i = 0; i < points.length; i++) {
        final dx = points.length == 1
            ? chartRect.center.dx
            : chartRect.left + (chartRect.width * i / (points.length - 1));
        final dy =
            chartRect.bottom -
            (points[i].value / maxValue).clamp(0, 1) * chartRect.height;
        if (i == 0) {
          path.moveTo(dx, dy);
          area.moveTo(dx, chartRect.bottom);
          area.lineTo(dx, dy);
        } else {
          path.lineTo(dx, dy);
          area.lineTo(dx, dy);
        }
      }
      area.lineTo(chartRect.right, chartRect.bottom);
      area.close();
      canvas.drawPath(
        area,
        Paint()
          ..color = color.withValues(alpha: prominent ? 0.16 : 0.11)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final labels =
        (series.isNotEmpty
                ? series.first.points
                : const <TimeseriesPointDto2>[])
            .take(6)
            .toList();
    for (var i = 0; i < labels.length; i++) {
      final x = labels.length == 1
          ? chartRect.center.dx
          : chartRect.left + (chartRect.width * i / (labels.length - 1));
      labelPainter.text = TextSpan(
        text: labels[i].label,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF9AA1B6),
          fontWeight: FontWeight.w700,
        ),
      );
      labelPainter.layout(minWidth: 0, maxWidth: 42);
      labelPainter.paint(
        canvas,
        Offset(x - labelPainter.width / 2, chartRect.bottom + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.series != series || oldDelegate.prominent != prominent;
}

class _EmptyTiny extends StatelessWidget {
  const _EmptyTiny({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DashboardLoadFallback extends ConsumerWidget {
  const _DashboardLoadFallback({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oldAnalytics = ref.watch(dashboardAnalyticsProvider);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMax),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _SoftPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionTitle(
                    title: context.l10n.t('dashboard.newNotLoaded'),
                  ),
                  const SizedBox(height: 10),
                  Text(FriendlyApiErrorMessage.from(error, context: context)),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.l10n.t('tryAgain')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            oldAnalytics.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Text(FriendlyApiErrorMessage.from(error, context: context)),
              data: (value) => _SoftPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionTitle(
                      title: context.l10n.t('dashboard.currentStats'),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _LegacyStat(
                          label: context.l10n.t('dashboard.forms'),
                          value: '${value.totalForms}',
                        ),
                        _LegacyStat(
                          label: context.l10n.t('dashboard.published'),
                          value: '${value.publishedForms}',
                        ),
                        _LegacyStat(
                          label: context.l10n.t('dashboard.users'),
                          value: '${value.totalUsers}',
                        ),
                        _LegacyStat(
                          label: context.l10n.t('dashboard.responses'),
                          value: '${value.totalSubmissions}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacyStat extends StatelessWidget {
  const _LegacyStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: _SoftPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

String _surveyStatusLabel(BuildContext context, String status) =>
    switch (status) {
      'completed' => context.l10n.t('status.completed'),
      'in_progress' => context.l10n.t('status.inProgress'),
      'pending' => context.l10n.t('status.pending'),
      'closed' => context.l10n.t('status.closed'),
      'new' => context.l10n.t('status.new'),
      _ => context.l10n.t('status.active'),
    };

String _roleLabel(BuildContext context, UserRole role) => switch (role) {
  UserRole.parent => context.l10n.enumLabel('parent'),
  UserRole.student => context.l10n.enumLabel('student'),
  UserRole.teacher => context.l10n.enumLabel('teacher'),
  UserRole.manager => context.l10n.enumLabel('manager'),
  UserRole.ceo => context.l10n.enumLabel('ceo'),
  UserRole.admin => context.l10n.enumLabel('admin'),
  UserRole.superAdmin => context.l10n.enumLabel('super_admin'),
  _ => context.l10n.t('role.user'),
};

String _statusFor(double? value, double? max) {
  if (value == null) return 'normal';
  final ratio = max == null || max == 0 ? (value / 100) : (value / max);
  if (ratio >= 0.82) return 'excellent';
  if (ratio >= 0.65) return 'good';
  return 'normal';
}

String? _metricStatus(DashboardMetricValueDto2 metric) {
  final explicit = metric.status?.trim();
  if (explicit != null && explicit.isNotEmpty) return explicit;
  if (metric.scaleMax == null || metric.scaleMax == 0) return null;
  return _statusFor(metric.value, metric.scaleMax);
}

Color _statusColor(String status) => switch (status) {
  'success' => AppTheme.success,
  'neutral' => AppTheme.primary,
  'excellent' || 'great' || 'عالی' => AppTheme.success,
  'good' || 'خوب' => AppTheme.primary,
  'warning' || 'normal' || 'معمولی' => AppTheme.warning,
  'danger' || 'bad' => AppTheme.danger,
  _ => AppTheme.primary,
};

String _statusLabel(BuildContext context, String status) => switch (status) {
  'success' => context.l10n.t('metric.status.excellent'),
  'neutral' => context.l10n.t('metric.status.good'),
  'excellent' || 'great' => context.l10n.t('metric.status.excellent'),
  'good' => context.l10n.t('metric.status.good'),
  'warning' || 'normal' => context.l10n.t('metric.status.warning'),
  'danger' || 'bad' => context.l10n.t('metric.status.danger'),
  _ => status,
};

class _CreateUserCard extends ConsumerStatefulWidget {
  const _CreateUserCard({required this.actorRole, required this.onCreated});

  final UserRole actorRole;
  final VoidCallback onCreated;

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
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            decoration: InputDecoration(
              labelText: context.l10n.t('phone'),
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
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
              icon: _saving
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
    final normalizedPhone = PhoneNumberNormalizer.normalize(_phone.text);
    if (!PhoneNumberNormalizer.isLikelyValid(normalizedPhone)) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.t('dashboard.invalidPhone'))),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(usersRepositoryProvider)
          .createUser(
            request: CreateUserRequest(
              phone: normalizedPhone,
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
      widget.onCreated();
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

class _AudienceGroupsCard extends ConsumerStatefulWidget {
  const _AudienceGroupsCard();

  @override
  ConsumerState<_AudienceGroupsCard> createState() =>
      _AudienceGroupsCardState();
}

class _AudienceGroupsCardState extends ConsumerState<_AudienceGroupsCard> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _search = TextEditingController();
  String _groupType = 'class';
  int _page = 1;
  bool _saving = false;
  late Future<ListResponse<AudienceGroupOptionDto2>> _future = _load();

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
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
            icon: Icons.groups_2_outlined,
            title: 'مدیریت کلاس‌ها و گروه‌ها',
            action: IconButton(
              tooltip: context.l10n.t('refresh'),
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'اینجا می‌توانید کلاس/گروه بسازید، کد اختیاری بدهید و کاربران را عضو کنید.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'نام کلاس یا گروه',
                    prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
                  ),
                ),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  initialValue: _groupType,
                  decoration: const InputDecoration(labelText: 'نوع'),
                  items: const [
                    DropdownMenuItem(value: 'class', child: Text('کلاس')),
                    DropdownMenuItem(value: 'group', child: Text('گروه')),
                    DropdownMenuItem(
                      value: 'department',
                      child: Text('دپارتمان'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _groupType = value);
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _code,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  decoration: const InputDecoration(
                    labelText: 'کد اختیاری',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : _create,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(
                  _saving ? context.l10n.t('saving') : 'ساخت کلاس/گروه',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
          FutureBuilder<ListResponse<AudienceGroupOptionDto2>>(
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
              final groups =
                  snapshot.data?.data ?? const <AudienceGroupOptionDto2>[];
              if (groups.isEmpty) {
                return const Text('هنوز کلاس یا گروهی ساخته نشده است.');
              }
              final meta = snapshot.data?.meta?.pagination;
              return Column(
                children: [
                  for (final group in groups)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Icon(_groupTypeIcon(group.groupType)),
                      ),
                      title: Text(
                        group.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${_groupTypeLabel(group.groupType)} · ${group.memberCount} عضو'
                        '${group.code == null ? '' : ' · کد: ${ltrIsolate(group.code!)}'}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            tooltip: 'اعضا',
                            onPressed: () => _manageMembers(group),
                            icon: const Icon(Icons.group_add_outlined),
                          ),
                          IconButton(
                            tooltip: context.l10n.t('delete'),
                            onPressed: () => _delete(group),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: _page > 1
                            ? () => _goToPage(_page - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Text('${context.l10n.t('page')} $_page'),
                      IconButton(
                        onPressed: meta != null && _page < meta.totalPages
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

  Future<ListResponse<AudienceGroupOptionDto2>> _load() {
    return ref
        .read(analyticsRepositoryProvider)
        .listAudienceGroups(
          page: _page,
          pageSize: 8,
          search: _search.text.trim().isEmpty ? null : _search.text.trim(),
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

  Future<void> _create() async {
    final messenger = ScaffoldMessenger.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('نام کلاس/گروه لازم است.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final metadata = <String, Object?>{};
      final code = _code.text.trim();
      if (code.isNotEmpty) metadata['code'] = code;
      await ref
          .read(analyticsRepositoryProvider)
          .createAudienceGroup(
            request: CreateAudienceGroupRequest2(
              name: name,
              groupType: _groupType,
              metadata: metadata,
            ),
          );
      _name.clear();
      _code.clear();
      _page = 1;
      _refresh();
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('کلاس/گروه ساخته شد.')),
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

  Future<void> _manageMembers(AudienceGroupOptionDto2 group) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _GroupMembersDialog(group: group),
    );
    if (mounted) _refresh();
  }

  Future<void> _delete(AudienceGroupOptionDto2 group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف کلاس/گروه'),
        content: Text('«${group.name}» حذف شود؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.t('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(analyticsRepositoryProvider)
          .deleteAudienceGroup(id: group.id);
      _refresh();
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('کلاس/گروه حذف شد.')),
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

class _GroupMembersDialog extends ConsumerStatefulWidget {
  const _GroupMembersDialog({required this.group});

  final AudienceGroupOptionDto2 group;

  @override
  ConsumerState<_GroupMembersDialog> createState() =>
      _GroupMembersDialogState();
}

class _GroupMembersDialogState extends ConsumerState<_GroupMembersDialog> {
  final _search = TextEditingController();
  final _roleInGroup = TextEditingController();
  String? _selectedUserId;
  bool _saving = false;
  late Future<List<AudienceGroupMemberDto2>> _membersFuture = _loadMembers();
  late Future<ListResponse<UserSummaryDto>> _usersFuture = _loadUsers();

  @override
  void dispose() {
    _search.dispose();
    _roleInGroup.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width.clamp(320.0, 620.0);
    return AlertDialog(
      title: Text('اعضای ${widget.group.name}'),
      content: SizedBox(
        width: maxWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FutureBuilder<List<AudienceGroupMemberDto2>>(
                future: _membersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
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
                  final members =
                      snapshot.data ?? const <AudienceGroupMemberDto2>[];
                  if (members.isEmpty) {
                    return const Text(
                      'هنوز عضوی به این کلاس/گروه اضافه نشده است.',
                    );
                  }
                  return Column(
                    children: [
                      for (final member in members)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text(
                              member.displayName.characters.first.toUpperCase(),
                            ),
                          ),
                          title: Text(member.displayName),
                          subtitle: Text(
                            '${context.l10n.enumLabel(member.primaryRole.toJson())}'
                            '${member.roleInGroup == null ? '' : ' · ${member.roleInGroup}'}',
                          ),
                          trailing: IconButton(
                            tooltip: context.l10n.t('delete'),
                            onPressed: _saving ? null : () => _remove(member),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const Divider(height: 28),
              TextField(
                controller: _search,
                decoration: InputDecoration(
                  labelText: 'جستجوی کاربر برای افزودن',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _usersFuture = _loadUsers()),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
                onSubmitted: (_) => setState(() => _usersFuture = _loadUsers()),
              ),
              const SizedBox(height: 10),
              FutureBuilder<ListResponse<UserSummaryDto>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  final users = snapshot.data?.data ?? const <UserSummaryDto>[];
                  final selected =
                      users.any((user) => user.id == _selectedUserId)
                      ? _selectedUserId
                      : null;
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text(
                      FriendlyApiErrorMessage.from(
                        snapshot.error!,
                        context: context,
                      ),
                    );
                  }
                  if (users.isEmpty) {
                    return const Text('کاربری پیدا نشد.');
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: selected,
                    decoration: const InputDecoration(labelText: 'کاربر'),
                    items: [
                      for (final user in users)
                        DropdownMenuItem(
                          value: user.id,
                          child: Text('${user.displayName} · ${user.phone}'),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedUserId = value),
                  );
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _roleInGroup,
                decoration: const InputDecoration(
                  labelText:
                      'نقش داخل گروه (اختیاری؛ مثل دانش‌آموز، نماینده، مربی)',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _add,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.group_add_rounded),
                  label: const Text('افزودن کاربر'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.t('close')),
        ),
      ],
    );
  }

  Future<List<AudienceGroupMemberDto2>> _loadMembers() {
    return ref
        .read(analyticsRepositoryProvider)
        .listAudienceGroupMembers(id: widget.group.id);
  }

  Future<ListResponse<UserSummaryDto>> _loadUsers() {
    return ref
        .read(usersRepositoryProvider)
        .listUsers(
          page: 1,
          pageSize: 20,
          search: _search.text.trim().isEmpty ? null : _search.text.trim(),
          sortBy: 'display_name',
          sortOrder: SortOrder.asc,
        );
  }

  Future<void> _add() async {
    final messenger = ScaffoldMessenger.of(context);
    final selected = _selectedUserId;
    if (selected == null || selected.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('ابتدا یک کاربر انتخاب کنید.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(analyticsRepositoryProvider)
          .addAudienceGroupMember(
            id: widget.group.id,
            member: AudienceGroupMemberInputDto2(
              userId: selected,
              roleInGroup: _roleInGroup.text.trim().isEmpty
                  ? null
                  : _roleInGroup.text.trim(),
            ),
          );
      _roleInGroup.clear();
      setState(() => _membersFuture = _loadMembers());
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('کاربر به کلاس/گروه اضافه شد.')),
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

  Future<void> _remove(AudienceGroupMemberDto2 member) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(analyticsRepositoryProvider)
          .removeAudienceGroupMember(
            id: widget.group.id,
            userId: member.userId,
          );
      setState(() => _membersFuture = _loadMembers());
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

String _groupTypeLabel(String value) => switch (value) {
  'class' => 'کلاس',
  'department' => 'دپارتمان',
  _ => 'گروه',
};

IconData _groupTypeIcon(String value) => switch (value) {
  'class' => Icons.school_outlined,
  'department' => Icons.account_tree_outlined,
  _ => Icons.groups_outlined,
};

class _UserManagementCard extends ConsumerStatefulWidget {
  const _UserManagementCard({super.key, required this.actorRole});

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
                        '${context.l10n.enumLabel(user.primaryRole.toJson())} · '
                        '${ltrIsolate(user.phone)}'
                        '${user.email == null ? '' : ' · ${ltrIsolate(user.email!)}'}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          Chip(label: Text(user.status)),
                          if (_canHaveFamilyLinks(user.primaryRole))
                            IconButton(
                              tooltip: context.l10n.t('familyLinks'),
                              onPressed: () => _manageFamily(user),
                              icon: const Icon(Icons.family_restroom_rounded),
                            ),
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
                        onPressed: _page > 1
                            ? () => _goToPage(_page - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Text('${context.l10n.t('page')} $_page'),
                      IconButton(
                        onPressed: meta != null && _page < meta.totalPages
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

  Future<void> _manageFamily(UserSummaryDto user) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _FamilyLinksDialog(user: user),
    );
    if (mounted) _refresh();
  }

  Future<void> _edit(UserSummaryDto user) async {
    final result = await showDialog<UpdateUserRequest>(
      context: context,
      builder: (context) =>
          _EditUserDialog(user: user, roles: _creatableRoles(widget.actorRole)),
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
  bool _banAvatar = false;

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
    final maxWidth = MediaQuery.sizeOf(context).width.clamp(280.0, 460.0);
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
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                decoration: InputDecoration(labelText: context.l10n.t('phone')),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                decoration: InputDecoration(labelText: context.l10n.t('email')),
              ),
              const SizedBox(height: AppSpacing.xs),
              _GenderDropdown(
                value: _gender,
                onChanged: (value) => setState(() => _gender = value),
              ),
              const SizedBox(height: AppSpacing.xs),
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
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: context.l10n.t('status'),
                ),
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
              const SizedBox(height: AppSpacing.xs),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _banAvatar,
                onChanged: (value) =>
                    setState(() => _banAvatar = value ?? false),
                title: Text(context.l10n.t('banAvatar')),
                controlAffinity: ListTileControlAffinity.leading,
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
                phone: PhoneNumberNormalizer.normalize(_phone.text),
                email: _email.text.trim().isEmpty ? null : _email.text.trim(),
                primaryRole: _role,
                gender: _gender,
                status: _status,
                profile: _banAvatar
                    ? const UserProfileDto(
                        avatarUrl: null,
                        metadata: <String, Object?>{'avatar_banned': true},
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
}

bool _canHaveFamilyLinks(UserRole role) =>
    role == UserRole.parent || role == UserRole.student;

class _FamilyLinksDialog extends ConsumerStatefulWidget {
  const _FamilyLinksDialog({required this.user});

  final UserSummaryDto user;

  @override
  ConsumerState<_FamilyLinksDialog> createState() => _FamilyLinksDialogState();
}

class _FamilyLinksDialogState extends ConsumerState<_FamilyLinksDialog> {
  final _candidateSearch = TextEditingController();
  late Future<UserFamilyLinksDto> _linksFuture = _loadLinks();
  late Future<ListResponse<UserSummaryDto>> _candidatesFuture =
      _loadCandidates();
  String? _selectedUserId;
  bool _saving = false;

  UserRole get _candidateRole => widget.user.primaryRole == UserRole.student
      ? UserRole.parent
      : UserRole.student;

  bool get _isStudent => widget.user.primaryRole == UserRole.student;

  @override
  void dispose() {
    _candidateSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width.clamp(300.0, 560.0);
    return AlertDialog(
      title: Text(context.l10n.t('familyLinks')),
      content: SizedBox(
        width: maxWidth,
        child: FutureBuilder<UserFamilyLinksDto>(
          future: _linksFuture,
          builder: (context, linksSnapshot) {
            if (linksSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (linksSnapshot.hasError) {
              return Text(
                FriendlyApiErrorMessage.from(
                  linksSnapshot.error!,
                  context: context,
                ),
              );
            }
            final links =
                linksSnapshot.data ??
                const UserFamilyLinksDto(parents: [], children: []);
            final activeLinks = _isStudent ? links.parents : links.children;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FamilyTargetSummary(user: widget.user),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _isStudent
                        ? context.l10n.t('linkedParents')
                        : context.l10n.t('linkedStudents'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (activeLinks.isEmpty)
                    Text(
                      _isStudent
                          ? context.l10n.t('noLinkedParents')
                          : context.l10n.t('noLinkedStudents'),
                    )
                  else
                    for (final link in activeLinks)
                      _FamilyLinkTile(
                        link: link,
                        onDelete: _saving
                            ? null
                            : () => _deleteRelationship(link),
                      ),
                  const Divider(height: AppSpacing.xl),
                  Text(
                    _isStudent
                        ? context.l10n.t('addParentToStudent')
                        : context.l10n.t('addStudentToParent'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _isStudent
                        ? context.l10n.t('addParentToStudentHint')
                        : context.l10n.t('addStudentToParentHint'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _candidateSearch,
                          decoration: InputDecoration(
                            labelText: context.l10n.t(
                              'searchUserByNameOrPhone',
                            ),
                            prefixIcon: const Icon(Icons.search_rounded),
                          ),
                          onSubmitted: (_) => _refreshCandidates(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      IconButton.filledTonal(
                        tooltip: context.l10n.t('search'),
                        onPressed: _refreshCandidates,
                        icon: const Icon(Icons.search_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FutureBuilder<ListResponse<UserSummaryDto>>(
                    future: _candidatesFuture,
                    builder: (context, candidatesSnapshot) {
                      if (candidatesSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (candidatesSnapshot.hasError) {
                        return Text(
                          FriendlyApiErrorMessage.from(
                            candidatesSnapshot.error!,
                            context: context,
                          ),
                        );
                      }
                      final linkedIds = activeLinks
                          .map((link) => link.user.id)
                          .toSet();
                      final candidates =
                          (candidatesSnapshot.data?.data ??
                                  const <UserSummaryDto>[])
                              .where(
                                (candidate) =>
                                    candidate.primaryRole == _candidateRole &&
                                    candidate.id != widget.user.id &&
                                    !linkedIds.contains(candidate.id) &&
                                    (widget.user.organizationId == null ||
                                        candidate.organizationId ==
                                            widget.user.organizationId),
                              )
                              .toList(growable: false);
                      if (candidates.isEmpty) {
                        return Text(
                          _candidateRole == UserRole.parent
                              ? context.l10n.t('noParentCandidates')
                              : context.l10n.t('noStudentCandidates'),
                        );
                      }
                      final selectedStillExists = candidates.any(
                        (user) => user.id == _selectedUserId,
                      );
                      final effectiveSelectedId = selectedStillExists
                          ? _selectedUserId
                          : null;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: effectiveSelectedId,
                            decoration: InputDecoration(
                              labelText: _candidateRole == UserRole.parent
                                  ? context.l10n.t('selectParent')
                                  : context.l10n.t('selectStudent'),
                            ),
                            items: [
                              for (final candidate in candidates)
                                DropdownMenuItem(
                                  value: candidate.id,
                                  child: Text(
                                    '${candidate.displayName} · ${ltrIsolate(candidate.phone)}',
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedUserId = value);
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          FilledButton.icon(
                            onPressed: _saving || effectiveSelectedId == null
                                ? null
                                : _addRelationship,
                            icon: _saving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.link_rounded),
                            label: Text(context.l10n.t('linkUsers')),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.t('close')),
        ),
      ],
    );
  }

  Future<UserFamilyLinksDto> _loadLinks() {
    return ref
        .read(usersRepositoryProvider)
        .getUserRelationships(id: widget.user.id);
  }

  Future<ListResponse<UserSummaryDto>> _loadCandidates() {
    return ref
        .read(usersRepositoryProvider)
        .listUsers(
          page: 1,
          pageSize: 50,
          search: _candidateSearch.text.trim().isEmpty
              ? null
              : _candidateSearch.text.trim(),
          sortBy: 'display_name',
          sortOrder: SortOrder.asc,
        );
  }

  void _refreshLinks() {
    setState(() {
      _linksFuture = _loadLinks();
      _selectedUserId = null;
    });
  }

  void _refreshCandidates() {
    setState(() {
      _selectedUserId = null;
      _candidatesFuture = _loadCandidates();
    });
  }

  Future<void> _addRelationship() async {
    final selectedUserId = _selectedUserId;
    if (selectedUserId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(usersRepositoryProvider)
          .createUserRelationship(
            id: widget.user.id,
            request: CreateUserRelationshipRequest(
              relatedUserId: selectedUserId,
            ),
          );
      if (!mounted) return;
      _refreshLinks();
      _refreshCandidates();
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.t('familyLinkCreated'))),
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

  Future<void> _deleteRelationship(UserFamilyRelationshipDto link) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(usersRepositoryProvider)
          .deleteUserRelationship(
            id: widget.user.id,
            relationshipId: link.relationship.id,
          );
      if (!mounted) return;
      _refreshLinks();
      _refreshCandidates();
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.t('familyLinkDeleted'))),
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

class _FamilyTargetSummary extends StatelessWidget {
  const _FamilyTargetSummary({required this.user});

  final UserSummaryDto user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            child: Text(user.displayName.characters.first.toUpperCase()),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${context.l10n.enumLabel(user.primaryRole.toJson())} · ${ltrIsolate(user.phone)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyLinkTile extends StatelessWidget {
  const _FamilyLinkTile({required this.link, required this.onDelete});

  final UserFamilyRelationshipDto link;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final user = link.user;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Text(user.displayName.characters.first.toUpperCase()),
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${context.l10n.enumLabel(user.primaryRole.toJson())} · ${ltrIsolate(user.phone)}',
      ),
      trailing: IconButton(
        tooltip: context.l10n.t('unlink'),
        onPressed: onDelete,
        icon: const Icon(Icons.link_off_rounded),
      ),
    );
  }
}

class _PendingApprovalCard extends ConsumerStatefulWidget {
  const _PendingApprovalCard();

  @override
  ConsumerState<_PendingApprovalCard> createState() =>
      _PendingApprovalCardState();
}

class _PendingApprovalCardState extends ConsumerState<_PendingApprovalCard> {
  late Future<ListResponse<FormSummaryDto>> _future = _load();
  bool _busy = false;

  Future<ListResponse<FormSummaryDto>> _load() {
    return ref
        .read(formsRepositoryProvider)
        .listForms(
          page: 1,
          pageSize: 100,
          sortBy: 'updated_at',
          sortOrder: SortOrder.desc,
          status: FormStatus.pendingReview.toJson(),
        );
  }

  void _refresh() {
    setState(() => _future = _load());
    ref.invalidate(dashboardExperienceProvider);
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: FutureBuilder<ListResponse<FormSummaryDto>>(
        future: _future,
        builder: (context, snapshot) {
          final pending = snapshot.data?.data ?? const <FormSummaryDto>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardHeader(
                icon: Icons.pending_actions_rounded,
                title: context.l10n.t('pendingApprovalForms'),
                action: IconButton.filledTonal(
                  tooltip: context.l10n.t('refresh'),
                  onPressed: _busy ? null : _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    FriendlyApiErrorMessage.from(
                      snapshot.error!,
                      context: context,
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
                for (final form in pending) ...[
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
                          onPressed: _busy ? null : () => _approve(form),
                          child: Text(context.l10n.t('approve')),
                        ),
                        IconButton(
                          tooltip: context.l10n.t('settings'),
                          onPressed: _busy
                              ? null
                              : () => context.go('/forms/${form.id}/publish'),
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ],
                    ),
                    onTap: () => context.go('/forms/${form.id}'),
                  ),
                  if (form != pending.last) const Divider(height: 8),
                ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _approve(FormSummaryDto form) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(formsRepositoryProvider)
          .approveForm(
            id: form.id,
            request: const ApproveFormRequest(publishAfterApproval: false),
          );
      ref.invalidate(formsControllerProvider);
      ref.invalidate(dashboardExperienceProvider);
      _refresh();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.t('settingsSaved'))),
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
      if (mounted) setState(() => _busy = false);
    }
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
                          onPressed: () =>
                              context.go('/forms/${form.id}/settings'),
                          icon: const Icon(Icons.tune_rounded),
                        ),
                        IconButton(
                          tooltip: 'هدف‌گیری فرم',
                          onPressed: () =>
                              _showFormAssignmentsDialog(context, ref, form),
                          icon: const Icon(Icons.hub_outlined),
                        ),
                        IconButton(
                          tooltip: 'قواعد فعالیت',
                          onPressed: () =>
                              _showActivityRulesDialog(context, ref, form),
                          icon: const Icon(Icons.rule_folder_outlined),
                        ),
                        IconButton(
                          tooltip: context.l10n.t('editField'),
                          onPressed: () =>
                              context.go('/forms/${form.id}/builder'),
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
        ?action,
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
  UserRole.admin => const [UserRole.parent, UserRole.teacher, UserRole.student],
  UserRole.ceo => const [
    UserRole.parent,
    UserRole.teacher,
    UserRole.student,
    UserRole.manager,
  ],
  UserRole.superAdmin => const [
    UserRole.parent,
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

String? _visibleDashboardAvatarUrl(UserProfileDto profile) {
  final metadata = profile.metadata;
  if (metadata is Map && metadata['avatar_banned'] == true) return null;
  final avatar = profile.avatarUrl;
  return avatar == null || avatar.isEmpty ? null : avatar;
}

ImageProvider<Object>? _dashboardAvatarImageProvider(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.isEmpty) return null;
  final bytes = _decodeDashboardDataUrl(avatarUrl);
  if (bytes != null) return MemoryImage(bytes);
  return NetworkImage(avatarUrl);
}

Uint8List? _decodeDashboardDataUrl(String value) {
  final match = RegExp(r'^data:image/[^;]+;base64,(.+)$').firstMatch(value);
  if (match == null) return null;
  try {
    return base64Decode(match.group(1)!);
  } catch (_) {
    return null;
  }
}
