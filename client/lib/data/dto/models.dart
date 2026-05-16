// GENERATED FROM openapi.json. Do not edit by hand.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
abstract class ActivityDto with _$ActivityDto {
  @JsonSerializable(explicitToJson: true)
  const factory ActivityDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'organization_id') required String organizationId,
    @JsonKey(name: 'form_id') String? formId,
    @JsonKey(name: 'submission_id') String? submissionId,
    @JsonKey(name: 'assigned_to_user_id') String? assignedToUserId,
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'description') String? description,
    @ActivityStatusJsonConverter()
    @JsonKey(name: 'status')
    required ActivityStatus status,
    @JsonKey(name: 'due_at') DateTime? dueAt,
    @JsonKey(name: 'metadata') Object? metadata,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _ActivityDto;

  factory ActivityDto.fromJson(Map<String, dynamic> json) =>
      _$ActivityDtoFromJson(json);
}

@freezed
abstract class ActivityRuleDto with _$ActivityRuleDto {
  @JsonSerializable(explicitToJson: true)
  const factory ActivityRuleDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'form_id') required String formId,
    @ActivityTriggerTypeJsonConverter()
    @JsonKey(name: 'trigger_type')
    required ActivityTriggerType triggerType,
    @JsonKey(name: 'condition') required Object? condition,
    @ActivityActionTypeJsonConverter()
    @JsonKey(name: 'action_type')
    required ActivityActionType actionType,
    @JsonKey(name: 'action_config') required Object? actionConfig,
    @JsonKey(name: 'enabled') required bool enabled,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _ActivityRuleDto;

  factory ActivityRuleDto.fromJson(Map<String, dynamic> json) =>
      _$ActivityRuleDtoFromJson(json);
}

@freezed
abstract class ActivitySummaryDto with _$ActivitySummaryDto {
  @JsonSerializable(explicitToJson: true)
  const factory ActivitySummaryDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'form_id') String? formId,
    @JsonKey(name: 'title') required String title,
    @ActivityStatusJsonConverter()
    @JsonKey(name: 'status')
    required ActivityStatus status,
    @JsonKey(name: 'assigned_to_user_id') String? assignedToUserId,
    @JsonKey(name: 'due_at') DateTime? dueAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ActivitySummaryDto;

  factory ActivitySummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ActivitySummaryDtoFromJson(json);
}

@freezed
abstract class AnswerDto with _$AnswerDto {
  @JsonSerializable(explicitToJson: true)
  const factory AnswerDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'submission_id') required String submissionId,
    @JsonKey(name: 'field_id') required String fieldId,
    @JsonKey(name: 'value') required Object? value,
    @JsonKey(name: 'metadata') Object? metadata,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _AnswerDto;

  factory AnswerDto.fromJson(Map<String, dynamic> json) =>
      _$AnswerDtoFromJson(json);
}

@freezed
abstract class AnswerInputDto with _$AnswerInputDto {
  @JsonSerializable(explicitToJson: true)
  const factory AnswerInputDto({
    @JsonKey(name: 'field_id') required String fieldId,
    @JsonKey(name: 'value') required Object? value,
    @JsonKey(name: 'metadata') Object? metadata,
  }) = _AnswerInputDto;

  factory AnswerInputDto.fromJson(Map<String, dynamic> json) =>
      _$AnswerInputDtoFromJson(json);
}

@freezed
abstract class ApprovalRuleDto with _$ApprovalRuleDto {
  @JsonSerializable(explicitToJson: true)
  const factory ApprovalRuleDto({
    @UserRoleJsonConverter() @JsonKey(name: 'role') required UserRole role,
    @JsonKey(name: 'approval_required') required bool approvalRequired,
    @JsonKey(name: 'two_step_required') required bool twoStepRequired,
    @UserRoleListJsonConverter()
    @JsonKey(name: 'approver_roles')
    required List<UserRole> approverRoles,
  }) = _ApprovalRuleDto;

  factory ApprovalRuleDto.fromJson(Map<String, dynamic> json) =>
      _$ApprovalRuleDtoFromJson(json);
}

@freezed
abstract class ApproveFormRequest with _$ApproveFormRequest {
  @JsonSerializable(explicitToJson: true)
  const factory ApproveFormRequest({
    @JsonKey(name: 'comment') String? comment,
    @JsonKey(name: 'publish_after_approval') bool? publishAfterApproval,
  }) = _ApproveFormRequest;

  factory ApproveFormRequest.fromJson(Map<String, dynamic> json) =>
      _$ApproveFormRequestFromJson(json);
}

@freezed
abstract class ArchiveFormRequest with _$ArchiveFormRequest {
  @JsonSerializable(explicitToJson: true)
  const factory ArchiveFormRequest({@JsonKey(name: 'reason') String? reason}) =
      _ArchiveFormRequest;

  factory ArchiveFormRequest.fromJson(Map<String, dynamic> json) =>
      _$ArchiveFormRequestFromJson(json);
}

@freezed
abstract class AudienceRuleDto with _$AudienceRuleDto {
  @JsonSerializable(explicitToJson: true)
  const factory AudienceRuleDto({
    @FormAudienceTypeJsonConverter()
    @JsonKey(name: 'audience_type')
    required FormAudienceType audienceType,
    @JsonKey(name: 'id') String? id,
    @NullableUserRoleJsonConverter() @JsonKey(name: 'role') UserRole? role,
    @JsonKey(name: 'label') String? label,
  }) = _AudienceRuleDto;

  factory AudienceRuleDto.fromJson(Map<String, dynamic> json) =>
      _$AudienceRuleDtoFromJson(json);
}

@freezed
abstract class AuditLogDto with _$AuditLogDto {
  @JsonSerializable(explicitToJson: true)
  const factory AuditLogDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'organization_id') String? organizationId,
    @JsonKey(name: 'actor_user_id') String? actorUserId,
    @AuditActionJsonConverter()
    @JsonKey(name: 'action')
    required AuditAction action,
    @JsonKey(name: 'resource_type') required String resourceType,
    @JsonKey(name: 'resource_id') String? resourceId,
    @JsonKey(name: 'ip_address') String? ipAddress,
    @JsonKey(name: 'user_agent') String? userAgent,
    @JsonKey(name: 'details') required Object? details,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _AuditLogDto;

  factory AuditLogDto.fromJson(Map<String, dynamic> json) =>
      _$AuditLogDtoFromJson(json);
}

@freezed
abstract class AuditLogSummaryDto with _$AuditLogSummaryDto {
  @JsonSerializable(explicitToJson: true)
  const factory AuditLogSummaryDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'actor_user_id') String? actorUserId,
    @AuditActionJsonConverter()
    @JsonKey(name: 'action')
    required AuditAction action,
    @JsonKey(name: 'resource_type') required String resourceType,
    @JsonKey(name: 'resource_id') String? resourceId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _AuditLogSummaryDto;

  factory AuditLogSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$AuditLogSummaryDtoFromJson(json);
}

@freezed
abstract class CloseFormRequest with _$CloseFormRequest {
  @JsonSerializable(explicitToJson: true)
  const factory CloseFormRequest({@JsonKey(name: 'reason') String? reason}) =
      _CloseFormRequest;

  factory CloseFormRequest.fromJson(Map<String, dynamic> json) =>
      _$CloseFormRequestFromJson(json);
}

@freezed
abstract class CompletionRateAnalyticsDto with _$CompletionRateAnalyticsDto {
  @JsonSerializable(explicitToJson: true)
  const factory CompletionRateAnalyticsDto({
    @JsonKey(name: 'started') required int started,
    @JsonKey(name: 'completed') required int completed,
    @JsonKey(name: 'completion_rate') required double completionRate,
  }) = _CompletionRateAnalyticsDto;

  factory CompletionRateAnalyticsDto.fromJson(Map<String, dynamic> json) =>
      _$CompletionRateAnalyticsDtoFromJson(json);
}

@freezed
abstract class AnalyticsBucketDto with _$AnalyticsBucketDto {
  @JsonSerializable(explicitToJson: true)
  const factory AnalyticsBucketDto({
    @JsonKey(name: 'key') required String key,
    @JsonKey(name: 'label') required String label,
    @JsonKey(name: 'count') required int count,
    @JsonKey(name: 'percentage') required double percentage,
  }) = _AnalyticsBucketDto;

  factory AnalyticsBucketDto.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsBucketDtoFromJson(json);
}

@freezed
abstract class AnalyticsTimeseriesPointDto
    with _$AnalyticsTimeseriesPointDto {
  @JsonSerializable(explicitToJson: true)
  const factory AnalyticsTimeseriesPointDto({
    @JsonKey(name: 'date') required String date,
    @JsonKey(name: 'count') required int count,
  }) = _AnalyticsTimeseriesPointDto;

  factory AnalyticsTimeseriesPointDto.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsTimeseriesPointDtoFromJson(json);
}

@freezed
abstract class DashboardTopFormDto with _$DashboardTopFormDto {
  @JsonSerializable(explicitToJson: true)
  const factory DashboardTopFormDto({
    @JsonKey(name: 'form_id') required String formId,
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'submissions') required int submissions,
  }) = _DashboardTopFormDto;

  factory DashboardTopFormDto.fromJson(Map<String, dynamic> json) =>
      _$DashboardTopFormDtoFromJson(json);
}

