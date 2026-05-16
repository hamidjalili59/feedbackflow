import '../api/feedback_flow_api_client.dart';
import '../api/api_exceptions.dart';
import '../dto/dto.dart';

abstract class AnalyticsRepository {
  Future<DashboardAnalyticsDto> getDashboardAnalytics();
  Future<FormAnalyticsDto> getFormAnalytics({required String id});
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

}
