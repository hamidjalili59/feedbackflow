use crate::api_types::{enums::*, fields::FormFieldDto};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use utoipa::ToSchema;
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct AudienceRuleDto {
    pub audience_type: FormAudienceType,
    pub id: Option<Uuid>,
    pub role: Option<UserRole>,
    pub label: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FormSettingsDto {
    pub allow_anonymous_answers: bool,
    pub one_submission_per_user: bool,
    pub answers_editable_after_submission: bool,
    pub start_at: Option<DateTime<Utc>>,
    pub end_at: Option<DateTime<Utc>>,
    pub max_submissions: Option<i64>,
    pub submission_cooldown_seconds: Option<i64>,
    pub submission_mode: SubmissionMode,
    pub answer_visibility: AnswerVisibility,
    pub guests_can_answer: bool,
    #[serde(default)]
    pub metadata: Value,
}

impl Default for FormSettingsDto {
    fn default() -> Self {
        Self {
            allow_anonymous_answers: false,
            one_submission_per_user: true,
            answers_editable_after_submission: false,
            start_at: None,
            end_at: None,
            max_submissions: None,
            submission_cooldown_seconds: Some(30),
            submission_mode: SubmissionMode::SingleSubmission,
            answer_visibility: AnswerVisibility::VisibleToCreator,
            guests_can_answer: false,
            metadata: Value::Object(Default::default()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FormVisibilityDto {
    pub mode: VisibilityMode,
    #[serde(default)]
    pub can_see: Vec<AudienceRuleDto>,
    #[serde(default)]
    pub can_answer: Vec<AudienceRuleDto>,
    #[serde(default)]
    pub cannot_see: Vec<AudienceRuleDto>,
    #[serde(default)]
    pub cannot_answer: Vec<AudienceRuleDto>,
    pub guest_can_answer: bool,
    pub anonymous_allowed: bool,
    #[serde(default)]
    pub metadata: Value,
}

impl Default for FormVisibilityDto {
    fn default() -> Self {
        Self {
            mode: VisibilityMode::Private,
            can_see: vec![],
            can_answer: vec![],
            cannot_see: vec![],
            cannot_answer: vec![],
            guest_can_answer: false,
            anonymous_allowed: false,
            metadata: Value::Object(Default::default()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct PublicProtectionSettingsDto {
    pub level: PublicProtectionLevel,
    #[serde(default)]
    pub strategies: Vec<RateLimitStrategy>,
    pub ip_limit_per_minute: Option<i64>,
    pub token_limit_per_day: Option<i64>,
    pub access_limit_per_minute: Option<i64>,
    pub cooldown_seconds: Option<i64>,
    pub max_submissions_per_ip: Option<i64>,
    pub max_submissions_per_fingerprint: Option<i64>,
    pub captcha_enabled: bool,
    pub email_verification_enabled: bool,
    pub phone_verification_enabled: bool,
    #[serde(default)]
    pub disabled_limits: Vec<RateLimitStrategy>,
    #[serde(default)]
    pub metadata: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FormAccessCodeDto {
    pub id: Uuid,
    pub code_type: String,
    pub label: Option<String>,
    pub enabled: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct FormAccessCodeInputDto {
    #[validate(length(min = 1, max = 120))]
    pub label: String,
    #[validate(length(min = 4, max = 256))]
    pub code: String,
    pub enabled: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct SharedFormPasswordInputDto {
    #[validate(length(min = 4, max = 256))]
    pub code: String,
    pub enabled: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct SetFormAccessCodesRequest {
    pub shared_password: Option<SharedFormPasswordInputDto>,
    pub clear_shared_password: Option<bool>,
    #[serde(default)]
    #[validate(nested)]
    pub identity_codes: Vec<FormAccessCodeInputDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FormAccessCodesResponse {
    pub shared_password: Option<FormAccessCodeDto>,
    #[serde(default)]
    pub identity_codes: Vec<FormAccessCodeDto>,
}

impl Default for PublicProtectionSettingsDto {
    fn default() -> Self {
        Self {
            level: PublicProtectionLevel::Standard,
            strategies: vec![
                RateLimitStrategy::Ip,
                RateLimitStrategy::Token,
                RateLimitStrategy::Fingerprint,
            ],
            ip_limit_per_minute: Some(20),
            token_limit_per_day: Some(5),
            access_limit_per_minute: Some(60),
            cooldown_seconds: Some(30),
            max_submissions_per_ip: Some(20),
            max_submissions_per_fingerprint: Some(5),
            captcha_enabled: false,
            email_verification_enabled: false,
            phone_verification_enabled: false,
            disabled_limits: vec![],
            metadata: Value::Object(Default::default()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct CreateFormRequest {
    #[validate(length(min = 1, max = 255))]
    pub title: String,
    pub description: Option<String>,
    pub category: Option<String>,
    #[serde(default)]
    pub tags: Vec<String>,
    #[serde(default)]
    pub settings: FormSettingsDto,
    #[serde(default)]
    pub visibility: FormVisibilityDto,
    #[serde(default)]
    pub scoring_mode: Option<ScoringMode>,
    #[serde(default)]
    pub scoring_config: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct UpdateFormRequest {
    #[validate(length(min = 1, max = 255))]
    pub title: Option<String>,
    pub description: Option<String>,
    pub category: Option<String>,
    #[serde(default)]
    pub tags: Option<Vec<String>>,
    pub settings: Option<FormSettingsDto>,
    pub visibility: Option<FormVisibilityDto>,
    pub scoring_mode: Option<ScoringMode>,
    pub scoring_config: Option<Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FormSummaryDto {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub creator_id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub category: Option<String>,
    #[serde(default)]
    pub tags: Vec<String>,
    pub status: FormStatus,
    pub visibility_mode: VisibilityMode,
    pub publish_mode: PublishMode,
    pub scoring_mode: ScoringMode,
    pub submissions_count: i64,
    pub my_submission_id: Option<Uuid>,
    pub public_token: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FormAnswerAccessDto {
    pub allowed: bool,
    pub can_view: bool,
    pub can_edit_workspace: bool,
    pub requires_public_link: bool,
    pub my_submission_id: Option<Uuid>,
    pub reason: Option<String>,
    pub reason_code: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FormDetailDto {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub creator_id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub category: Option<String>,
    #[serde(default)]
    pub tags: Vec<String>,
    pub status: FormStatus,
    pub visibility_mode: VisibilityMode,
    pub publish_mode: PublishMode,
    pub settings: FormSettingsDto,
    pub visibility: FormVisibilityDto,
    pub public_protection: PublicProtectionSettingsDto,
    pub scoring_mode: ScoringMode,
    pub scoring_config: Value,
    pub fields: Vec<FormFieldDto>,
    pub public_token: Option<String>,
    pub my_submission_id: Option<Uuid>,
    pub approved_at: Option<DateTime<Utc>>,
    pub published_at: Option<DateTime<Utc>>,
    pub closed_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct DuplicateFormRequest {
    #[validate(length(min = 1, max = 255))]
    pub title: Option<String>,
    pub include_fields: bool,
    pub include_visibility: bool,
    pub include_activity_rules: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct UpdateFormVisibilityRequest {
    pub visibility: FormVisibilityDto,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct UpdatePublicProtectionRequest {
    pub public_protection: PublicProtectionSettingsDto,
    pub reason: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct SubmitForApprovalRequest {
    pub note: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct ApproveFormRequest {
    pub comment: Option<String>,
    pub publish_after_approval: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct RejectFormRequest {
    #[validate(length(min = 1, max = 2000))]
    pub reason: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct PublishFormRequest {
    pub publish_mode: PublishMode,
    pub visibility: Option<FormVisibilityDto>,
    pub public_protection: Option<PublicProtectionSettingsDto>,
    pub scheduled_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct CloseFormRequest {
    pub reason: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct ArchiveFormRequest {
    pub reason: Option<String>,
}