@freezed
abstract class DashboardAnalyticsDto with _$DashboardAnalyticsDto {
  @JsonSerializable(explicitToJson: true)
  const factory DashboardAnalyticsDto({
    @JsonKey(name: 'total_forms') required int totalForms,
    @JsonKey(name: 'published_forms') required int publishedForms,
    @JsonKey(name: 'total_users') required int totalUsers,
    @JsonKey(name: 'total_submissions') required int totalSubmissions,
    @JsonKey(name: 'valid_submissions') required int validSubmissions,
    @JsonKey(name: 'participation_rate') required double participationRate,
    @JsonKey(name: 'today_submissions') required int todaySubmissions,
    @JsonKey(name: 'week_submissions') required int weekSubmissions,
    @JsonKey(name: 'month_submissions') required int monthSubmissions,
    @JsonKey(name: 'by_day') required List<AnalyticsTimeseriesPointDto> byDay,
    @JsonKey(name: 'gender_distribution')
    required List<AnalyticsBucketDto> genderDistribution,
    @JsonKey(name: 'user_role_distribution')
    required List<AnalyticsBucketDto> userRoleDistribution,
    @JsonKey(name: 'respondent_mode_distribution')
    required List<AnalyticsBucketDto> respondentModeDistribution,
    @JsonKey(name: 'access_code_distribution')
    required List<AnalyticsBucketDto> accessCodeDistribution,
    @JsonKey(name: 'top_forms') required List<DashboardTopFormDto> topForms,
  }) = _DashboardAnalyticsDto;

  factory DashboardAnalyticsDto.fromJson(Map<String, dynamic> json) =>
      _$DashboardAnalyticsDtoFromJson(json);
}

@freezed
abstract class ConditionalLogicRuleDto with _$ConditionalLogicRuleDto {
  @JsonSerializable(explicitToJson: true)
  const factory ConditionalLogicRuleDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'mode') required String mode,
    @JsonKey(name: 'action') required String action,
    @JsonKey(name: 'conditions')
    required List<FieldVisibilityConditionDto> conditions,
    @JsonKey(name: 'target_field_ids') List<String>? targetFieldIds,
    @JsonKey(name: 'target_page_index') int? targetPageIndex,
  }) = _ConditionalLogicRuleDto;

  factory ConditionalLogicRuleDto.fromJson(Map<String, dynamic> json) =>
      _$ConditionalLogicRuleDtoFromJson(json);
}

@freezed
abstract class CreateActivityRuleRequest with _$CreateActivityRuleRequest {
  @JsonSerializable(explicitToJson: true)
  const factory CreateActivityRuleRequest({
    @ActivityTriggerTypeJsonConverter()
    @JsonKey(name: 'trigger_type')
    required ActivityTriggerType triggerType,
    @JsonKey(name: 'condition') required Object? condition,
    @ActivityActionTypeJsonConverter()
    @JsonKey(name: 'action_type')
    required ActivityActionType actionType,
    @JsonKey(name: 'action_config') required Object? actionConfig,
    @JsonKey(name: 'enabled') required bool enabled,
  }) = _CreateActivityRuleRequest;

  factory CreateActivityRuleRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateActivityRuleRequestFromJson(json);
}

@freezed
abstract class CreateFormFieldRequest with _$CreateFormFieldRequest {
  @JsonSerializable(explicitToJson: true)
  const factory CreateFormFieldRequest({
    @FieldTypeJsonConverter() @JsonKey(name: 'type') required FieldType type,
    @JsonKey(name: 'label') required String label,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'placeholder') String? placeholder,
    @JsonKey(name: 'required') required bool isRequired,
    @JsonKey(name: 'order_index') required int orderIndex,
    @JsonKey(name: 'config') FieldConfigDto? config,
    @JsonKey(name: 'validation') FieldValidationDto? validation,
    @JsonKey(name: 'visibility_conditions')
    List<ConditionalLogicRuleDto>? visibilityConditions,
    @JsonKey(name: 'scoring_config') FieldScoringConfigDto? scoringConfig,
    @JsonKey(name: 'permissions') FieldPermissionConfigDto? permissions,
  }) = _CreateFormFieldRequest;

  factory CreateFormFieldRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateFormFieldRequestFromJson(json);
}

@freezed
abstract class CreateFormRequest with _$CreateFormRequest {
  @JsonSerializable(explicitToJson: true)
  const factory CreateFormRequest({
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'category') String? category,
    @JsonKey(name: 'tags') List<String>? tags,
    @JsonKey(name: 'settings') FormSettingsDto? settings,
    @JsonKey(name: 'visibility') FormVisibilityDto? visibility,
    @NullableScoringModeJsonConverter()
    @JsonKey(name: 'scoring_mode')
    ScoringMode? scoringMode,
    @JsonKey(name: 'scoring_config') Object? scoringConfig,
  }) = _CreateFormRequest;

  factory CreateFormRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateFormRequestFromJson(json);
}

@freezed
abstract class CreateUserRequest with _$CreateUserRequest {
  @JsonSerializable(explicitToJson: true)
  const factory CreateUserRequest({
    @JsonKey(name: 'organization_id') String? organizationId,
    @JsonKey(name: 'phone') required String phone,
    @JsonKey(name: 'email') String? email,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'gender') String? gender,
    @JsonKey(name: 'password') required String password,
    @UserRoleJsonConverter()
    @JsonKey(name: 'primary_role')
    required UserRole primaryRole,
    @JsonKey(name: 'profile') UserProfileDto? profile,
  }) = _CreateUserRequest;

  factory CreateUserRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateUserRequestFromJson(json);
}

@freezed
abstract class UpdateUserRequest with _$UpdateUserRequest {
  @JsonSerializable(explicitToJson: true)
  const factory UpdateUserRequest({
    @JsonKey(name: 'phone') String? phone,
    @JsonKey(name: 'email') String? email,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'gender') String? gender,
    @UserRoleJsonConverter()
    @JsonKey(name: 'primary_role')
    UserRole? primaryRole,
    @JsonKey(name: 'status') String? status,
    @JsonKey(name: 'profile') UserProfileDto? profile,
  }) = _UpdateUserRequest;

  factory UpdateUserRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserRequestFromJson(json);
}

@freezed
abstract class CreateScoreTemplateRequest with _$CreateScoreTemplateRequest {
  @JsonSerializable(explicitToJson: true)
  const factory CreateScoreTemplateRequest({
    @NullableFieldTypeJsonConverter()
    @JsonKey(name: 'field_type')
    FieldType? fieldType,
    @ScoringModeJsonConverter()
    @JsonKey(name: 'scoring_mode')
    required ScoringMode scoringMode,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'config') Object? config,
    @JsonKey(name: 'is_default') bool? isDefault,
  }) = _CreateScoreTemplateRequest;

  factory CreateScoreTemplateRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateScoreTemplateRequestFromJson(json);
}

@freezed
abstract class CreateSubmissionRequest with _$CreateSubmissionRequest {
  @JsonSerializable(explicitToJson: true)
  const factory CreateSubmissionRequest({
    @JsonKey(name: 'answers') required List<AnswerInputDto> answers,
    @JsonKey(name: 'anonymous') bool? anonymous,
    @JsonKey(name: 'fingerprint_token') String? fingerprintToken,
  }) = _CreateSubmissionRequest;

  factory CreateSubmissionRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateSubmissionRequestFromJson(json);
}

@freezed
abstract class DeleteResultDto with _$DeleteResultDto {
  @JsonSerializable(explicitToJson: true)
  const factory DeleteResultDto({
    @JsonKey(name: 'deleted') required bool deleted,
  }) = _DeleteResultDto;

  factory DeleteResultDto.fromJson(Map<String, dynamic> json) =>
      _$DeleteResultDtoFromJson(json);
}

@freezed
abstract class DuplicateFormRequest with _$DuplicateFormRequest {
  @JsonSerializable(explicitToJson: true)
  const factory DuplicateFormRequest({
    @JsonKey(name: 'title') String? title,
    @JsonKey(name: 'include_fields') required bool includeFields,
    @JsonKey(name: 'include_visibility') required bool includeVisibility,
    @JsonKey(name: 'include_activity_rules') required bool includeActivityRules,
  }) = _DuplicateFormRequest;

  factory DuplicateFormRequest.fromJson(Map<String, dynamic> json) =>
      _$DuplicateFormRequestFromJson(json);
}

@freezed
abstract class EffectivePermissionsDto with _$EffectivePermissionsDto {
  @JsonSerializable(explicitToJson: true)
  const factory EffectivePermissionsDto({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'organization_id') String? organizationId,
    @UserRoleJsonConverter() @JsonKey(name: 'role') required UserRole role,
    @PermissionActionListJsonConverter()
    @JsonKey(name: 'actions')
    required List<PermissionAction> actions,
    @ResourceTypeListJsonConverter()
    @JsonKey(name: 'resources')
    required List<ResourceType> resources,
    @FieldTypeListJsonConverter()
    @JsonKey(name: 'field_types')
    required List<FieldType> fieldTypes,
    @JsonKey(name: 'publishing_rules')
    required List<PublishingRuleDto> publishingRules,
    @JsonKey(name: 'can_manage_permissions') required bool canManagePermissions,
    @JsonKey(name: 'can_manage_scoring') required bool canManageScoring,
    @JsonKey(name: 'can_manage_public_protection')
    required bool canManagePublicProtection,
    @JsonKey(name: 'abac_context') Object? abacContext,
  }) = _EffectivePermissionsDto;

  factory EffectivePermissionsDto.fromJson(Map<String, dynamic> json) =>
      _$EffectivePermissionsDtoFromJson(json);
}

