import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../data/dto/dto.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/common/friendly_api_error_message.dart';
import '../../../presentation/theme/app_breakpoints.dart';
import '../../../presentation/theme/app_spacing.dart';
import '../../../presentation/theme/app_theme.dart';
import '../../../presentation/widgets/app_chrome.dart';
import '../../../presentation/widgets/app_shell.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return AppShell(
      selected: AppDestination.dashboard,
      appBar: AdaptiveAppBar(
        title: const Text('داشبورد'),
        primaryAction: IconButton.filledTonal(
          tooltip: 'فرم‌ها',
          onPressed: () => context.go('/forms'),
          icon: const Icon(Icons.article_outlined),
        ),
      ),
      body: auth.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _DashboardError(onLogin: () => context.go('/login')),
        data: (session) {
          if (session == null) return _DashboardError(onLogin: () => context.go('/login'));
          return _ExperienceDashboard(session: session);
        },
      ),
    );
  }
}

class _ExperienceDashboard extends ConsumerStatefulWidget {
  const _ExperienceDashboard({required this.session});

  final AuthSession session;

  @override
  ConsumerState<_ExperienceDashboard> createState() => _ExperienceDashboardState();
}

class _ExperienceDashboardState extends ConsumerState<_ExperienceDashboard> {
  String _period = 'this_month';

