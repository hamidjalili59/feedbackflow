import '../../domain/entities/user_entity.dart';
import '../dto/dto.dart';

class UserDtoMapper {
  const UserDtoMapper._();

  static UserEntity detailToDomain(UserDetailDto dto) => UserEntity(
        id: dto.id,
        organizationId: dto.organizationId,
        phone: dto.phone,
        email: dto.email,
        displayName: dto.displayName,
        role: dto.primaryRole.toJson(),
        status: dto.status,
      );

  static UserEntity summaryToDomain(UserSummaryDto dto) => UserEntity(
        id: dto.id,
        organizationId: dto.organizationId,
        phone: dto.phone,
        email: dto.email,
        displayName: dto.displayName,
        role: dto.primaryRole.toJson(),
        status: dto.status,
      );
}