@freezed
abstract class FieldAnalyticsDto with _$FieldAnalyticsDto {
  @JsonSerializable(explicitToJson: true)
  const factory FieldAnalyticsDto({
    @JsonKey(name: 'field_id') required String fieldId,
    @JsonKey(name: 'label') required String label,
    @JsonKey(name: 'response_count') required int responseCount,
    @JsonKey(name: 'summary') required Object? summary,
  }) = _FieldAnalyticsDto;

  factory FieldAnalyticsDto.fromJson(Map<String, dynamic> json) =>
      _$FieldAnalyticsDtoFromJson(json);
}

@freezed
abstract class FieldConfigDto with _$FieldConfigDto {
  @JsonSerializable(explicitToJson: true)
  const factory FieldConfigDto({
    @JsonKey(name: 'options') List<FieldOptionDto>? options,
    @JsonKey(name: 'rows') List<FieldOptionDto>? rows,
    @JsonKey(name: 'columns') List<FieldOptionDto>? columns,
    @JsonKey(name: 'min') double? min,
    @JsonKey(name: 'max') double? max,
    @JsonKey(name: 'step') double? step,
    @JsonKey(name: 'default_value') Object? defaultValue,
    @JsonKey(name: 'accept_mime_types') List<String>? acceptMimeTypes,
    @JsonKey(name: 'max_file_size_mb') int? maxFileSizeMb,
    @JsonKey(name: 'page_title') String? pageTitle,
    @JsonKey(name: 'static_text') String? staticText,
    @JsonKey(name: 'metadata') Object? metadata,
  }) = _FieldConfigDto;

  factory FieldConfigDto.fromJson(Map<String, dynamic> json) =>
      _$FieldConfigDtoFromJson(json);
}

@freezed
abstract class FieldOptionDto with _$FieldOptionDto {
  @JsonSerializable(explicitToJson: true)
  const factory FieldOptionDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'label') required String label,
    @JsonKey(name: 'value') required Object? value,
    @JsonKey(name: 'order_index') required int orderIndex,
    @JsonKey(name: 'score') double? score,
    @JsonKey(name: 'metadata') Object? metadata,
  }) = _FieldOptionDto;

  factory FieldOptionDto.fromJson(Map<String, dynamic> json) =>
      _$FieldOptionDtoFromJson(json);
}

@freezed
abstract class FieldPermissionConfigDto with _$FieldPermissionConfigDto {
  @JsonSerializable(explicitToJson: true)
  const factory FieldPermissionConfigDto({
    @NullableUserRoleListJsonConverter()
    @JsonKey(name: 'visible_to_roles')
    List<UserRole>? visibleToRoles,
    @NullableUserRoleListJsonConverter()
    @JsonKey(name: 'editable_by_roles')
    List<UserRole>? editableByRoles,
    @NullableUserRoleListJsonConverter()
    @JsonKey(name: 'answerable_by_roles')
    List<UserRole>? answerableByRoles,
    @NullableUserRoleListJsonConverter()
    @JsonKey(name: 'hidden_from_roles')
    List<UserRole>? hiddenFromRoles,
    @JsonKey(name: 'metadata') Object? metadata,
  }) = _FieldPermissionConfigDto;

  factory FieldPermissionConfigDto.fromJson(Map<String, dynamic> json) =>
      _$FieldPermissionConfigDtoFromJson(json);
}

@freezed
abstract class FieldScoreBreakdownDto with _$FieldScoreBreakdownDto {
  @JsonSerializable(explicitToJson: true)
  const factory FieldScoreBreakdownDto({
    @JsonKey(name: 'field_id') required String fieldId,
    @JsonKey(name: 'label') required String label,
    @JsonKey(name: 'score') required double score,
    @JsonKey(name: 'max_score') required double maxScore,
    @JsonKey(name: 'weighted_score') required double weightedScore,
    @JsonKey(name: 'rule_id') String? ruleId,
    @JsonKey(name: 'details') Object? details,
  }) = _FieldScoreBreakdownDto;

  factory FieldScoreBreakdownDto.fromJson(Map<String, dynamic> json) =>
      _$FieldScoreBreakdownDtoFromJson(json);
}

@freezed
abstract class FieldScoringConfigDto with _$FieldScoringConfigDto {
  @JsonSerializable(explicitToJson: true)
  const factory FieldScoringConfigDto({
    @JsonKey(name: 'enabled') required bool enabled,
    @JsonKey(name: 'max_score') double? maxScore,
    @JsonKey(name: 'weight') double? weight,
    @JsonKey(name: 'option_scores') Map<String, double>? optionScores,
    @JsonKey(name: 'rules') List<ScoreRuleDto>? rules,
    @JsonKey(name: 'categories') List<ScoreCategoryDto>? categories,
    @JsonKey(name: 'metadata') Object? metadata,
  }) = _FieldScoringConfigDto;

  factory FieldScoringConfigDto.fromJson(Map<String, dynamic> json) =>
      _$FieldScoringConfigDtoFromJson(json);
}

@freezed
abstract class FieldTypePermissionDto with _$FieldTypePermissionDto {
  @JsonSerializable(explicitToJson: true)
  const factory FieldTypePermissionDto({
    @UserRoleJsonConverter() @JsonKey(name: 'role') required UserRole role,
    @FieldTypeJsonConverter()
    @JsonKey(name: 'field_type')
    required FieldType fieldType,
    @JsonKey(name: 'allowed') required bool allowed,
    @JsonKey(name: 'reason') String? reason,
  }) = _FieldTypePermissionDto;

  factory FieldTypePermissionDto.fromJson(Map<String, dynamic> json) =>
      _$FieldTypePermissionDtoFromJson(json);
}

@freezed
abstract class FieldValidationDto with _$FieldValidationDto {
  @JsonSerializable(explicitToJson: true)
  const factory FieldValidationDto({
    @JsonKey(name: 'min_length') int? minLength,
    @JsonKey(name: 'max_length') int? maxLength,
    @JsonKey(name: 'regex') String? regex,
    @JsonKey(name: 'min_number') double? minNumber,
    @JsonKey(name: 'max_number') double? maxNumber,
    @JsonKey(name: 'min_items') int? minItems,
    @JsonKey(name: 'max_items') int? maxItems,
    @JsonKey(name: 'required_message') String? requiredMessage,
    @JsonKey(name: 'custom') Object? custom,
  }) = _FieldValidationDto;

  factory FieldValidationDto.fromJson(Map<String, dynamic> json) =>
      _$FieldValidationDtoFromJson(json);
}

@freezed
abstract class FieldVisibilityConditionDto with _$FieldVisibilityConditionDto {
  @JsonSerializable(explicitToJson: true)
  const factory FieldVisibilityConditionDto({
    @JsonKey(name: 'source_field_id') required String sourceFieldId,
    @JsonKey(name: 'operator') required String operatorValue,
    @JsonKey(name: 'value') required Object? value,
  }) = _FieldVisibilityConditionDto;

  factory FieldVisibilityConditionDto.fromJson(Map<String, dynamic> json) =>
      _$FieldVisibilityConditionDtoFromJson(json);
}

@freezed
abstract class FormAnalyticsDto with _$FormAnalyticsDto {
  @JsonSerializable(explicitToJson: true)
  const factory FormAnalyticsDto({
    @JsonKey(name: 'form_id') required String formId,
    @JsonKey(name: 'submissions')
    required SubmissionCountAnalyticsDto submissions,
    @JsonKey(name: 'completion') required CompletionRateAnalyticsDto completion,
    @JsonKey(name: 'score') required ScoreAnalyticsDto score,
    @JsonKey(name: 'fields') required List<FieldAnalyticsDto> fields,
    @JsonKey(name: 'respondent_modes')
    required List<AnalyticsBucketDto> respondentModes,
    @JsonKey(name: 'gender_distribution')
    required List<AnalyticsBucketDto> genderDistribution,
    @JsonKey(name: 'user_role_distribution')
    required List<AnalyticsBucketDto> userRoleDistribution,
    @JsonKey(name: 'access_code_distribution')
    required List<AnalyticsBucketDto> accessCodeDistribution,
  }) = _FormAnalyticsDto;

  factory FormAnalyticsDto.fromJson(Map<String, dynamic> json) =>
      _$FormAnalyticsDtoFromJson(json);
}

@freezed
abstract class FormAccessCodeDto with _$FormAccessCodeDto {
  @JsonSerializable(explicitToJson: true)
  const factory FormAccessCodeDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'code_type') required String codeType,
    @JsonKey(name: 'label') String? label,
    @JsonKey(name: 'enabled') required bool enabled,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _FormAccessCodeDto;

  factory FormAccessCodeDto.fromJson(Map<String, dynamic> json) =>
      _$FormAccessCodeDtoFromJson(json);
}

