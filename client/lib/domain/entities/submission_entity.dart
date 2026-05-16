class AnswerEntity {
  const AnswerEntity({
    required this.fieldId,
    required this.value,
    this.metadata,
  });

  final String fieldId;
  final Object? value;
  final Object? metadata;
}

class SubmissionEntity {
  const SubmissionEntity({
    required this.id,
    required this.formId,
    required this.anonymous,
    required this.valid,
    required this.answers,
    required this.submittedAt,
    required this.updatedAt,
    this.respondentUserId,
    this.scorePercentage,
  });

  final String id;
  final String formId;
  final String? respondentUserId;
  final bool anonymous;
  final bool valid;
  final List<AnswerEntity> answers;
  final double? scorePercentage;
  final DateTime submittedAt;
  final DateTime updatedAt;
}
