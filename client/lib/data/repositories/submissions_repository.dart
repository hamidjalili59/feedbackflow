import '../api/feedback_flow_api_client.dart';
import '../api/api_exceptions.dart';
import '../dto/dto.dart';

abstract class SubmissionsRepository {
  Future<ListResponse<SubmissionSummaryDto>> listSubmissions({
    required String id,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    SortOrder? sortOrder,
    String? filters,
  });
  Future<Map<String, dynamic>?> getAnswerDraft({required String id, String? childId});
  Future<void> saveAnswerDraft({required String id, required Map<String, Object?> answers, required int currentStep, required int totalSteps, String? childId});
  Future<void> deleteAnswerDraft({required String id, String? childId});
  Future<SubmissionDetailDto> createSubmission({
    required String id,
    required CreateSubmissionRequest request,
  });
  Future<SubmissionDetailDto> getSubmission({required String id});
  Future<DeleteResultDto> deleteSubmission({required String id});
  Future<SubmissionDetailDto> updateSubmission({
    required String id,
    required UpdateSubmissionRequest request,
  });
}

class DioSubmissionsRepository implements SubmissionsRepository {
  DioSubmissionsRepository(this._api);

  final FeedbackFlowApiClient _api;


  @override
  Future<Map<String, dynamic>?> getAnswerDraft({required String id, String? childId}) async {
    return EnvelopeGuard.data(await _api.getAnswerDraft(id: id, childId: childId));
  }

  @override
  Future<void> saveAnswerDraft({required String id, required Map<String, Object?> answers, required int currentStep, required int totalSteps, String? childId}) async {
    EnvelopeGuard.data(await _api.saveAnswerDraft(id: id, request: <String, dynamic>{
      'answers': answers, 'current_step': currentStep, 'total_steps': totalSteps, 'child_id': childId,
    }));
  }

  @override
  Future<void> deleteAnswerDraft({required String id, String? childId}) async {
    EnvelopeGuard.data(await _api.deleteAnswerDraft(id: id, childId: childId));
  }
  @override
  Future<ListResponse<SubmissionSummaryDto>> listSubmissions({
    required String id,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    SortOrder? sortOrder,
    String? filters,
  }) async {
    return EnvelopeGuard.list(
      await _api.listSubmissions(
        id: id,
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
  Future<SubmissionDetailDto> createSubmission({
    required String id,
    required CreateSubmissionRequest request,
  }) async {
    return EnvelopeGuard.data(
      await _api.createSubmission(id: id, request: request),
    );
  }

  @override
  Future<SubmissionDetailDto> getSubmission({required String id}) async {
    return EnvelopeGuard.data(await _api.getSubmission(id: id));
  }

  @override
  Future<DeleteResultDto> deleteSubmission({required String id}) async {
    return EnvelopeGuard.data(await _api.deleteSubmission(id: id));
  }

  @override
  Future<SubmissionDetailDto> updateSubmission({
    required String id,
    required UpdateSubmissionRequest request,
  }) async {
    return EnvelopeGuard.data(
      await _api.updateSubmission(id: id, request: request),
    );
  }
}
