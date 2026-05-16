import '../api/feedback_flow_api_client.dart';
import '../api/api_exceptions.dart';
import '../dto/dto.dart';

abstract class AuthRepository {
  Future<LoginResponse> login({required LoginRequest request});
  Future<LogoutResponse> logout({required LogoutRequest request});
  Future<MeResponse> getMe();
  Future<RefreshTokenResponse> refreshToken({required RefreshTokenRequest request});
  Future<RegisterResponse> register({required RegisterRequest request});
}

class DioAuthRepository implements AuthRepository {
  DioAuthRepository(this._api);

  final FeedbackFlowApiClient _api;

  @override
  Future<LoginResponse> login({required LoginRequest request}) async {
    return EnvelopeGuard.data(await _api.login(request: request));
  }

  @override
  Future<LogoutResponse> logout({required LogoutRequest request}) async {
    return EnvelopeGuard.data(await _api.logout(request: request));
  }

  @override
  Future<MeResponse> getMe() async {
    return EnvelopeGuard.data(await _api.getMe());
  }

  @override
  Future<RefreshTokenResponse> refreshToken({required RefreshTokenRequest request}) async {
    return EnvelopeGuard.data(await _api.refreshToken(request: request));
  }

  @override
  Future<RegisterResponse> register({required RegisterRequest request}) async {
    return EnvelopeGuard.data(await _api.register(request: request));
  }

}
