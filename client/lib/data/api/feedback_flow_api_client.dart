// GENERATED FROM openapi.json operationIds. Do not edit by hand.
import 'package:dio/dio.dart';

import '../dto/dto.dart';
import 'api_exceptions.dart';
import 'json_payload_normalizer.dart';

class FeedbackFlowApiClient {
  FeedbackFlowApiClient(this._dio);

  final Dio _dio;

  Map<String, dynamic> _jsonObject(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const ApiContractException('Expected a JSON object from the API.');
  }

  Map<String, dynamic> _clean(Map<String, dynamic> value) {
    return JsonPayloadNormalizer.normalizeMap(value);
  }

  Map<String, dynamic> _body(Map<String, dynamic> value) {
    return JsonPayloadNormalizer.normalizeMap(value);
  }

  String _path(String template, Map<String, String> params) {
    var path = template;
    for (final entry in params.entries) {
      path = path.replaceAll(
        '{${entry.key}}',
        Uri.encodeComponent(entry.value),
      );
    }
    return path;
  }

  ApiResponse<T> _parseApiResponse<T>(
    Object? json,
    T Function(Object?) fromJsonT,
  ) {
    return ApiResponse<T>.fromJson(_jsonObject(json), fromJsonT);
  }

  ListResponse<T> _parseListResponse<T>(
    Object? json,
    T Function(Object?) fromJsonT,
  ) {
    final map = _jsonObject(json);
    final dataRaw = map['data'];
    final data = dataRaw is Iterable
        ? dataRaw.map(fromJsonT).toList(growable: false)
        : null;
    final errorRaw = map['error'];
    final error = errorRaw is Map
        ? ApiError.fromJson(Map<String, dynamic>.from(errorRaw))
        : null;
    final metaRaw = map['meta'];
    ListMetaDto? meta;
    if (metaRaw is Map && metaRaw['pagination'] != null) {
      meta = ListMetaDto.fromJson(Map<String, dynamic>.from(metaRaw));
    }
    return ListResponse<T>(
      success: map['success'] == true,
      data: data,
      error: error,
      meta: meta,
    );
  }

  List<T> _parseDtoList<T>(Object? json, T Function(Object?) fromJsonT) {
    final source = switch (json) {
      Iterable value => value,
      Map value when value['data'] is Iterable => value['data'] as Iterable,
      Map value when value['members'] is Iterable =>
        value['members'] as Iterable,
      Map value when value['items'] is Iterable => value['items'] as Iterable,
      _ => null,
    };
    if (source == null) return const [];
    return source.map(fromJsonT).toList(growable: false);
  }

