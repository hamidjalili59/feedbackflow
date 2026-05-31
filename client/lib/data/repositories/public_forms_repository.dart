import '../api/feedback_flow_api_client.dart';
import '../api/api_exceptions.dart';
import '../dto/dto.dart';

abstract class PublicFormsRepository {
  Future<PublicFormDto> getPublicForm({required String publicToken});
  Future<PublicSubmissionResponse> submitPublicForm({
    required String publicToken,
    required PublicSubmissionRequest request,
  });
  Future<ValidatePublicFormAccessResponse> validatePublicFormAccess({
    required String publicToken,
    required ValidatePublicFormAccessRequest request,
  });
}

class DioPublicFormsRepository implements PublicFormsRepository {
  DioPublicFormsRepository(this._api);

  final FeedbackFlowApiClient _api;

  @override
  Future<PublicFormDto> getPublicForm({required String publicToken}) async {
    return EnvelopeGuard.data(
      await _api.getPublicForm(publicToken: publicToken),
    );
  }

  @override
  Future<PublicSubmissionResponse> submitPublicForm({
    required String publicToken,
    required PublicSubmissionRequest request,
  }) async {
    return EnvelopeGuard.data(
      await _api.submitPublicForm(publicToken: publicToken, request: request),
    );
  }

  @override
  Future<ValidatePublicFormAccessResponse> validatePublicFormAccess({
    required String publicToken,
    required ValidatePublicFormAccessRequest request,
  }) async {
    return EnvelopeGuard.data(
      await _api.validatePublicFormAccess(
        publicToken: publicToken,
        request: request,
      ),
    );
  }
}