@freezed
abstract class FormAccessCodeInputDto with _$FormAccessCodeInputDto {
  @JsonSerializable(explicitToJson: true)
  const factory FormAccessCodeInputDto({
    @JsonKey(name: 'label') required String label,
    @JsonKey(name: 'code') required String code,
    @JsonKey(name: 'enabled') bool? enabled,
  }) = _FormAccessCodeInputDto;

  factory FormAccessCodeInputDto.fromJson(Map<String, dynamic> json) =>
      _$FormAccessCodeInputDtoFromJson(json);
}

@freezed
abstract class SharedFormPasswordInputDto with _$SharedFormPasswordInputDto {
  @JsonSerializable(explicitToJson: true)
  const factory SharedFormPasswordInputDto({
    @JsonKey(name: 'code') required String code,
    @JsonKey(name: 'enabled') bool? enabled,
  }) = _SharedFormPasswordInputDto;

  factory SharedFormPasswordInputDto.fromJson(Map<String, dynamic> json) =>
      _$SharedFormPasswordInputDtoFromJson(json);
}

@freezed
abstract class SetFormAccessCodesRequest with _$SetFormAccessCodesRequest {
  @JsonSerializable(explicitToJson: true)
  const factory SetFormAccessCodesRequest({
    @JsonKey(name: 'shared_password')
    SharedFormPasswordInputDto? sharedPassword,
    @JsonKey(name: 'clear_shared_password') bool? clearSharedPassword,
    @JsonKey(name: 'identity_codes')
    @Default(<FormAccessCodeInputDto>[])
    List<FormAccessCodeInputDto> identityCodes,
  }) = _SetFormAccessCodesRequest;

  factory SetFormAccessCodesRequest.fromJson(Map<String, dynamic> json) =>
      _$SetFormAccessCodesRequestFromJson(json);
}

@freezed
abstract class FormAccessCodesResponse with _$FormAccessCodesResponse {
  @JsonSerializable(explicitToJson: true)
  const factory FormAccessCodesResponse({
    @JsonKey(name: 'shared_password') FormAccessCodeDto? sharedPassword,
    @JsonKey(name: 'identity_codes')
    @Default(<FormAccessCodeDto>[])
    List<FormAccessCodeDto> identityCodes,
  }) = _FormAccessCodesResponse;

  factory FormAccessCodesResponse.fromJson(Map<String, dynamic> json) =>
      _$FormAccessCodesResponseFromJson(json);
}

@freezed
abstract class FormDetailDto with _$FormDetailDto {
  @JsonSerializable(explicitToJson: true)
  const factory FormDetailDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'organization_id') required String organizationId,
    @JsonKey(name: 'creator_id') required String creatorId,
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'category') String? category,
    @JsonKey(name: 'tags') List<String>? tags,
    @FormStatusJsonConverter()
    @JsonKey(name: 'status')
    required FormStatus status,
    @VisibilityModeJsonConverter()
    @JsonKey(name: 'visibility_mode')
    required VisibilityMode visibilityMode,
    @PublishModeJsonConverter()
    @JsonKey(name: 'publish_mode')
    required PublishMode publishMode,
    @JsonKey(name: 'settings') required FormSettingsDto settings,
    @JsonKey(name: 'visibility') required FormVisibilityDto visibility,
    @JsonKey(name: 'public_protection')
    required PublicProtectionSettingsDto publicProtection,
    @ScoringModeJsonConverter()
    @JsonKey(name: 'scoring_mode')
    required ScoringMode scoringMode,
    @JsonKey(name: 'scoring_config') required Object? scoringConfig,
    @JsonKey(name: 'fields') required List<FormFieldDto> fields,
    @JsonKey(name: 'public_token') String? publicToken,
    @JsonKey(name: 'approved_at') DateTime? approvedAt,
    @JsonKey(name: 'published_at') DateTime? publishedAt,
    @JsonKey(name: 'closed_at') DateTime? closedAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _FormDetailDto;

  factory FormDetailDto.fromJson(Map<String, dynamic> json) =>
      _$FormDetailDtoFromJson(json);
}

@freezed
abstract class FormFieldDto with _$FormFieldDto {
  @JsonSerializable(explicitToJson: true)
  const factory FormFieldDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'form_id') required String formId,
    @FieldTypeJsonConverter() @JsonKey(name: 'type') required FieldType type,
    @JsonKey(name: 'label') required String label,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'placeholder') String? placeholder,
    @JsonKey(name: 'required') required bool isRequired,
    @JsonKey(name: 'order_index') required int orderIndex,
    @JsonKey(name: 'config') required FieldConfigDto config,
    @JsonKey(name: 'validation') required FieldValidationDto validation,
    @JsonKey(name: 'visibility_conditions')
    required List<ConditionalLogicRuleDto> visibilityConditions,
    @JsonKey(name: 'scoring_config')
    required FieldScoringConfigDto scoringConfig,
    @JsonKey(name: 'permissions') required FieldPermissionConfigDto permissions,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _FormFieldDto;

  factory FormFieldDto.fromJson(Map<String, dynamic> json) =>
      _$FormFieldDtoFromJson(json);
}

@freezed
abstract class FormSettingsDto with _$FormSettingsDto {
  @JsonSerializable(explicitToJson: true)
  const factory FormSettingsDto({
    @JsonKey(name: 'allow_anonymous_answers')
    required bool allowAnonymousAnswers,
    @JsonKey(name: 'one_submission_per_user')
    required bool oneSubmissionPerUser,
    @JsonKey(name: 'answers_editable_after_submission')
    required bool answersEditableAfterSubmission,
    @JsonKey(name: 'start_at') DateTime? startAt,
    @JsonKey(name: 'end_at') DateTime? endAt,
    @JsonKey(name: 'max_submissions') int? maxSubmissions,
    @JsonKey(name: 'submission_cooldown_seconds')
    int? submissionCooldownSeconds,
    @SubmissionModeJsonConverter()
    @JsonKey(name: 'submission_mode')
    required SubmissionMode submissionMode,
    @AnswerVisibilityJsonConverter()
    @JsonKey(name: 'answer_visibility')
    required AnswerVisibility answerVisibility,
    @JsonKey(name: 'guests_can_answer') required bool guestsCanAnswer,
    @JsonKey(name: 'metadata') Object? metadata,
  }) = _FormSettingsDto;

  factory FormSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$FormSettingsDtoFromJson(json);
}

@freezed
abstract class FormSummaryDto with _$FormSummaryDto {
  @JsonSerializable(explicitToJson: true)
  const factory FormSummaryDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'organization_id') required String organizationId,
    @JsonKey(name: 'creator_id') required String creatorId,
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'category') String? category,
    @JsonKey(name: 'tags') List<String>? tags,
    @FormStatusJsonConverter()
    @JsonKey(name: 'status')
    required FormStatus status,
    @VisibilityModeJsonConverter()
    @JsonKey(name: 'visibility_mode')
    required VisibilityMode visibilityMode,
    @PublishModeJsonConverter()
    @JsonKey(name: 'publish_mode')
    required PublishMode publishMode,
    @ScoringModeJsonConverter()
    @JsonKey(name: 'scoring_mode')
    required ScoringMode scoringMode,
    @JsonKey(name: 'submissions_count') required int submissionsCount,
    @JsonKey(name: 'public_token') String? publicToken,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _FormSummaryDto;

  factory FormSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$FormSummaryDtoFromJson(json);
}

@freezed
abstract class FormVisibilityDto with _$FormVisibilityDto {
  @JsonSerializable(explicitToJson: true)
  const factory FormVisibilityDto({
    @VisibilityModeJsonConverter()
    @JsonKey(name: 'mode')
    required VisibilityMode mode,
    @JsonKey(name: 'can_see') List<AudienceRuleDto>? canSee,
    @JsonKey(name: 'can_answer') List<AudienceRuleDto>? canAnswer,
    @JsonKey(name: 'cannot_see') List<AudienceRuleDto>? cannotSee,
    @JsonKey(name: 'cannot_answer') List<AudienceRuleDto>? cannotAnswer,
    @JsonKey(name: 'guest_can_answer') required bool guestCanAnswer,
    @JsonKey(name: 'anonymous_allowed') required bool anonymousAllowed,
    @JsonKey(name: 'metadata') Object? metadata,
  }) = _FormVisibilityDto;

  factory FormVisibilityDto.fromJson(Map<String, dynamic> json) =>
      _$FormVisibilityDtoFromJson(json);
}

@freezed
abstract class ListMetaDto with _$ListMetaDto {
  @JsonSerializable(explicitToJson: true)
  const factory ListMetaDto({
    @JsonKey(name: 'pagination') required PaginationMeta pagination,
  }) = _ListMetaDto;

  factory ListMetaDto.fromJson(Map<String, dynamic> json) =>
      _$ListMetaDtoFromJson(json);
}

