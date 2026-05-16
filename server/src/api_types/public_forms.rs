use crate::api_types::{
    fields::FormFieldDto,
    forms::{FormSettingsDto, FormVisibilityDto, PublicProtectionSettingsDto},
    submissions::{AnswerInputDto, SubmissionDetailDto},
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use utoipa::ToSchema;
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct PublicFormDto {
    pub id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub settings: FormSettingsDto,
    pub visibility: FormVisibilityDto,
    pub public_protection: PublicProtectionSettingsDto,
    pub fields: Vec<FormFieldDto>,
    pub access_policy: PublicFormAccessPolicyDto,
    pub start_at: Option<DateTime<Utc>>,
    pub end_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct PublicFormAccessPolicyDto {
    #[serde(default)]
    pub respondent_modes: Vec<String>,
    pub requires_form_password: bool,
    pub identity_codes_enabled: bool,
    pub public_access_validation_required: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct PublicFormAccessDto {
    pub public_token: String,
    pub fingerprint_token: Option<String>,
    pub ip_hint: Option<String>,
    #[serde(default)]
    pub metadata: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct ValidatePublicFormAccessRequest {
    pub respondent_mode: Option<String>,
    pub form_password: Option<String>,
    pub identity_code: Option<String>,
    pub fingerprint_token: Option<String>,
    pub captcha_token: Option<String>,
    pub email_verification_token: Option<String>,
    pub phone_verification_token: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ValidatePublicFormAccessResponse {
    pub allowed: bool,
    pub reason: Option<String>,
    pub access_token: Option<String>,
    pub respondent_mode: Option<String>,
    pub identity_label: Option<String>,
    pub rate_limit: crate::api_types::rate_limit::PublicRateLimitStatusDto,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct PublicSubmissionRequest {
    #[validate(length(min = 1))]
    pub answers: Vec<AnswerInputDto>,
    pub respondent_mode: Option<String>,
    pub anonymous: Option<bool>,
    pub fingerprint_token: Option<String>,
    pub public_access_token: Option<String>,
    pub captcha_token: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct PublicSubmissionResponse {
    pub submission: SubmissionDetailDto,
    pub message: String,
}
