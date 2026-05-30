use crate::api_types::enums::UserRole;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use utoipa::{IntoParams, ToSchema};
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum AssignmentAudienceType {
    User,
    Role,
    Group,
    Class,
    Department,
    Organization,
    Segment,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum AudienceSegmentType {
    Static,
    Dynamic,
    Event,
    Camp,
    Cohort,
    Custom,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct AudienceSegmentDto {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub name: String,
    pub slug: String,
    pub description: Option<String>,
    pub segment_type: AudienceSegmentType,
    pub rules: Value,
    pub metadata: Value,
    pub enabled: bool,
    pub member_count: i64,
    pub created_by_user_id: Option<Uuid>,
    pub updated_by_user_id: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct CreateAudienceSegmentRequest {
    #[validate(length(min = 1, max = 160))]
    pub name: String,
    #[validate(length(min = 1, max = 180))]
    pub slug: Option<String>,
    #[validate(length(max = 2000))]
    pub description: Option<String>,
    pub segment_type: Option<AudienceSegmentType>,
    #[serde(default)]
    pub rules: Value,
    #[serde(default)]
    pub metadata: Value,
    pub enabled: Option<bool>,
    #[serde(default)]
    pub member_user_ids: Vec<Uuid>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct UpdateAudienceSegmentRequest {
    #[validate(length(min = 1, max = 160))]
    pub name: Option<String>,
    #[validate(length(min = 1, max = 180))]
    pub slug: Option<String>,
    #[validate(length(max = 2000))]
    pub description: Option<String>,
    pub segment_type: Option<AudienceSegmentType>,
    pub rules: Option<Value>,
    pub metadata: Option<Value>,
    pub enabled: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct SetAudienceSegmentMembersRequest {
    #[serde(default)]
    pub user_ids: Vec<Uuid>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct AudienceSegmentMemberDto {
    pub user_id: Uuid,
    pub display_name: String,
    pub primary_role: UserRole,
    pub role_snapshot: Option<String>,
    pub metadata: Value,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FormAssignmentDto {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub form_id: Uuid,
    pub audience_type: AssignmentAudienceType,
    pub audience_user_id: Option<Uuid>,
    pub audience_role: Option<UserRole>,
    pub audience_group_id: Option<Uuid>,
    pub audience_segment_id: Option<Uuid>,
    pub label: Option<String>,
    pub can_see: bool,
    pub can_answer: bool,
    pub assigned_by_user_id: Option<Uuid>,
    pub metadata: Value,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct FormAssignmentInputDto {
    pub audience_type: AssignmentAudienceType,
    pub audience_user_id: Option<Uuid>,
    pub audience_role: Option<UserRole>,
    pub audience_group_id: Option<Uuid>,
    pub audience_segment_id: Option<Uuid>,
    #[validate(length(max = 180))]
    pub label: Option<String>,
    pub can_see: Option<bool>,
    pub can_answer: Option<bool>,
    #[serde(default)]
    pub metadata: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct SetFormAssignmentsRequest {
    #[serde(default)]
    #[validate(nested)]
    pub assignments: Vec<FormAssignmentInputDto>,
}

#[derive(Debug, Clone, Deserialize, IntoParams)]
pub struct AudienceSegmentQuery {
    pub search: Option<String>,
    pub segment_type: Option<String>,
    pub enabled: Option<bool>,
    #[serde(default = "default_page")]
    pub page: i64,
    #[serde(default = "default_page_size")]
    pub page_size: i64,
}

impl AudienceSegmentQuery {
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
