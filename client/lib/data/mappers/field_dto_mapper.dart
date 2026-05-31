import '../../domain/entities/field_entity.dart';
import '../dto/dto.dart';

class FieldDtoMapper {
  const FieldDtoMapper._();

  static FormFieldEntity toEntity(FormFieldDto dto) => FormFieldEntity(
    id: dto.id,
    formId: dto.formId,
    type: dto.type.toJson(),
    label: dto.label,
    description: dto.description,
    placeholder: dto.placeholder,
    isRequired: dto.isRequired,
    orderIndex: dto.orderIndex,
  );

  static FormFieldEntity toDomain(FormFieldDto dto) => toEntity(dto);
}
