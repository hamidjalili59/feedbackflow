import '../api/feedback_flow_api_client.dart';
import '../api/api_exceptions.dart';
import '../dto/dto.dart';

abstract class AuditRepository {
  Future<ListResponse<AuditLogDto>> listAuditLogs({int page = 1, int pageSize = 20, String? search, String? sortBy, SortOrder? sortOrder, String? filters});
}

class DioAuditRepository implements AuditRepository {
  DioAuditRepository(this._api);

  final FeedbackFlowApiClient _api;

  @override
  Future<ListResponse<AuditLogDto>> listAuditLogs({int page = 1, int pageSize = 20, String? search, String? sortBy, SortOrder? sortOrder, String? filters}) async {
    return EnvelopeGuard.list(await _api.listAuditLogs(page: page, pageSize: pageSize, search: search, sortBy: sortBy, sortOrder: sortOrder, filters: filters));
  }

}
