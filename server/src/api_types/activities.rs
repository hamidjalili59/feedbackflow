use crate::api_types::enums::{ActivityActionType, ActivityStatus, ActivityTriggerType};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use utoipa::ToSchema;
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ActivityRuleDto {
    pub id: Uuid,
    pub form_id: Uuid,
    pub trigger_type: ActivityTriggerType,
    pub condition: Value,
    pub action_type: ActivityActionType,
    pub action_config: Value,
    pub enabled: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct CreateActivityRuleRequest {
    pub trigger_type: ActivityTriggerType,
    pub condition: Value,
    pub action_type: ActivityActionType,
    pub action_config: Value,
    pub enabled: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct UpdateActivityRuleRequest {
    pub trigger_type: Option<ActivityTriggerType>,
    pub condition: Option<Value>,
    pub action_type: Option<ActivityActionType>,
    pub action_config: Option<Value>,
    pub enabled: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ActivityDto {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub form_id: Option<Uuid>,
    pub submission_id: Option<Uuid>,
    pub assigned_to_user_id: Option<Uuid>,
    pub title: String,
    pub description: Option<String>,
    pub status: ActivityStatus,
    pub due_at: Option<DateTime<Utc>>,
    #[serde(default)]
    pub metadata: Value,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct UpdateActivityRequest {
    #[validate(length(min = 1, max = 255))]
    pub title: Option<String>,
    pub description: Option<String>,
    pub status: Option<ActivityStatus>,
    pub assigned_to_user_id: Option<Uuid>,
    pub due_at: Option<DateTime<Utc>>,
    pub metadata: Option<Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ActivitySummaryDto {
    pub id: Uuid,
    pub form_id: Option<Uuid>,
    pub title: String,
    pub status: ActivityStatus,
    pub assigned_to_user_id: Option<Uuid>,
    pub due_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
}
