import '../api/feedback_flow_api_client.dart';
import '../api/api_exceptions.dart';
import '../dto/dto.dart';

abstract class OrganizationsRepository {
  Future<OrganizationDto> getOrganization({required String id});
  Future<UpdateResultDto> updateRoleRules({required String id, required UpdateRoleRulesRequest request});
  Future<ListResponse<OrganizationRoleDto>> getOrganizationRoles({required String id});
}

class DioOrganizationsRepository implements OrganizationsRepository {
  DioOrganizationsRepository(this._api);

  final FeedbackFlowApiClient _api;

  @override
  Future<OrganizationDto> getOrganization({required String id}) async {
    return EnvelopeGuard.data(await _api.getOrganization(id: id));
  }

  @override
  Future<UpdateResultDto> updateRoleRules({required String id, required UpdateRoleRulesRequest request}) async {
    return EnvelopeGuard.data(await _api.updateRoleRules(id: id, request: request));
  }

  @override
  Future<ListResponse<OrganizationRoleDto>> getOrganizationRoles({required String id}) async {
    return EnvelopeGuard.list(await _api.getOrganizationRoles(id: id));
  }

}
