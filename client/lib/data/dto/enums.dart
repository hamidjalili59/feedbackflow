// GENERATED FROM openapi.json. Do not edit by hand.
import 'package:json_annotation/json_annotation.dart';

enum ActivityActionType {
  createActivity('create_activity'),
  notifyUser('notify_user'),
  notifyManager('notify_manager'),
  sendEmail('send_email'),
  sendWebhook('send_webhook'),
  markSubmission('mark_submission'),
  assignFollowUp('assign_follow_up'),
  unknown('__unknown__');

  const ActivityActionType(this.wireValue);
  final String wireValue;

  static ActivityActionType fromJson(Object? value) {
    final wire = value is String ? value : null;
    return ActivityActionTypeWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class ActivityActionTypeWire {
  static const unknown = ActivityActionType.unknown;
  static const Map<String, ActivityActionType> _byWire =
      <String, ActivityActionType>{
        'create_activity': ActivityActionType.createActivity,
        'notify_user': ActivityActionType.notifyUser,
        'notify_manager': ActivityActionType.notifyManager,
        'send_email': ActivityActionType.sendEmail,
        'send_webhook': ActivityActionType.sendWebhook,
        'mark_submission': ActivityActionType.markSubmission,
        'assign_follow_up': ActivityActionType.assignFollowUp,
      };

  static ActivityActionType fromJson(Object? value) => value is String
      ? (_byWire[value] ?? ActivityActionType.unknown)
      : ActivityActionType.unknown;

  static String toJson(ActivityActionType value) => value.wireValue;
}

class ActivityActionTypeJsonConverter
    implements JsonConverter<ActivityActionType, Object?> {
  const ActivityActionTypeJsonConverter();

  @override
  ActivityActionType fromJson(Object? json) =>
      ActivityActionType.fromJson(json);

  @override
  Object? toJson(ActivityActionType object) => object.toJson();
}

class NullableActivityActionTypeJsonConverter
    implements JsonConverter<ActivityActionType?, Object?> {
  const NullableActivityActionTypeJsonConverter();

  @override
  ActivityActionType? fromJson(Object? json) =>
      json == null ? null : ActivityActionType.fromJson(json);

  @override
  Object? toJson(ActivityActionType? object) => object?.toJson();
}

class ActivityActionTypeListJsonConverter
    implements JsonConverter<List<ActivityActionType>, Object?> {
  const ActivityActionTypeListJsonConverter();

  @override
  List<ActivityActionType> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(ActivityActionType.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<ActivityActionType> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableActivityActionTypeListJsonConverter
    implements JsonConverter<List<ActivityActionType>?, Object?> {
  const NullableActivityActionTypeListJsonConverter();

  @override
  List<ActivityActionType>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(ActivityActionType.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<ActivityActionType>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum ActivityStatus {
  open('open'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled'),
  unknown('__unknown__');

  const ActivityStatus(this.wireValue);
  final String wireValue;

  static ActivityStatus fromJson(Object? value) {
    final wire = value is String ? value : null;
    return ActivityStatusWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class ActivityStatusWire {
  static const unknown = ActivityStatus.unknown;
  static const Map<String, ActivityStatus> _byWire = <String, ActivityStatus>{
    'open': ActivityStatus.open,
    'in_progress': ActivityStatus.inProgress,
    'completed': ActivityStatus.completed,
    'cancelled': ActivityStatus.cancelled,
  };

  static ActivityStatus fromJson(Object? value) => value is String
      ? (_byWire[value] ?? ActivityStatus.unknown)
      : ActivityStatus.unknown;

  static String toJson(ActivityStatus value) => value.wireValue;
}

class ActivityStatusJsonConverter
    implements JsonConverter<ActivityStatus, Object?> {
  const ActivityStatusJsonConverter();

  @override
  ActivityStatus fromJson(Object? json) => ActivityStatus.fromJson(json);

  @override
  Object? toJson(ActivityStatus object) => object.toJson();
}

class NullableActivityStatusJsonConverter
    implements JsonConverter<ActivityStatus?, Object?> {
  const NullableActivityStatusJsonConverter();

  @override
  ActivityStatus? fromJson(Object? json) =>
      json == null ? null : ActivityStatus.fromJson(json);

  @override
  Object? toJson(ActivityStatus? object) => object?.toJson();
}

class ActivityStatusListJsonConverter
    implements JsonConverter<List<ActivityStatus>, Object?> {
  const ActivityStatusListJsonConverter();

  @override
  List<ActivityStatus> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(ActivityStatus.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<ActivityStatus> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableActivityStatusListJsonConverter
    implements JsonConverter<List<ActivityStatus>?, Object?> {
  const NullableActivityStatusListJsonConverter();

  @override
  List<ActivityStatus>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(ActivityStatus.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<ActivityStatus>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum ActivityTriggerType {
  submissionCreated('submission_created'),
  scoreAbove('score_above'),
  scoreBelow('score_below'),
  answerEquals('answer_equals'),
  answerContains('answer_contains'),
  npsLow('nps_low'),
  npsHigh('nps_high'),
  submissionCountReached('submission_count_reached'),
  formClosed('form_closed'),
  unknown('__unknown__');

  const ActivityTriggerType(this.wireValue);
  final String wireValue;

  static ActivityTriggerType fromJson(Object? value) {
    final wire = value is String ? value : null;
    return ActivityTriggerTypeWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class ActivityTriggerTypeWire {
  static const unknown = ActivityTriggerType.unknown;
  static const Map<String, ActivityTriggerType> _byWire =
      <String, ActivityTriggerType>{
        'submission_created': ActivityTriggerType.submissionCreated,
        'score_above': ActivityTriggerType.scoreAbove,
        'score_below': ActivityTriggerType.scoreBelow,
        'answer_equals': ActivityTriggerType.answerEquals,
        'answer_contains': ActivityTriggerType.answerContains,
        'nps_low': ActivityTriggerType.npsLow,
        'nps_high': ActivityTriggerType.npsHigh,
        'submission_count_reached': ActivityTriggerType.submissionCountReached,
        'form_closed': ActivityTriggerType.formClosed,
      };

  static ActivityTriggerType fromJson(Object? value) => value is String
      ? (_byWire[value] ?? ActivityTriggerType.unknown)
      : ActivityTriggerType.unknown;

  static String toJson(ActivityTriggerType value) => value.wireValue;
}

class ActivityTriggerTypeJsonConverter
    implements JsonConverter<ActivityTriggerType, Object?> {
  const ActivityTriggerTypeJsonConverter();

  @override
  ActivityTriggerType fromJson(Object? json) =>
      ActivityTriggerType.fromJson(json);

  @override
  Object? toJson(ActivityTriggerType object) => object.toJson();
}

class NullableActivityTriggerTypeJsonConverter
    implements JsonConverter<ActivityTriggerType?, Object?> {
  const NullableActivityTriggerTypeJsonConverter();

  @override
  ActivityTriggerType? fromJson(Object? json) =>
      json == null ? null : ActivityTriggerType.fromJson(json);

  @override
  Object? toJson(ActivityTriggerType? object) => object?.toJson();
}

class ActivityTriggerTypeListJsonConverter
    implements JsonConverter<List<ActivityTriggerType>, Object?> {
  const ActivityTriggerTypeListJsonConverter();

  @override
  List<ActivityTriggerType> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(ActivityTriggerType.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<ActivityTriggerType> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableActivityTriggerTypeListJsonConverter
    implements JsonConverter<List<ActivityTriggerType>?, Object?> {
  const NullableActivityTriggerTypeListJsonConverter();

  @override
  List<ActivityTriggerType>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(ActivityTriggerType.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<ActivityTriggerType>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum AnswerVisibility {
  visibleToCreator('visible_to_creator'),
  visibleToAdmin('visible_to_admin'),
  visibleToManager('visible_to_manager'),
  anonymous('anonymous'),
  private('private'),
  unknown('__unknown__');

  const AnswerVisibility(this.wireValue);
  final String wireValue;

  static AnswerVisibility fromJson(Object? value) {
    final wire = value is String ? value : null;
    return AnswerVisibilityWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class AnswerVisibilityWire {
  static const unknown = AnswerVisibility.unknown;
  static const Map<String, AnswerVisibility> _byWire =
      <String, AnswerVisibility>{
        'visible_to_creator': AnswerVisibility.visibleToCreator,
        'visible_to_admin': AnswerVisibility.visibleToAdmin,
        'visible_to_manager': AnswerVisibility.visibleToManager,
        'anonymous': AnswerVisibility.anonymous,
        'private': AnswerVisibility.private,
      };

  static AnswerVisibility fromJson(Object? value) => value is String
      ? (_byWire[value] ?? AnswerVisibility.unknown)
      : AnswerVisibility.unknown;

  static String toJson(AnswerVisibility value) => value.wireValue;
}

class AnswerVisibilityJsonConverter
    implements JsonConverter<AnswerVisibility, Object?> {
  const AnswerVisibilityJsonConverter();

  @override
  AnswerVisibility fromJson(Object? json) => AnswerVisibility.fromJson(json);

  @override
  Object? toJson(AnswerVisibility object) => object.toJson();
}

class NullableAnswerVisibilityJsonConverter
    implements JsonConverter<AnswerVisibility?, Object?> {
  const NullableAnswerVisibilityJsonConverter();

  @override
  AnswerVisibility? fromJson(Object? json) =>
      json == null ? null : AnswerVisibility.fromJson(json);

  @override
  Object? toJson(AnswerVisibility? object) => object?.toJson();
}

class AnswerVisibilityListJsonConverter
    implements JsonConverter<List<AnswerVisibility>, Object?> {
  const AnswerVisibilityListJsonConverter();

  @override
  List<AnswerVisibility> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(AnswerVisibility.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<AnswerVisibility> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableAnswerVisibilityListJsonConverter
    implements JsonConverter<List<AnswerVisibility>?, Object?> {
  const NullableAnswerVisibilityListJsonConverter();

  @override
  List<AnswerVisibility>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(AnswerVisibility.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<AnswerVisibility>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum ApprovalStatus {
  notRequired('not_required'),
  requiredValue('required'),
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  cancelled('cancelled'),
  unknown('__unknown__');

  const ApprovalStatus(this.wireValue);
  final String wireValue;

  static ApprovalStatus fromJson(Object? value) {
    final wire = value is String ? value : null;
    return ApprovalStatusWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class ApprovalStatusWire {
  static const unknown = ApprovalStatus.unknown;
  static const Map<String, ApprovalStatus> _byWire = <String, ApprovalStatus>{
    'not_required': ApprovalStatus.notRequired,
    'required': ApprovalStatus.requiredValue,
    'pending': ApprovalStatus.pending,
    'approved': ApprovalStatus.approved,
    'rejected': ApprovalStatus.rejected,
    'cancelled': ApprovalStatus.cancelled,
  };

  static ApprovalStatus fromJson(Object? value) => value is String
      ? (_byWire[value] ?? ApprovalStatus.unknown)
      : ApprovalStatus.unknown;

  static String toJson(ApprovalStatus value) => value.wireValue;
}

class ApprovalStatusJsonConverter
    implements JsonConverter<ApprovalStatus, Object?> {
  const ApprovalStatusJsonConverter();

  @override
  ApprovalStatus fromJson(Object? json) => ApprovalStatus.fromJson(json);

  @override
  Object? toJson(ApprovalStatus object) => object.toJson();
}

class NullableApprovalStatusJsonConverter
    implements JsonConverter<ApprovalStatus?, Object?> {
  const NullableApprovalStatusJsonConverter();

  @override
  ApprovalStatus? fromJson(Object? json) =>
      json == null ? null : ApprovalStatus.fromJson(json);

  @override
  Object? toJson(ApprovalStatus? object) => object?.toJson();
}

class ApprovalStatusListJsonConverter
    implements JsonConverter<List<ApprovalStatus>, Object?> {
  const ApprovalStatusListJsonConverter();

  @override
  List<ApprovalStatus> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(ApprovalStatus.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<ApprovalStatus> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableApprovalStatusListJsonConverter
    implements JsonConverter<List<ApprovalStatus>?, Object?> {
  const NullableApprovalStatusListJsonConverter();

  @override
  List<ApprovalStatus>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(ApprovalStatus.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<ApprovalStatus>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum AuditAction {
  created('created'),
  updated('updated'),
  deleted('deleted'),
  published('published'),
  submittedForApproval('submitted_for_approval'),
  approved('approved'),
  rejected('rejected'),
  closed('closed'),
  archived('archived'),
  permissionChanged('permission_changed'),
  publicProtectionDisabled('public_protection_disabled'),
  login('login'),
  logout('logout'),
  submissionCreated('submission_created'),
  unknown('__unknown__');

  const AuditAction(this.wireValue);
  final String wireValue;

  static AuditAction fromJson(Object? value) {
    final wire = value is String ? value : null;
    return AuditActionWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class AuditActionWire {
  static const unknown = AuditAction.unknown;
  static const Map<String, AuditAction> _byWire = <String, AuditAction>{
    'created': AuditAction.created,
    'updated': AuditAction.updated,
    'deleted': AuditAction.deleted,
    'published': AuditAction.published,
    'submitted_for_approval': AuditAction.submittedForApproval,
    'approved': AuditAction.approved,
    'rejected': AuditAction.rejected,
    'closed': AuditAction.closed,
    'archived': AuditAction.archived,
    'permission_changed': AuditAction.permissionChanged,
    'public_protection_disabled': AuditAction.publicProtectionDisabled,
    'login': AuditAction.login,
    'logout': AuditAction.logout,
    'submission_created': AuditAction.submissionCreated,
  };

  static AuditAction fromJson(Object? value) => value is String
      ? (_byWire[value] ?? AuditAction.unknown)
      : AuditAction.unknown;

  static String toJson(AuditAction value) => value.wireValue;
}

class AuditActionJsonConverter implements JsonConverter<AuditAction, Object?> {
  const AuditActionJsonConverter();

  @override
  AuditAction fromJson(Object? json) => AuditAction.fromJson(json);

  @override
  Object? toJson(AuditAction object) => object.toJson();
}

class NullableAuditActionJsonConverter
    implements JsonConverter<AuditAction?, Object?> {
  const NullableAuditActionJsonConverter();

  @override
  AuditAction? fromJson(Object? json) =>
      json == null ? null : AuditAction.fromJson(json);

  @override
  Object? toJson(AuditAction? object) => object?.toJson();
}

class AuditActionListJsonConverter
    implements JsonConverter<List<AuditAction>, Object?> {
  const AuditActionListJsonConverter();

  @override
  List<AuditAction> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(AuditAction.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<AuditAction> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableAuditActionListJsonConverter
    implements JsonConverter<List<AuditAction>?, Object?> {
  const NullableAuditActionListJsonConverter();

  @override
  List<AuditAction>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(AuditAction.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<AuditAction>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum ErrorCode {
  unauthorized('UNAUTHORIZED'),
  forbidden('FORBIDDEN'),
  permissionDenied('PERMISSION_DENIED'),
  validationError('VALIDATION_ERROR'),
  notFound('NOT_FOUND'),
  conflict('CONFLICT'),
  rateLimited('RATE_LIMITED'),
  formClosed('FORM_CLOSED'),
  formNotPublished('FORM_NOT_PUBLISHED'),
  approvalRequired('APPROVAL_REQUIRED'),
  publicProtectionRequired('PUBLIC_PROTECTION_REQUIRED'),
  publicAccessDenied('PUBLIC_ACCESS_DENIED'),
  invalidToken('INVALID_TOKEN'),
  tokenExpired('TOKEN_EXPIRED'),
  internalServerError('INTERNAL_SERVER_ERROR'),
  serviceUnavailable('SERVICE_UNAVAILABLE'),
  unknown('__unknown__');

  const ErrorCode(this.wireValue);
  final String wireValue;

  static ErrorCode fromJson(Object? value) {
    final wire = value is String ? value : null;
    return ErrorCodeWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class ErrorCodeWire {
  static const unknown = ErrorCode.unknown;
  static const Map<String, ErrorCode> _byWire = <String, ErrorCode>{
    'UNAUTHORIZED': ErrorCode.unauthorized,
    'FORBIDDEN': ErrorCode.forbidden,
    'PERMISSION_DENIED': ErrorCode.permissionDenied,
    'VALIDATION_ERROR': ErrorCode.validationError,
    'NOT_FOUND': ErrorCode.notFound,
    'CONFLICT': ErrorCode.conflict,
    'RATE_LIMITED': ErrorCode.rateLimited,
    'FORM_CLOSED': ErrorCode.formClosed,
    'FORM_NOT_PUBLISHED': ErrorCode.formNotPublished,
    'APPROVAL_REQUIRED': ErrorCode.approvalRequired,
    'PUBLIC_PROTECTION_REQUIRED': ErrorCode.publicProtectionRequired,
    'PUBLIC_ACCESS_DENIED': ErrorCode.publicAccessDenied,
    'INVALID_TOKEN': ErrorCode.invalidToken,
    'TOKEN_EXPIRED': ErrorCode.tokenExpired,
    'INTERNAL_SERVER_ERROR': ErrorCode.internalServerError,
    'SERVICE_UNAVAILABLE': ErrorCode.serviceUnavailable,
  };

  static ErrorCode fromJson(Object? value) => value is String
      ? (_byWire[value] ?? ErrorCode.unknown)
      : ErrorCode.unknown;

  static String toJson(ErrorCode value) => value.wireValue;
}

class ErrorCodeJsonConverter implements JsonConverter<ErrorCode, Object?> {
  const ErrorCodeJsonConverter();

  @override
  ErrorCode fromJson(Object? json) => ErrorCode.fromJson(json);

  @override
  Object? toJson(ErrorCode object) => object.toJson();
}

class NullableErrorCodeJsonConverter
    implements JsonConverter<ErrorCode?, Object?> {
  const NullableErrorCodeJsonConverter();

  @override
  ErrorCode? fromJson(Object? json) =>
      json == null ? null : ErrorCode.fromJson(json);

  @override
  Object? toJson(ErrorCode? object) => object?.toJson();
}

class ErrorCodeListJsonConverter
    implements JsonConverter<List<ErrorCode>, Object?> {
  const ErrorCodeListJsonConverter();

  @override
  List<ErrorCode> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(ErrorCode.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<ErrorCode> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableErrorCodeListJsonConverter
    implements JsonConverter<List<ErrorCode>?, Object?> {
  const NullableErrorCodeListJsonConverter();

  @override
  List<ErrorCode>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(ErrorCode.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<ErrorCode>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum FieldType {
  shortText('short_text'),
  longText('long_text'),
  email('email'),
  phone('phone'),
  number('number'),
  decimal('decimal'),
  date('date'),
  time('time'),
  dateTime('date_time'),
  singleChoice('single_choice'),
  multipleChoice('multiple_choice'),
  dropdown('dropdown'),
  ratingStars('rating_stars'),
  numericRating('numeric_rating'),
  slider('slider'),
  likertScale('likert_scale'),
  matrixSingleChoice('matrix_single_choice'),
  matrixMultipleChoice('matrix_multiple_choice'),
  yesNo('yes_no'),
  booleanSwitch('boolean_switch'),
  nps('nps'),
  emojiReaction('emoji_reaction'),
  fileUpload('file_upload'),
  imageUpload('image_upload'),
  signature('signature'),
  location('location'),
  ranking('ranking'),
  sectionTitle('section_title'),
  descriptionBlock('description_block'),
  divider('divider'),
  consentCheckbox('consent_checkbox'),
  termsAcceptance('terms_acceptance'),
  hidden('hidden'),
  calculated('calculated'),
  conditionalLogic('conditional_logic'),
  scoreDisplay('score_display'),
  quizQuestion('quiz_question'),
  pageBreak('page_break'),
  unknown('__unknown__');

  const FieldType(this.wireValue);
  final String wireValue;

  static FieldType fromJson(Object? value) {
    final wire = value is String ? value : null;
    return FieldTypeWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class FieldTypeWire {
  static const unknown = FieldType.unknown;
  static const Map<String, FieldType> _byWire = <String, FieldType>{
    'short_text': FieldType.shortText,
    'long_text': FieldType.longText,
    'email': FieldType.email,
    'phone': FieldType.phone,
    'number': FieldType.number,
    'decimal': FieldType.decimal,
    'date': FieldType.date,
    'time': FieldType.time,
    'date_time': FieldType.dateTime,
    'single_choice': FieldType.singleChoice,
    'multiple_choice': FieldType.multipleChoice,
    'dropdown': FieldType.dropdown,
    'rating_stars': FieldType.ratingStars,
    'numeric_rating': FieldType.numericRating,
    'slider': FieldType.slider,
    'likert_scale': FieldType.likertScale,
    'matrix_single_choice': FieldType.matrixSingleChoice,
    'matrix_multiple_choice': FieldType.matrixMultipleChoice,
    'yes_no': FieldType.yesNo,
    'boolean_switch': FieldType.booleanSwitch,
    'nps': FieldType.nps,
    'emoji_reaction': FieldType.emojiReaction,
    'file_upload': FieldType.fileUpload,
    'image_upload': FieldType.imageUpload,
    'signature': FieldType.signature,
    'location': FieldType.location,
    'ranking': FieldType.ranking,
    'section_title': FieldType.sectionTitle,
    'description_block': FieldType.descriptionBlock,
    'divider': FieldType.divider,
    'consent_checkbox': FieldType.consentCheckbox,
    'terms_acceptance': FieldType.termsAcceptance,
    'hidden': FieldType.hidden,
    'calculated': FieldType.calculated,
    'conditional_logic': FieldType.conditionalLogic,
    'score_display': FieldType.scoreDisplay,
    'quiz_question': FieldType.quizQuestion,
    'page_break': FieldType.pageBreak,
  };

  static FieldType fromJson(Object? value) => value is String
      ? (_byWire[value] ?? FieldType.unknown)
      : FieldType.unknown;

  static String toJson(FieldType value) => value.wireValue;
}

class FieldTypeJsonConverter implements JsonConverter<FieldType, Object?> {
  const FieldTypeJsonConverter();

  @override
  FieldType fromJson(Object? json) => FieldType.fromJson(json);

  @override
  Object? toJson(FieldType object) => object.toJson();
}

class NullableFieldTypeJsonConverter
    implements JsonConverter<FieldType?, Object?> {
  const NullableFieldTypeJsonConverter();

  @override
  FieldType? fromJson(Object? json) =>
      json == null ? null : FieldType.fromJson(json);

  @override
  Object? toJson(FieldType? object) => object?.toJson();
}

class FieldTypeListJsonConverter
    implements JsonConverter<List<FieldType>, Object?> {
  const FieldTypeListJsonConverter();

  @override
  List<FieldType> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(FieldType.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<FieldType> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableFieldTypeListJsonConverter
    implements JsonConverter<List<FieldType>?, Object?> {
  const NullableFieldTypeListJsonConverter();

  @override
  List<FieldType>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(FieldType.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<FieldType>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum FormAudienceType {
  user('user'),
  role('role'),
  group('group'),
  classValue('class'),
  department('department'),
  organization('organization'),
  public('public'),
  unknown('__unknown__');

  const FormAudienceType(this.wireValue);
  final String wireValue;

  static FormAudienceType fromJson(Object? value) {
    final wire = value is String ? value : null;
    return FormAudienceTypeWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class FormAudienceTypeWire {
  static const unknown = FormAudienceType.unknown;
  static const Map<String, FormAudienceType> _byWire =
      <String, FormAudienceType>{
        'user': FormAudienceType.user,
        'role': FormAudienceType.role,
        'group': FormAudienceType.group,
        'class': FormAudienceType.classValue,
        'department': FormAudienceType.department,
        'organization': FormAudienceType.organization,
        'public': FormAudienceType.public,
      };

  static FormAudienceType fromJson(Object? value) => value is String
      ? (_byWire[value] ?? FormAudienceType.unknown)
      : FormAudienceType.unknown;

  static String toJson(FormAudienceType value) => value.wireValue;
}

class FormAudienceTypeJsonConverter
    implements JsonConverter<FormAudienceType, Object?> {
  const FormAudienceTypeJsonConverter();

  @override
  FormAudienceType fromJson(Object? json) => FormAudienceType.fromJson(json);

  @override
  Object? toJson(FormAudienceType object) => object.toJson();
}

class NullableFormAudienceTypeJsonConverter
    implements JsonConverter<FormAudienceType?, Object?> {
  const NullableFormAudienceTypeJsonConverter();

  @override
  FormAudienceType? fromJson(Object? json) =>
      json == null ? null : FormAudienceType.fromJson(json);

  @override
  Object? toJson(FormAudienceType? object) => object?.toJson();
}

class FormAudienceTypeListJsonConverter
    implements JsonConverter<List<FormAudienceType>, Object?> {
  const FormAudienceTypeListJsonConverter();

  @override
  List<FormAudienceType> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(FormAudienceType.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<FormAudienceType> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableFormAudienceTypeListJsonConverter
    implements JsonConverter<List<FormAudienceType>?, Object?> {
  const NullableFormAudienceTypeListJsonConverter();

  @override
  List<FormAudienceType>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(FormAudienceType.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<FormAudienceType>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum FormStatus {
  draft('draft'),
  pendingReview('pending_review'),
  rejected('rejected'),
  approved('approved'),
  scheduled('scheduled'),
  published('published'),
  closed('closed'),
  archived('archived'),
  unknown('__unknown__');

  const FormStatus(this.wireValue);
  final String wireValue;

  static FormStatus fromJson(Object? value) {
    final wire = value is String ? value : null;
    return FormStatusWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class FormStatusWire {
  static const unknown = FormStatus.unknown;
  static const Map<String, FormStatus> _byWire = <String, FormStatus>{
    'draft': FormStatus.draft,
    'pending_review': FormStatus.pendingReview,
    'rejected': FormStatus.rejected,
    'approved': FormStatus.approved,
    'scheduled': FormStatus.scheduled,
    'published': FormStatus.published,
    'closed': FormStatus.closed,
    'archived': FormStatus.archived,
  };

  static FormStatus fromJson(Object? value) => value is String
      ? (_byWire[value] ?? FormStatus.unknown)
      : FormStatus.unknown;

  static String toJson(FormStatus value) => value.wireValue;
}

class FormStatusJsonConverter implements JsonConverter<FormStatus, Object?> {
  const FormStatusJsonConverter();

  @override
  FormStatus fromJson(Object? json) => FormStatus.fromJson(json);

  @override
  Object? toJson(FormStatus object) => object.toJson();
}

class NullableFormStatusJsonConverter
    implements JsonConverter<FormStatus?, Object?> {
  const NullableFormStatusJsonConverter();

  @override
  FormStatus? fromJson(Object? json) =>
      json == null ? null : FormStatus.fromJson(json);

  @override
  Object? toJson(FormStatus? object) => object?.toJson();
}

class FormStatusListJsonConverter
    implements JsonConverter<List<FormStatus>, Object?> {
  const FormStatusListJsonConverter();

  @override
  List<FormStatus> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(FormStatus.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<FormStatus> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableFormStatusListJsonConverter
    implements JsonConverter<List<FormStatus>?, Object?> {
  const NullableFormStatusListJsonConverter();

  @override
  List<FormStatus>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(FormStatus.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<FormStatus>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum PermissionAction {
  create('create'),
  read('read'),
  update('update'),
  delete('delete'),
  publish('publish'),
  approve('approve'),
  reject('reject'),
  answer('answer'),
  viewResults('view_results'),
  exportValue('export'),
  managePermissions('manage_permissions'),
  manageScoring('manage_scoring'),
  managePublicProtection('manage_public_protection'),
  unknown('__unknown__');

  const PermissionAction(this.wireValue);
  final String wireValue;

  static PermissionAction fromJson(Object? value) {
    final wire = value is String ? value : null;
    return PermissionActionWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class PermissionActionWire {
  static const unknown = PermissionAction.unknown;
  static const Map<String, PermissionAction> _byWire =
      <String, PermissionAction>{
        'create': PermissionAction.create,
        'read': PermissionAction.read,
        'update': PermissionAction.update,
        'delete': PermissionAction.delete,
        'publish': PermissionAction.publish,
        'approve': PermissionAction.approve,
        'reject': PermissionAction.reject,
        'answer': PermissionAction.answer,
        'view_results': PermissionAction.viewResults,
        'export': PermissionAction.exportValue,
        'manage_permissions': PermissionAction.managePermissions,
        'manage_scoring': PermissionAction.manageScoring,
        'manage_public_protection': PermissionAction.managePublicProtection,
      };

  static PermissionAction fromJson(Object? value) => value is String
      ? (_byWire[value] ?? PermissionAction.unknown)
      : PermissionAction.unknown;

  static String toJson(PermissionAction value) => value.wireValue;
}

class PermissionActionJsonConverter
    implements JsonConverter<PermissionAction, Object?> {
  const PermissionActionJsonConverter();

  @override
  PermissionAction fromJson(Object? json) => PermissionAction.fromJson(json);

  @override
  Object? toJson(PermissionAction object) => object.toJson();
}

class NullablePermissionActionJsonConverter
    implements JsonConverter<PermissionAction?, Object?> {
  const NullablePermissionActionJsonConverter();

  @override
  PermissionAction? fromJson(Object? json) =>
      json == null ? null : PermissionAction.fromJson(json);

  @override
  Object? toJson(PermissionAction? object) => object?.toJson();
}

class PermissionActionListJsonConverter
    implements JsonConverter<List<PermissionAction>, Object?> {
  const PermissionActionListJsonConverter();

  @override
  List<PermissionAction> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(PermissionAction.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<PermissionAction> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullablePermissionActionListJsonConverter
    implements JsonConverter<List<PermissionAction>?, Object?> {
  const NullablePermissionActionListJsonConverter();

  @override
  List<PermissionAction>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(PermissionAction.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<PermissionAction>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum PublicProtectionLevel {
  none('none'),
  basic('basic'),
  standard('standard'),
  strict('strict'),
  custom('custom'),
  unknown('__unknown__');

  const PublicProtectionLevel(this.wireValue);
  final String wireValue;

  static PublicProtectionLevel fromJson(Object? value) {
    final wire = value is String ? value : null;
    return PublicProtectionLevelWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class PublicProtectionLevelWire {
  static const unknown = PublicProtectionLevel.unknown;
  static const Map<String, PublicProtectionLevel> _byWire =
      <String, PublicProtectionLevel>{
        'none': PublicProtectionLevel.none,
        'basic': PublicProtectionLevel.basic,
        'standard': PublicProtectionLevel.standard,
        'strict': PublicProtectionLevel.strict,
        'custom': PublicProtectionLevel.custom,
      };

  static PublicProtectionLevel fromJson(Object? value) => value is String
      ? (_byWire[value] ?? PublicProtectionLevel.unknown)
      : PublicProtectionLevel.unknown;

  static String toJson(PublicProtectionLevel value) => value.wireValue;
}

class PublicProtectionLevelJsonConverter
    implements JsonConverter<PublicProtectionLevel, Object?> {
  const PublicProtectionLevelJsonConverter();

  @override
  PublicProtectionLevel fromJson(Object? json) =>
      PublicProtectionLevel.fromJson(json);

  @override
  Object? toJson(PublicProtectionLevel object) => object.toJson();
}

class NullablePublicProtectionLevelJsonConverter
    implements JsonConverter<PublicProtectionLevel?, Object?> {
  const NullablePublicProtectionLevelJsonConverter();

  @override
  PublicProtectionLevel? fromJson(Object? json) =>
      json == null ? null : PublicProtectionLevel.fromJson(json);

  @override
  Object? toJson(PublicProtectionLevel? object) => object?.toJson();
}

class PublicProtectionLevelListJsonConverter
    implements JsonConverter<List<PublicProtectionLevel>, Object?> {
  const PublicProtectionLevelListJsonConverter();

  @override
  List<PublicProtectionLevel> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(PublicProtectionLevel.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<PublicProtectionLevel> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullablePublicProtectionLevelListJsonConverter
    implements JsonConverter<List<PublicProtectionLevel>?, Object?> {
  const NullablePublicProtectionLevelListJsonConverter();

  @override
  List<PublicProtectionLevel>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(PublicProtectionLevel.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<PublicProtectionLevel>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum PublishMode {
  private('private'),
  organization('organization'),
  subordinates('subordinates'),
  roleBased('role_based'),
  publicLink('public_link'),
  unknown('__unknown__');

  const PublishMode(this.wireValue);
  final String wireValue;

  static PublishMode fromJson(Object? value) {
    final wire = value is String ? value : null;
    return PublishModeWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class PublishModeWire {
  static const unknown = PublishMode.unknown;
  static const Map<String, PublishMode> _byWire = <String, PublishMode>{
    'private': PublishMode.private,
    'organization': PublishMode.organization,
    'subordinates': PublishMode.subordinates,
    'role_based': PublishMode.roleBased,
    'public_link': PublishMode.publicLink,
  };

  static PublishMode fromJson(Object? value) => value is String
      ? (_byWire[value] ?? PublishMode.unknown)
      : PublishMode.unknown;

  static String toJson(PublishMode value) => value.wireValue;
}

class PublishModeJsonConverter implements JsonConverter<PublishMode, Object?> {
  const PublishModeJsonConverter();

  @override
  PublishMode fromJson(Object? json) => PublishMode.fromJson(json);

  @override
  Object? toJson(PublishMode object) => object.toJson();
}

class NullablePublishModeJsonConverter
    implements JsonConverter<PublishMode?, Object?> {
  const NullablePublishModeJsonConverter();

  @override
  PublishMode? fromJson(Object? json) =>
      json == null ? null : PublishMode.fromJson(json);

  @override
  Object? toJson(PublishMode? object) => object?.toJson();
}

class PublishModeListJsonConverter
    implements JsonConverter<List<PublishMode>, Object?> {
  const PublishModeListJsonConverter();

  @override
  List<PublishMode> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(PublishMode.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<PublishMode> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullablePublishModeListJsonConverter
    implements JsonConverter<List<PublishMode>?, Object?> {
  const NullablePublishModeListJsonConverter();

  @override
  List<PublishMode>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(PublishMode.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<PublishMode>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum RateLimitStrategy {
  ip('ip'),
  user('user'),
  token('token'),
  fingerprint('fingerprint'),
  captcha('captcha'),
  combined('combined'),
  unknown('__unknown__');

  const RateLimitStrategy(this.wireValue);
  final String wireValue;

  static RateLimitStrategy fromJson(Object? value) {
    final wire = value is String ? value : null;
    return RateLimitStrategyWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class RateLimitStrategyWire {
  static const unknown = RateLimitStrategy.unknown;
  static const Map<String, RateLimitStrategy> _byWire =
      <String, RateLimitStrategy>{
        'ip': RateLimitStrategy.ip,
        'user': RateLimitStrategy.user,
        'token': RateLimitStrategy.token,
        'fingerprint': RateLimitStrategy.fingerprint,
        'captcha': RateLimitStrategy.captcha,
        'combined': RateLimitStrategy.combined,
      };

  static RateLimitStrategy fromJson(Object? value) => value is String
      ? (_byWire[value] ?? RateLimitStrategy.unknown)
      : RateLimitStrategy.unknown;

  static String toJson(RateLimitStrategy value) => value.wireValue;
}

class RateLimitStrategyJsonConverter
    implements JsonConverter<RateLimitStrategy, Object?> {
  const RateLimitStrategyJsonConverter();

  @override
  RateLimitStrategy fromJson(Object? json) => RateLimitStrategy.fromJson(json);

  @override
  Object? toJson(RateLimitStrategy object) => object.toJson();
}

class NullableRateLimitStrategyJsonConverter
    implements JsonConverter<RateLimitStrategy?, Object?> {
  const NullableRateLimitStrategyJsonConverter();

  @override
  RateLimitStrategy? fromJson(Object? json) =>
      json == null ? null : RateLimitStrategy.fromJson(json);

  @override
  Object? toJson(RateLimitStrategy? object) => object?.toJson();
}

class RateLimitStrategyListJsonConverter
    implements JsonConverter<List<RateLimitStrategy>, Object?> {
  const RateLimitStrategyListJsonConverter();

  @override
  List<RateLimitStrategy> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(RateLimitStrategy.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<RateLimitStrategy> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableRateLimitStrategyListJsonConverter
    implements JsonConverter<List<RateLimitStrategy>?, Object?> {
  const NullableRateLimitStrategyListJsonConverter();

  @override
  List<RateLimitStrategy>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(RateLimitStrategy.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<RateLimitStrategy>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum ResourceType {
  form('form'),
  formField('form_field'),
  submission('submission'),
  activity('activity'),
  user('user'),
  organization('organization'),
  permission('permission'),
  scoreTemplate('score_template'),
  auditLog('audit_log'),
  unknown('__unknown__');

  const ResourceType(this.wireValue);
  final String wireValue;

  static ResourceType fromJson(Object? value) {
    final wire = value is String ? value : null;
    return ResourceTypeWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class ResourceTypeWire {
  static const unknown = ResourceType.unknown;
  static const Map<String, ResourceType> _byWire = <String, ResourceType>{
    'form': ResourceType.form,
    'form_field': ResourceType.formField,
    'submission': ResourceType.submission,
    'activity': ResourceType.activity,
    'user': ResourceType.user,
    'organization': ResourceType.organization,
    'permission': ResourceType.permission,
    'score_template': ResourceType.scoreTemplate,
    'audit_log': ResourceType.auditLog,
  };

  static ResourceType fromJson(Object? value) => value is String
      ? (_byWire[value] ?? ResourceType.unknown)
      : ResourceType.unknown;

  static String toJson(ResourceType value) => value.wireValue;
}

class ResourceTypeJsonConverter
    implements JsonConverter<ResourceType, Object?> {
  const ResourceTypeJsonConverter();

  @override
  ResourceType fromJson(Object? json) => ResourceType.fromJson(json);

  @override
  Object? toJson(ResourceType object) => object.toJson();
}

class NullableResourceTypeJsonConverter
    implements JsonConverter<ResourceType?, Object?> {
  const NullableResourceTypeJsonConverter();

  @override
  ResourceType? fromJson(Object? json) =>
      json == null ? null : ResourceType.fromJson(json);

  @override
  Object? toJson(ResourceType? object) => object?.toJson();
}

class ResourceTypeListJsonConverter
    implements JsonConverter<List<ResourceType>, Object?> {
  const ResourceTypeListJsonConverter();

  @override
  List<ResourceType> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(ResourceType.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<ResourceType> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableResourceTypeListJsonConverter
    implements JsonConverter<List<ResourceType>?, Object?> {
  const NullableResourceTypeListJsonConverter();

  @override
  List<ResourceType>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(ResourceType.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<ResourceType>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum ScoreRuleType {
  fixed('fixed'),
  optionBased('option_based'),
  rangeBased('range_based'),
  formula('formula'),
  weighted('weighted'),
  negativeScore('negative_score'),
  unknown('__unknown__');

  const ScoreRuleType(this.wireValue);
  final String wireValue;

  static ScoreRuleType fromJson(Object? value) {
    final wire = value is String ? value : null;
    return ScoreRuleTypeWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class ScoreRuleTypeWire {
  static const unknown = ScoreRuleType.unknown;
  static const Map<String, ScoreRuleType> _byWire = <String, ScoreRuleType>{
    'fixed': ScoreRuleType.fixed,
    'option_based': ScoreRuleType.optionBased,
    'range_based': ScoreRuleType.rangeBased,
    'formula': ScoreRuleType.formula,
    'weighted': ScoreRuleType.weighted,
    'negative_score': ScoreRuleType.negativeScore,
  };

  static ScoreRuleType fromJson(Object? value) => value is String
      ? (_byWire[value] ?? ScoreRuleType.unknown)
      : ScoreRuleType.unknown;

  static String toJson(ScoreRuleType value) => value.wireValue;
}

class ScoreRuleTypeJsonConverter
    implements JsonConverter<ScoreRuleType, Object?> {
  const ScoreRuleTypeJsonConverter();

  @override
  ScoreRuleType fromJson(Object? json) => ScoreRuleType.fromJson(json);

  @override
  Object? toJson(ScoreRuleType object) => object.toJson();
}

class NullableScoreRuleTypeJsonConverter
    implements JsonConverter<ScoreRuleType?, Object?> {
  const NullableScoreRuleTypeJsonConverter();

  @override
  ScoreRuleType? fromJson(Object? json) =>
      json == null ? null : ScoreRuleType.fromJson(json);

  @override
  Object? toJson(ScoreRuleType? object) => object?.toJson();
}

class ScoreRuleTypeListJsonConverter
    implements JsonConverter<List<ScoreRuleType>, Object?> {
  const ScoreRuleTypeListJsonConverter();

  @override
  List<ScoreRuleType> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(ScoreRuleType.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<ScoreRuleType> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableScoreRuleTypeListJsonConverter
    implements JsonConverter<List<ScoreRuleType>?, Object?> {
  const NullableScoreRuleTypeListJsonConverter();

  @override
  List<ScoreRuleType>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(ScoreRuleType.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<ScoreRuleType>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum ScoringMode {
  none('none'),
  quiz('quiz'),
  satisfaction('satisfaction'),
  riskAssessment('risk_assessment'),
  weighted('weighted'),
  custom('custom'),
  unknown('__unknown__');

  const ScoringMode(this.wireValue);
  final String wireValue;

  static ScoringMode fromJson(Object? value) {
    final wire = value is String ? value : null;
    return ScoringModeWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class ScoringModeWire {
  static const unknown = ScoringMode.unknown;
  static const Map<String, ScoringMode> _byWire = <String, ScoringMode>{
    'none': ScoringMode.none,
    'quiz': ScoringMode.quiz,
    'satisfaction': ScoringMode.satisfaction,
    'risk_assessment': ScoringMode.riskAssessment,
    'weighted': ScoringMode.weighted,
    'custom': ScoringMode.custom,
  };

  static ScoringMode fromJson(Object? value) => value is String
      ? (_byWire[value] ?? ScoringMode.unknown)
      : ScoringMode.unknown;

  static String toJson(ScoringMode value) => value.wireValue;
}

class ScoringModeJsonConverter implements JsonConverter<ScoringMode, Object?> {
  const ScoringModeJsonConverter();

  @override
  ScoringMode fromJson(Object? json) => ScoringMode.fromJson(json);

  @override
  Object? toJson(ScoringMode object) => object.toJson();
}

class NullableScoringModeJsonConverter
    implements JsonConverter<ScoringMode?, Object?> {
  const NullableScoringModeJsonConverter();

  @override
  ScoringMode? fromJson(Object? json) =>
      json == null ? null : ScoringMode.fromJson(json);

  @override
  Object? toJson(ScoringMode? object) => object?.toJson();
}

class ScoringModeListJsonConverter
    implements JsonConverter<List<ScoringMode>, Object?> {
  const ScoringModeListJsonConverter();

  @override
  List<ScoringMode> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(ScoringMode.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<ScoringMode> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableScoringModeListJsonConverter
    implements JsonConverter<List<ScoringMode>?, Object?> {
  const NullableScoringModeListJsonConverter();

  @override
  List<ScoringMode>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(ScoringMode.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<ScoringMode>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum SortOrder {
  asc('asc'),
  desc('desc'),
  unknown('__unknown__');

  const SortOrder(this.wireValue);
  final String wireValue;

  static SortOrder fromJson(Object? value) {
    final wire = value is String ? value : null;
    return SortOrderWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class SortOrderWire {
  static const unknown = SortOrder.unknown;
  static const Map<String, SortOrder> _byWire = <String, SortOrder>{
    'asc': SortOrder.asc,
    'desc': SortOrder.desc,
  };

  static SortOrder fromJson(Object? value) => value is String
      ? (_byWire[value] ?? SortOrder.unknown)
      : SortOrder.unknown;

  static String toJson(SortOrder value) => value.wireValue;
}

class SortOrderJsonConverter implements JsonConverter<SortOrder, Object?> {
  const SortOrderJsonConverter();

  @override
  SortOrder fromJson(Object? json) => SortOrder.fromJson(json);

  @override
  Object? toJson(SortOrder object) => object.toJson();
}

class NullableSortOrderJsonConverter
    implements JsonConverter<SortOrder?, Object?> {
  const NullableSortOrderJsonConverter();

  @override
  SortOrder? fromJson(Object? json) =>
      json == null ? null : SortOrder.fromJson(json);

  @override
  Object? toJson(SortOrder? object) => object?.toJson();
}

class SortOrderListJsonConverter
    implements JsonConverter<List<SortOrder>, Object?> {
  const SortOrderListJsonConverter();

  @override
  List<SortOrder> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(SortOrder.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<SortOrder> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableSortOrderListJsonConverter
    implements JsonConverter<List<SortOrder>?, Object?> {
  const NullableSortOrderListJsonConverter();

  @override
  List<SortOrder>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(SortOrder.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<SortOrder>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum SubmissionMode {
  singleSubmission('single_submission'),
  multipleSubmissions('multiple_submissions'),
  editableSubmission('editable_submission'),
  anonymousSubmission('anonymous_submission'),
  unknown('__unknown__');

  const SubmissionMode(this.wireValue);
  final String wireValue;

  static SubmissionMode fromJson(Object? value) {
    final wire = value is String ? value : null;
    return SubmissionModeWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class SubmissionModeWire {
  static const unknown = SubmissionMode.unknown;
  static const Map<String, SubmissionMode> _byWire = <String, SubmissionMode>{
    'single_submission': SubmissionMode.singleSubmission,
    'multiple_submissions': SubmissionMode.multipleSubmissions,
    'editable_submission': SubmissionMode.editableSubmission,
    'anonymous_submission': SubmissionMode.anonymousSubmission,
  };

  static SubmissionMode fromJson(Object? value) => value is String
      ? (_byWire[value] ?? SubmissionMode.unknown)
      : SubmissionMode.unknown;

  static String toJson(SubmissionMode value) => value.wireValue;
}

class SubmissionModeJsonConverter
    implements JsonConverter<SubmissionMode, Object?> {
  const SubmissionModeJsonConverter();

  @override
  SubmissionMode fromJson(Object? json) => SubmissionMode.fromJson(json);

  @override
  Object? toJson(SubmissionMode object) => object.toJson();
}

class NullableSubmissionModeJsonConverter
    implements JsonConverter<SubmissionMode?, Object?> {
  const NullableSubmissionModeJsonConverter();

  @override
  SubmissionMode? fromJson(Object? json) =>
      json == null ? null : SubmissionMode.fromJson(json);

  @override
  Object? toJson(SubmissionMode? object) => object?.toJson();
}

class SubmissionModeListJsonConverter
    implements JsonConverter<List<SubmissionMode>, Object?> {
  const SubmissionModeListJsonConverter();

  @override
  List<SubmissionMode> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(SubmissionMode.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<SubmissionMode> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableSubmissionModeListJsonConverter
    implements JsonConverter<List<SubmissionMode>?, Object?> {
  const NullableSubmissionModeListJsonConverter();

  @override
  List<SubmissionMode>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(SubmissionMode.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<SubmissionMode>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum UserRole {
  guest('guest'),
  parent('parent'),
  student('student'),
  teacher('teacher'),
  manager('manager'),
  admin('admin'),
  ceo('ceo'),
  superAdmin('super_admin'),
  unknown('__unknown__');

  const UserRole(this.wireValue);
  final String wireValue;

  static UserRole fromJson(Object? value) {
    final wire = value is String ? value : null;
    return UserRoleWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class UserRoleWire {
  static const unknown = UserRole.unknown;
  static const Map<String, UserRole> _byWire = <String, UserRole>{
    'guest': UserRole.guest,
    'parent': UserRole.parent,
    'student': UserRole.student,
    'teacher': UserRole.teacher,
    'manager': UserRole.manager,
    'admin': UserRole.admin,
    'ceo': UserRole.ceo,
    'super_admin': UserRole.superAdmin,
  };

  static UserRole fromJson(Object? value) =>
      value is String ? (_byWire[value] ?? UserRole.unknown) : UserRole.unknown;

  static String toJson(UserRole value) => value.wireValue;
}

class UserRoleJsonConverter implements JsonConverter<UserRole, Object?> {
  const UserRoleJsonConverter();

  @override
  UserRole fromJson(Object? json) => UserRole.fromJson(json);

  @override
  Object? toJson(UserRole object) => object.toJson();
}

class NullableUserRoleJsonConverter
    implements JsonConverter<UserRole?, Object?> {
  const NullableUserRoleJsonConverter();

  @override
  UserRole? fromJson(Object? json) =>
      json == null ? null : UserRole.fromJson(json);

  @override
  Object? toJson(UserRole? object) => object?.toJson();
}

class UserRoleListJsonConverter
    implements JsonConverter<List<UserRole>, Object?> {
  const UserRoleListJsonConverter();

  @override
  List<UserRole> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(UserRole.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<UserRole> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableUserRoleListJsonConverter
    implements JsonConverter<List<UserRole>?, Object?> {
  const NullableUserRoleListJsonConverter();

  @override
  List<UserRole>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(UserRole.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<UserRole>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}

enum VisibilityMode {
  private('private'),
  selectedUsers('selected_users'),
  selectedRoles('selected_roles'),
  subordinates('subordinates'),
  organization('organization'),
  publicLink('public_link'),
  unknown('__unknown__');

  const VisibilityMode(this.wireValue);
  final String wireValue;

  static VisibilityMode fromJson(Object? value) {
    final wire = value is String ? value : null;
    return VisibilityModeWire.fromJson(wire);
  }

  String toJson() => wireValue;

  @override
  String toString() => wireValue;
}

class VisibilityModeWire {
  static const unknown = VisibilityMode.unknown;
  static const Map<String, VisibilityMode> _byWire = <String, VisibilityMode>{
    'private': VisibilityMode.private,
    'selected_users': VisibilityMode.selectedUsers,
    'selected_roles': VisibilityMode.selectedRoles,
    'subordinates': VisibilityMode.subordinates,
    'organization': VisibilityMode.organization,
    'public_link': VisibilityMode.publicLink,
  };

  static VisibilityMode fromJson(Object? value) => value is String
      ? (_byWire[value] ?? VisibilityMode.unknown)
      : VisibilityMode.unknown;

  static String toJson(VisibilityMode value) => value.wireValue;
}

class VisibilityModeJsonConverter
    implements JsonConverter<VisibilityMode, Object?> {
  const VisibilityModeJsonConverter();

  @override
  VisibilityMode fromJson(Object? json) => VisibilityMode.fromJson(json);

  @override
  Object? toJson(VisibilityMode object) => object.toJson();
}

class NullableVisibilityModeJsonConverter
    implements JsonConverter<VisibilityMode?, Object?> {
  const NullableVisibilityModeJsonConverter();

  @override
  VisibilityMode? fromJson(Object? json) =>
      json == null ? null : VisibilityMode.fromJson(json);

  @override
  Object? toJson(VisibilityMode? object) => object?.toJson();
}

class VisibilityModeListJsonConverter
    implements JsonConverter<List<VisibilityMode>, Object?> {
  const VisibilityModeListJsonConverter();

  @override
  List<VisibilityMode> fromJson(Object? json) {
    if (json is! Iterable) return const [];
    return json.map(VisibilityMode.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<VisibilityMode> object) =>
      object.map((e) => e.toJson()).toList(growable: false);
}

class NullableVisibilityModeListJsonConverter
    implements JsonConverter<List<VisibilityMode>?, Object?> {
  const NullableVisibilityModeListJsonConverter();

  @override
  List<VisibilityMode>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Iterable) return const [];
    return json.map(VisibilityMode.fromJson).toList(growable: false);
  }

  @override
  Object? toJson(List<VisibilityMode>? object) =>
      object?.map((e) => e.toJson()).toList(growable: false);
}
