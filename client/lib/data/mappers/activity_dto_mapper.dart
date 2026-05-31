import '../../domain/entities/activity_entity.dart';
import '../dto/dto.dart';

class ActivityDtoMapper {
  const ActivityDtoMapper._();

  static ActivityEntity toEntity(ActivityDto dto) => ActivityEntity(
    id: dto.id,
    organizationId: dto.organizationId,
    formId: dto.formId,
    submissionId: dto.submissionId,
    assignedToUserId: dto.assignedToUserId,
    title: dto.title,
    description: dto.description,
    status: dto.status.toJson(),
    dueAt: dto.dueAt,
    createdAt: dto.createdAt,
    updatedAt: dto.updatedAt,
  );

  static ActivityEntity toDomain(ActivityDto dto) => toEntity(dto);
}
