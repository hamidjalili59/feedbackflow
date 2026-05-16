import '../../domain/entities/form_entity.dart';
import '../dto/dto.dart';
import 'field_dto_mapper.dart';

class FormDtoMapper {
  const FormDtoMapper._();

  static FormSummaryEntity summaryToEntity(FormSummaryDto dto) => FormSummaryEntity(
        id: dto.id,
        organizationId: dto.organizationId,
        creatorId: dto.creatorId,
        title: dto.title,
        description: dto.description,
        status: dto.status.toJson(),
        visibilityMode: dto.visibilityMode.toJson(),
        publishMode: dto.publishMode.toJson(),
        scoringMode: dto.scoringMode.toJson(),
        submissionsCount: dto.submissionsCount,
        publicToken: dto.publicToken,
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
      );

  static FormSummaryEntity summaryToDomain(FormSummaryDto dto) => summaryToEntity(dto);

  static FormDetailEntity detailToEntity(FormDetailDto dto) => FormDetailEntity(
        id: dto.id,
        organizationId: dto.organizationId,
        creatorId: dto.creatorId,
        title: dto.title,
        description: dto.description,
        status: dto.status.toJson(),
        visibilityMode: dto.visibilityMode.toJson(),
        publishMode: dto.publishMode.toJson(),
        scoringMode: dto.scoringMode.toJson(),
        fields: dto.fields.map(FieldDtoMapper.toEntity).toList(growable: false),
        publicToken: dto.publicToken,
        approvedAt: dto.approvedAt,
        publishedAt: dto.publishedAt,
        closedAt: dto.closedAt,
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
      );

  static FormDetailEntity detailToDomain(FormDetailDto dto) => detailToEntity(dto);

  static PublicFormEntity publicToEntity(PublicFormDto dto) => PublicFormEntity(
        id: dto.id,
        title: dto.title,
        description: dto.description,
        fields: dto.fields.map(FieldDtoMapper.toEntity).toList(growable: false),
        startAt: dto.startAt,
        endAt: dto.endAt,
      );

  static PublicFormEntity publicToDomain(PublicFormDto dto) => publicToEntity(dto);
}