  DashboardQueryInput get _query => DashboardQueryInput(period: _period, compare: 'previous_period');

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
        final role = widget.session.user.primaryRole;
        final management = _isManagementRole(role);
        final family = role == UserRole.parent || role == UserRole.student;
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardExperienceProvider(_query)),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: ListView(
                padding: EdgeInsets.fromLTRB(18, 8, 18, compact ? 104 : 40),
                children: [
                  _DashboardTopBar(
                    dashboard: dashboard,
                    user: widget.session.user,
                    period: _period,
                    onPeriodChanged: (value) => setState(() => _period = value),
                  ),
                  const SizedBox(height: 16),
                  if (family) ...[
                    _FamilyHero(dashboard: dashboard, user: widget.session.user),
                    const SizedBox(height: 16),
                    _ParentSurveyArea(dashboard: dashboard),
                  ] else ...[
                    _ManagementHero(dashboard: dashboard),
                    const SizedBox(height: 16),
                    _OperationalCards(dashboard: dashboard),
                  ],
                  const SizedBox(height: 16),
                  _ResponsiveTwoColumn(
                    left: _DynamicMetricsGrid(metrics: dashboard.metrics),
                    right: _SurveyStatusAndCalendar(dashboard: dashboard),
                  ),
                  const SizedBox(height: 16),
                  _ResponsiveTwoColumn(
                    left: _LatestSurveysCard(surveys: dashboard.latestSurveys),
                    right: _ActivitiesCard(items: dashboard.activities),
                  ),
                  if (management && (dashboard.rankings.isNotEmpty || dashboard.activities.isNotEmpty)) ...[
                    const SizedBox(height: 16),
                    _RankingsAndAlerts(dashboard: dashboard),
                  ],
                  if (management) ...[
                    const SizedBox(height: 16),
                    _ManagementConfigurationRow(role: widget.session.user.primaryRole),
                    const SizedBox(height: 16),
                    _CreateUserCard(actorRole: widget.session.user.primaryRole),
                    const SizedBox(height: 16),
                    _UserManagementCard(actorRole: widget.session.user.primaryRole),
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

class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({
    required this.dashboard,
    required this.user,
    required this.period,
    required this.onPeriodChanged,
  });

  final DashboardResponseDto2 dashboard;
  final UserDetailDto user;
  final String period;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final title = dashboard.role == UserRole.parent
        ? 'پیشرفت ${dashboard.children.isNotEmpty ? dashboard.children.first.displayName : 'فرزند'}'
        : dashboard.role == UserRole.student
            ? 'داشبورد دانش‌آموز'
            : 'داشبورد ${_roleLabel(dashboard.role)}';
    return Row(
      children: [
        IconButton.filled(
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) navigator.maybePop();
          },
          style: IconButton.styleFrom(backgroundColor: AppTheme.ink, foregroundColor: Colors.white),
          icon: Icon(context.l10n.textDirection == TextDirection.rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(title, style: theme.textTheme.headlineSmall?.copyWith(color: const Color(0xFF5F6388), fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text('${user.displayName} · ${_roleLabel(user.primaryRole)}', style: theme.textTheme.bodySmall?.copyWith(color: muted)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _PeriodDropdown(value: period, onChanged: onPeriodChanged),
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
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.expand_more_rounded, size: 18),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF747A9A)),
          items: const [
            DropdownMenuItem(value: 'this_month', child: Text('ماه جاری')),
            DropdownMenuItem(value: 'last_month', child: Text('ماه گذشته')),
            DropdownMenuItem(value: 'last_3_months', child: Text('۳ ماهه')),
            DropdownMenuItem(value: 'this_year', child: Text('سال جاری')),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _FamilyHero extends StatelessWidget {
  const _FamilyHero({required this.dashboard, required this.user});

  final DashboardResponseDto2 dashboard;
  final UserDetailDto user;

  @override
  Widget build(BuildContext context) {
    final child = dashboard.children.isNotEmpty ? dashboard.children.first : null;
    return _SoftPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (child != null)
            _ChildCard(child: child)
          else
            _StudentProfileCard(user: user),
          const SizedBox(height: 18),
          _SectionTitle(title: dashboard.role == UserRole.student ? 'مشارکت من در فعالیت‌ها' : 'مشارکت در فعالیت‌ها', trailing: _ChartLegend()),
          const SizedBox(height: 12),
          SizedBox(height: 176, child: _DashboardLineChart(chart: dashboard.charts.isNotEmpty ? dashboard.charts.first : null)),
        ],
      ),
    );
  }
}

class _ManagementHero extends StatelessWidget {
  const _ManagementHero({required this.dashboard});

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
            title: 'مشارکت در نظرسنجی',
            trailing: _ChartLegend(),
          ),
          const SizedBox(height: 14),
          SizedBox(height: 210, child: _DashboardLineChart(chart: chart, prominent: true)),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child});

  final ChildProfileDto2 child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: const Color(0xFFFFE2C1),
            backgroundImage: child.avatarUrl == null ? null : NetworkImage(child.avatarUrl!),
            child: child.avatarUrl == null ? const Text('👧', style: TextStyle(fontSize: 28)) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(child.displayName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text([child.gradeLabel, child.className].whereType<String>().where((e) => e.isNotEmpty).join(' · '), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          TextButton(onPressed: () => context.go('/profile'), child: const Text('نمایش پروفایل')),
        ],
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(user.displayName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text('نمای دانش‌آموزی · نظرسنجی‌ها و شاخص‌های مربوط به خودتان', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          TextButton(onPressed: () => context.go('/profile'), child: const Text('نمایش پروفایل')),
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
    final fresh = surveys.where((s) => s.status == 'new' || s.status == 'pending').take(2).toList();
    return _SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TextButton(onPressed: () => context.go('/forms'), child: const Text('دیدن همه')),
              const Spacer(),
              const _SectionTitle(title: 'نظرسنجی جدید'),
            ],
          ),
          const SizedBox(height: 12),
          if (fresh.isEmpty)
            const _EmptyTiny(message: 'نظرسنجی جدیدی برای شما وجود ندارد')
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
          const _SectionTitle(title: 'نمای کلی نظرسنجی'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _StatusMini(label: 'تمام شده', value: summary.completed, color: AppTheme.primary)),
              const SizedBox(width: 10),
              Expanded(child: _StatusMini(label: 'در حال انجام', value: summary.inProgress, color: AppTheme.warning)),
              const SizedBox(width: 10),
              Expanded(child: _StatusMini(label: 'در انتظار', value: summary.pending + summary.newItems, color: const Color(0xFF8C90A9))),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusMini extends StatelessWidget {
  const _StatusMini({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('$value', style: theme.textTheme.headlineMedium?.copyWith(color: AppTheme.ink, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _OperationalCards extends StatelessWidget {
  const _OperationalCards({required this.dashboard});

  final DashboardResponseDto2 dashboard;

  @override
  Widget build(BuildContext context) {
    final summary = dashboard.surveySummary;
    final total = summary.completed + summary.inProgress + summary.pending + summary.newItems;
    return _ResponsiveTwoColumn(
      left: _SoftPanel(
        child: _BigNumberTile(title: 'تعداد مشارکت', value: '$total', subtitle: 'بر اساس نقش و assignmentهای جدید', trend: dashboard.metrics.isNotEmpty ? dashboard.metrics.first.trend : null),
      ),
      right: _SoftPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle(title: 'هشدارها و موارد نیازمند توجه'),
            const SizedBox(height: 10),
            if (dashboard.activities.isEmpty)
              const _EmptyTiny(message: 'مورد جدیدی ثبت نشده است')
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
  const _BigNumberTile({required this.title, required this.value, required this.subtitle, this.trend});

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
          decoration: BoxDecoration(color: const Color(0xFFE9F8EF), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.trending_up_rounded, color: AppTheme.success, size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.ink)),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
      return const _SoftPanel(
        child: _EmptyTiny(
          message: 'هنوز شاخصی برای این داشبورد تعریف نشده است. مدیر یا CEO می‌تواند شاخص‌های داینامیک را در سرور تعریف و به فیلدهای فرم متصل کند.',
        ),
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
                width: twoColumns ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth,
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
    final status = metric.status ?? _statusFor(metric.value, metric.scaleMax);
    final statusColor = _statusColor(status);
    return _SoftPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              _MetricMenuDot(metric: metric),
              const Spacer(),
              Text(metric.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          Text(metric.displayValue, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.ink)),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
              child: Text(_statusLabel(status), style: theme.textTheme.labelMedium?.copyWith(color: statusColor, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurveyStatusAndCalendar extends ConsumerWidget {
  const _SurveyStatusAndCalendar({required this.dashboard});

  final DashboardResponseDto2 dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendar = ref.watch(surveyCalendarProvider(dashboard.period));
    return _SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          calendar.when(
            loading: () => const Row(
              children: const [
                _SectionTitle(title: 'تقویم نظرسنجی‌ها'),
                Spacer(),
                SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            error: (error, _) => Row(
              children: [
                const _SectionTitle(title: 'تقویم نظرسنجی‌ها'),
                const Spacer(),
                IconButton(
                  tooltip: 'تلاش مجدد',
                  onPressed: () => ref.invalidate(surveyCalendarProvider(dashboard.period)),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            data: (value) => Row(
              children: [
                const _SectionTitle(title: 'تقویم نظرسنجی‌ها'),
                const Spacer(),
                TextButton(
                  onPressed: value.days.isEmpty ? null : () => _showCalendarSheet(context, value),
                  child: const Text('دیدن همه'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          calendar.when(
            loading: () => const SizedBox(height: 74, child: Center(child: CircularProgressIndicator())),
            error: (error, _) => _EmptyTiny(message: FriendlyApiErrorMessage.from(error, context: context)),
            data: (value) {
              final visibleDays = value.days.where((day) => day.count > 0 || day.highlight).take(14).toList();
              final days = visibleDays.isEmpty ? value.days.take(14).toList() : visibleDays;
              if (days.isEmpty) return const _EmptyTiny(message: 'برای این بازه زمانی نظرسنجی زمان‌بندی نشده است.');
              return _CalendarStrip(days: days, onDayTap: (day) => _showCalendarDaySheet(context, day));
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
                    border: Border.all(color: day.count > 0 ? AppTheme.primary : const Color(0xFFE4E9F3)),
                  ),
                  child: Column(
                    children: [
                      Text(day.weekday ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: day.count > 0 ? Colors.white : theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Text(day.label, style: theme.textTheme.titleMedium?.copyWith(color: day.count > 0 ? Colors.white : AppTheme.ink, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Container(width: 7, height: 7, decoration: BoxDecoration(color: day.count > 0 ? Colors.white : const Color(0xFFD8DDE8), shape: BoxShape.circle)),
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
                Text('همه روزهای تقویم نظرسنجی', textAlign: TextAlign.right, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
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
            Text('${day.weekday ?? ''} ${day.label}', textAlign: TextAlign.right, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            if (day.surveys.isEmpty)
              const _EmptyTiny(message: 'در این روز نظرسنجی فعالی وجود ندارد.')
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE4E9F3))),
        child: Row(
          children: [
            Text('${day.count} مورد', style: theme.textTheme.labelLarge?.copyWith(color: day.count > 0 ? AppTheme.primary : theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w900)),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(day.date, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                Text('${day.weekday ?? ''} ${day.label}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
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
      onTap: survey.formId.isEmpty ? null : () => context.go('/forms/${survey.formId}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF4F7FB), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            _StatusPill(status: survey.status),
            const Spacer(),
            Expanded(
              flex: 2,
              child: Text(survey.title, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(_surveyStatusLabel(status), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w900)),
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
              TextButton(onPressed: () => context.go('/forms'), child: const Text('دیدن همه')),
              const Spacer(),
              const _SectionTitle(title: 'آخرین نظرسنجی‌ها'),
            ],
          ),
          const SizedBox(height: 12),
          if (surveys.isEmpty)
            const _EmptyTiny(message: 'هنوز نظرسنجی در دسترس نیست')
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

class _SurveyTile extends StatelessWidget {
  const _SurveyTile({required this.survey, this.primary = false});

  final SurveyCardDto2 survey;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go('/forms/${survey.formId}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            if (primary)
              SizedBox(
                width: 96,
                child: FilledButton(onPressed: () => context.go('/forms/${survey.formId}'), child: const Text('شروع')),
              )
            else
              Text(survey.dateLabel ?? '${survey.questionCount} پرسش', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(survey.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  if ((survey.dateLabel ?? survey.description ?? '').isNotEmpty)
                    Text(survey.dateLabel ?? survey.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
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
          const _SectionTitle(title: 'آخرین فعالیت‌ها'),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const _EmptyTiny(message: 'فعلاً فعالیت جدیدی وجود ندارد')
          else
            for (final item in items.take(5))
              _ActivityRow(item: item),
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
          Text(item.timeAgo ?? '', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                if ((item.subtitle ?? '').isNotEmpty)
                  Text(item.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFFE8EEFF), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.task_alt_rounded, size: 18, color: AppTheme.primary)),
        ],
      ),
    );
  }
}

class _RankingsAndAlerts extends ConsumerWidget {
  const _RankingsAndAlerts({required this.dashboard});

  final DashboardResponseDto2 dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(rpAlertsProvider(dashboard.period));
    return _ResponsiveTwoColumn(
      left: _SoftPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle(title: 'بیشترین رضایت'),
            const SizedBox(height: 12),
            if (dashboard.rankings.isEmpty || dashboard.rankings.first.items.isEmpty)
              const _EmptyTiny(message: 'رتبه‌بندی آماده نیست')
            else
              for (final item in dashboard.rankings.first.items.take(5))
                _RankingRow(item: item),
          ],
        ),
      ),
      right: _SoftPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle(title: 'بیشترین نارضایتی'),
            const SizedBox(height: 12),
            alerts.when(
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              error: (_, _) => const _EmptyTiny(message: 'هشداری ثبت نشده است'),
              data: (value) => value.items.isEmpty
                  ? const _EmptyTiny(message: 'هشداری ثبت نشده است')
                  : Column(children: [for (final item in value.items.take(5)) _AlertRow(item: item)]),
            ),
          ],
        ),
      ),
    );
  }
}

final rpAlertsProvider = FutureProvider.family<AnalyticsAlertsResponseDto2, String>((ref, period) {
  return ref.watch(analyticsRepositoryProvider).getAnalyticsAlerts(period: period, limit: 10);
});

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
          Text('${item.score.toStringAsFixed(0)}٪', style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              if ((item.subtitle ?? '').isNotEmpty) Text(item.subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(width: 10),
          CircleAvatar(radius: 16, backgroundColor: const Color(0xFFE8EEFF), child: Text('${item.rank}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.item});

  final AnalyticsAlertDto2 item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                if ((item.description ?? '').isNotEmpty) Text(item.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
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
      left: _SoftPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(children: [Icon(Icons.insights_rounded, color: AppTheme.primary), SizedBox(width: 8), _SectionTitle(title: 'شاخص‌های داینامیک')]),
            const SizedBox(height: 10),
            metrics.when(
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              error: (error, _) => Text(FriendlyApiErrorMessage.from(error, context: context)),
              data: (value) => _ManagementList(
                empty: 'هنوز شاخصی تعریف نشده است',
                items: [
                  for (final metric in value.data ?? const <MetricDefinitionDto2>[])
                    _ManagementListItem(title: metric.title, subtitle: '${metric.key} · ${metric.metricType}', trailing: '${metric.mappingCount} مپ'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text('مدیر و CEO می‌توانند شاخص‌ها را در سرور تعریف/ویرایش/حذف کنند؛ این لیست مستقیم از /metrics خوانده می‌شود.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
      right: _SoftPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(children: [Icon(Icons.groups_2_rounded, color: AppTheme.primary), SizedBox(width: 8), _SectionTitle(title: 'گروه‌های هدف و Segmentها')]),
            const SizedBox(height: 10),
            segments.when(
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              error: (error, _) => Text(FriendlyApiErrorMessage.from(error, context: context)),
              data: (value) => _ManagementList(
                empty: 'هنوز segment تعریف نشده است',
                items: [
                  for (final segment in value.data ?? const <AudienceSegmentDto2>[])
                    _ManagementListItem(title: segment.name, subtitle: '${segment.slug} · ${segment.segmentType}', trailing: '${segment.memberCount} نفر'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text('برای مواردی مثل «شرکت‌کنندگان اردوی ۲۷ام»، فرم‌ها از assignment جدید به این Segmentها متصل می‌شوند.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
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
  const _ManagementListItem({required this.title, required this.subtitle, required this.trailing});

  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Text(trailing, style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
    if (trailing == null) return Align(alignment: AlignmentDirectional.centerEnd, child: titleWidget);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        trailing!,
        const SizedBox(width: 8),
        titleWidget,
      ],
    );
  }
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF161C30) : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(blurRadius: 28, offset: const Offset(0, 14), color: Colors.black.withValues(alpha: dark ? 0.18 : 0.045)),
        ],
      ),
      child: child,
    );
  }
}

class _MetricMenuDot extends StatelessWidget {
  const _MetricMenuDot({required this.metric});

  final DashboardMetricValueDto2 metric;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'عملیات شاخص',
      icon: const Icon(Icons.more_vert_rounded, size: 22, color: Color(0xFF1B1F3A)),
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
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'details', child: Text('جزئیات شاخص')),
        PopupMenuItem(value: 'chart', child: Text('نحوه محاسبه و نمودار')),
      ],
    );
  }
}

void _showMetricDetails(BuildContext context, DashboardMetricValueDto2 metric) {
  final display = metric.display;
  final source = display['source']?.toString();
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
              Text(metric.title, textAlign: TextAlign.right, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(description?.isNotEmpty == true ? description! : 'این شاخص از endpoint داشبورد سرور خوانده می‌شود و مقدار آن بر اساس mappingهای تعریف‌شده برای شاخص محاسبه شده است.', textAlign: TextAlign.right),
              const SizedBox(height: 14),
              _MetricInfoRow(label: 'کلید شاخص', value: metric.key),
              _MetricInfoRow(label: 'مقدار فعلی', value: metric.displayValue),
              _MetricInfoRow(label: 'واحد', value: unit?.isNotEmpty == true ? unit! : '-'),
              _MetricInfoRow(label: 'وضعیت', value: _statusLabel(metric.status ?? _statusFor(metric.value, metric.scaleMax))),
              _MetricInfoRow(label: 'منبع', value: source?.isNotEmpty == true ? source! : 'metric_definitions + metric_mappings'),
            ],
          ),
        ),
      );
    },
  );
}

void _showMetricChartInfo(BuildContext context, DashboardMetricValueDto2 metric) {
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
            Text('نمودار ${metric.title}', textAlign: TextAlign.right, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(
              'این نمودار از /api/v1/analytics/timeseries با metric=${metric.key} خوانده می‌شود.',
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: Consumer(
                builder: (context, ref, _) {
                  final async = ref.watch(metricTimeseriesProvider(metric.key));
                  return async.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => _EmptyTiny(message: FriendlyApiErrorMessage.from(error, context: context)),
                    data: (chart) => _DashboardLineChart(chart: chart, prominent: true),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check_rounded),
              label: const Text('بستن'),
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
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800))),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
      decoration: BoxDecoration(color: (positive ? AppTheme.success : AppTheme.danger).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14, color: positive ? AppTheme.success : AppTheme.danger),
          Text(value.abs().toStringAsFixed(0), style: TextStyle(color: positive ? AppTheme.success : AppTheme.danger, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendItem(color: Color(0xFF3ACB82), label: 'نیمه دوم سال'),
        SizedBox(width: 10),
        _LegendItem(color: Color(0xFF23A7FF), label: 'نیمه اول سال'),
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
        Container(width: 12, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99))),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
      return const Center(child: _EmptyTiny(message: 'داده نمودار برای این بازه هنوز وجود ندارد.'));
    }
    return CustomPaint(
      painter: _LineChartPainter(series: series, prominent: prominent, textDirection: Directionality.of(context)),
      child: const SizedBox.expand(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({required this.series, required this.prominent, required this.textDirection});

  final List<TimeseriesSeriesDto2> series;
  final bool prominent;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xFFE7ECF4)
      ..strokeWidth = 1;
    final labelPainter = TextPainter(textDirection: textDirection, textAlign: TextAlign.center);
    final topPad = 10.0;
    final bottomPad = 30.0;
    final leftPad = 28.0;
    final rightPad = 6.0;
    final chartRect = Rect.fromLTWH(leftPad, topPad, size.width - leftPad - rightPad, size.height - topPad - bottomPad);
    for (var i = 0; i < 5; i++) {
      final y = chartRect.top + chartRect.height * i / 4;
      canvas.drawLine(Offset(chartRect.left, y), Offset(chartRect.right, y), axisPaint);
    }
    final allPoints = series.expand((s) => s.points).toList();
    final maxValue = math.max(100.0, allPoints.fold<double>(0, (p, e) => math.max(p, e.value)));
    final colors = [const Color(0xFF3ACB82), const Color(0xFF23A7FF), AppTheme.warning];
    for (var si = 0; si < series.length; si++) {
      final points = series[si].points;
      if (points.isEmpty) continue;
      final color = colors[si % colors.length];
      final path = Path();
      final area = Path();
      for (var i = 0; i < points.length; i++) {
        final dx = points.length == 1 ? chartRect.center.dx : chartRect.left + (chartRect.width * i / (points.length - 1));
        final dy = chartRect.bottom - (points[i].value / maxValue).clamp(0, 1) * chartRect.height;
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
      canvas.drawPath(area, Paint()..color = color.withValues(alpha: prominent ? 0.16 : 0.11)..style = PaintingStyle.fill);
      canvas.drawPath(path, Paint()..color = color..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    }
    final labels = (series.isNotEmpty ? series.first.points : const <TimeseriesPointDto2>[]).take(6).toList();
    for (var i = 0; i < labels.length; i++) {
      final x = labels.length == 1 ? chartRect.center.dx : chartRect.left + (chartRect.width * i / (labels.length - 1));
      labelPainter.text = TextSpan(text: labels[i].label, style: const TextStyle(fontSize: 10, color: Color(0xFF9AA1B6), fontWeight: FontWeight.w700));
      labelPainter.layout(minWidth: 0, maxWidth: 42);
      labelPainter.paint(canvas, Offset(x - labelPainter.width / 2, chartRect.bottom + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => oldDelegate.series != series || oldDelegate.prominent != prominent;
}

class _EmptyTiny extends StatelessWidget {
  const _EmptyTiny({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF4F7FB), borderRadius: BorderRadius.circular(12)),
      child: Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                  const _SectionTitle(title: 'داشبورد جدید هنوز از سرور دریافت نشد'),
                  const SizedBox(height: 10),
                  Text(FriendlyApiErrorMessage.from(error, context: context)),
                  const SizedBox(height: 10),
                  FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('تلاش مجدد')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            oldAnalytics.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(FriendlyApiErrorMessage.from(error, context: context)),
              data: (value) => _SoftPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionTitle(title: 'آمار فعلی'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _LegacyStat(label: 'فرم‌ها', value: '${value.totalForms}'),
                        _LegacyStat(label: 'منتشر شده', value: '${value.publishedForms}'),
                        _LegacyStat(label: 'کاربران', value: '${value.totalUsers}'),
                        _LegacyStat(label: 'پاسخ‌ها', value: '${value.totalSubmissions}'),
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
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

String _surveyStatusLabel(String status) => switch (status) {
      'completed' => 'تکمیل شده',
      'in_progress' => 'در حال انجام',
      'pending' => 'در انتظار',
      'closed' => 'بسته شده',
      'new' => 'جدید',
      _ => 'فعال',
    };

String _roleLabel(UserRole role) => switch (role) {
      UserRole.parent => 'والد',
      UserRole.student => 'دانش‌آموز',
      UserRole.teacher => 'معلم',
      UserRole.manager => 'مدیر',
      UserRole.ceo => 'مدیر عامل',
      UserRole.admin => 'ادمین',
      UserRole.superAdmin => 'سوپر ادمین',
      _ => 'کاربر',
    };

String _statusFor(double? value, double? max) {
  if (value == null) return 'normal';
  final ratio = max == null || max == 0 ? (value / 100) : (value / max);
  if (ratio >= 0.82) return 'excellent';
  if (ratio >= 0.65) return 'good';
  return 'normal';
}

Color _statusColor(String status) => switch (status) {
      'excellent' || 'great' || 'عالی' => AppTheme.success,
      'good' || 'خوب' => AppTheme.primary,
      'warning' || 'normal' || 'معمولی' => AppTheme.warning,
      'danger' || 'bad' => AppTheme.danger,
      _ => AppTheme.primary,
    };

String _statusLabel(String status) => switch (status) {
      'excellent' || 'great' => 'عالی',
      'good' => 'خوب',
      'warning' || 'normal' => 'معمولی',
      'danger' || 'bad' => 'نیازمند توجه',
      _ => status,
    };

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
                          onPressed: () => context.go('/forms/${form.id}/builder'),
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

