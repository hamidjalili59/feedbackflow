use crate::api_types::{enums::UserRole, organizations::OrganizationDto, users::UserDetailDto};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct RegisterRequest {
    #[validate(length(min = 6, max = 32))]
    pub phone: String,
    pub email: Option<String>,
    #[validate(length(min = 8, max = 256))]
    pub password: String,
    #[validate(length(min = 1, max = 160))]
    pub display_name: String,
    pub gender: Option<String>,
    pub organization_id: Option<Uuid>,
    pub organization_name: Option<String>,
    pub role: Option<UserRole>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct RegisterResponse {
    pub user: UserDetailDto,
    pub organization: Option<OrganizationDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct LoginRequest {
    #[validate(length(min = 6, max = 32))]
    pub phone: String,
    #[validate(length(min = 1, max = 256))]
    pub password: String,
}


#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct GuestLoginRequest {
    pub organization_id: Option<Uuid>,
    #[validate(length(min = 1, max = 180))]
    pub organization_slug: Option<String>,
    #[validate(length(min = 8, max = 160))]
    pub public_token: Option<String>,
    #[validate(length(max = 160))]
    pub display_name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct LoginResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub token_type: String,
    pub expires_in: i64,
    pub user: UserDetailDto,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct RefreshTokenRequest {
    #[validate(length(min = 16))]
    pub refresh_token: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct RefreshTokenResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub token_type: String,
    pub expires_in: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct LogoutRequest {
    #[validate(length(min = 16))]
    pub refresh_token: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct MeResponse {
    pub user: UserDetailDto,
    pub effective_permissions: crate::api_types::permissions::EffectivePermissionsDto,
}