@freezed
abstract class LoginRequest with _$LoginRequest {
  @JsonSerializable(explicitToJson: true)
  const factory LoginRequest({
    @JsonKey(name: 'phone') required String phone,
    @JsonKey(name: 'password') required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

@freezed
abstract class LoginResponse with _$LoginResponse {
  @JsonSerializable(explicitToJson: true)
  const factory LoginResponse({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'token_type') required String tokenType,
    @JsonKey(name: 'expires_in') required int expiresIn,
    @JsonKey(name: 'user') required UserDetailDto user,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}

@freezed
abstract class LogoutRequest with _$LogoutRequest {
  @JsonSerializable(explicitToJson: true)
  const factory LogoutRequest({
    @JsonKey(name: 'refresh_token') required String refreshToken,
  }) = _LogoutRequest;

  factory LogoutRequest.fromJson(Map<String, dynamic> json) =>
      _$LogoutRequestFromJson(json);
}

@freezed
abstract class LogoutResponse with _$LogoutResponse {
  @JsonSerializable(explicitToJson: true)
  const factory LogoutResponse({
    @JsonKey(name: 'logged_out') required bool loggedOut,
  }) = _LogoutResponse;

  factory LogoutResponse.fromJson(Map<String, dynamic> json) =>
      _$LogoutResponseFromJson(json);
}

@freezed
abstract class MeResponse with _$MeResponse {
  @JsonSerializable(explicitToJson: true)
  const factory MeResponse({
    @JsonKey(name: 'user') required UserDetailDto user,
    @JsonKey(name: 'effective_permissions')
    required EffectivePermissionsDto effectivePermissions,
  }) = _MeResponse;

  factory MeResponse.fromJson(Map<String, dynamic> json) =>
      _$MeResponseFromJson(json);
}

@freezed
abstract class OperationStatusDto with _$OperationStatusDto {
  @JsonSerializable(explicitToJson: true)
  const factory OperationStatusDto({
    @JsonKey(name: 'success') required bool success,
    @JsonKey(name: 'message') String? message,
  }) = _OperationStatusDto;

  factory OperationStatusDto.fromJson(Map<String, dynamic> json) =>
      _$OperationStatusDtoFromJson(json);
}

@freezed
abstract class OrganizationDto with _$OrganizationDto {
  @JsonSerializable(explicitToJson: true)
  const factory OrganizationDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'parent_organization_id') String? parentOrganizationId,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'slug') required String slug,
    @JsonKey(name: 'settings') required OrganizationSettingsDto settings,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _OrganizationDto;

  factory OrganizationDto.fromJson(Map<String, dynamic> json) =>
      _$OrganizationDtoFromJson(json);
}

@freezed
abstract class OrganizationRoleDto with _$OrganizationRoleDto {
  @JsonSerializable(explicitToJson: true)
  const factory OrganizationRoleDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'organization_id') String? organizationId,
    @UserRoleJsonConverter() @JsonKey(name: 'name') required UserRole name,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'is_system') required bool isSystem,
    @NullablePermissionActionListJsonConverter()
    @JsonKey(name: 'default_permissions')
    List<PermissionAction>? defaultPermissions,
  }) = _OrganizationRoleDto;

  factory OrganizationRoleDto.fromJson(Map<String, dynamic> json) =>
      _$OrganizationRoleDtoFromJson(json);
}

@freezed
abstract class OrganizationSettingsDto with _$OrganizationSettingsDto {
  @JsonSerializable(explicitToJson: true)
  const factory OrganizationSettingsDto({
    @JsonKey(name: 'default_timezone') required String defaultTimezone,
    @JsonKey(name: 'public_forms_enabled') required bool publicFormsEnabled,
    @PublicProtectionLevelJsonConverter()
    @JsonKey(name: 'default_public_protection_level')
    required PublicProtectionLevel defaultPublicProtectionLevel,
    @JsonKey(name: 'require_audit_for_public_protection_disable')
    required bool requireAuditForPublicProtectionDisable,
    @JsonKey(name: 'metadata') Object? metadata,
  }) = _OrganizationSettingsDto;

  factory OrganizationSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$OrganizationSettingsDtoFromJson(json);
}

@freezed
abstract class PaginationMeta with _$PaginationMeta {
  @JsonSerializable(explicitToJson: true)
  const factory PaginationMeta({
    @JsonKey(name: 'page') required int page,
    @JsonKey(name: 'page_size') required int pageSize,
    @JsonKey(name: 'total_items') required int totalItems,
    @JsonKey(name: 'total_pages') required int totalPages,
    @JsonKey(name: 'has_next') required bool hasNext,
    @JsonKey(name: 'has_previous') required bool hasPrevious,
  }) = _PaginationMeta;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaFromJson(json);
}

@freezed
abstract class PermissionDto with _$PermissionDto {
  @JsonSerializable(explicitToJson: true)
  const factory PermissionDto({
    @JsonKey(name: 'id') required String id,
    @PermissionActionJsonConverter()
    @JsonKey(name: 'action')
    required PermissionAction action,
    @ResourceTypeJsonConverter()
    @JsonKey(name: 'resource_type')
    required ResourceType resourceType,
    @JsonKey(name: 'key') required String key,
    @JsonKey(name: 'description') String? description,
  }) = _PermissionDto;

  factory PermissionDto.fromJson(Map<String, dynamic> json) =>
      _$PermissionDtoFromJson(json);
}

@freezed
abstract class PublicFormAccessDto with _$PublicFormAccessDto {
  @JsonSerializable(explicitToJson: true)
  const factory PublicFormAccessDto({
    @JsonKey(name: 'public_token') required String publicToken,
    @JsonKey(name: 'fingerprint_token') String? fingerprintToken,
    @JsonKey(name: 'ip_hint') String? ipHint,
    @JsonKey(name: 'metadata') Object? metadata,
  }) = _PublicFormAccessDto;

  factory PublicFormAccessDto.fromJson(Map<String, dynamic> json) =>
      _$PublicFormAccessDtoFromJson(json);
}

@freezed
abstract class PublicFormDto with _$PublicFormDto {
  @JsonSerializable(explicitToJson: true)
  const factory PublicFormDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'settings') required FormSettingsDto settings,
    @JsonKey(name: 'visibility') required FormVisibilityDto visibility,
    @JsonKey(name: 'public_protection')
    required PublicProtectionSettingsDto publicProtection,
    @JsonKey(name: 'fields') required List<FormFieldDto> fields,
    @JsonKey(name: 'access_policy')
    required PublicFormAccessPolicyDto accessPolicy,
    @JsonKey(name: 'start_at') DateTime? startAt,
    @JsonKey(name: 'end_at') DateTime? endAt,
  }) = _PublicFormDto;

  factory PublicFormDto.fromJson(Map<String, dynamic> json) =>
      _$PublicFormDtoFromJson(json);
}

@freezed
abstract class PublicFormAccessPolicyDto with _$PublicFormAccessPolicyDto {
  @JsonSerializable(explicitToJson: true)
  const factory PublicFormAccessPolicyDto({
    @JsonKey(name: 'respondent_modes') required List<String> respondentModes,
    @JsonKey(name: 'requires_form_password') required bool requiresFormPassword,
    @JsonKey(name: 'identity_codes_enabled') required bool identityCodesEnabled,
    @JsonKey(name: 'public_access_validation_required')
    required bool publicAccessValidationRequired,
  }) = _PublicFormAccessPolicyDto;

  factory PublicFormAccessPolicyDto.fromJson(Map<String, dynamic> json) =>
      _$PublicFormAccessPolicyDtoFromJson(json);
}

@freezed
abstract class PublicProtectionSettingsDto with _$PublicProtectionSettingsDto {
  @JsonSerializable(explicitToJson: true)
  const factory PublicProtectionSettingsDto({
    @PublicProtectionLevelJsonConverter()
    @JsonKey(name: 'level')
    required PublicProtectionLevel level,
    @NullableRateLimitStrategyListJsonConverter()
    @JsonKey(name: 'strategies')
    List<RateLimitStrategy>? strategies,
    @JsonKey(name: 'ip_limit_per_minute') int? ipLimitPerMinute,
    @JsonKey(name: 'token_limit_per_day') int? tokenLimitPerDay,
    @JsonKey(name: 'access_limit_per_minute') int? accessLimitPerMinute,
    @JsonKey(name: 'cooldown_seconds') int? cooldownSeconds,
    @JsonKey(name: 'max_submissions_per_ip') int? maxSubmissionsPerIp,
    @JsonKey(name: 'max_submissions_per_fingerprint')
    int? maxSubmissionsPerFingerprint,
    @JsonKey(name: 'captcha_enabled') required bool captchaEnabled,
    @JsonKey(name: 'email_verification_enabled')
    required bool emailVerificationEnabled,
    @JsonKey(name: 'phone_verification_enabled')
    required bool phoneVerificationEnabled,
    @NullableRateLimitStrategyListJsonConverter()
    @JsonKey(name: 'disabled_limits')
    List<RateLimitStrategy>? disabledLimits,
    @JsonKey(name: 'metadata') Object? metadata,
  }) = _PublicProtectionSettingsDto;

  factory PublicProtectionSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$PublicProtectionSettingsDtoFromJson(json);
}

