use serde::{Deserialize, Serialize};
use serde_json::Value;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct AnalyticsBucketDto {
    pub key: String,
    pub label: String,
    pub count: i64,
    pub percentage: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct AnalyticsTimeseriesPointDto {
    pub date: String,
    pub count: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct SubmissionCountAnalyticsDto {
    pub total: i64,
    pub valid: i64,
    pub anonymous: i64,
    pub by_day: Vec<AnalyticsTimeseriesPointDto>,
    pub today: i64,
    pub this_week: i64,
    pub this_month: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct CompletionRateAnalyticsDto {
    pub started: i64,
    pub completed: i64,
    pub completion_rate: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FieldAnalyticsDto {
    pub field_id: Uuid,
    pub label: String,
    pub response_count: i64,
    pub summary: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ScoreAnalyticsDto {
    pub average_score: f64,
    pub max_score: f64,
    pub average_percentage: f64,
    pub category_distribution: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FormAnalyticsDto {
    pub form_id: Uuid,
    pub submissions: SubmissionCountAnalyticsDto,
    pub completion: CompletionRateAnalyticsDto,
    pub score: ScoreAnalyticsDto,
    pub fields: Vec<FieldAnalyticsDto>,
    pub respondent_modes: Vec<AnalyticsBucketDto>,
    pub gender_distribution: Vec<AnalyticsBucketDto>,
    pub user_role_distribution: Vec<AnalyticsBucketDto>,
    pub access_code_distribution: Vec<AnalyticsBucketDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct DashboardTopFormDto {
    pub form_id: Uuid,
    pub title: String,
    pub submissions: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct DashboardAnalyticsDto {
    pub total_forms: i64,
    pub published_forms: i64,
    pub total_users: i64,
    pub total_submissions: i64,
    pub valid_submissions: i64,
    pub participation_rate: f64,
    pub today_submissions: i64,
    pub week_submissions: i64,
    pub month_submissions: i64,
    pub by_day: Vec<AnalyticsTimeseriesPointDto>,
    pub gender_distribution: Vec<AnalyticsBucketDto>,
    pub user_role_distribution: Vec<AnalyticsBucketDto>,
    pub respondent_mode_distribution: Vec<AnalyticsBucketDto>,
    pub access_code_distribution: Vec<AnalyticsBucketDto>,
    pub top_forms: Vec<DashboardTopFormDto>,
}
