import 'models.dart';

class CreateUserRelationshipRequest {
  const CreateUserRelationshipRequest({
    required this.relatedUserId,
    this.relationshipType = 'parent_child',
  });

  final String relatedUserId;
  final String relationshipType;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'related_user_id': relatedUserId,
    'relationship_type': relationshipType,
  };
}

class UserFamilyRelationshipDto {
  const UserFamilyRelationshipDto({
    required this.relationship,
    required this.user,
  });

  final UserRelationshipDto relationship;
  final UserSummaryDto user;

  factory UserFamilyRelationshipDto.fromJson(Map<String, dynamic> json) {
    return UserFamilyRelationshipDto(
      relationship: UserRelationshipDto.fromJson(
        Map<String, dynamic>.from(json['relationship'] as Map),
      ),
      user: UserSummaryDto.fromJson(
        Map<String, dynamic>.from(json['user'] as Map),
      ),
    );
  }
}

class UserFamilyLinksDto {
  const UserFamilyLinksDto({required this.parents, required this.children});

  final List<UserFamilyRelationshipDto> parents;
  final List<UserFamilyRelationshipDto> children;

  factory UserFamilyLinksDto.fromJson(Map<String, dynamic> json) {
    List<UserFamilyRelationshipDto> list(Object? value) {
      if (value is! Iterable) return <UserFamilyRelationshipDto>[];
      return value
          .whereType<Map>()
          .map(
            (item) => UserFamilyRelationshipDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false);
    }

    return UserFamilyLinksDto(
      parents: list(json['parents']),
      children: list(json['children']),
    );
  }
}
