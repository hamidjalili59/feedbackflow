use crate::api_types::scoring::ScoreResultDto;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use utoipa::ToSchema;
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct AnswerInputDto {
    pub field_id: Uuid,
    pub value: Value,
    #[serde(default)]
    pub metadata: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct AnswerDto {
    pub id: Uuid,
    pub submission_id: Uuid,
    pub field_id: Uuid,
    pub value: Value,
    #[serde(default)]
    pub metadata: Value,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct CreateSubmissionRequest {
    #[validate(length(min = 1))]
    pub answers: Vec<AnswerInputDto>,
    pub anonymous: Option<bool>,
    pub fingerprint_token: Option<String>,
    pub respondent_name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct UpdateSubmissionRequest {
    #[validate(length(min = 1))]
    pub answers: Vec<AnswerInputDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct SubmissionScoreDto {
    pub total_score: f64,
    pub max_score: f64,
    pub percentage_score: f64,
    pub category_label: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct SubmissionSummaryDto {
    pub id: Uuid,
    pub form_id: Uuid,
    pub respondent_user_id: Option<Uuid>,
    pub access_code_id: Option<Uuid>,
    pub respondent_mode: String,
    pub respondent_label: Option<String>,
    pub anonymous: bool,
    pub valid: bool,
    pub submitted_at: DateTime<Utc>,
    pub score: SubmissionScoreDto,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct SubmissionDetailDto {
    pub id: Uuid,
    pub form_id: Uuid,
    pub respondent_user_id: Option<Uuid>,
    pub guest_token_id: Option<Uuid>,
    pub access_code_id: Option<Uuid>,
    pub respondent_mode: String,
    pub respondent_label: Option<String>,
    pub anonymous: bool,
    pub valid: bool,
    pub answers: Vec<AnswerDto>,
    pub score: SubmissionScoreDto,
    pub submitted_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ScoreBreakdownDto {
    pub submission_id: Uuid,
    pub result: ScoreResultDto,
}
