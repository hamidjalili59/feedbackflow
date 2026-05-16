import '../api/feedback_flow_api_client.dart';
import '../api/api_exceptions.dart';
import '../dto/dto.dart';

abstract class PermissionsRepository {
  Future<EffectivePermissionsDto> getEffectivePermissions();
  Future<List<FieldTypePermissionDto>> getFieldTypePermissions({int page = 1, int pageSize = 20, String? search, String? sortBy, SortOrder? sortOrder, String? filters});
  Future<UpdateResultDto> updateFieldTypePermissions({required UpdateFieldTypePermissionsRequest request});
  Future<List<PublishingRuleDto>> getPublishingRules();
  Future<UpdateResultDto> updatePublishingRules({required UpdatePublishingRulesRequest request});
}

class DioPermissionsRepository implements PermissionsRepository {
  DioPermissionsRepository(this._api);

  final FeedbackFlowApiClient _api;

  @override
  Future<EffectivePermissionsDto> getEffectivePermissions() async {
    return EnvelopeGuard.data(await _api.getEffectivePermissions());
  }

  @override
  Future<List<FieldTypePermissionDto>> getFieldTypePermissions({int page = 1, int pageSize = 20, String? search, String? sortBy, SortOrder? sortOrder, String? filters}) async {
    return EnvelopeGuard.dataList(await _api.getFieldTypePermissions(page: page, pageSize: pageSize, search: search, sortBy: sortBy, sortOrder: sortOrder, filters: filters));
  }

  @override
  Future<UpdateResultDto> updateFieldTypePermissions({required UpdateFieldTypePermissionsRequest request}) async {
    return EnvelopeGuard.data(await _api.updateFieldTypePermissions(request: request));
  }

  @override
  Future<List<PublishingRuleDto>> getPublishingRules() async {
    return EnvelopeGuard.dataList(await _api.getPublishingRules());
  }

  @override
  Future<UpdateResultDto> updatePublishingRules({required UpdatePublishingRulesRequest request}) async {
    return EnvelopeGuard.data(await _api.updatePublishingRules(request: request));
  }

}