@freezed
abstract class PublicRateLimitStatusDto with _$PublicRateLimitStatusDto {
  @JsonSerializable(explicitToJson: true)
  const factory PublicRateLimitStatusDto({
    @JsonKey(name: 'allowed') required bool allowed,
    @JsonKey(name: 'limits') required List<RateLimitInfoDto> limits,
    @JsonKey(name: 'retry_after_seconds') int? retryAfterSeconds,
  }) = _PublicRateLimitStatusDto;

  factory PublicRateLimitStatusDto.fromJson(Map<String, dynamic> json) =>
      _$PublicRateLimitStatusDtoFromJson(json);
}

@freezed
abstract class PublicSubmissionRequest with _$PublicSubmissionRequest {
  @JsonSerializable(explicitToJson: true)
  const factory PublicSubmissionRequest({
    @JsonKey(name: 'answers') required List<AnswerInputDto> answers,
    @JsonKey(name: 'respondent_mode') String? respondentMode,
    @JsonKey(name: 'anonymous') bool? anonymous,
    @JsonKey(name: 'fingerprint_token') String? fingerprintToken,
    @JsonKey(name: 'public_access_token') String? publicAccessToken,
    @JsonKey(name: 'captcha_token') String? captchaToken,
    @JsonKey(name: 'respondent_name') String? respondentName,
  }) = _PublicSubmissionRequest;

  factory PublicSubmissionRequest.fromJson(Map<String, dynamic> json) =>
      _$PublicSubmissionRequestFromJson(json);
}

@freezed
abstract class PublicSubmissionResponse with _$PublicSubmissionResponse {
  @JsonSerializable(explicitToJson: true)
  const factory PublicSubmissionResponse({
    @JsonKey(name: 'submission') required SubmissionDetailDto submission,
    @JsonKey(name: 'message') required String message,
  }) = _PublicSubmissionResponse;

  factory PublicSubmissionResponse.fromJson(Map<String, dynamic> json) =>
      _$PublicSubmissionResponseFromJson(json);
}

@freezed
abstract class PublishFormRequest with _$PublishFormRequest {
  @JsonSerializable(explicitToJson: true)
  const factory PublishFormRequest({
    @PublishModeJsonConverter()
    @JsonKey(name: 'publish_mode')
    required PublishMode publishMode,
    @JsonKey(name: 'visibility') FormVisibilityDto? visibility,
    @JsonKey(name: 'public_protection')
    PublicProtectionSettingsDto? publicProtection,
    @JsonKey(name: 'scheduled_at') DateTime? scheduledAt,
  }) = _PublishFormRequest;

  factory PublishFormRequest.fromJson(Map<String, dynamic> json) =>
      _$PublishFormRequestFromJson(json);
}

@freezed
abstract class PublishingRuleDto with _$PublishingRuleDto {
  @JsonSerializable(explicitToJson: true)
  const factory PublishingRuleDto({
    @UserRoleJsonConverter() @JsonKey(name: 'role') required UserRole role,
    @JsonKey(name: 'can_publish_directly') required bool canPublishDirectly,
    @PublishModeListJsonConverter()
    @JsonKey(name: 'allowed_publish_modes')
    required List<PublishMode> allowedPublishModes,
    @JsonKey(name: 'approval_rule') required ApprovalRuleDto approvalRule,
    @JsonKey(name: 'can_disable_public_protection')
    required bool canDisablePublicProtection,
  }) = _PublishingRuleDto;

  factory PublishingRuleDto.fromJson(Map<String, dynamic> json) =>
      _$PublishingRuleDtoFromJson(json);
}

@freezed
abstract class RateLimitInfoDto with _$RateLimitInfoDto {
  @JsonSerializable(explicitToJson: true)
  const factory RateLimitInfoDto({
    @RateLimitStrategyJsonConverter()
    @JsonKey(name: 'strategy')
    required RateLimitStrategy strategy,
    @JsonKey(name: 'limit') required int limit,
    @JsonKey(name: 'remaining') required int remaining,
    @JsonKey(name: 'reset_at') required DateTime resetAt,
  }) = _RateLimitInfoDto;

  factory RateLimitInfoDto.fromJson(Map<String, dynamic> json) =>
      _$RateLimitInfoDtoFromJson(json);
}

@freezed
abstract class RefreshTokenRequest with _$RefreshTokenRequest {
  @JsonSerializable(explicitToJson: true)
  const factory RefreshTokenRequest({
    @JsonKey(name: 'refresh_token') required String refreshToken,
  }) = _RefreshTokenRequest;

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestFromJson(json);
}

@freezed
abstract class RefreshTokenResponse with _$RefreshTokenResponse {
  @JsonSerializable(explicitToJson: true)
  const factory RefreshTokenResponse({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'token_type') required String tokenType,
    @JsonKey(name: 'expires_in') required int expiresIn,
  }) = _RefreshTokenResponse;

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenResponseFromJson(json);
}

@freezed
abstract class RegisterRequest with _$RegisterRequest {
  @JsonSerializable(explicitToJson: true)
  const factory RegisterRequest({
    @JsonKey(name: 'phone') required String phone,
    @JsonKey(name: 'email') String? email,
    @JsonKey(name: 'password') required String password,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'gender') String? gender,
    @JsonKey(name: 'organization_id') String? organizationId,
    @JsonKey(name: 'organization_name') String? organizationName,
    @NullableUserRoleJsonConverter() @JsonKey(name: 'role') UserRole? role,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
}

@freezed
abstract class RegisterResponse with _$RegisterResponse {
  @JsonSerializable(explicitToJson: true)
  const factory RegisterResponse({
    @JsonKey(name: 'user') required UserDetailDto user,
    @JsonKey(name: 'organization') OrganizationDto? organization,
  }) = _RegisterResponse;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseFromJson(json);
}

@freezed
abstract class RejectFormRequest with _$RejectFormRequest {
  @JsonSerializable(explicitToJson: true)
  const factory RejectFormRequest({
    @JsonKey(name: 'reason') required String reason,
  }) = _RejectFormRequest;

  factory RejectFormRequest.fromJson(Map<String, dynamic> json) =>
      _$RejectFormRequestFromJson(json);
}

@freezed
abstract class RolePermissionDto with _$RolePermissionDto {
  @JsonSerializable(explicitToJson: true)
  const factory RolePermissionDto({
    @UserRoleJsonConverter() @JsonKey(name: 'role') required UserRole role,
    @JsonKey(name: 'permission') required PermissionDto permission,
    @JsonKey(name: 'allowed') required bool allowed,
  }) = _RolePermissionDto;

  factory RolePermissionDto.fromJson(Map<String, dynamic> json) =>
      _$RolePermissionDtoFromJson(json);
}

@freezed
abstract class RoleRuleDto with _$RoleRuleDto {
  @JsonSerializable(explicitToJson: true)
  const factory RoleRuleDto({
    @UserRoleJsonConverter() @JsonKey(name: 'role') required UserRole role,
    @JsonKey(name: 'can_create_forms') required bool canCreateForms,
    @JsonKey(name: 'can_publish_forms') required bool canPublishForms,
    @JsonKey(name: 'requires_approval_to_publish')
    required bool requiresApprovalToPublish,
    @JsonKey(name: 'two_step_approval_required')
    required bool twoStepApprovalRequired,
    @JsonKey(name: 'can_change_scoring') required bool canChangeScoring,
    @UserRoleListJsonConverter()
    @JsonKey(name: 'approver_roles')
    required List<UserRole> approverRoles,
    @FieldTypeListJsonConverter()
    @JsonKey(name: 'allowed_field_types')
    required List<FieldType> allowedFieldTypes,
    @FieldTypeListJsonConverter()
    @JsonKey(name: 'denied_field_types')
    required List<FieldType> deniedFieldTypes,
    @JsonKey(name: 'metadata') Object? metadata,
  }) = _RoleRuleDto;

  factory RoleRuleDto.fromJson(Map<String, dynamic> json) =>
      _$RoleRuleDtoFromJson(json);
}

@freezed
abstract class ScoreAnalyticsDto with _$ScoreAnalyticsDto {
  @JsonSerializable(explicitToJson: true)
  const factory ScoreAnalyticsDto({
    @JsonKey(name: 'average_score') required double averageScore,
    @JsonKey(name: 'max_score') required double maxScore,
    @JsonKey(name: 'average_percentage') required double averagePercentage,
    @JsonKey(name: 'category_distribution')
    required Object? categoryDistribution,
  }) = _ScoreAnalyticsDto;

  factory ScoreAnalyticsDto.fromJson(Map<String, dynamic> json) =>
      _$ScoreAnalyticsDtoFromJson(json);
}

@freezed
abstract class ScoreBreakdownDto with _$ScoreBreakdownDto {
  @JsonSerializable(explicitToJson: true)
  const factory ScoreBreakdownDto({
    @JsonKey(name: 'submission_id') required String submissionId,
    @JsonKey(name: 'result') required ScoreResultDto result,
  }) = _ScoreBreakdownDto;

  factory ScoreBreakdownDto.fromJson(Map<String, dynamic> json) =>
      _$ScoreBreakdownDtoFromJson(json);
}

@freezed
abstract class ScoreCategoryDto with _$ScoreCategoryDto {
  @JsonSerializable(explicitToJson: true)
  const factory ScoreCategoryDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'label') required String label,
    @JsonKey(name: 'min_percentage') required double minPercentage,
    @JsonKey(name: 'max_percentage') required double maxPercentage,
    @JsonKey(name: 'color') String? color,
    @JsonKey(name: 'description') String? description,
  }) = _ScoreCategoryDto;

  factory ScoreCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$ScoreCategoryDtoFromJson(json);
}

