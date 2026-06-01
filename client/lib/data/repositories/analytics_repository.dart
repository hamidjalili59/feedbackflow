import '../api/feedback_flow_api_client.dart';
import '../api/api_exceptions.dart';
import '../dto/dto.dart';

abstract class AnalyticsRepository {
  Future<DashboardAnalyticsDto> getDashboardAnalytics();
  Future<FormAnalyticsDto> getFormAnalytics({required String id});
  Future<DashboardResponseDto2> getDashboardExperience({
    DashboardQueryInput query = const DashboardQueryInput(),
  });
  Future<List<ChildProfileDto2>> getMyChildren();
  Future<List<SurveyCardDto2>> getMySurveys({
    String? status,
    String? period,
    String? childId,
    int limit = 20,
  });
  Future<CalendarResponseDto2> getSurveyCalendar({
    String? period,
    String? childId,
    String? startDate,
    String? endDate,
    String? scope,
    String? scopeId,
  });
  Future<TimeseriesResponseDto2> getAnalyticsTimeseries({
    String? metric,
    String? period,
    String? compare,
    String? granularity,
    String? scope,
    String? scopeId,
  });
  Future<RankingResponseDto2> getAnalyticsRankings({
    String? metric,
    String? dimension,
    String? period,
    String? order,
    int limit = 20,
  });
  Future<AnalyticsAlertsResponseDto2> getAnalyticsAlerts({
    String? metric,
    String? scope,
    String? period,
    int limit = 20,
  });
  Future<ListResponse<MetricDefinitionDto2>> listMetrics({
    int page = 1,
    int pageSize = 20,
    String? search,
    bool? enabled,
  });
  Future<MetricDefinitionDto2> createMetric({
    required Map<String, dynamic> request,
  });
  Future<MetricDefinitionDto2> updateMetric({
    required String id,
    required Map<String, dynamic> request,
  });
  Future<DeleteResultDto> deleteMetric({required String id});
  Future<ListResponse<AudienceSegmentDto2>> listAudienceSegments({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? segmentType,
    bool? enabled,
  });
  Future<List<FormAssignmentDto2>> listFormAssignments({required String id});
}

class DioAnalyticsRepository implements AnalyticsRepository {
  DioAnalyticsRepository(this._api);

  final FeedbackFlowApiClient _api;

  @override
  Future<DashboardAnalyticsDto> getDashboardAnalytics() async {
    return EnvelopeGuard.data(await _api.getDashboardAnalytics());
  }

  @override
  Future<FormAnalyticsDto> getFormAnalytics({required String id}) async {
    return EnvelopeGuard.data(await _api.getFormAnalytics(id: id));
  }

  @override
  Future<DashboardResponseDto2> getDashboardExperience({
    DashboardQueryInput query = const DashboardQueryInput(),
  }) async {
    return EnvelopeGuard.data(await _api.getDashboardExperience(query: query));
  }

  @override
  Future<List<ChildProfileDto2>> getMyChildren() async {
    return EnvelopeGuard.data(await _api.getMyChildren());
  }

  @override
  Future<List<SurveyCardDto2>> getMySurveys({
    String? status,
    String? period,
    String? childId,
    int limit = 20,
  }) async {
    return EnvelopeGuard.data(
      await _api.getMySurveys(
        status: status,
        period: period,
        childId: childId,
        limit: limit,
      ),
    );
  }

  @override
  Future<CalendarResponseDto2> getSurveyCalendar({
    String? period,
    String? childId,
    String? startDate,
    String? endDate,
    String? scope,
    String? scopeId,
  }) async {
    return EnvelopeGuard.data(
      await _api.getSurveyCalendar(
        period: period,
        childId: childId,
        startDate: startDate,
        endDate: endDate,
        scope: scope,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<TimeseriesResponseDto2> getAnalyticsTimeseries({
    String? metric,
    String? period,
    String? compare,
    String? granularity,
    String? scope,
    String? scopeId,
  }) async {
    return EnvelopeGuard.data(
      await _api.getAnalyticsTimeseries(
        metric: metric,
        period: period,
        compare: compare,
        granularity: granularity,
        scope: scope,
        scopeId: scopeId,
      ),
    );
  }

  @override
  Future<RankingResponseDto2> getAnalyticsRankings({
    String? metric,
    String? dimension,
    String? period,
    String? order,
    int limit = 20,
  }) async {
    return EnvelopeGuard.data(
      await _api.getAnalyticsRankings(
        metric: metric,
        dimension: dimension,
        period: period,
        order: order,
        limit: limit,
      ),
    );
  }

  @override
  Future<AnalyticsAlertsResponseDto2> getAnalyticsAlerts({
    String? metric,
    String? scope,
    String? period,
    int limit = 20,
  }) async {
    return EnvelopeGuard.data(
      await _api.getAnalyticsAlerts(
        metric: metric,
        scope: scope,
        period: period,
        limit: limit,
      ),
    );
  }

  @override
  Future<ListResponse<MetricDefinitionDto2>> listMetrics({
    int page = 1,
    int pageSize = 20,
    String? search,
    bool? enabled,
  }) async {
    return EnvelopeGuard.list(
      await _api.listMetrics(
        page: page,
        pageSize: pageSize,
        search: search,
        enabled: enabled,
      ),
    );
  }

  @override
  Future<MetricDefinitionDto2> createMetric({
    required Map<String, dynamic> request,
  }) async {
    return EnvelopeGuard.data(await _api.createMetric(request: request));
  }

  @override
  Future<MetricDefinitionDto2> updateMetric({
    required String id,
    required Map<String, dynamic> request,
  }) async {
    return EnvelopeGuard.data(
      await _api.updateMetric(id: id, request: request),
    );
  }

  @override
  Future<DeleteResultDto> deleteMetric({required String id}) async {
    return EnvelopeGuard.data(await _api.deleteMetric(id: id));
  }

  @override
  Future<ListResponse<AudienceSegmentDto2>> listAudienceSegments({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? segmentType,
    bool? enabled,
  }) async {
    return EnvelopeGuard.list(
      await _api.listAudienceSegments(
        page: page,
        pageSize: pageSize,
        search: search,
        segmentType: segmentType,
        enabled: enabled,
      ),
    );
  }

  @override
  Future<List<FormAssignmentDto2>> listFormAssignments({
    required String id,
  }) async {
    return EnvelopeGuard.data(await _api.listFormAssignments(id: id));
  }
}
