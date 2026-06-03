import 'enums.dart';

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

List<T> _list<T>(Object? value, T Function(Object?) parse) {
  if (value is! Iterable) return <T>[];
  return value.map(parse).toList(growable: false);
}

String? _string(Object? value) => value?.toString();

double? _double(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int _int(Object? value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool _bool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is String) return value == 'true' || value == '1';
  if (value is num) return value != 0;
  return fallback;
}

Map<String, Object?> _json(Object? value) =>
    Map<String, Object?>.from(_map(value));

class DashboardQueryInput {
  const DashboardQueryInput({
    this.period = 'this_month',
    this.compare,
    this.childId,
    this.cacheUserId,
    this.classId,
    this.branchId,
    this.scope,
    this.scopeId,
  });

  final String period;
  final String? compare;
  final String? childId;
  final String? cacheUserId;
  final String? classId;
  final String? branchId;
  final String? scope;
  final String? scopeId;

  Map<String, dynamic> toQuery() => <String, dynamic>{
    'period': period,
    if (compare != null) 'compare': compare,
    if (childId != null) 'child_id': childId,
    if (classId != null) 'class_id': classId,
    if (branchId != null) 'branch_id': branchId,
    if (scope != null) 'scope': scope,
    if (scopeId != null) 'scope_id': scopeId,
  };

  @override
  bool operator ==(Object other) {
    return other is DashboardQueryInput &&
        period == other.period &&
        compare == other.compare &&
        childId == other.childId &&
        cacheUserId == other.cacheUserId &&
        classId == other.classId &&
        branchId == other.branchId &&
        scope == other.scope &&
        scopeId == other.scopeId;
  }

  @override
  int get hashCode => Object.hash(
    period,
    compare,
    childId,
    cacheUserId,
    classId,
    branchId,
    scope,
    scopeId,
  );
}

class CalendarQueryInput {
  const CalendarQueryInput({
    required this.period,
    this.childId,
    this.cacheUserId,
  });

  final String period;
  final String? childId;
  final String? cacheUserId;

  @override
  bool operator ==(Object other) {
    return other is CalendarQueryInput &&
        period == other.period &&
        childId == other.childId &&
        cacheUserId == other.cacheUserId;
  }

  @override
  int get hashCode => Object.hash(period, childId, cacheUserId);
}