@freezed
abstract class ScoreResultDto with _$ScoreResultDto {
  @JsonSerializable(explicitToJson: true)
  const factory ScoreResultDto({
    @JsonKey(name: 'total_score') required double totalScore,
    @JsonKey(name: 'max_score') required double maxScore,
    @JsonKey(name: 'percentage_score') required double percentageScore,
    @JsonKey(name: 'category') ScoreCategoryDto? category,
    @JsonKey(name: 'field_breakdowns')
    required List<FieldScoreBreakdownDto> fieldBreakdowns,
    @JsonKey(name: 'metadata') Map<String, Object?>? metadata,
  }) = _ScoreResultDto;

  factory ScoreResultDto.fromJson(Map<String, dynamic> json) =>
      _$ScoreResultDtoFromJson(json);
}

@freezed
abstract class ScoreRuleDto with _$ScoreRuleDto {
  @JsonSerializable(explicitToJson: true)
  const factory ScoreRuleDto({
    @JsonKey(name: 'id') String? id,
    @ScoreRuleTypeJsonConverter()
    @JsonKey(name: 'rule_type')
    required ScoreRuleType ruleType,
    @JsonKey(name: 'min') double? min,
    @JsonKey(name: 'max') double? max,
    @JsonKey(name: 'value') Object? value,
    @JsonKey(name: 'score') required double score,
    @JsonKey(name: 'weight') double? weight,
    @JsonKey(name: 'formula') String? formula,
  }) = _ScoreRuleDto;

  factory ScoreRuleDto.fromJson(Map<String, dynamic> json) =>
      _$ScoreRuleDtoFromJson(json);
}

@freezed
abstract class ScoreTemplateDto with _$ScoreTemplateDto {
  @JsonSerializable(explicitToJson: true)
  const factory ScoreTemplateDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'organization_id') String? organizationId,
    @NullableFieldTypeJsonConverter()
    @JsonKey(name: 'field_type')
    FieldType? fieldType,
    @ScoringModeJsonConverter()
    @JsonKey(name: 'scoring_mode')
    required ScoringMode scoringMode,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'config') required Object? config,
    @JsonKey(name: 'is_default') required bool isDefault,
  }) = _ScoreTemplateDto;

  factory ScoreTemplateDto.fromJson(Map<String, dynamic> json) =>
      _$ScoreTemplateDtoFromJson(json);
}

@freezed
abstract class SubmissionCountAnalyticsDto with _$SubmissionCountAnalyticsDto {
  @JsonSerializable(explicitToJson: true)
  const factory SubmissionCountAnalyticsDto({
    @JsonKey(name: 'total') required int total,
    @JsonKey(name: 'valid') required int valid,
    @JsonKey(name: 'anonymous') required int anonymous,
    @JsonKey(name: 'by_day') required List<AnalyticsTimeseriesPointDto> byDay,
    @JsonKey(name: 'today') required int today,
    @JsonKey(name: 'this_week') required int thisWeek,
    @JsonKey(name: 'this_month') required int thisMonth,
  }) = _SubmissionCountAnalyticsDto;

  factory SubmissionCountAnalyticsDto.fromJson(Map<String, dynamic> json) =>
      _$SubmissionCountAnalyticsDtoFromJson(json);
}

@freezed
abstract class SubmissionDetailDto with _$SubmissionDetailDto {
  @JsonSerializable(explicitToJson: true)
  const factory SubmissionDetailDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'form_id') required String formId,
    @JsonKey(name: 'respondent_user_id') String? respondentUserId,
    @JsonKey(name: 'guest_token_id') String? guestTokenId,
    @JsonKey(name: 'access_code_id') String? accessCodeId,
    @JsonKey(name: 'respondent_mode') required String respondentMode,
    @JsonKey(name: 'respondent_label') String? respondentLabel,
    @JsonKey(name: 'anonymous') required bool anonymous,
    @JsonKey(name: 'valid') required bool valid,
    @JsonKey(name: 'answers') required List<AnswerDto> answers,
    @JsonKey(name: 'score') required SubmissionScoreDto score,
    @JsonKey(name: 'submitted_at') required DateTime submittedAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _SubmissionDetailDto;

  factory SubmissionDetailDto.fromJson(Map<String, dynamic> json) =>
      _$SubmissionDetailDtoFromJson(json);
}

@freezed
abstract class SubmissionScoreDto with _$SubmissionScoreDto {
  @JsonSerializable(explicitToJson: true)
  const factory SubmissionScoreDto({
    @JsonKey(name: 'total_score') required double totalScore,
    @JsonKey(name: 'max_score') required double maxScore,
    @JsonKey(name: 'percentage_score') required double percentageScore,
    @JsonKey(name: 'category_label') String? categoryLabel,
  }) = _SubmissionScoreDto;

  factory SubmissionScoreDto.fromJson(Map<String, dynamic> json) =>
      _$SubmissionScoreDtoFromJson(json);
}

@freezed
abstract class SubmissionSummaryDto with _$SubmissionSummaryDto {
  @JsonSerializable(explicitToJson: true)
  const factory SubmissionSummaryDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'form_id') required String formId,
    @JsonKey(name: 'respondent_user_id') String? respondentUserId,
    @JsonKey(name: 'access_code_id') String? accessCodeId,
    @JsonKey(name: 'respondent_mode') required String respondentMode,
    @JsonKey(name: 'respondent_label') String? respondentLabel,
    @JsonKey(name: 'anonymous') required bool anonymous,
    @JsonKey(name: 'valid') required bool valid,
    @JsonKey(name: 'submitted_at') required DateTime submittedAt,
    @JsonKey(name: 'score') required SubmissionScoreDto score,
  }) = _SubmissionSummaryDto;

  factory SubmissionSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$SubmissionSummaryDtoFromJson(json);
}

@freezed
abstract class SubmitForApprovalRequest with _$SubmitForApprovalRequest {
  @JsonSerializable(explicitToJson: true)
  const factory SubmitForApprovalRequest({
    @JsonKey(name: 'note') String? note,
  }) = _SubmitForApprovalRequest;

  factory SubmitForApprovalRequest.fromJson(Map<String, dynamic> json) =>
      _$SubmitForApprovalRequestFromJson(json);
}

@freezed
abstract class SubordinateUserDto with _$SubordinateUserDto {
  @JsonSerializable(explicitToJson: true)
  const factory SubordinateUserDto({
    @JsonKey(name: 'user') required UserSummaryDto user,
    @JsonKey(name: 'relationship_type') required String relationshipType,
    @JsonKey(name: 'depth') required int depth,
  }) = _SubordinateUserDto;

  factory SubordinateUserDto.fromJson(Map<String, dynamic> json) =>
      _$SubordinateUserDtoFromJson(json);
}

@freezed
abstract class UpdateActivityRequest with _$UpdateActivityRequest {
  @JsonSerializable(explicitToJson: true)
  const factory UpdateActivityRequest({
    @JsonKey(name: 'title') String? title,
    @JsonKey(name: 'description') String? description,
    @NullableActivityStatusJsonConverter()
    @JsonKey(name: 'status')
    ActivityStatus? status,
    @JsonKey(name: 'assigned_to_user_id') String? assignedToUserId,
    @JsonKey(name: 'due_at') DateTime? dueAt,
    @JsonKey(name: 'metadata') Object? metadata,
  }) = _UpdateActivityRequest;

  factory UpdateActivityRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateActivityRequestFromJson(json);
}

@freezed
abstract class UpdateActivityRuleRequest with _$UpdateActivityRuleRequest {
  @JsonSerializable(explicitToJson: true)
  const factory UpdateActivityRuleRequest({
    @NullableActivityTriggerTypeJsonConverter()
    @JsonKey(name: 'trigger_type')
    ActivityTriggerType? triggerType,
    @JsonKey(name: 'condition') Object? condition,
    @NullableActivityActionTypeJsonConverter()
    @JsonKey(name: 'action_type')
    ActivityActionType? actionType,
    @JsonKey(name: 'action_config') Object? actionConfig,
    @JsonKey(name: 'enabled') bool? enabled,
  }) = _UpdateActivityRuleRequest;

  factory UpdateActivityRuleRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateActivityRuleRequestFromJson(json);
}

@freezed
abstract class UpdateFieldTypePermissionsRequest
    with _$UpdateFieldTypePermissionsRequest {
  @JsonSerializable(explicitToJson: true)
  const factory UpdateFieldTypePermissionsRequest({
    @JsonKey(name: 'permissions')
    required List<FieldTypePermissionDto> permissions,
  }) = _UpdateFieldTypePermissionsRequest;

  factory UpdateFieldTypePermissionsRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$UpdateFieldTypePermissionsRequestFromJson(json);
}

