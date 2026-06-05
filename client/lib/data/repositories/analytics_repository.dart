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
  Future<List<MetricMappingDto2>> listMetricMappings({required String id});
  Future<List<MetricMappingDto2>> setMetricMappings({
    required String id,
    required SetMetricMappingsRequest2 request,
  });
  Future<ListResponse<AudienceSegmentDto2>> listAudienceSegments({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? segmentType,
    bool? enabled,
  });
  Future<AudienceSegmentDto2> createAudienceSegment({
    required CreateAudienceSegmentRequest2 request,
  });
  Future<AudienceSegmentDto2> updateAudienceSegment({
    required String id,
    required UpdateAudienceSegmentRequest2 request,
  });
  Future<DeleteResultDto> deleteAudienceSegment({required String id});
  Future<List<AudienceSegmentMemberDto2>> listAudienceSegmentMembers({
    required String id,
  });
  Future<List<AudienceSegmentMemberDto2>> setAudienceSegmentMembers({
    required String id,
    required SetAudienceSegmentMembersRequest2 request,
  });
  Future<ListResponse<AudienceGroupOptionDto2>> listAudienceGroups({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? groupType,
  });
  Future<AudienceGroupDto2> getAudienceGroup({required String id});
  Future<AudienceGroupDto2> createAudienceGroup({
    required CreateAudienceGroupRequest2 request,
  });
  Future<AudienceGroupDto2> updateAudienceGroup({
    required String id,
    required UpdateAudienceGroupRequest2 request,
  });
  Future<DeleteResultDto> deleteAudienceGroup({required String id});
  Future<List<AudienceGroupMemberDto2>> listAudienceGroupMembers({
    required String id,
  });
  Future<List<AudienceGroupMemberDto2>> setAudienceGroupMembers({
    required String id,
    required SetAudienceGroupMembersRequest2 request,
  });
  Future<List<AudienceGroupMemberDto2>> addAudienceGroupMember({
    required String id,
    required AudienceGroupMemberInputDto2 member,
  });
  Future<List<AudienceGroupMemberDto2>> removeAudienceGroupMember({
    required String id,
    required String userId,
  });
  Future<List<FormAssignmentDto2>> listFormAssignments({required String id});
  Future<List<FormAssignmentDto2>> setFormAssignments({
    required String id,
    required SetFormAssignmentsRequest2 request,
  });
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
  Future<List<MetricMappingDto2>> listMetricMappings({
    required String id,
  }) async {
    return EnvelopeGuard.data(await _api.listMetricMappings(id: id));
  }

  @override
  Future<List<MetricMappingDto2>> setMetricMappings({
    required String id,
    required SetMetricMappingsRequest2 request,
  }) async {
    return EnvelopeGuard.data(
      await _api.setMetricMappings(id: id, request: request),
    );
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
  Future<AudienceSegmentDto2> createAudienceSegment({
    required CreateAudienceSegmentRequest2 request,
  }) async {
    return EnvelopeGuard.data(
      await _api.createAudienceSegment(request: request),
    );
  }

  @override
  Future<AudienceSegmentDto2> updateAudienceSegment({
    required String id,
    required UpdateAudienceSegmentRequest2 request,
  }) async {
    return EnvelopeGuard.data(
      await _api.updateAudienceSegment(id: id, request: request),
    );
  }

  @override
  Future<DeleteResultDto> deleteAudienceSegment({required String id}) async {
    return EnvelopeGuard.data(await _api.deleteAudienceSegment(id: id));
  }

  @override
  Future<List<AudienceSegmentMemberDto2>> listAudienceSegmentMembers({
    required String id,
  }) async {
    return EnvelopeGuard.data(await _api.listAudienceSegmentMembers(id: id));
  }

  @override
  Future<List<AudienceSegmentMemberDto2>> setAudienceSegmentMembers({
    required String id,
    required SetAudienceSegmentMembersRequest2 request,
  }) async {
    return EnvelopeGuard.data(
      await _api.setAudienceSegmentMembers(id: id, request: request),
    );
  }

  @override
  Future<ListResponse<AudienceGroupOptionDto2>> listAudienceGroups({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? groupType,
  }) async {
    return EnvelopeGuard.list(
      await _api.listAudienceGroups(
        page: page,
        pageSize: pageSize,
        search: search,
        groupType: groupType,
      ),
    );
  }

  @override
  Future<AudienceGroupDto2> getAudienceGroup({required String id}) async {
    return EnvelopeGuard.data(await _api.getAudienceGroup(id: id));
  }

  @override
  Future<AudienceGroupDto2> createAudienceGroup({
    required CreateAudienceGroupRequest2 request,
  }) async {
    return EnvelopeGuard.data(await _api.createAudienceGroup(request: request));
  }

  @override
  Future<AudienceGroupDto2> updateAudienceGroup({
    required String id,
    required UpdateAudienceGroupRequest2 request,
  }) async {
    return EnvelopeGuard.data(
      await _api.updateAudienceGroup(id: id, request: request),
    );
  }

  @override
  Future<DeleteResultDto> deleteAudienceGroup({required String id}) async {
    return EnvelopeGuard.data(await _api.deleteAudienceGroup(id: id));
  }

  @override
  Future<List<AudienceGroupMemberDto2>> listAudienceGroupMembers({
    required String id,
  }) async {
    return EnvelopeGuard.data(await _api.listAudienceGroupMembers(id: id));
  }

  @override
  Future<List<AudienceGroupMemberDto2>> setAudienceGroupMembers({
    required String id,
    required SetAudienceGroupMembersRequest2 request,
  }) async {
    return EnvelopeGuard.data(
      await _api.setAudienceGroupMembers(id: id, request: request),
    );
  }

  @override
  Future<List<AudienceGroupMemberDto2>> addAudienceGroupMember({
    required String id,
    required AudienceGroupMemberInputDto2 member,
  }) async {
    return EnvelopeGuard.data(
      await _api.addAudienceGroupMember(id: id, member: member),
    );
  }

  @override
  Future<List<AudienceGroupMemberDto2>> removeAudienceGroupMember({
    required String id,
    required String userId,
  }) async {
    return EnvelopeGuard.data(
      await _api.removeAudienceGroupMember(id: id, userId: userId),
    );
  }

  @override
  Future<List<FormAssignmentDto2>> listFormAssignments({
    required String id,
  }) async {
    return EnvelopeGuard.data(await _api.listFormAssignments(id: id));
  }

  @override
  Future<List<FormAssignmentDto2>> setFormAssignments({
    required String id,
    required SetFormAssignmentsRequest2 request,
  }) async {
    return EnvelopeGuard.data(
      await _api.setFormAssignments(id: id, request: request),
    );
  }
}
