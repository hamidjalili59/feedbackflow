use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use utoipa::{IntoParams, ToSchema};
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum MetricType {
    Score,
    Percentage,
    Rating,
    Count,
    Label,
    Custom,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum MetricAggregationMethod {
    Avg,
    Sum,
    Count,
    Min,
    Max,
    Latest,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum MetricPositiveDirection {
    HigherIsBetter,
    LowerIsBetter,
    Neutral,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum MetricMappingSourceType {
    FieldAnswer,
    SubmissionScore,
    SubmissionPercentage,
    SubmissionCount,
    Custom,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct MetricDefinitionDto {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub key: String,
    pub title: String,
    pub description: Option<String>,
    pub metric_type: MetricType,
    pub aggregation_method: MetricAggregationMethod,
    pub scale_min: Option<f64>,
    pub scale_max: Option<f64>,
    pub positive_direction: MetricPositiveDirection,
    pub thresholds: Value,
    pub display: Value,
    pub enabled: bool,
    pub mapping_count: i64,
    pub created_by_user_id: Option<Uuid>,
    pub updated_by_user_id: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct CreateMetricDefinitionRequest {
    #[validate(length(min = 1, max = 120))]
    pub key: String,
    #[validate(length(min = 1, max = 180))]
    pub title: String,
    #[validate(length(max = 2000))]
    pub description: Option<String>,
    pub metric_type: Option<MetricType>,
    pub aggregation_method: Option<MetricAggregationMethod>,
    pub scale_min: Option<f64>,
    pub scale_max: Option<f64>,
    pub positive_direction: Option<MetricPositiveDirection>,
    #[serde(default)]
    pub thresholds: Value,
    #[serde(default)]
    pub display: Value,
    pub enabled: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct UpdateMetricDefinitionRequest {
    #[validate(length(min = 1, max = 120))]
    pub key: Option<String>,
    #[validate(length(min = 1, max = 180))]
    pub title: Option<String>,
    #[validate(length(max = 2000))]
    pub description: Option<String>,
    pub metric_type: Option<MetricType>,
    pub aggregation_method: Option<MetricAggregationMethod>,
    pub scale_min: Option<f64>,
    pub scale_max: Option<f64>,
    pub positive_direction: Option<MetricPositiveDirection>,
    pub thresholds: Option<Value>,
    pub display: Option<Value>,
    pub enabled: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct MetricMappingDto {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub metric_id: Uuid,
    pub form_id: Option<Uuid>,
    pub field_id: Option<Uuid>,
    pub source_type: MetricMappingSourceType,
    pub transform: Value,
    pub weight: f64,
    pub enabled: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct MetricMappingInputDto {
    pub form_id: Option<Uuid>,
    pub field_id: Option<Uuid>,
    pub source_type: Option<MetricMappingSourceType>,
    #[serde(default)]
    pub transform: Value,
    pub weight: Option<f64>,
    pub enabled: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct SetMetricMappingsRequest {
    #[serde(default)]
    #[validate(nested)]
    pub mappings: Vec<MetricMappingInputDto>,
}

#[derive(Debug, Clone, Deserialize, IntoParams)]
pub struct MetricQuery {
    pub search: Option<String>,
    pub enabled: Option<bool>,
    #[serde(default = "default_page")]
    pub page: i64,
    #[serde(default = "default_page_size")]
    pub page_size: i64,
}

impl MetricQuery {
    pub fn limit(&self) -> i64 {
        self.page_size.clamp(1, 100)
    }

    pub fn offset(&self) -> i64 {
        (self.page.max(1) - 1) * self.limit()
    }
}

fn default_page() -> i64 {
    1
}

fn default_page_size() -> i64 {
    20
}