@freezed
abstract class UpdateFormFieldRequest with _$UpdateFormFieldRequest {
  @JsonSerializable(explicitToJson: true)
  const factory UpdateFormFieldRequest({
    @NullableFieldTypeJsonConverter() @JsonKey(name: 'type') FieldType? type,
    @JsonKey(name: 'label') String? label,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'placeholder') String? placeholder,
    @JsonKey(name: 'required') bool? isRequired,
    @JsonKey(name: 'order_index') int? orderIndex,
    @JsonKey(name: 'config') FieldConfigDto? config,
    @JsonKey(name: 'validation') FieldValidationDto? validation,
    @JsonKey(name: 'visibility_conditions')
    List<ConditionalLogicRuleDto>? visibilityConditions,
    @JsonKey(name: 'scoring_config') FieldScoringConfigDto? scoringConfig,
    @JsonKey(name: 'permissions') FieldPermissionConfigDto? permissions,
  }) = _UpdateFormFieldRequest;

  factory UpdateFormFieldRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateFormFieldRequestFromJson(json);
}

@freezed
abstract class UpdateFormRequest with _$UpdateFormRequest {
  @JsonSerializable(explicitToJson: true)
  const factory UpdateFormRequest({
    @JsonKey(name: 'title') String? title,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'category') String? category,
    @JsonKey(name: 'tags') List<String>? tags,
    @JsonKey(name: 'settings') FormSettingsDto? settings,
    @JsonKey(name: 'visibility') FormVisibilityDto? visibility,
    @NullableScoringModeJsonConverter()
    @JsonKey(name: 'scoring_mode')
    ScoringMode? scoringMode,
    @JsonKey(name: 'scoring_config') Object? scoringConfig,
  }) = _UpdateFormRequest;

  factory UpdateFormRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateFormRequestFromJson(json);
}

@freezed
abstract class UpdateFormVisibilityRequest with _$UpdateFormVisibilityRequest {
  @JsonSerializable(explicitToJson: true)
  const factory UpdateFormVisibilityRequest({
    @JsonKey(name: 'visibility') required FormVisibilityDto visibility,
  }) = _UpdateFormVisibilityRequest;

  factory UpdateFormVisibilityRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateFormVisibilityRequestFromJson(json);
}

@freezed
abstract class UpdatePublicProtectionRequest
    with _$UpdatePublicProtectionRequest {
  @JsonSerializable(explicitToJson: true)
  const factory UpdatePublicProtectionRequest({
    @JsonKey(name: 'public_protection')
    required PublicProtectionSettingsDto publicProtection,
    @JsonKey(name: 'reason') String? reason,
  }) = _UpdatePublicProtectionRequest;

  factory UpdatePublicProtectionRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdatePublicProtectionRequestFromJson(json);
}

@freezed
abstract class UpdatePublishingRulesRequest
    with _$UpdatePublishingRulesRequest {
  @JsonSerializable(explicitToJson: true)
  const factory UpdatePublishingRulesRequest({
    @JsonKey(name: 'rules') required List<PublishingRuleDto> rules,
  }) = _UpdatePublishingRulesRequest;

  factory UpdatePublishingRulesRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdatePublishingRulesRequestFromJson(json);
}

@freezed
abstract class UpdateResultDto with _$UpdateResultDto {
  @JsonSerializable(explicitToJson: true)
  const factory UpdateResultDto({
    @JsonKey(name: 'updated') required bool updated,
  }) = _UpdateResultDto;

  factory UpdateResultDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateResultDtoFromJson(json);
}

@freezed
abstract class UpdateRoleRulesRequest with _$UpdateRoleRulesRequest {
  @JsonSerializable(explicitToJson: true)
  const factory UpdateRoleRulesRequest({
    @JsonKey(name: 'rules') required List<RoleRuleDto> rules,
  }) = _UpdateRoleRulesRequest;

  factory UpdateRoleRulesRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateRoleRulesRequestFromJson(json);
}

@freezed
abstract class UpdateScoreTemplateRequest with _$UpdateScoreTemplateRequest {
  @JsonSerializable(explicitToJson: true)
  const factory UpdateScoreTemplateRequest({
    @NullableFieldTypeJsonConverter()
    @JsonKey(name: 'field_type')
    FieldType? fieldType,
    @NullableScoringModeJsonConverter()
    @JsonKey(name: 'scoring_mode')
    ScoringMode? scoringMode,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'config') Object? config,
    @JsonKey(name: 'is_default') bool? isDefault,
  }) = _UpdateScoreTemplateRequest;

  factory UpdateScoreTemplateRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateScoreTemplateRequestFromJson(json);
}

@freezed
abstract class UpdateSubmissionRequest with _$UpdateSubmissionRequest {
  @JsonSerializable(explicitToJson: true)
  const factory UpdateSubmissionRequest({
    @JsonKey(name: 'answers') required List<AnswerInputDto> answers,
  }) = _UpdateSubmissionRequest;

  factory UpdateSubmissionRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateSubmissionRequestFromJson(json);
}

@freezed
abstract class UpdateUserProfileRequest with _$UpdateUserProfileRequest {
  @JsonSerializable(explicitToJson: true)
  const factory UpdateUserProfileRequest({
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'email') String? email,
    @JsonKey(name: 'gender') String? gender,
    @JsonKey(name: 'profile') UserProfileDto? profile,
  }) = _UpdateUserProfileRequest;

  factory UpdateUserProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserProfileRequestFromJson(json);
}

@freezed
abstract class UserDetailDto with _$UserDetailDto {
  @JsonSerializable(explicitToJson: true)
  const factory UserDetailDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'organization_id') String? organizationId,
    @JsonKey(name: 'phone') required String phone,
    @JsonKey(name: 'email') String? email,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'gender') String? gender,
    @UserRoleJsonConverter()
    @JsonKey(name: 'primary_role')
    required UserRole primaryRole,
    @JsonKey(name: 'profile') required UserProfileDto profile,
    @JsonKey(name: 'status') required String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _UserDetailDto;

  factory UserDetailDto.fromJson(Map<String, dynamic> json) =>
      _$UserDetailDtoFromJson(json);
}

@freezed
abstract class UserProfileDto with _$UserProfileDto {
  @JsonSerializable(explicitToJson: true)
  const factory UserProfileDto({
    @JsonKey(name: 'phone') String? phone,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'locale') String? locale,
    @JsonKey(name: 'timezone') String? timezone,
    @JsonKey(name: 'metadata') Object? metadata,
  }) = _UserProfileDto;

  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);
}

@freezed
abstract class UserRelationshipDto with _$UserRelationshipDto {
  @JsonSerializable(explicitToJson: true)
  const factory UserRelationshipDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'organization_id') required String organizationId,
    @JsonKey(name: 'parent_user_id') required String parentUserId,
    @JsonKey(name: 'child_user_id') required String childUserId,
    @JsonKey(name: 'relationship_type') required String relationshipType,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _UserRelationshipDto;

  factory UserRelationshipDto.fromJson(Map<String, dynamic> json) =>
      _$UserRelationshipDtoFromJson(json);
}

@freezed
abstract class UserSummaryDto with _$UserSummaryDto {
  @JsonSerializable(explicitToJson: true)
  const factory UserSummaryDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'organization_id') String? organizationId,
    @JsonKey(name: 'phone') required String phone,
    @JsonKey(name: 'email') String? email,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'gender') String? gender,
    @UserRoleJsonConverter()
    @JsonKey(name: 'primary_role')
    required UserRole primaryRole,
    @JsonKey(name: 'status') required String status,
  }) = _UserSummaryDto;

  factory UserSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$UserSummaryDtoFromJson(json);
}

@freezed
abstract class ValidatePublicFormAccessRequest
    with _$ValidatePublicFormAccessRequest {
  @JsonSerializable(explicitToJson: true)
  const factory ValidatePublicFormAccessRequest({
    @JsonKey(name: 'respondent_mode') String? respondentMode,
    @JsonKey(name: 'form_password') String? formPassword,
    @JsonKey(name: 'identity_code') String? identityCode,
    @JsonKey(name: 'fingerprint_token') String? fingerprintToken,
    @JsonKey(name: 'captcha_token') String? captchaToken,
    @JsonKey(name: 'email_verification_token') String? emailVerificationToken,
    @JsonKey(name: 'phone_verification_token') String? phoneVerificationToken,
  }) = _ValidatePublicFormAccessRequest;

  factory ValidatePublicFormAccessRequest.fromJson(Map<String, dynamic> json) =>
      _$ValidatePublicFormAccessRequestFromJson(json);
}

@freezed
abstract class ValidatePublicFormAccessResponse
    with _$ValidatePublicFormAccessResponse {
  @JsonSerializable(explicitToJson: true)
  const factory ValidatePublicFormAccessResponse({
    @JsonKey(name: 'allowed') required bool allowed,
    @JsonKey(name: 'reason') String? reason,
    @JsonKey(name: 'access_token') String? accessToken,
    @JsonKey(name: 'respondent_mode') String? respondentMode,
    @JsonKey(name: 'identity_label') String? identityLabel,
    @JsonKey(name: 'rate_limit') required PublicRateLimitStatusDto rateLimit,
  }) = _ValidatePublicFormAccessResponse;

  factory ValidatePublicFormAccessResponse.fromJson(
    Map<String, dynamic> json,
  ) => _$ValidatePublicFormAccessResponseFromJson(json);
}
