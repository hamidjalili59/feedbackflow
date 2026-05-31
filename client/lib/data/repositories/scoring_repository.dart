import '../api/feedback_flow_api_client.dart';
import '../api/api_exceptions.dart';
import '../dto/dto.dart';

abstract class ScoringRepository {
  Future<ListResponse<ScoreTemplateDto>> listScoreTemplates({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    SortOrder? sortOrder,
    String? filters,
  });
  Future<ScoreTemplateDto> createScoreTemplate({
    required CreateScoreTemplateRequest request,
  });
  Future<ScoreTemplateDto> getScoreTemplate({required String id});
  Future<DeleteResultDto> deleteScoreTemplate({required String id});
  Future<ScoreTemplateDto> updateScoreTemplate({
    required String id,
    required UpdateScoreTemplateRequest request,
  });
  Future<ScoreBreakdownDto> getSubmissionScoreBreakdown({required String id});
}

class DioScoringRepository implements ScoringRepository {
  DioScoringRepository(this._api);

  final FeedbackFlowApiClient _api;

  @override
  Future<ListResponse<ScoreTemplateDto>> listScoreTemplates({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    SortOrder? sortOrder,
    String? filters,
  }) async {
    return EnvelopeGuard.list(
      await _api.listScoreTemplates(
        page: page,
        pageSize: pageSize,
        search: search,
        sortBy: sortBy,
        sortOrder: sortOrder,
        filters: filters,
      ),
    );
  }

  @override
  Future<ScoreTemplateDto> createScoreTemplate({
    required CreateScoreTemplateRequest request,
  }) async {
    return EnvelopeGuard.data(await _api.createScoreTemplate(request: request));
  }

  @override
  Future<ScoreTemplateDto> getScoreTemplate({required String id}) async {
    return EnvelopeGuard.data(await _api.getScoreTemplate(id: id));
  }

  @override
  Future<DeleteResultDto> deleteScoreTemplate({required String id}) async {
    return EnvelopeGuard.data(await _api.deleteScoreTemplate(id: id));
  }

  @override
  Future<ScoreTemplateDto> updateScoreTemplate({
    required String id,
    required UpdateScoreTemplateRequest request,
  }) async {
    return EnvelopeGuard.data(
      await _api.updateScoreTemplate(id: id, request: request),
    );
  }

  @override
  Future<ScoreBreakdownDto> getSubmissionScoreBreakdown({
    required String id,
  }) async {
    return EnvelopeGuard.data(await _api.getSubmissionScoreBreakdown(id: id));
  }
}
