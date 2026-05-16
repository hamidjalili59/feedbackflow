use crate::api_types::enums::{FieldType, ScoreRuleType, ScoringMode};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::BTreeMap;
use utoipa::ToSchema;
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ScoreRuleDto {
    pub id: Option<String>,
    pub rule_type: ScoreRuleType,
    pub min: Option<f64>,
    pub max: Option<f64>,
    pub value: Option<Value>,
    pub score: f64,
    pub weight: Option<f64>,
    pub formula: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ScoreCategoryDto {
    pub id: String,
    pub label: String,
    pub min_percentage: f64,
    pub max_percentage: f64,
    pub color: Option<String>,
    pub description: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ScoreTemplateDto {
    pub id: Uuid,
    pub organization_id: Option<Uuid>,
    pub field_type: Option<FieldType>,
    pub scoring_mode: ScoringMode,
    pub name: String,
    pub config: Value,
    pub is_default: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct CreateScoreTemplateRequest {
    pub field_type: Option<FieldType>,
    pub scoring_mode: ScoringMode,
    #[validate(length(min = 1, max = 160))]
    pub name: String,
    #[serde(default)]
    pub config: Value,
    #[serde(default)]
    pub is_default: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct UpdateScoreTemplateRequest {
    pub field_type: Option<FieldType>,
    pub scoring_mode: Option<ScoringMode>,
    #[validate(length(min = 1, max = 160))]
    pub name: Option<String>,
    pub config: Option<Value>,
    pub is_default: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FieldScoreBreakdownDto {
    pub field_id: Uuid,
    pub label: String,
    pub score: f64,
    pub max_score: f64,
    pub weighted_score: f64,
    pub rule_id: Option<String>,
    #[serde(default)]
    pub details: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ScoreResultDto {
    pub total_score: f64,
    pub max_score: f64,
    pub percentage_score: f64,
    pub category: Option<ScoreCategoryDto>,
    pub field_breakdowns: Vec<FieldScoreBreakdownDto>,
    #[serde(default)]
    pub metadata: BTreeMap<String, Value>,
}
