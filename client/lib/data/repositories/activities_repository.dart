import '../api/feedback_flow_api_client.dart';
import '../api/api_exceptions.dart';
import '../dto/dto.dart';

abstract class ActivitiesRepository {
  Future<ListResponse<ActivitySummaryDto>> listActivities({int page = 1, int pageSize = 20, String? search, String? sortBy, SortOrder? sortOrder, String? filters});
  Future<ActivityDto> getActivity({required String id});
  Future<ActivityDto> updateActivity({required String id, required UpdateActivityRequest request});
  Future<DeleteResultDto> deleteActivityRule({required String id});
  Future<ActivityRuleDto> updateActivityRule({required String id, required UpdateActivityRuleRequest request});
  Future<ListResponse<ActivityRuleDto>> listActivityRules({required String id, int page = 1, int pageSize = 20, String? search, String? sortBy, SortOrder? sortOrder, String? filters});
  Future<ActivityRuleDto> createActivityRule({required String id, required CreateActivityRuleRequest request});
}

class DioActivitiesRepository implements ActivitiesRepository {
  DioActivitiesRepository(this._api);

  final FeedbackFlowApiClient _api;

  @override
  Future<ListResponse<ActivitySummaryDto>> listActivities({int page = 1, int pageSize = 20, String? search, String? sortBy, SortOrder? sortOrder, String? filters}) async {
    return EnvelopeGuard.list(await _api.listActivities(page: page, pageSize: pageSize, search: search, sortBy: sortBy, sortOrder: sortOrder, filters: filters));
  }

  @override
  Future<ActivityDto> getActivity({required String id}) async {
    return EnvelopeGuard.data(await _api.getActivity(id: id));
  }

  @override
  Future<ActivityDto> updateActivity({required String id, required UpdateActivityRequest request}) async {
    return EnvelopeGuard.data(await _api.updateActivity(id: id, request: request));
  }

  @override
  Future<DeleteResultDto> deleteActivityRule({required String id}) async {
    return EnvelopeGuard.data(await _api.deleteActivityRule(id: id));
  }

  @override
  Future<ActivityRuleDto> updateActivityRule({required String id, required UpdateActivityRuleRequest request}) async {
    return EnvelopeGuard.data(await _api.updateActivityRule(id: id, request: request));
  }

  @override
  Future<ListResponse<ActivityRuleDto>> listActivityRules({required String id, int page = 1, int pageSize = 20, String? search, String? sortBy, SortOrder? sortOrder, String? filters}) async {
    return EnvelopeGuard.list(await _api.listActivityRules(id: id, page: page, pageSize: pageSize, search: search, sortBy: sortBy, sortOrder: sortOrder, filters: filters));
  }

  @override
  Future<ActivityRuleDto> createActivityRule({required String id, required CreateActivityRuleRequest request}) async {
    return EnvelopeGuard.data(await _api.createActivityRule(id: id, request: request));
  }

}
