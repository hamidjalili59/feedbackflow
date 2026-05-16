use crate::api_types::enums::UserRole;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use utoipa::ToSchema;
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct UserSummaryDto {
    pub id: Uuid,
    pub organization_id: Option<Uuid>,
    pub phone: String,
    pub email: Option<String>,
    pub display_name: String,
    pub gender: Option<String>,
    pub primary_role: UserRole,
    pub status: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct UserProfileDto {
    pub phone: Option<String>,
    pub avatar_url: Option<String>,
    pub locale: Option<String>,
    pub timezone: Option<String>,
    #[serde(default)]
    pub metadata: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct UserDetailDto {
    pub id: Uuid,
    pub organization_id: Option<Uuid>,
    pub phone: String,
    pub email: Option<String>,
    pub display_name: String,
    pub gender: Option<String>,
    pub primary_role: UserRole,
    pub profile: UserProfileDto,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct UpdateUserProfileRequest {
    #[validate(length(min = 1, max = 160))]
    pub display_name: Option<String>,
    pub email: Option<String>,
    pub gender: Option<String>,
    pub profile: Option<UserProfileDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct CreateUserRequest {
    pub organization_id: Option<Uuid>,
    #[validate(length(min = 6, max = 32))]
    pub phone: String,
    pub email: Option<String>,
    #[validate(length(min = 1, max = 160))]
    pub display_name: String,
    pub gender: Option<String>,
    #[validate(length(min = 8, max = 160))]
    pub password: String,
    pub primary_role: UserRole,
    pub profile: Option<UserProfileDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct UpdateUserRequest {
    #[validate(length(min = 6, max = 32))]
    pub phone: Option<String>,
    pub email: Option<String>,
    #[validate(length(min = 1, max = 160))]
    pub display_name: Option<String>,
    pub gender: Option<String>,
    pub primary_role: Option<UserRole>,
    pub status: Option<String>,
    pub profile: Option<UserProfileDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct UserRelationshipDto {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub parent_user_id: Uuid,
    pub child_user_id: Uuid,
    pub relationship_type: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct SubordinateUserDto {
    pub user: UserSummaryDto,
    pub relationship_type: String,
    pub depth: i32,
}
