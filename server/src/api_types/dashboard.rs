use crate::api_types::{analytics::AnalyticsBucketDto, enums::UserRole};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use utoipa::{IntoParams, ToSchema};
use uuid::Uuid;

#[derive(Debug, Clone, Deserialize, IntoParams)]
pub struct DashboardQuery {
    pub period: Option<String>,
    pub compare: Option<String>,
    pub child_id: Option<Uuid>,
    pub class_id: Option<Uuid>,
    pub branch_id: Option<Uuid>,
    pub scope: Option<String>,
    pub scope_id: Option<Uuid>,
}

#[derive(Debug, Clone, Deserialize, IntoParams)]
pub struct MySurveysQuery {
    pub status: Option<String>,
    pub period: Option<String>,
    pub child_id: Option<Uuid>,
    #[serde(default = "default_limit")]
    pub limit: i64,
}

#[derive(Debug, Clone, Deserialize, IntoParams)]
pub struct CalendarQuery {
    pub period: Option<String>,
    pub child_id: Option<Uuid>,
    pub start_date: Option<String>,
    pub end_date: Option<String>,
    pub scope: Option<String>,
    pub scope_id: Option<Uuid>,
}

#[derive(Debug, Clone, Deserialize, IntoParams)]
pub struct TimeseriesQuery {
    pub metric: Option<String>,
    pub period: Option<String>,
    pub compare: Option<String>,
    pub granularity: Option<String>,
    pub scope: Option<String>,
    pub scope_id: Option<Uuid>,
}

#[derive(Debug, Clone, Deserialize, IntoParams)]
pub struct RankingQuery {
    pub metric: Option<String>,
    pub dimension: Option<String>,
    pub period: Option<String>,
    pub order: Option<String>,
    #[serde(default = "default_limit")]
    pub limit: i64,
}

#[derive(Debug, Clone, Deserialize, IntoParams)]
pub struct AlertQuery {
    pub metric: Option<String>,
    pub scope: Option<String>,
    pub period: Option<String>,
    #[serde(default = "default_limit")]
    pub limit: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ChildProfileDto {
    pub id: Uuid,
    pub display_name: String,
    pub avatar_url: Option<String>,
    pub grade_label: Option<String>,
    pub class_id: Option<Uuid>,
    pub class_name: Option<String>,
    pub branch_id: Option<Uuid>,
    pub branch_name: Option<String>,
    pub metadata: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct SurveyCardDto {
    pub form_id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub category: Option<String>,
    #[serde(default)]
    pub tags: Vec<String>,
    pub status: String,
    pub my_submission_id: Option<Uuid>,
    pub progress: f64,
    pub question_count: i64,
    pub estimated_minutes: Option<i64>,
    pub cta: String,
    pub date_label: Option<String>,
    pub scheduled_at: Option<DateTime<Utc>>,
    pub published_at: Option<DateTime<Utc>>,
    pub closed_at: Option<DateTime<Utc>>,
    pub assigned_reason: Option<String>,
    pub metadata: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct SurveyStatusSummaryDto {
    pub completed: i64,
    pub in_progress: i64,
    pub pending: i64,
    pub new_items: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct DashboardMetricValueDto {
    pub metric_id: Uuid,
    pub key: String,
    pub title: String,
    pub value: Option<f64>,
    pub label: Option<String>,
    pub unit: Option<String>,
    pub scale_min: Option<f64>,
    pub scale_max: Option<f64>,
    pub status: Option<String>,
    pub trend: Option<f64>,
    pub display: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct TimeseriesPointDto {
    pub label: String,
    pub date: String,
    pub value: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct TimeseriesSeriesDto {
    pub key: String,
    pub label: String,
    pub points: Vec<TimeseriesPointDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct TimeseriesResponseDto {
    pub metric: String,
    pub period: String,
    pub granularity: String,
    pub series: Vec<TimeseriesSeriesDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct CalendarSurveyDto {
    pub form_id: Uuid,
    pub title: String,
    pub status: String,
    pub date_label: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct CalendarDayDto {
    pub date: String,
    pub label: String,
    pub weekday: Option<String>,
    pub status: String,
    pub count: i64,
    pub highlight: bool,
    #[serde(default)]
    pub surveys: Vec<CalendarSurveyDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct CalendarResponseDto {
    pub period: String,
    pub days: Vec<CalendarDayDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ActivityFeedItemDto {
    pub id: Uuid,
    pub activity_type: String,
    pub title: String,
    pub subtitle: Option<String>,
    pub status: String,
    pub time_ago: Option<String>,
    pub created_at: DateTime<Utc>,
    pub target_url: Option<String>,
    pub icon: Option<String>,
    pub metadata: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct RankingItemDto {
    pub rank: i64,
    pub entity_id: Uuid,
    pub entity_type: String,
    pub title: String,
    pub subtitle: Option<String>,
    pub score: f64,
    pub trend: Option<f64>,
    pub avatar_url: Option<String>,
    pub metadata: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct RankingResponseDto {
    pub metric: String,
    pub dimension: String,
    pub period: String,
    pub items: Vec<RankingItemDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct AnalyticsAlertDto {
    pub id: String,
    pub severity: String,
    pub title: String,
    pub description: Option<String>,
    pub entity_id: Option<Uuid>,
    pub entity_type: Option<String>,
    pub metric_key: Option<String>,
    pub value: Option<f64>,
    pub threshold: Option<f64>,
    pub metadata: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct AnalyticsAlertsResponseDto {
    pub period: String,
    pub items: Vec<AnalyticsAlertDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct DashboardResponseDto {
    pub role: UserRole,
    pub period: String,
    pub children: Vec<ChildProfileDto>,
    pub selected_child_id: Option<Uuid>,
    pub survey_summary: SurveyStatusSummaryDto,
    pub latest_surveys: Vec<SurveyCardDto>,
    pub metrics: Vec<DashboardMetricValueDto>,
    pub charts: Vec<TimeseriesResponseDto>,
    pub activities: Vec<ActivityFeedItemDto>,
    pub rankings: Vec<RankingResponseDto>,
    pub distributions: Vec<AnalyticsBucketDto>,
    pub metadata: Value,
}

fn default_limit() -> i64 {
    20
}
