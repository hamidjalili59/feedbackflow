class ActivityEntity {
  const ActivityEntity({
    required this.id,
    required this.organizationId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.formId,
    this.submissionId,
    this.assignedToUserId,
    this.description,
    this.dueAt,
  });

  final String id;
  final String organizationId;
  final String? formId;
  final String? submissionId;
  final String? assignedToUserId;
  final String title;
  final String? description;
  final String status;
  final DateTime? dueAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
