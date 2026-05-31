import 'field_entity.dart';

class FormSummaryEntity {
  const FormSummaryEntity({
    required this.id,
    required this.organizationId,
    required this.creatorId,
    required this.title,
    required this.status,
    required this.visibilityMode,
    required this.publishMode,
    required this.scoringMode,
    required this.submissionsCount,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.publicToken,
  });

  final String id;
  final String organizationId;
  final String creatorId;
  final String title;
  final String? description;
  final String status;
  final String visibilityMode;
  final String publishMode;
  final String scoringMode;
  final int submissionsCount;
  final String? publicToken;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class FormDetailEntity {
  const FormDetailEntity({
    required this.id,
    required this.organizationId,
    required this.creatorId,
    required this.title,
    required this.status,
    required this.visibilityMode,
    required this.publishMode,
    required this.scoringMode,
    required this.fields,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.publicToken,
    this.approvedAt,
    this.publishedAt,
    this.closedAt,
  });

  final String id;
  final String organizationId;
  final String creatorId;
  final String title;
  final String? description;
  final String status;
  final String visibilityMode;
  final String publishMode;
  final String scoringMode;
  final List<FormFieldEntity> fields;
  final String? publicToken;
  final DateTime? approvedAt;
  final DateTime? publishedAt;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class PublicFormEntity {
  const PublicFormEntity({
    required this.id,
    required this.title,
    required this.fields,
    this.description,
    this.startAt,
    this.endAt,
  });

  final String id;
  final String title;
  final String? description;
  final List<FormFieldEntity> fields;
  final DateTime? startAt;
  final DateTime? endAt;
}
