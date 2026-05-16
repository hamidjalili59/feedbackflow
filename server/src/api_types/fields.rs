use crate::api_types::{
    enums::{FieldType, UserRole},
    scoring::{ScoreCategoryDto, ScoreRuleDto},
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::BTreeMap;
use utoipa::ToSchema;
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FieldOptionDto {
    pub id: String,
    pub label: String,
    pub value: Value,
    pub order_index: i32,
    pub score: Option<f64>,
    #[serde(default)]
    pub metadata: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FieldConfigDto {
    #[serde(default)]
    pub options: Vec<FieldOptionDto>,
    #[serde(default)]
    pub rows: Vec<FieldOptionDto>,
    #[serde(default)]
    pub columns: Vec<FieldOptionDto>,
    pub min: Option<f64>,
    pub max: Option<f64>,
    pub step: Option<f64>,
    pub default_value: Option<Value>,
    pub accept_mime_types: Option<Vec<String>>,
    pub max_file_size_mb: Option<i64>,
    pub page_title: Option<String>,
    pub static_text: Option<String>,
    #[serde(default)]
    pub metadata: Value,
}

impl Default for FieldConfigDto {
    fn default() -> Self {
        Self {
            options: vec![],
            rows: vec![],
            columns: vec![],
            min: None,
            max: None,
            step: None,
            default_value: None,
            accept_mime_types: None,
            max_file_size_mb: None,
            page_title: None,
            static_text: None,
            metadata: Value::Object(Default::default()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FieldValidationDto {
    pub min_length: Option<i64>,
    pub max_length: Option<i64>,
    pub regex: Option<String>,
    pub min_number: Option<f64>,
    pub max_number: Option<f64>,
    pub min_items: Option<i64>,
    pub max_items: Option<i64>,
    pub required_message: Option<String>,
    #[serde(default)]
    pub custom: Value,
}

impl Default for FieldValidationDto {
    fn default() -> Self {
        Self {
            min_length: None,
            max_length: None,
            regex: None,
            min_number: None,
            max_number: None,
            min_items: None,
            max_items: None,
            required_message: None,
            custom: Value::Object(Default::default()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FieldVisibilityConditionDto {
    pub source_field_id: Uuid,
    pub operator: String,
    pub value: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ConditionalLogicRuleDto {
    pub id: String,
    pub mode: String,
    pub action: String,
    pub conditions: Vec<FieldVisibilityConditionDto>,
    #[serde(default)]
    pub target_field_ids: Vec<Uuid>,
    pub target_page_index: Option<i32>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FieldScoringConfigDto {
    pub enabled: bool,
    pub max_score: Option<f64>,
    pub weight: Option<f64>,
    #[serde(default)]
    pub option_scores: BTreeMap<String, f64>,
    #[serde(default)]
    pub rules: Vec<ScoreRuleDto>,
    #[serde(default)]
    pub categories: Vec<ScoreCategoryDto>,
    #[serde(default)]
    pub metadata: Value,
}

impl Default for FieldScoringConfigDto {
    fn default() -> Self {
        Self {
            enabled: false,
            max_score: None,
            weight: Some(1.0),
            option_scores: BTreeMap::new(),
            rules: vec![],
            categories: vec![],
            metadata: Value::Object(Default::default()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FieldPermissionConfigDto {
    #[serde(default)]
    pub visible_to_roles: Vec<UserRole>,
    #[serde(default)]
    pub editable_by_roles: Vec<UserRole>,
    #[serde(default)]
    pub answerable_by_roles: Vec<UserRole>,
    #[serde(default)]
    pub hidden_from_roles: Vec<UserRole>,
    #[serde(default)]
    pub metadata: Value,
}

impl Default for FieldPermissionConfigDto {
    fn default() -> Self {
        Self {
            visible_to_roles: vec![],
            editable_by_roles: vec![],
            answerable_by_roles: vec![],
            hidden_from_roles: vec![],
            metadata: Value::Object(Default::default()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FormFieldDto {
    pub id: Uuid,
    pub form_id: Uuid,
    #[serde(rename = "type")]
    pub field_type: FieldType,
    pub label: String,
    pub description: Option<String>,
    pub placeholder: Option<String>,
    pub required: bool,
    pub order_index: i32,
    pub config: FieldConfigDto,
    pub validation: FieldValidationDto,
    pub visibility_conditions: Vec<ConditionalLogicRuleDto>,
    pub scoring_config: FieldScoringConfigDto,
    pub permissions: FieldPermissionConfigDto,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct CreateFormFieldRequest {
    #[serde(rename = "type")]
    pub field_type: FieldType,
    #[validate(length(min = 1, max = 255))]
    pub label: String,
    pub description: Option<String>,
    pub placeholder: Option<String>,
    pub required: bool,
    pub order_index: i32,
    #[serde(default)]
    pub config: FieldConfigDto,
    #[serde(default)]
    pub validation: FieldValidationDto,
    #[serde(default)]
    pub visibility_conditions: Vec<ConditionalLogicRuleDto>,
    #[serde(default)]
    pub scoring_config: FieldScoringConfigDto,
    #[serde(default)]
    pub permissions: FieldPermissionConfigDto,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct UpdateFormFieldRequest {
    #[serde(rename = "type")]
    pub field_type: Option<FieldType>,
    #[validate(length(min = 1, max = 255))]
    pub label: Option<String>,
    pub description: Option<String>,
    pub placeholder: Option<String>,
    pub required: Option<bool>,
    pub order_index: Option<i32>,
    pub config: Option<FieldConfigDto>,
    pub validation: Option<FieldValidationDto>,
    pub visibility_conditions: Option<Vec<ConditionalLogicRuleDto>>,
    pub scoring_config: Option<FieldScoringConfigDto>,
    pub permissions: Option<FieldPermissionConfigDto>,
}
