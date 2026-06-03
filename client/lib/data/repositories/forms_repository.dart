import '../api/feedback_flow_api_client.dart';
import '../api/api_exceptions.dart';
import '../dto/dto.dart';

abstract class FormsRepository {
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
  });
  Future<List<String>> listFormTags({String? search});
  Future<FormDetailDto> createForm({required CreateFormRequest request});
  Future<FormDetailDto> getForm({required String id});
  Future<FormAnswerAccessDto2> getFormAnswerAccess({required String id});
  Future<DeleteResultDto> deleteForm({required String id});
  Future<FormDetailDto> updateForm({
    required String id,
    required UpdateFormRequest request,
  });
  Future<FormDetailDto> approveForm({
    required String id,
    required ApproveFormRequest request,
  });
  Future<FormDetailDto> archiveForm({
    required String id,
    required ArchiveFormRequest request,
  });
  Future<FormDetailDto> closeForm({
    required String id,
    required CloseFormRequest request,
  });
  Future<FormDetailDto> duplicateForm({
    required String id,
    required DuplicateFormRequest request,
  });
  Future<FormAccessCodesResponse> listFormAccessCodes({required String id});
  Future<FormAccessCodesResponse> setFormAccessCodes({
    required String id,
    required SetFormAccessCodesRequest request,
  });
  Future<FormDetailDto> updatePublicProtection({
    required String id,
    required UpdatePublicProtectionRequest request,
  });
  Future<FormDetailDto> publishForm({
    required String id,
    required PublishFormRequest request,
  });
  Future<FormDetailDto> rejectForm({
    required String id,
    required RejectFormRequest request,
  });
  Future<FormDetailDto> submitFormForApproval({
    required String id,
    required SubmitForApprovalRequest request,
  });
  Future<FormDetailDto> updateFormVisibility({
    required String id,
    required UpdateFormVisibilityRequest request,
  });
}

class DioFormsRepository implements FormsRepository {
  DioFormsRepository(this._api);

  final FeedbackFlowApiClient _api;

  @override
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
    return EnvelopeGuard.list(
      await _api.listForms(
        page: page,
        pageSize: pageSize,
        search: search,
        sortBy: sortBy,
        sortOrder: sortOrder,
        filters: filters,
        category: category,
        tags: tags,
        status: status,
      ),
    );
  }

  @override
  Future<List<String>> listFormTags({String? search}) async {
    return EnvelopeGuard.data(await _api.listFormTags(search: search));
  }

  @override
  Future<FormDetailDto> createForm({required CreateFormRequest request}) async {
    return EnvelopeGuard.data(await _api.createForm(request: request));
  }

  @override
  Future<FormDetailDto> getForm({required String id}) async {
    return EnvelopeGuard.data(await _api.getForm(id: id));
  }

  @override
  Future<FormAnswerAccessDto2> getFormAnswerAccess({required String id}) async {
    return EnvelopeGuard.data(await _api.getFormAnswerAccess(id: id));
  }

  @override
  Future<DeleteResultDto> deleteForm({required String id}) async {
    return EnvelopeGuard.data(await _api.deleteForm(id: id));
  }

  @override
  Future<FormDetailDto> updateForm({
    required String id,
    required UpdateFormRequest request,
  }) async {
    return EnvelopeGuard.data(await _api.updateForm(id: id, request: request));
  }

  @override
  Future<FormDetailDto> approveForm({
    required String id,
    required ApproveFormRequest request,
  }) async {
    return EnvelopeGuard.data(await _api.approveForm(id: id, request: request));
  }

  @override
  Future<FormDetailDto> archiveForm({
    required String id,
    required ArchiveFormRequest request,
  }) async {
    return EnvelopeGuard.data(await _api.archiveForm(id: id, request: request));
  }

  @override
  Future<FormDetailDto> closeForm({
    required String id,
    required CloseFormRequest request,
  }) async {
    return EnvelopeGuard.data(await _api.closeForm(id: id, request: request));
  }

  @override
  Future<FormDetailDto> duplicateForm({
    required String id,
    required DuplicateFormRequest request,
  }) async {
    return EnvelopeGuard.data(
      await _api.duplicateForm(id: id, request: request),
    );
  }

  @override
  Future<FormAccessCodesResponse> listFormAccessCodes({
    required String id,
  }) async {
    return EnvelopeGuard.data(await _api.listFormAccessCodes(id: id));
  }

  @override
  Future<FormAccessCodesResponse> setFormAccessCodes({
    required String id,
    required SetFormAccessCodesRequest request,
  }) async {
    return EnvelopeGuard.data(
      await _api.setFormAccessCodes(id: id, request: request),
    );
  }

  @override
  Future<FormDetailDto> updatePublicProtection({
    required String id,
    required UpdatePublicProtectionRequest request,
  }) async {
    return EnvelopeGuard.data(
      await _api.updatePublicProtection(id: id, request: request),
    );
  }

  @override
  Future<FormDetailDto> publishForm({
    required String id,
    required PublishFormRequest request,
  }) async {
    return EnvelopeGuard.data(await _api.publishForm(id: id, request: request));
  }

  @override
  Future<FormDetailDto> rejectForm({
    required String id,
    required RejectFormRequest request,
  }) async {
    return EnvelopeGuard.data(await _api.rejectForm(id: id, request: request));
  }

  @override
  Future<FormDetailDto> submitFormForApproval({
    required String id,
    required SubmitForApprovalRequest request,
  }) async {
    return EnvelopeGuard.data(
      await _api.submitFormForApproval(id: id, request: request),
    );
  }

  @override
  Future<FormDetailDto> updateFormVisibility({
    required String id,
    required UpdateFormVisibilityRequest request,
  }) async {
    return EnvelopeGuard.data(
      await _api.updateFormVisibility(id: id, request: request),
    );
  }
}