  /// operationId: listActivities
  /// GET /api/v1/activities
  /// Requires Bearer JWT.
  Future<ListResponse<ActivitySummaryDto>> listActivities({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    SortOrder? sortOrder,
    String? filters,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/activities',
      queryParameters: _clean(<String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'search': search,
        'sort_by': sortBy,
        'sort_order': sortOrder?.toJson(),
        'filters': filters,
      }),
    );
    return _parseListResponse<ActivitySummaryDto>(
      response.data,
      (json) => ActivitySummaryDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getActivity
  /// GET /api/v1/activities/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<ActivityDto>> getActivity({required String id}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/activities/{id}', <String, String>{'id': id.toString()}),
    );
    return _parseApiResponse<ActivityDto>(
      response.data,
      (json) => ActivityDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: updateActivity
  /// PATCH /api/v1/activities/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<ActivityDto>> updateActivity({
    required String id,
    required UpdateActivityRequest request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      _path('/api/v1/activities/{id}', <String, String>{'id': id.toString()}),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<ActivityDto>(
      response.data,
      (json) => ActivityDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: deleteActivityRule
  /// DELETE /api/v1/activity-rules/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<DeleteResultDto>> deleteActivityRule({
    required String id,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      _path('/api/v1/activity-rules/{id}', <String, String>{
        'id': id.toString(),
      }),
    );
    return _parseApiResponse<DeleteResultDto>(
      response.data,
      (json) => DeleteResultDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: updateActivityRule
  /// PATCH /api/v1/activity-rules/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<ActivityRuleDto>> updateActivityRule({
    required String id,
    required UpdateActivityRuleRequest request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      _path('/api/v1/activity-rules/{id}', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<ActivityRuleDto>(
      response.data,
      (json) => ActivityRuleDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: listAuditLogs
  /// GET /api/v1/audit-logs
  /// Requires Bearer JWT.
  Future<ListResponse<AuditLogDto>> listAuditLogs({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    SortOrder? sortOrder,
    String? filters,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/audit-logs',
      queryParameters: _clean(<String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'search': search,
        'sort_by': sortBy,
        'sort_order': sortOrder?.toJson(),
        'filters': filters,
      }),
    );
    return _parseListResponse<AuditLogDto>(
      response.data,
      (json) => AuditLogDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: login
  /// POST /api/v1/auth/login
  /// Public endpoint; no Bearer JWT required by the contract.
  Future<ApiResponse<LoginResponse>> login({
    required LoginRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/login',
      data: _body(request.toJson()),
    );
    return _parseApiResponse<LoginResponse>(
      response.data,
      (json) => LoginResponse.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: guestLogin
  /// POST /api/v1/auth/guest
  /// Public endpoint; creates a limited guest session scoped to an organization
  /// or to the organization inferred from a public form token.
  Future<ApiResponse<LoginResponse>> guestLogin({
    required GuestLoginRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/guest',
      data: _body(request.toJson()),
    );
    return _parseApiResponse<LoginResponse>(
      response.data,
      (json) => LoginResponse.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: logout
  /// POST /api/v1/auth/logout
  /// Requires Bearer JWT.
  Future<ApiResponse<LogoutResponse>> logout({
    required LogoutRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/logout',
      data: _body(request.toJson()),
    );
    return _parseApiResponse<LogoutResponse>(
      response.data,
      (json) => LogoutResponse.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getMe
  /// GET /api/v1/auth/me
  /// Requires Bearer JWT.
  Future<ApiResponse<MeResponse>> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/auth/me');
    return _parseApiResponse<MeResponse>(
      response.data,
      (json) => MeResponse.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: refreshToken
  /// POST /api/v1/auth/refresh
  /// Public endpoint; no Bearer JWT required by the contract.
  Future<ApiResponse<RefreshTokenResponse>> refreshToken({
    required RefreshTokenRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/refresh',
      data: _body(request.toJson()),
    );
    return _parseApiResponse<RefreshTokenResponse>(
      response.data,
      (json) => RefreshTokenResponse.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: register
  /// POST /api/v1/auth/register
  /// Public endpoint; no Bearer JWT required by the contract.
  Future<ApiResponse<RegisterResponse>> register({
    required RegisterRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/register',
      data: _body(request.toJson()),
    );
    return _parseApiResponse<RegisterResponse>(
      response.data,
      (json) => RegisterResponse.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: listForms
  /// GET /api/v1/forms
  /// Requires Bearer JWT.
  Future<ListResponse<FormSummaryDto>> listForms({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    SortOrder? sortOrder,
    String? filters,
    String? category,
    String? tags,
    String? status,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/forms',
      queryParameters: _clean(<String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'search': search,
        'sort_by': sortBy,
        'sort_order': sortOrder?.toJson(),
        'filters': filters,
        'category': category,
        'tags': tags,
        'status': status,
      }),
    );
    return _parseListResponse<FormSummaryDto>(
      response.data,
      (json) => FormSummaryDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: listFormTags
  /// GET /api/v1/forms/tags
  /// Requires Bearer JWT.
  Future<ApiResponse<List<String>>> listFormTags({String? search}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/forms/tags',
      queryParameters: _clean(<String, dynamic>{'search': search}),
    );
    return _parseApiResponse<List<String>>(response.data, (json) {
      if (json is! Iterable) return const <String>[];
      return json.map((item) => item.toString()).toList(growable: false);
    });
  }

  /// operationId: createForm
  /// POST /api/v1/forms
  /// Requires Bearer JWT.
  Future<ApiResponse<FormDetailDto>> createForm({
    required CreateFormRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/forms',
      data: _body(request.toJson()),
    );
    return _parseApiResponse<FormDetailDto>(
      response.data,
      (json) => FormDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getForm
  /// GET /api/v1/forms/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<FormDetailDto>> getForm({
    required String id,
    String? childId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}', <String, String>{'id': id.toString()}),
      queryParameters: _clean(<String, dynamic>{'child_id': childId}),
    );
    return _parseApiResponse<FormDetailDto>(
      response.data,
      (json) => FormDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getFormAnswerAccess
  /// GET /api/v1/forms/{id}/answer-access
  /// Requires Bearer JWT.
  Future<ApiResponse<FormAnswerAccessDto2>> getFormAnswerAccess({
    required String id,
    String? childId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/answer-access', <String, String>{
        'id': id.toString(),
      }),
      queryParameters: _clean(<String, dynamic>{'child_id': childId}),
    );
    return _parseApiResponse<FormAnswerAccessDto2>(
      response.data,
      (json) => FormAnswerAccessDto2.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: deleteForm
  /// DELETE /api/v1/forms/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<DeleteResultDto>> deleteForm({required String id}) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}', <String, String>{'id': id.toString()}),
    );
    return _parseApiResponse<DeleteResultDto>(
      response.data,
      (json) => DeleteResultDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: updateForm
  /// PATCH /api/v1/forms/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<FormDetailDto>> updateForm({
    required String id,
    required UpdateFormRequest request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}', <String, String>{'id': id.toString()}),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<FormDetailDto>(
      response.data,
      (json) => FormDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: listActivityRules
  /// GET /api/v1/forms/{id}/activity-rules
  /// Requires Bearer JWT.
  Future<ListResponse<ActivityRuleDto>> listActivityRules({
    required String id,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    SortOrder? sortOrder,
    String? filters,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/activity-rules', <String, String>{
        'id': id.toString(),
      }),
      queryParameters: _clean(<String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'search': search,
        'sort_by': sortBy,
        'sort_order': sortOrder?.toJson(),
        'filters': filters,
      }),
    );
    return _parseListResponse<ActivityRuleDto>(
      response.data,
      (json) => ActivityRuleDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: createActivityRule
  /// POST /api/v1/forms/{id}/activity-rules
  /// Requires Bearer JWT.
  Future<ApiResponse<ActivityRuleDto>> createActivityRule({
    required String id,
    required CreateActivityRuleRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/activity-rules', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<ActivityRuleDto>(
      response.data,
      (json) => ActivityRuleDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getFormAnalytics
  /// GET /api/v1/forms/{id}/analytics
  /// Requires Bearer JWT.
  Future<ApiResponse<FormAnalyticsDto>> getFormAnalytics({
    required String id,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/analytics', <String, String>{
        'id': id.toString(),
      }),
    );
    return _parseApiResponse<FormAnalyticsDto>(
      response.data,
      (json) => FormAnalyticsDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getDashboardAnalytics
  /// GET /api/v1/dashboard/analytics
  /// Requires Bearer JWT.
  Future<ApiResponse<DashboardAnalyticsDto>> getDashboardAnalytics() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/dashboard/analytics',
    );
    return _parseApiResponse<DashboardAnalyticsDto>(
      response.data,
      (json) => DashboardAnalyticsDto.fromJson(_jsonObject(json)),
    );
  }

  /// GET /api/v1/dashboards/me
  /// Requires Bearer JWT.
  Future<ApiResponse<DashboardResponseDto2>> getDashboardExperience({
    DashboardQueryInput query = const DashboardQueryInput(),
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/dashboards/me',
      queryParameters: _clean(query.toQuery()),
    );
    return _parseApiResponse<DashboardResponseDto2>(
      response.data,
      (json) => DashboardResponseDto2.fromJson(_jsonObject(json)),
    );
  }

  /// GET /api/v1/users/me/children
  /// Requires Bearer JWT.
  Future<ApiResponse<List<ChildProfileDto2>>> getMyChildren() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/users/me/children',
    );
    return _parseApiResponse<List<ChildProfileDto2>>(
      response.data,
      (json) =>
          _parseDtoList<ChildProfileDto2>(json, ChildProfileDto2.fromJson),
    );
  }

  /// GET /api/v1/surveys/me
  /// Requires Bearer JWT.
  Future<ApiResponse<List<SurveyCardDto2>>> getMySurveys({
    String? status,
    String? period,
    String? childId,
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/surveys/me',
      queryParameters: _clean(<String, dynamic>{
        'status': status,
        'period': period,
        'child_id': childId,
        'limit': limit,
      }),
    );
    return _parseApiResponse<List<SurveyCardDto2>>(
      response.data,
      (json) => _parseDtoList<SurveyCardDto2>(json, SurveyCardDto2.fromJson),
    );
  }

  /// GET /api/v1/surveys/calendar
  /// Requires Bearer JWT.
  Future<ApiResponse<CalendarResponseDto2>> getSurveyCalendar({
    String? period,
    String? childId,
    String? startDate,
    String? endDate,
    String? scope,
    String? scopeId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/surveys/calendar',
      queryParameters: _clean(<String, dynamic>{
        'period': period,
        'child_id': childId,
        'start_date': startDate,
        'end_date': endDate,
        'scope': scope,
        'scope_id': scopeId,
      }),
    );
    return _parseApiResponse<CalendarResponseDto2>(
      response.data,
      (json) => CalendarResponseDto2.fromJson(_jsonObject(json)),
    );
  }

  /// GET /api/v1/analytics/timeseries
  /// Requires Bearer JWT.
  Future<ApiResponse<TimeseriesResponseDto2>> getAnalyticsTimeseries({
    String? metric,
    String? period,
    String? compare,
    String? granularity,
    String? scope,
    String? scopeId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/analytics/timeseries',
      queryParameters: _clean(<String, dynamic>{
        'metric': metric,
        'period': period,
        'compare': compare,
        'granularity': granularity,
        'scope': scope,
        'scope_id': scopeId,
      }),
    );
    return _parseApiResponse<TimeseriesResponseDto2>(
      response.data,
      (json) => TimeseriesResponseDto2.fromJson(_jsonObject(json)),
    );
  }

  /// GET /api/v1/analytics/rankings
  /// Requires Bearer JWT.
  Future<ApiResponse<RankingResponseDto2>> getAnalyticsRankings({
    String? metric,
    String? dimension,
    String? period,
    String? order,
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/analytics/rankings',
      queryParameters: _clean(<String, dynamic>{
        'metric': metric,
        'dimension': dimension,
        'period': period,
        'order': order,
        'limit': limit,
      }),
    );
    return _parseApiResponse<RankingResponseDto2>(
      response.data,
      (json) => RankingResponseDto2.fromJson(_jsonObject(json)),
    );
  }

  /// GET /api/v1/analytics/alerts
  /// Requires Bearer JWT.
  Future<ApiResponse<AnalyticsAlertsResponseDto2>> getAnalyticsAlerts({
    String? metric,
    String? scope,
    String? period,
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/analytics/alerts',
      queryParameters: _clean(<String, dynamic>{
        'metric': metric,
        'scope': scope,
        'period': period,
        'limit': limit,
      }),
    );
    return _parseApiResponse<AnalyticsAlertsResponseDto2>(
      response.data,
      (json) => AnalyticsAlertsResponseDto2.fromJson(_jsonObject(json)),
    );
  }

  /// GET /api/v1/metrics
  /// Requires Bearer JWT.
  Future<ListResponse<MetricDefinitionDto2>> listMetrics({
    int page = 1,
    int pageSize = 20,
    String? search,
    bool? enabled,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/metrics',
      queryParameters: _clean(<String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'search': search,
        'enabled': enabled,
      }),
    );
    return _parseListResponse<MetricDefinitionDto2>(
      response.data,
      (json) => MetricDefinitionDto2.fromJson(_jsonObject(json)),
    );
  }

  Future<ApiResponse<MetricDefinitionDto2>> createMetric({
    required Map<String, dynamic> request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/metrics',
      data: _body(request),
    );
    return _parseApiResponse<MetricDefinitionDto2>(
      response.data,
      (json) => MetricDefinitionDto2.fromJson(_jsonObject(json)),
    );
  }

  Future<ApiResponse<MetricDefinitionDto2>> updateMetric({
    required String id,
    required Map<String, dynamic> request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      _path('/api/v1/metrics/{id}', <String, String>{'id': id.toString()}),
      data: _body(request),
    );
    return _parseApiResponse<MetricDefinitionDto2>(
      response.data,
      (json) => MetricDefinitionDto2.fromJson(_jsonObject(json)),
    );
  }

  Future<ApiResponse<DeleteResultDto>> deleteMetric({
    required String id,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      _path('/api/v1/metrics/{id}', <String, String>{'id': id.toString()}),
    );
    return _parseApiResponse<DeleteResultDto>(
      response.data,
      (json) => DeleteResultDto.fromJson(_jsonObject(json)),
    );
  }

  Future<ApiResponse<List<MetricMappingDto2>>> listMetricMappings({
    required String id,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/metrics/{id}/mappings', <String, String>{
        'id': id.toString(),
      }),
    );
    return _parseApiResponse<List<MetricMappingDto2>>(
      response.data,
      (json) =>
          _parseDtoList<MetricMappingDto2>(json, MetricMappingDto2.fromJson),
    );
  }

  Future<ApiResponse<List<MetricMappingDto2>>> setMetricMappings({
    required String id,
    required SetMetricMappingsRequest2 request,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      _path('/api/v1/metrics/{id}/mappings', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<List<MetricMappingDto2>>(
      response.data,
      (json) =>
          _parseDtoList<MetricMappingDto2>(json, MetricMappingDto2.fromJson),
    );
  }

  /// GET /api/v1/audience-segments
  /// Requires Bearer JWT.
  Future<ListResponse<AudienceSegmentDto2>> listAudienceSegments({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? segmentType,
    bool? enabled,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/audience-segments',
      queryParameters: _clean(<String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'search': search,
        'segment_type': segmentType,
        'enabled': enabled,
      }),
    );
    return _parseListResponse<AudienceSegmentDto2>(
      response.data,
      (json) => AudienceSegmentDto2.fromJson(_jsonObject(json)),
    );
  }

  Future<ApiResponse<AudienceSegmentDto2>> createAudienceSegment({
    required CreateAudienceSegmentRequest2 request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/audience-segments',
      data: _body(request.toJson()),
    );
    return _parseApiResponse<AudienceSegmentDto2>(
      response.data,
      (json) => AudienceSegmentDto2.fromJson(_jsonObject(json)),
    );
  }

  Future<ApiResponse<AudienceSegmentDto2>> updateAudienceSegment({
    required String id,
    required UpdateAudienceSegmentRequest2 request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      _path('/api/v1/audience-segments/{id}', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<AudienceSegmentDto2>(
      response.data,
      (json) => AudienceSegmentDto2.fromJson(_jsonObject(json)),
    );
  }

  Future<ApiResponse<DeleteResultDto>> deleteAudienceSegment({
    required String id,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      _path('/api/v1/audience-segments/{id}', <String, String>{
        'id': id.toString(),
      }),
    );
    return _parseApiResponse<DeleteResultDto>(
      response.data,
      (json) => DeleteResultDto.fromJson(_jsonObject(json)),
    );
  }

  Future<ApiResponse<List<AudienceSegmentMemberDto2>>>
  listAudienceSegmentMembers({required String id}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/audience-segments/{id}/members', <String, String>{
        'id': id.toString(),
      }),
    );
    return _parseApiResponse<List<AudienceSegmentMemberDto2>>(
      response.data,
      (json) => _parseDtoList<AudienceSegmentMemberDto2>(
        json,
        AudienceSegmentMemberDto2.fromJson,
      ),
    );
  }

  Future<ApiResponse<List<AudienceSegmentMemberDto2>>>
  setAudienceSegmentMembers({
    required String id,
    required SetAudienceSegmentMembersRequest2 request,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      _path('/api/v1/audience-segments/{id}/members', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<List<AudienceSegmentMemberDto2>>(
      response.data,
      (json) => _parseDtoList<AudienceSegmentMemberDto2>(
        json,
        AudienceSegmentMemberDto2.fromJson,
      ),
    );
  }

  /// GET /api/v1/audience-groups
  /// Requires Bearer JWT.
  Future<ListResponse<AudienceGroupOptionDto2>> listAudienceGroups({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? groupType,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/audience-groups',
      queryParameters: _clean(<String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'search': search,
        'group_type': groupType,
      }),
    );
    return _parseListResponse<AudienceGroupOptionDto2>(
      response.data,
      (json) => AudienceGroupOptionDto2.fromJson(_jsonObject(json)),
    );
  }

  /// POST /api/v1/audience-groups
  /// Requires Bearer JWT.
  Future<ApiResponse<AudienceGroupDto2>> createAudienceGroup({
    required CreateAudienceGroupRequest2 request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/audience-groups',
      data: _body(request.toJson()),
    );
    return _parseApiResponse<AudienceGroupDto2>(
      response.data,
      (json) => AudienceGroupDto2.fromJson(_jsonObject(json)),
    );
  }

  /// GET /api/v1/audience-groups/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<AudienceGroupDto2>> getAudienceGroup({
    required String id,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/audience-groups/{id}', <String, String>{
        'id': id.toString(),
      }),
    );
    return _parseApiResponse<AudienceGroupDto2>(
      response.data,
      (json) => AudienceGroupDto2.fromJson(_jsonObject(json)),
    );
  }

  /// PATCH /api/v1/audience-groups/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<AudienceGroupDto2>> updateAudienceGroup({
    required String id,
    required UpdateAudienceGroupRequest2 request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      _path('/api/v1/audience-groups/{id}', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<AudienceGroupDto2>(
      response.data,
      (json) => AudienceGroupDto2.fromJson(_jsonObject(json)),
    );
  }

  /// DELETE /api/v1/audience-groups/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<DeleteResultDto>> deleteAudienceGroup({
    required String id,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      _path('/api/v1/audience-groups/{id}', <String, String>{
        'id': id.toString(),
      }),
    );
    return _parseApiResponse<DeleteResultDto>(
      response.data,
      (json) => DeleteResultDto.fromJson(_jsonObject(json)),
    );
  }

  /// GET /api/v1/audience-groups/{id}/members
  /// Requires Bearer JWT.
  Future<ApiResponse<List<AudienceGroupMemberDto2>>> listAudienceGroupMembers({
    required String id,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/audience-groups/{id}/members', <String, String>{
        'id': id.toString(),
      }),
    );
    return _parseApiResponse<List<AudienceGroupMemberDto2>>(
      response.data,
      (json) => _parseDtoList<AudienceGroupMemberDto2>(
        json,
        AudienceGroupMemberDto2.fromJson,
      ),
    );
  }

  /// PUT /api/v1/audience-groups/{id}/members
  /// Requires Bearer JWT.
  Future<ApiResponse<List<AudienceGroupMemberDto2>>> setAudienceGroupMembers({
    required String id,
    required SetAudienceGroupMembersRequest2 request,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      _path('/api/v1/audience-groups/{id}/members', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<List<AudienceGroupMemberDto2>>(
      response.data,
      (json) => _parseDtoList<AudienceGroupMemberDto2>(
        json,
        AudienceGroupMemberDto2.fromJson,
      ),
    );
  }

  /// POST /api/v1/audience-groups/{id}/members
  /// Requires Bearer JWT.
  Future<ApiResponse<List<AudienceGroupMemberDto2>>> addAudienceGroupMember({
    required String id,
    required AudienceGroupMemberInputDto2 member,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path('/api/v1/audience-groups/{id}/members', <String, String>{
        'id': id.toString(),
      }),
      data: _body(member.toJson()),
    );
    return _parseApiResponse<List<AudienceGroupMemberDto2>>(
      response.data,
      (json) => _parseDtoList<AudienceGroupMemberDto2>(
        json,
        AudienceGroupMemberDto2.fromJson,
      ),
    );
  }

  /// DELETE /api/v1/audience-groups/{id}/members/{userId}
  /// Requires Bearer JWT.
  Future<ApiResponse<List<AudienceGroupMemberDto2>>> removeAudienceGroupMember({
    required String id,
    required String userId,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      _path('/api/v1/audience-groups/{id}/members/{userId}', <String, String>{
        'id': id.toString(),
        'userId': userId.toString(),
      }),
    );
    return _parseApiResponse<List<AudienceGroupMemberDto2>>(
      response.data,
      (json) => _parseDtoList<AudienceGroupMemberDto2>(
        json,
        AudienceGroupMemberDto2.fromJson,
      ),
    );
  }

  /// GET /api/v1/forms/{id}/assignments
  /// Requires Bearer JWT.
  Future<ApiResponse<List<FormAssignmentDto2>>> listFormAssignments({
    required String id,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/assignments', <String, String>{
        'id': id.toString(),
      }),
    );
    return _parseApiResponse<List<FormAssignmentDto2>>(
      response.data,
      (json) =>
          _parseDtoList<FormAssignmentDto2>(json, FormAssignmentDto2.fromJson),
    );
  }

  /// PUT /api/v1/forms/{id}/assignments
  /// Requires Bearer JWT and form update permission.
  Future<ApiResponse<List<FormAssignmentDto2>>> setFormAssignments({
    required String id,
    required SetFormAssignmentsRequest2 request,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/assignments', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<List<FormAssignmentDto2>>(
      response.data,
      (json) =>
          _parseDtoList<FormAssignmentDto2>(json, FormAssignmentDto2.fromJson),
    );
  }

  /// operationId: approveForm
  /// POST /api/v1/forms/{id}/approve
  /// Requires Bearer JWT.
  Future<ApiResponse<FormDetailDto>> approveForm({
    required String id,
    required ApproveFormRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/approve', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<FormDetailDto>(
      response.data,
      (json) => FormDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: archiveForm
  /// POST /api/v1/forms/{id}/archive
  /// Requires Bearer JWT.
  Future<ApiResponse<FormDetailDto>> archiveForm({
    required String id,
    required ArchiveFormRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/archive', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<FormDetailDto>(
      response.data,
      (json) => FormDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: closeForm
  /// POST /api/v1/forms/{id}/close
  /// Requires Bearer JWT.
  Future<ApiResponse<FormDetailDto>> closeForm({
    required String id,
    required CloseFormRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/close', <String, String>{'id': id.toString()}),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<FormDetailDto>(
      response.data,
      (json) => FormDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: duplicateForm
  /// POST /api/v1/forms/{id}/duplicate
  /// Requires Bearer JWT.
  Future<ApiResponse<FormDetailDto>> duplicateForm({
    required String id,
    required DuplicateFormRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/duplicate', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<FormDetailDto>(
      response.data,
      (json) => FormDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: createFormField
  /// POST /api/v1/forms/{id}/fields
  /// Requires Bearer JWT.
  Future<ApiResponse<FormFieldDto>> createFormField({
    required String id,
    required CreateFormFieldRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/fields', <String, String>{'id': id.toString()}),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<FormFieldDto>(
      response.data,
      (json) => FormFieldDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: deleteFormField
  /// DELETE /api/v1/forms/{id}/fields/{field_id}
  /// Requires Bearer JWT.
  Future<ApiResponse<DeleteResultDto>> deleteFormField({
    required String id,
    required String fieldId,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/fields/{field_id}', <String, String>{
        'id': id.toString(),
        'field_id': fieldId.toString(),
      }),
    );
    return _parseApiResponse<DeleteResultDto>(
      response.data,
      (json) => DeleteResultDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: updateFormField
  /// PATCH /api/v1/forms/{id}/fields/{field_id}
  /// Requires Bearer JWT.
  Future<ApiResponse<FormFieldDto>> updateFormField({
    required String id,
    required String fieldId,
    required UpdateFormFieldRequest request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/fields/{field_id}', <String, String>{
        'id': id.toString(),
        'field_id': fieldId.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<FormFieldDto>(
      response.data,
      (json) => FormFieldDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: updatePublicProtection
  /// PATCH /api/v1/forms/{id}/public-protection
  /// Requires Bearer JWT.
  Future<ApiResponse<FormDetailDto>> updatePublicProtection({
    required String id,
    required UpdatePublicProtectionRequest request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/public-protection', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<FormDetailDto>(
      response.data,
      (json) => FormDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// GET /api/v1/forms/{id}/access-codes
  /// Requires Bearer JWT.
  Future<ApiResponse<FormAccessCodesResponse>> listFormAccessCodes({
    required String id,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/access-codes', <String, String>{
        'id': id.toString(),
      }),
    );
    return _parseApiResponse<FormAccessCodesResponse>(
      response.data,
      (json) => FormAccessCodesResponse.fromJson(_jsonObject(json)),
    );
  }

  /// PUT /api/v1/forms/{id}/access-codes
  /// Requires Bearer JWT.
  Future<ApiResponse<FormAccessCodesResponse>> setFormAccessCodes({
    required String id,
    required SetFormAccessCodesRequest request,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/access-codes', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<FormAccessCodesResponse>(
      response.data,
      (json) => FormAccessCodesResponse.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: publishForm
  /// POST /api/v1/forms/{id}/publish
  /// Requires Bearer JWT.
  Future<ApiResponse<FormDetailDto>> publishForm({
    required String id,
    required PublishFormRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/publish', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<FormDetailDto>(
      response.data,
      (json) => FormDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: rejectForm
  /// POST /api/v1/forms/{id}/reject
  /// Requires Bearer JWT.
  Future<ApiResponse<FormDetailDto>> rejectForm({
    required String id,
    required RejectFormRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/reject', <String, String>{'id': id.toString()}),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<FormDetailDto>(
      response.data,
      (json) => FormDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: listSubmissions
  /// GET /api/v1/forms/{id}/submissions
  /// Requires Bearer JWT.
  Future<ListResponse<SubmissionSummaryDto>> listSubmissions({
    required String id,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    SortOrder? sortOrder,
    String? filters,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/submissions', <String, String>{
        'id': id.toString(),
      }),
      queryParameters: _clean(<String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'search': search,
        'sort_by': sortBy,
        'sort_order': sortOrder?.toJson(),
        'filters': filters,
      }),
    );
    return _parseListResponse<SubmissionSummaryDto>(
      response.data,
      (json) => SubmissionSummaryDto.fromJson(_jsonObject(json)),
    );
  }

  Future<ApiResponse<Map<String, dynamic>?>> getAnswerDraft({
    required String id,
    String? childId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/answer-draft', <String, String>{'id': id}),
      queryParameters: _clean(<String, dynamic>{'child_id': childId}),
    );
    return _parseApiResponse<Map<String, dynamic>?>(
      response.data,
      (json) => json == null ? null : _jsonObject(json),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> saveAnswerDraft({
    required String id,
    required Map<String, dynamic> request,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/answer-draft', <String, String>{'id': id}),
      data: _body(request),
    );
    return _parseApiResponse<Map<String, dynamic>>(response.data, _jsonObject);
  }

  Future<ApiResponse<DeleteResultDto>> deleteAnswerDraft({
    required String id,
    String? childId,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/answer-draft', <String, String>{'id': id}),
      queryParameters: _clean(<String, dynamic>{'child_id': childId}),
    );
    return _parseApiResponse<DeleteResultDto>(
      response.data,
      (json) => DeleteResultDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: createSubmission
  /// POST /api/v1/forms/{id}/submissions
  /// Requires Bearer JWT.
  Future<ApiResponse<SubmissionDetailDto>> createSubmission({
    required String id,
    required CreateSubmissionRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/submissions', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<SubmissionDetailDto>(
      response.data,
      (json) => SubmissionDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: submitFormForApproval
  /// POST /api/v1/forms/{id}/submit-for-approval
  /// Requires Bearer JWT.
  Future<ApiResponse<FormDetailDto>> submitFormForApproval({
    required String id,
    required SubmitForApprovalRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/submit-for-approval', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<FormDetailDto>(
      response.data,
      (json) => FormDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: updateFormVisibility
  /// PATCH /api/v1/forms/{id}/visibility
  /// Requires Bearer JWT.
  Future<ApiResponse<FormDetailDto>> updateFormVisibility({
    required String id,
    required UpdateFormVisibilityRequest request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      _path('/api/v1/forms/{id}/visibility', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<FormDetailDto>(
      response.data,
      (json) => FormDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getOrganization
  /// GET /api/v1/organizations/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<OrganizationDto>> getOrganization({
    required String id,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/organizations/{id}', <String, String>{
        'id': id.toString(),
      }),
    );
    return _parseApiResponse<OrganizationDto>(
      response.data,
      (json) => OrganizationDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: updateRoleRules
  /// PATCH /api/v1/organizations/{id}/role-rules
  /// Requires Bearer JWT.
  Future<ApiResponse<UpdateResultDto>> updateRoleRules({
    required String id,
    required UpdateRoleRulesRequest request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      _path('/api/v1/organizations/{id}/role-rules', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<UpdateResultDto>(
      response.data,
      (json) => UpdateResultDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getOrganizationRoles
  /// GET /api/v1/organizations/{id}/roles
  /// Requires Bearer JWT.
  Future<ListResponse<OrganizationRoleDto>> getOrganizationRoles({
    required String id,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/organizations/{id}/roles', <String, String>{
        'id': id.toString(),
      }),
    );
    return _parseListResponse<OrganizationRoleDto>(
      response.data,
      (json) => OrganizationRoleDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getEffectivePermissions
  /// GET /api/v1/permissions/effective
  /// Requires Bearer JWT.
  Future<ApiResponse<EffectivePermissionsDto>> getEffectivePermissions() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/permissions/effective',
    );
    return _parseApiResponse<EffectivePermissionsDto>(
      response.data,
      (json) => EffectivePermissionsDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getFieldTypePermissions
  /// GET /api/v1/permissions/field-types
  /// Requires Bearer JWT.
  Future<ApiResponse<List<FieldTypePermissionDto>>> getFieldTypePermissions({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    SortOrder? sortOrder,
    String? filters,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/permissions/field-types',
      queryParameters: _clean(<String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'search': search,
        'sort_by': sortBy,
        'sort_order': sortOrder?.toJson(),
        'filters': filters,
      }),
    );
    return _parseApiResponse<List<FieldTypePermissionDto>>(
      response.data,
      (json) => _parseDtoList<FieldTypePermissionDto>(
        json,
        (item) => FieldTypePermissionDto.fromJson(_jsonObject(item)),
      ),
    );
  }

  /// operationId: updateFieldTypePermissions
  /// PATCH /api/v1/permissions/field-types
  /// Requires Bearer JWT.
  Future<ApiResponse<UpdateResultDto>> updateFieldTypePermissions({
    required UpdateFieldTypePermissionsRequest request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/permissions/field-types',
      data: _body(request.toJson()),
    );
    return _parseApiResponse<UpdateResultDto>(
      response.data,
      (json) => UpdateResultDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getPublishingRules
  /// GET /api/v1/permissions/publishing-rules
  /// Requires Bearer JWT.
  Future<ApiResponse<List<PublishingRuleDto>>> getPublishingRules() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/permissions/publishing-rules',
    );
    return _parseApiResponse<List<PublishingRuleDto>>(
      response.data,
      (json) => _parseDtoList<PublishingRuleDto>(
        json,
        (item) => PublishingRuleDto.fromJson(_jsonObject(item)),
      ),
    );
  }

  /// operationId: updatePublishingRules
  /// PATCH /api/v1/permissions/publishing-rules
  /// Requires Bearer JWT.
  Future<ApiResponse<UpdateResultDto>> updatePublishingRules({
    required UpdatePublishingRulesRequest request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/permissions/publishing-rules',
      data: _body(request.toJson()),
    );
    return _parseApiResponse<UpdateResultDto>(
      response.data,
      (json) => UpdateResultDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getPublicForm
  /// GET /api/v1/public/forms/{public_token}
  /// Public endpoint; no Bearer JWT required by the contract.
  Future<ApiResponse<PublicFormDto>> getPublicForm({
    required String publicToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/public/forms/{public_token}', <String, String>{
        'public_token': publicToken.toString(),
      }),
    );
    return _parseApiResponse<PublicFormDto>(
      response.data,
      (json) => PublicFormDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: submitPublicForm
  /// POST /api/v1/public/forms/{public_token}/submissions
  /// Public endpoint; no Bearer JWT required by the contract.
  Future<ApiResponse<PublicSubmissionResponse>> submitPublicForm({
    required String publicToken,
    required PublicSubmissionRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path('/api/v1/public/forms/{public_token}/submissions', <String, String>{
        'public_token': publicToken.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<PublicSubmissionResponse>(
      response.data,
      (json) => PublicSubmissionResponse.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: validatePublicFormAccess
  /// POST /api/v1/public/forms/{public_token}/validate-access
  /// Public endpoint; no Bearer JWT required by the contract.
  Future<ApiResponse<ValidatePublicFormAccessResponse>>
  validatePublicFormAccess({
    required String publicToken,
    required ValidatePublicFormAccessRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path(
        '/api/v1/public/forms/{public_token}/validate-access',
        <String, String>{'public_token': publicToken.toString()},
      ),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<ValidatePublicFormAccessResponse>(
      response.data,
      (json) => ValidatePublicFormAccessResponse.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: listScoreTemplates
  /// GET /api/v1/score-templates
  /// Requires Bearer JWT.
  Future<ListResponse<ScoreTemplateDto>> listScoreTemplates({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    SortOrder? sortOrder,
    String? filters,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/score-templates',
      queryParameters: _clean(<String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'search': search,
        'sort_by': sortBy,
        'sort_order': sortOrder?.toJson(),
        'filters': filters,
      }),
    );
    return _parseListResponse<ScoreTemplateDto>(
      response.data,
      (json) => ScoreTemplateDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: createScoreTemplate
  /// POST /api/v1/score-templates
  /// Requires Bearer JWT.
  Future<ApiResponse<ScoreTemplateDto>> createScoreTemplate({
    required CreateScoreTemplateRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/score-templates',
      data: _body(request.toJson()),
    );
    return _parseApiResponse<ScoreTemplateDto>(
      response.data,
      (json) => ScoreTemplateDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getScoreTemplate
  /// GET /api/v1/score-templates/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<ScoreTemplateDto>> getScoreTemplate({
    required String id,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/score-templates/{id}', <String, String>{
        'id': id.toString(),
      }),
    );
    return _parseApiResponse<ScoreTemplateDto>(
      response.data,
      (json) => ScoreTemplateDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: deleteScoreTemplate
  /// DELETE /api/v1/score-templates/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<DeleteResultDto>> deleteScoreTemplate({
    required String id,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      _path('/api/v1/score-templates/{id}', <String, String>{
        'id': id.toString(),
      }),
    );
    return _parseApiResponse<DeleteResultDto>(
      response.data,
      (json) => DeleteResultDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: updateScoreTemplate
  /// PATCH /api/v1/score-templates/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<ScoreTemplateDto>> updateScoreTemplate({
    required String id,
    required UpdateScoreTemplateRequest request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      _path('/api/v1/score-templates/{id}', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<ScoreTemplateDto>(
      response.data,
      (json) => ScoreTemplateDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getSubmission
  /// GET /api/v1/submissions/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<SubmissionDetailDto>> getSubmission({
    required String id,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/submissions/{id}', <String, String>{'id': id.toString()}),
    );
    return _parseApiResponse<SubmissionDetailDto>(
      response.data,
      (json) => SubmissionDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: deleteSubmission
  /// DELETE /api/v1/submissions/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<DeleteResultDto>> deleteSubmission({
    required String id,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      _path('/api/v1/submissions/{id}', <String, String>{'id': id.toString()}),
    );
    return _parseApiResponse<DeleteResultDto>(
      response.data,
      (json) => DeleteResultDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: updateSubmission
  /// PATCH /api/v1/submissions/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<SubmissionDetailDto>> updateSubmission({
    required String id,
    required UpdateSubmissionRequest request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      _path('/api/v1/submissions/{id}', <String, String>{'id': id.toString()}),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<SubmissionDetailDto>(
      response.data,
      (json) => SubmissionDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getSubmissionScoreBreakdown
  /// GET /api/v1/submissions/{id}/score-breakdown
  /// Requires Bearer JWT.
  Future<ApiResponse<ScoreBreakdownDto>> getSubmissionScoreBreakdown({
    required String id,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/submissions/{id}/score-breakdown', <String, String>{
        'id': id.toString(),
      }),
    );
    return _parseApiResponse<ScoreBreakdownDto>(
      response.data,
      (json) => ScoreBreakdownDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: listUsers
  /// GET /api/v1/users
  /// Requires Bearer JWT.
  Future<ListResponse<UserSummaryDto>> listUsers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    SortOrder? sortOrder,
    String? filters,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/users',
      queryParameters: _clean(<String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'search': search,
        'sort_by': sortBy,
        'sort_order': sortOrder?.toJson(),
        'filters': filters,
      }),
    );
    return _parseListResponse<UserSummaryDto>(
      response.data,
      (json) => UserSummaryDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: createUser
  /// POST /api/v1/users
  /// Requires Bearer JWT.
  Future<ApiResponse<UserDetailDto>> createUser({
    required CreateUserRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/users',
      data: _body(request.toJson()),
    );
    return _parseApiResponse<UserDetailDto>(
      response.data,
      (json) => UserDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getMyUser
  /// GET /api/v1/users/me
  /// Requires Bearer JWT.
  Future<ApiResponse<UserDetailDto>> getMyUser() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/users/me');
    return _parseApiResponse<UserDetailDto>(
      response.data,
      (json) => UserDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: updateMyProfile
  /// PATCH /api/v1/users/me
  /// Requires Bearer JWT.
  Future<ApiResponse<UserDetailDto>> updateMyProfile({
    required UpdateUserProfileRequest request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/users/me',
      data: _body(request.toJson()),
    );
    return _parseApiResponse<UserDetailDto>(
      response.data,
      (json) => UserDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getUser
  /// GET /api/v1/users/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<UserDetailDto>> getUser({required String id}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/users/{id}', <String, String>{'id': id.toString()}),
    );
    return _parseApiResponse<UserDetailDto>(
      response.data,
      (json) => UserDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: updateUser
  /// PATCH /api/v1/users/{id}
  /// Requires Bearer JWT.
  Future<ApiResponse<UserDetailDto>> updateUser({
    required String id,
    required UpdateUserRequest request,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      _path('/api/v1/users/{id}', <String, String>{'id': id.toString()}),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<UserDetailDto>(
      response.data,
      (json) => UserDetailDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getUserRelationships
  /// GET /api/v1/users/{id}/relationships
  /// Requires Bearer JWT.
  Future<ApiResponse<UserFamilyLinksDto>> getUserRelationships({
    required String id,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/users/{id}/relationships', <String, String>{
        'id': id.toString(),
      }),
    );
    return _parseApiResponse<UserFamilyLinksDto>(
      response.data,
      (json) => UserFamilyLinksDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: createUserRelationship
  /// POST /api/v1/users/{id}/relationships
  /// Requires Bearer JWT.
  Future<ApiResponse<UserRelationshipDto>> createUserRelationship({
    required String id,
    required CreateUserRelationshipRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path('/api/v1/users/{id}/relationships', <String, String>{
        'id': id.toString(),
      }),
      data: _body(request.toJson()),
    );
    return _parseApiResponse<UserRelationshipDto>(
      response.data,
      (json) => UserRelationshipDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: deleteUserRelationship
  /// DELETE /api/v1/users/{id}/relationships/{relationship_id}
  /// Requires Bearer JWT.
  Future<ApiResponse<DeleteResultDto>> deleteUserRelationship({
    required String id,
    required String relationshipId,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      _path(
        '/api/v1/users/{id}/relationships/{relationship_id}',
        <String, String>{
          'id': id.toString(),
          'relationship_id': relationshipId.toString(),
        },
      ),
    );
    return _parseApiResponse<DeleteResultDto>(
      response.data,
      (json) => DeleteResultDto.fromJson(_jsonObject(json)),
    );
  }

  /// operationId: getUserSubordinates
  /// GET /api/v1/users/{id}/subordinates
  /// Requires Bearer JWT.
  Future<ListResponse<SubordinateUserDto>> getUserSubordinates({
    required String id,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    SortOrder? sortOrder,
    String? filters,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path('/api/v1/users/{id}/subordinates', <String, String>{
        'id': id.toString(),
      }),
      queryParameters: _clean(<String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'search': search,
        'sort_by': sortBy,
        'sort_order': sortOrder?.toJson(),
        'filters': filters,
      }),
    );
    return _parseListResponse<SubordinateUserDto>(
      response.data,
      (json) => SubordinateUserDto.fromJson(_jsonObject(json)),
    );
  }
}
