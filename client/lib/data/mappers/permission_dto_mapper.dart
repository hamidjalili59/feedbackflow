import '../../domain/entities/permission_entity.dart';
import '../dto/dto.dart';

class PermissionDtoMapper {
  const PermissionDtoMapper._();

  static EffectivePermissionEntity toEntity(EffectivePermissionsDto dto) => EffectivePermissionEntity(
        userId: dto.userId,
        organizationId: dto.organizationId,
        role: dto.role.toJson(),
        actions: dto.actions.map((value) => value.toJson()).toList(growable: false),
        resources: dto.resources.map((value) => value.toJson()).toList(growable: false),
        fieldTypes: dto.fieldTypes.map((value) => value.toJson()).toList(growable: false),
        canManagePermissions: dto.canManagePermissions,
        canManageScoring: dto.canManageScoring,
        canManagePublicProtection: dto.canManagePublicProtection,
      );

  static EffectivePermissionEntity toDomain(EffectivePermissionsDto dto) => toEntity(dto);
}
