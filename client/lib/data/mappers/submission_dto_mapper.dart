import '../../domain/entities/submission_entity.dart';
import '../dto/dto.dart';

class SubmissionDtoMapper {
  const SubmissionDtoMapper._();

  static AnswerEntity answerToEntity(AnswerDto dto) => AnswerEntity(
    fieldId: dto.fieldId,
    value: dto.value,
    metadata: dto.metadata,
  );

  static SubmissionEntity detailToEntity(SubmissionDetailDto dto) =>
      SubmissionEntity(
        id: dto.id,
        formId: dto.formId,
        respondentUserId: dto.respondentUserId,
        anonymous: dto.anonymous,
        valid: dto.valid,
        answers: dto.answers.map(answerToEntity).toList(growable: false),
        scorePercentage: dto.score.percentageScore,
        submittedAt: dto.submittedAt,
        updatedAt: dto.updatedAt,
      );

  static SubmissionEntity detailToDomain(SubmissionDetailDto dto) =>
      detailToEntity(dto);

  static SubmissionEntity summaryToEntity(SubmissionSummaryDto dto) =>
      SubmissionEntity(
        id: dto.id,
        formId: dto.formId,
        respondentUserId: dto.respondentUserId,
        anonymous: dto.anonymous,
        valid: dto.valid,
        answers: const [],
        scorePercentage: dto.score.percentageScore,
        submittedAt: dto.submittedAt,
        updatedAt: dto.submittedAt,
      );

  static SubmissionEntity summaryToDomain(SubmissionSummaryDto dto) =>
      summaryToEntity(dto);
}
