import '../api/feedback_flow_api_client.dart';
import '../api/api_exceptions.dart';
import '../dto/dto.dart';

abstract class UsersRepository {
  Future<ListResponse<UserSummaryDto>> listUsers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    SortOrder? sortOrder,
    String? filters,
  });
  Future<UserDetailDto> createUser({required CreateUserRequest request});
  Future<UserDetailDto> getMyUser();
  Future<UserDetailDto> updateMyProfile({
    required UpdateUserProfileRequest request,
  });
  Future<UserDetailDto> getUser({required String id});
  Future<UserDetailDto> updateUser({
    required String id,
    required UpdateUserRequest request,
  });
  Future<UserFamilyLinksDto> getUserRelationships({required String id});
  Future<UserRelationshipDto> createUserRelationship({
    required String id,
    required CreateUserRelationshipRequest request,
  });
  Future<DeleteResultDto> deleteUserRelationship({
    required String id,
    required String relationshipId,
  });
  Future<ListResponse<SubordinateUserDto>> getUserSubordinates({
    required String id,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    SortOrder? sortOrder,
    String? filters,
  });
}

class DioUsersRepository implements UsersRepository {
  DioUsersRepository(this._api);

  final FeedbackFlowApiClient _api;

  @override
  Future<ListResponse<UserSummaryDto>> listUsers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    SortOrder? sortOrder,
    String? filters,
  }) async {
    return EnvelopeGuard.list(
      await _api.listUsers(
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
  Future<UserDetailDto> createUser({required CreateUserRequest request}) async {
    return EnvelopeGuard.data(await _api.createUser(request: request));
  }

  @override
  Future<UserDetailDto> getMyUser() async {
    return EnvelopeGuard.data(await _api.getMyUser());
  }

  @override
  Future<UserDetailDto> updateMyProfile({
    required UpdateUserProfileRequest request,
  }) async {
    return EnvelopeGuard.data(await _api.updateMyProfile(request: request));
  }

  @override
  Future<UserDetailDto> getUser({required String id}) async {
    return EnvelopeGuard.data(await _api.getUser(id: id));
  }

  @override
  Future<UserDetailDto> updateUser({
    required String id,
    required UpdateUserRequest request,
  }) async {
    return EnvelopeGuard.data(await _api.updateUser(id: id, request: request));
  }

  @override
  Future<UserFamilyLinksDto> getUserRelationships({required String id}) async {
    return EnvelopeGuard.data(await _api.getUserRelationships(id: id));
  }

  @override
  Future<UserRelationshipDto> createUserRelationship({
    required String id,
    required CreateUserRelationshipRequest request,
  }) async {
    return EnvelopeGuard.data(
      await _api.createUserRelationship(id: id, request: request),
    );
  }

  @override
  Future<DeleteResultDto> deleteUserRelationship({
    required String id,
    required String relationshipId,
  }) async {
    return EnvelopeGuard.data(
      await _api.deleteUserRelationship(id: id, relationshipId: relationshipId),
    );
  }

  @override
  Future<ListResponse<SubordinateUserDto>> getUserSubordinates({
    required String id,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    SortOrder? sortOrder,
    String? filters,
  }) async {
    return EnvelopeGuard.list(
      await _api.getUserSubordinates(
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
}