class ChildProfileDto2 {
  const ChildProfileDto2({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.gradeLabel,
    this.classId,
    this.className,
    this.branchId,
    this.branchName,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? gradeLabel;
  final String? classId;
  final String? className;
  final String? branchId;
  final String? branchName;
  final Map<String, Object?> metadata;

  factory ChildProfileDto2.fromJson(Object? json) {
    final map = _map(json);
    return ChildProfileDto2(
      id: _string(map['id']) ?? '',
      displayName: _string(map['display_name']) ?? '',
      avatarUrl: _string(map['avatar_url']),
      gradeLabel: _string(map['grade_label']),
      classId: _string(map['class_id']),
      className: _string(map['class_name']),
      branchId: _string(map['branch_id']),
      branchName: _string(map['branch_name']),
      metadata: _json(map['metadata']),
    );
  }
}

class SurveyCardDto2 {
  const SurveyCardDto2({
    required this.formId,
    required this.title,
    this.description,
    this.category,
    this.tags = const <String>[],
    required this.status,
    this.mySubmissionId,
    required this.progress,
    required this.questionCount,
    this.estimatedMinutes,
    required this.cta,
    this.dateLabel,
    this.scheduledAt,
    this.publishedAt,
    this.closedAt,
    this.assignedReason,
    this.metadata = const <String, Object?>{},
  });

  final String formId;
  final String title;
  final String? description;
  final String? category;
  final List<String> tags;
  final String status;
  final String? mySubmissionId;
  final double progress;
  final int questionCount;
  final int? estimatedMinutes;
  final String cta;
  final String? dateLabel;
  final String? scheduledAt;
  final String? publishedAt;
  final String? closedAt;
  final String? assignedReason;
  final Map<String, Object?> metadata;

  factory SurveyCardDto2.fromJson(Object? json) {
    final map = _map(json);
    return SurveyCardDto2(
      formId: _string(map['form_id']) ?? '',
      title: _string(map['title']) ?? '',
      description: _string(map['description']),
      category: _string(map['category']),
      tags: _list<String>(map['tags'], (value) => value.toString()),
      status: _string(map['status']) ?? 'pending',
      mySubmissionId: _string(map['my_submission_id']),
      progress: _double(map['progress']) ?? 0,
      questionCount: _int(map['question_count']),
      estimatedMinutes: map['estimated_minutes'] == null
          ? null
          : _int(map['estimated_minutes']),
      cta: _string(map['cta']) ?? 'start',
      dateLabel: _string(map['date_label']),
      scheduledAt: _string(map['scheduled_at']),
      publishedAt: _string(map['published_at']),
      closedAt: _string(map['closed_at']),
      assignedReason: _string(map['assigned_reason']),
      metadata: _json(map['metadata']),
    );
  }
}

class SurveyStatusSummaryDto2 {
  const SurveyStatusSummaryDto2({
    required this.completed,
    required this.inProgress,
    required this.pending,
    required this.newItems,
  });

  final int completed;
  final int inProgress;
  final int pending;
  final int newItems;

  factory SurveyStatusSummaryDto2.fromJson(Object? json) {
    final map = _map(json);
    return SurveyStatusSummaryDto2(
      completed: _int(map['completed']),
      inProgress: _int(map['in_progress']),
      pending: _int(map['pending']),
      newItems: _int(map['new_items']),
    );
  }

  static const empty = SurveyStatusSummaryDto2(
    completed: 0,
    inProgress: 0,
    pending: 0,
    newItems: 0,
  );
}

class DashboardMetricValueDto2 {
  const DashboardMetricValueDto2({
    required this.metricId,
    required this.key,
    required this.title,
    this.value,
    this.label,
    this.unit,
    this.scaleMin,
    this.scaleMax,
    this.status,
    this.trend,
    this.display = const <String, Object?>{},
  });

  final String metricId;
  final String key;
  final String title;
  final double? value;
  final String? label;
  final String? unit;
  final double? scaleMin;
  final double? scaleMax;
  final String? status;
  final double? trend;
  final Map<String, Object?> display;

  String get displayValue {
    if (label != null && label!.trim().isNotEmpty) return label!;
    if (value == null) return '-';
    final normalized = value! % 1 == 0
        ? value!.toStringAsFixed(0)
        : value!.toStringAsFixed(1);
    return unit == null || unit!.isEmpty ? normalized : '$normalized$unit';
  }

  factory DashboardMetricValueDto2.fromJson(Object? json) {
    final map = _map(json);
    return DashboardMetricValueDto2(
      metricId: _string(map['metric_id']) ?? '',
      key: _string(map['key']) ?? '',
      title: _string(map['title']) ?? '',
      value: _double(map['value']),
      label: _string(map['label']),
      unit: _string(map['unit']),
      scaleMin: _double(map['scale_min']),
      scaleMax: _double(map['scale_max']),
      status: _string(map['status']),
      trend: _double(map['trend']),
      display: _json(map['display']),
    );
  }
}

class TimeseriesPointDto2 {
  const TimeseriesPointDto2({
    required this.label,
    required this.date,
    required this.value,
  });

  final String label;
  final String date;
  final double value;

  factory TimeseriesPointDto2.fromJson(Object? json) {
    final map = _map(json);
    return TimeseriesPointDto2(
      label: _string(map['label']) ?? '',
      date: _string(map['date']) ?? '',
      value: _double(map['value']) ?? 0,
    );
  }
}

class TimeseriesSeriesDto2 {
  const TimeseriesSeriesDto2({
    required this.key,
    required this.label,
    required this.points,
  });

  final String key;
  final String label;
  final List<TimeseriesPointDto2> points;

  factory TimeseriesSeriesDto2.fromJson(Object? json) {
    final map = _map(json);
    return TimeseriesSeriesDto2(
      key: _string(map['key']) ?? '',
      label: _string(map['label']) ?? '',
      points: _list<TimeseriesPointDto2>(
        map['points'],
        TimeseriesPointDto2.fromJson,
      ),
    );
  }
}

class TimeseriesResponseDto2 {
  const TimeseriesResponseDto2({
    required this.metric,
    required this.period,
    required this.granularity,
    required this.series,
  });

  final String metric;
  final String period;
  final String granularity;
  final List<TimeseriesSeriesDto2> series;

  factory TimeseriesResponseDto2.fromJson(Object? json) {
    final map = _map(json);
    return TimeseriesResponseDto2(
      metric: _string(map['metric']) ?? '',
      period: _string(map['period']) ?? '',
      granularity: _string(map['granularity']) ?? '',
      series: _list<TimeseriesSeriesDto2>(
        map['series'],
        TimeseriesSeriesDto2.fromJson,
      ),
    );
  }
}

class CalendarSurveyDto2 {
  const CalendarSurveyDto2({
    required this.formId,
    required this.title,
    required this.status,
    this.dateLabel,
  });

  final String formId;
  final String title;
  final String status;
  final String? dateLabel;

  factory CalendarSurveyDto2.fromJson(Object? json) {
    final map = _map(json);
    return CalendarSurveyDto2(
      formId: _string(map['form_id']) ?? '',
      title: _string(map['title']) ?? '',
      status: _string(map['status']) ?? 'pending',
      dateLabel: _string(map['date_label']),
    );
  }
}

class CalendarDayDto2 {
  const CalendarDayDto2({
    required this.date,
    required this.label,
    this.weekday,
    required this.status,
    required this.count,
    required this.highlight,
    this.surveys = const <CalendarSurveyDto2>[],
  });

  final String date;
  final String label;
  final String? weekday;
  final String status;
  final int count;
  final bool highlight;
  final List<CalendarSurveyDto2> surveys;

  factory CalendarDayDto2.fromJson(Object? json) {
    final map = _map(json);
    return CalendarDayDto2(
      date: _string(map['date']) ?? '',
      label: _string(map['label']) ?? '',
      weekday: _string(map['weekday']),
      status: _string(map['status']) ?? 'empty',
      count: _int(map['count']),
      highlight: _bool(map['highlight']),
      surveys: _list<CalendarSurveyDto2>(
        map['surveys'],
        CalendarSurveyDto2.fromJson,
      ),
    );
  }
}

class CalendarResponseDto2 {
  const CalendarResponseDto2({required this.period, required this.days});

  final String period;
  final List<CalendarDayDto2> days;

  factory CalendarResponseDto2.fromJson(Object? json) {
    final map = _map(json);
    return CalendarResponseDto2(
      period: _string(map['period']) ?? '',
      days: _list<CalendarDayDto2>(map['days'], CalendarDayDto2.fromJson),
    );
  }
}

class ActivityFeedItemDto2 {
  const ActivityFeedItemDto2({
    required this.id,
    required this.activityType,
    required this.title,
    this.subtitle,
    required this.status,
    this.timeAgo,
    this.createdAt,
    this.targetUrl,
    this.icon,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String activityType;
  final String title;
  final String? subtitle;
  final String status;
  final String? timeAgo;
  final String? createdAt;
  final String? targetUrl;
  final String? icon;
  final Map<String, Object?> metadata;

  factory ActivityFeedItemDto2.fromJson(Object? json) {
    final map = _map(json);
    return ActivityFeedItemDto2(
      id: _string(map['id']) ?? '',
      activityType: _string(map['activity_type']) ?? '',
      title: _string(map['title']) ?? '',
      subtitle: _string(map['subtitle']),
      status: _string(map['status']) ?? '',
      timeAgo: _string(map['time_ago']),
      createdAt: _string(map['created_at']),
      targetUrl: _string(map['target_url']),
      icon: _string(map['icon']),
      metadata: _json(map['metadata']),
    );
  }
}

class RankingItemDto2 {
  const RankingItemDto2({
    required this.rank,
    required this.entityId,
    required this.entityType,
    required this.title,
    this.subtitle,
    required this.score,
    this.trend,
    this.avatarUrl,
    this.metadata = const <String, Object?>{},
  });

  final int rank;
  final String entityId;
  final String entityType;
  final String title;
  final String? subtitle;
  final double score;
  final double? trend;
  final String? avatarUrl;
  final Map<String, Object?> metadata;

  factory RankingItemDto2.fromJson(Object? json) {
    final map = _map(json);
    return RankingItemDto2(
      rank: _int(map['rank']),
      entityId: _string(map['entity_id']) ?? '',
      entityType: _string(map['entity_type']) ?? '',
      title: _string(map['title']) ?? '',
      subtitle: _string(map['subtitle']),
      score: _double(map['score']) ?? 0,
      trend: _double(map['trend']),
      avatarUrl: _string(map['avatar_url']),
      metadata: _json(map['metadata']),
    );
  }
}

class RankingResponseDto2 {
  const RankingResponseDto2({
    required this.metric,
    required this.dimension,
    required this.period,
    required this.items,
  });

  final String metric;
  final String dimension;
  final String period;
  final List<RankingItemDto2> items;

  factory RankingResponseDto2.fromJson(Object? json) {
    final map = _map(json);
    return RankingResponseDto2(
      metric: _string(map['metric']) ?? '',
      dimension: _string(map['dimension']) ?? '',
      period: _string(map['period']) ?? '',
      items: _list<RankingItemDto2>(map['items'], RankingItemDto2.fromJson),
    );
  }
}

class AnalyticsAlertDto2 {
  const AnalyticsAlertDto2({
    required this.id,
    required this.severity,
    required this.title,
    this.description,
    this.entityId,
    this.entityType,
    this.metricKey,
    this.value,
    this.threshold,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String severity;
  final String title;
  final String? description;
  final String? entityId;
  final String? entityType;
  final String? metricKey;
  final double? value;
  final double? threshold;
  final Map<String, Object?> metadata;

  factory AnalyticsAlertDto2.fromJson(Object? json) {
    final map = _map(json);
    return AnalyticsAlertDto2(
      id: _string(map['id']) ?? '',
      severity: _string(map['severity']) ?? 'info',
      title: _string(map['title']) ?? '',
      description: _string(map['description']),
      entityId: _string(map['entity_id']),
      entityType: _string(map['entity_type']),
      metricKey: _string(map['metric_key']),
      value: _double(map['value']),
      threshold: _double(map['threshold']),
      metadata: _json(map['metadata']),
    );
  }
}

class AnalyticsAlertsResponseDto2 {
  const AnalyticsAlertsResponseDto2({
    required this.period,
    required this.items,
  });

  final String period;
  final List<AnalyticsAlertDto2> items;

  factory AnalyticsAlertsResponseDto2.fromJson(Object? json) {
    final map = _map(json);
    return AnalyticsAlertsResponseDto2(
      period: _string(map['period']) ?? '',
      items: _list<AnalyticsAlertDto2>(
        map['items'],
        AnalyticsAlertDto2.fromJson,
      ),
    );
  }
}

class DashboardResponseDto2 {
  const DashboardResponseDto2({
    required this.role,
    required this.period,
    required this.children,
    this.selectedChildId,
    required this.surveySummary,
    required this.latestSurveys,
    required this.metrics,
    required this.charts,
    required this.activities,
    required this.rankings,
    required this.distributions,
    this.metadata = const <String, Object?>{},
  });

  final UserRole role;
  final String period;
  final List<ChildProfileDto2> children;
  final String? selectedChildId;
  final SurveyStatusSummaryDto2 surveySummary;
  final List<SurveyCardDto2> latestSurveys;
  final List<DashboardMetricValueDto2> metrics;
  final List<TimeseriesResponseDto2> charts;
  final List<ActivityFeedItemDto2> activities;
  final List<RankingResponseDto2> rankings;
  final List<Object> distributions;
  final Map<String, Object?> metadata;

  factory DashboardResponseDto2.fromJson(Object? json) {
    final map = _map(json);
    return DashboardResponseDto2(
      role: UserRole.fromJson(map['role']),
      period: _string(map['period']) ?? 'this_month',
      children: _list<ChildProfileDto2>(
        map['children'],
        ChildProfileDto2.fromJson,
      ),
      selectedChildId: _string(map['selected_child_id']),
      surveySummary: SurveyStatusSummaryDto2.fromJson(map['survey_summary']),
      latestSurveys: _list<SurveyCardDto2>(
        map['latest_surveys'],
        SurveyCardDto2.fromJson,
      ),
      metrics: _list<DashboardMetricValueDto2>(
        map['metrics'],
        DashboardMetricValueDto2.fromJson,
      ),
      charts: _list<TimeseriesResponseDto2>(
        map['charts'],
        TimeseriesResponseDto2.fromJson,
      ),
      activities: _list<ActivityFeedItemDto2>(
        map['activities'],
        ActivityFeedItemDto2.fromJson,
      ),
      rankings: _list<RankingResponseDto2>(
        map['rankings'],
        RankingResponseDto2.fromJson,
      ),
      distributions: _list<Object>(
        map['distributions'],
        (value) => value ?? const <String, Object?>{},
      ),
      metadata: _json(map['metadata']),
    );
  }
}

class MetricDefinitionDto2 {
  const MetricDefinitionDto2({
    required this.id,
    required this.key,
    required this.title,
    this.description,
    required this.metricType,
    required this.enabled,
    required this.mappingCount,
    this.display = const <String, Object?>{},
  });

  final String id;
  final String key;
  final String title;
  final String? description;
  final String metricType;
  final bool enabled;
  final int mappingCount;
  final Map<String, Object?> display;

  factory MetricDefinitionDto2.fromJson(Object? json) {
    final map = _map(json);
    return MetricDefinitionDto2(
      id: _string(map['id']) ?? '',
      key: _string(map['key']) ?? '',
      title: _string(map['title']) ?? '',
      description: _string(map['description']),
      metricType: _string(map['metric_type']) ?? 'score',
      enabled: _bool(map['enabled'], true),
      mappingCount: _int(map['mapping_count']),
      display: _json(map['display']),
    );
  }
}

class AudienceSegmentDto2 {
  const AudienceSegmentDto2({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.segmentType,
    required this.enabled,
    required this.memberCount,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String segmentType;
  final bool enabled;
  final int memberCount;
  final Map<String, Object?> metadata;

  factory AudienceSegmentDto2.fromJson(Object? json) {
    final map = _map(json);
    return AudienceSegmentDto2(
      id: _string(map['id']) ?? '',
      name: _string(map['name']) ?? '',
      slug: _string(map['slug']) ?? '',
      description: _string(map['description']),
      segmentType: _string(map['segment_type']) ?? 'custom',
      enabled: _bool(map['enabled'], true),
      memberCount: _int(map['member_count']),
      metadata: _json(map['metadata']),
    );
  }
}

class FormAssignmentDto2 {
  const FormAssignmentDto2({
    required this.id,
    required this.formId,
    required this.audienceType,
    this.audienceUserId,
    this.audienceRole,
    this.audienceGroupId,
    this.audienceSegmentId,
    this.label,
    required this.canSee,
    required this.canAnswer,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String formId;
  final String audienceType;
  final String? audienceUserId;
  final UserRole? audienceRole;
  final String? audienceGroupId;
  final String? audienceSegmentId;
  final String? label;
  final bool canSee;
  final bool canAnswer;
  final Map<String, Object?> metadata;

  factory FormAssignmentDto2.fromJson(Object? json) {
    final map = _map(json);
    final roleRaw = map['audience_role'];
    return FormAssignmentDto2(
      id: _string(map['id']) ?? '',
      formId: _string(map['form_id']) ?? '',
      audienceType: _string(map['audience_type']) ?? '',
      audienceUserId: _string(map['audience_user_id']),
      audienceRole: roleRaw == null ? null : UserRole.fromJson(roleRaw),
      audienceGroupId: _string(map['audience_group_id']),
      audienceSegmentId: _string(map['audience_segment_id']),
      label: _string(map['label']),
      canSee: _bool(map['can_see'], true),
      canAnswer: _bool(map['can_answer'], true),
      metadata: _json(map['metadata']),
    );
  }
}

class FormAssignmentInputDto2 {
  const FormAssignmentInputDto2({
    required this.audienceType,
    this.audienceUserId,
    this.audienceRole,
    this.audienceGroupId,
    this.audienceSegmentId,
    this.label,
    this.canSee = true,
    this.canAnswer = true,
    this.metadata = const <String, Object?>{},
  });

  final String audienceType;
  final String? audienceUserId;
  final UserRole? audienceRole;
  final String? audienceGroupId;
  final String? audienceSegmentId;
  final String? label;
  final bool canSee;
  final bool canAnswer;
  final Map<String, Object?> metadata;

  factory FormAssignmentInputDto2.fromAssignment(
    FormAssignmentDto2 assignment,
  ) {
    return FormAssignmentInputDto2(
      audienceType: assignment.audienceType,
      audienceUserId: assignment.audienceUserId,
      audienceRole: assignment.audienceRole,
      audienceGroupId: assignment.audienceGroupId,
      audienceSegmentId: assignment.audienceSegmentId,
      label: assignment.label,
      canSee: assignment.canSee,
      canAnswer: assignment.canAnswer,
      metadata: assignment.metadata,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'audience_type': audienceType,
    if (audienceUserId != null && audienceUserId!.trim().isNotEmpty)
      'audience_user_id': audienceUserId,
    if (audienceRole != null) 'audience_role': audienceRole!.toJson(),
    if (audienceGroupId != null && audienceGroupId!.trim().isNotEmpty)
      'audience_group_id': audienceGroupId,
    if (audienceSegmentId != null && audienceSegmentId!.trim().isNotEmpty)
      'audience_segment_id': audienceSegmentId,
    if (label != null && label!.trim().isNotEmpty) 'label': label,
    'can_see': canSee,
    'can_answer': canAnswer,
    'metadata': metadata,
  };
}

class SetFormAssignmentsRequest2 {
  const SetFormAssignmentsRequest2({required this.assignments});

  final List<FormAssignmentInputDto2> assignments;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'assignments': [for (final assignment in assignments) assignment.toJson()],
  };
}

class GuestLoginRequest {
  const GuestLoginRequest({
    this.organizationId,
    this.organizationSlug,
    this.publicToken,
    this.displayName,
  });

  final String? organizationId;
  final String? organizationSlug;
  final String? publicToken;
  final String? displayName;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (organizationId != null && organizationId!.trim().isNotEmpty)
      'organization_id': organizationId,
    if (organizationSlug != null && organizationSlug!.trim().isNotEmpty)
      'organization_slug': organizationSlug,
    if (publicToken != null && publicToken!.trim().isNotEmpty)
      'public_token': publicToken,
    if (displayName != null && displayName!.trim().isNotEmpty)
      'display_name': displayName,
  };
}

class FormAnswerAccessDto2 {
  const FormAnswerAccessDto2({
    required this.allowed,
    required this.canView,
    required this.canEditWorkspace,
    required this.requiresPublicLink,
    this.mySubmissionId,
    this.reason,
    this.reasonCode,
  });

  final bool allowed;
  final bool canView;
  final bool canEditWorkspace;
  final bool requiresPublicLink;
  final String? mySubmissionId;
  final String? reason;
  final String? reasonCode;

  factory FormAnswerAccessDto2.fromJson(Object? json) {
    final map = _map(json);
    return FormAnswerAccessDto2(
      allowed: _bool(map['allowed']),
      canView: _bool(map['can_view']),
      canEditWorkspace: _bool(map['can_edit_workspace']),
      requiresPublicLink: _bool(map['requires_public_link']),
      mySubmissionId: _string(map['my_submission_id']),
      reason: _string(map['reason']),
      reasonCode: _string(map['reason_code']),
    );
  }
}
