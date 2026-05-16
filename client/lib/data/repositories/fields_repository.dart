import '../api/feedback_flow_api_client.dart';
import '../api/api_exceptions.dart';
import '../dto/dto.dart';

abstract class FieldsRepository {
  Future<FormFieldDto> createFormField({required String id, required CreateFormFieldRequest request});
  Future<DeleteResultDto> deleteFormField({required String id, required String fieldId});
  Future<FormFieldDto> updateFormField({required String id, required String fieldId, required UpdateFormFieldRequest request});
}

class DioFieldsRepository implements FieldsRepository {
  DioFieldsRepository(this._api);

  final FeedbackFlowApiClient _api;

  @override
  Future<FormFieldDto> createFormField({required String id, required CreateFormFieldRequest request}) async {
    return EnvelopeGuard.data(await _api.createFormField(id: id, request: request));
  }

  @override
  Future<DeleteResultDto> deleteFormField({required String id, required String fieldId}) async {
    return EnvelopeGuard.data(await _api.deleteFormField(id: id, fieldId: fieldId));
  }

  @override
  Future<FormFieldDto> updateFormField({required String id, required String fieldId, required UpdateFormFieldRequest request}) async {
    return EnvelopeGuard.data(await _api.updateFormField(id: id, fieldId: fieldId, request: request));
  }

}
