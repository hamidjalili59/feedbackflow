use serde::{de::DeserializeOwned, Deserialize, Serialize};
use utoipa::ToSchema;

pub fn enum_to_string<T: Serialize>(value: &T) -> String {
    serde_json::to_string(value)
        .unwrap_or_else(|_| "null".to_owned())
        .trim_matches('"')
        .to_owned()
}

pub fn enum_from_str<T: DeserializeOwned>(value: &str) -> serde_json::Result<T> {
    serde_json::from_value(serde_json::Value::String(value.to_owned()))
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum UserRole {
    Guest,
    Parent,
    Student,
    Teacher,
    Manager,
    Admin,
    Ceo,
    SuperAdmin,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum PermissionAction {
    Create,
    Read,
    Update,
    Delete,
    Publish,
    Approve,
    Reject,
    Answer,
    ViewResults,
    Export,
    ManagePermissions,
    ManageScoring,
    ManagePublicProtection,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum ResourceType {
    Form,
    FormField,
    Submission,
    Activity,
    User,
    Organization,
    Permission,
    ScoreTemplate,
    AuditLog,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum FormStatus {
    Draft,
    PendingReview,
    Rejected,
    Approved,
    Scheduled,
    Published,
    Closed,
    Archived,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum ApprovalStatus {
    NotRequired,
    Required,
    Pending,
    Approved,
    Rejected,
    Cancelled,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum PublishMode {
    Private,
    Organization,
    Subordinates,
    RoleBased,
    PublicLink,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum VisibilityMode {
    Private,
    SelectedUsers,
    SelectedRoles,
    Subordinates,
    Organization,
    PublicLink,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum SubmissionMode {
    SingleSubmission,
    MultipleSubmissions,
    EditableSubmission,
    AnonymousSubmission,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum FieldType {
    ShortText,
    LongText,
    Email,
    Phone,
    Number,
    Decimal,
    Date,
    Time,
    DateTime,
    SingleChoice,
    MultipleChoice,
    Dropdown,
    RatingStars,
    NumericRating,
    Slider,
    LikertScale,
    MatrixSingleChoice,
    MatrixMultipleChoice,
    YesNo,
    BooleanSwitch,
    Nps,
    EmojiReaction,
    FileUpload,
    ImageUpload,
    Signature,
    Location,
    Ranking,
    SectionTitle,
    DescriptionBlock,
    Divider,
    ConsentCheckbox,
    TermsAcceptance,
    Hidden,
    Calculated,
    ConditionalLogic,
    ScoreDisplay,
    QuizQuestion,
    PageBreak,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum SortOrder {
    Asc,
    Desc,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum FormAudienceType {
    User,
    Role,
    Group,
    Class,
    Department,
    Organization,
    Public,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum AnswerVisibility {
    VisibleToCreator,
    VisibleToAdmin,
    VisibleToManager,
    Anonymous,
    Private,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum ScoringMode {
    None,
    Quiz,
    Satisfaction,
    RiskAssessment,
    Weighted,
    Custom,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum ScoreRuleType {
    Fixed,
    OptionBased,
    RangeBased,
    Formula,
    Weighted,
    NegativeScore,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum ActivityTriggerType {
    SubmissionCreated,
    ScoreAbove,
    ScoreBelow,
    AnswerEquals,
    AnswerContains,
    NpsLow,
    NpsHigh,
    SubmissionCountReached,
    FormClosed,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum ActivityActionType {
    CreateActivity,
    NotifyUser,
    NotifyManager,
    SendEmail,
    SendWebhook,
    MarkSubmission,
    AssignFollowUp,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum ActivityStatus {
    Open,
    InProgress,
    Completed,
    Cancelled,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum PublicProtectionLevel {
    None,
    Basic,
    Standard,
    Strict,
    Custom,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum RateLimitStrategy {
    Ip,
    User,
    Token,
    Fingerprint,
    Captcha,
    Combined,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum AuditAction {
    Created,
    Updated,
    Deleted,
    Published,
    SubmittedForApproval,
    Approved,
    Rejected,
    Closed,
    Archived,
    PermissionChanged,
    PublicProtectionDisabled,
    Login,
    Logout,
    SubmissionCreated,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum ErrorCode {
    Unauthorized,
    Forbidden,
    PermissionDenied,
    ValidationError,
    NotFound,
    Conflict,
    RateLimited,
    FormClosed,
    FormNotPublished,
    ApprovalRequired,
    PublicProtectionRequired,
    PublicAccessDenied,
    InvalidToken,
    TokenExpired,
    InternalServerError,
    ServiceUnavailable,
}
