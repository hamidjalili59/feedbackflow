use crate::api_types::enums::{FieldType, PermissionAction, UserRole};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use utoipa::ToSchema;
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct OrganizationSettingsDto {
    pub default_timezone: String,
    pub public_forms_enabled: bool,
    pub default_public_protection_level: crate::api_types::enums::PublicProtectionLevel,
    pub require_audit_for_public_protection_disable: bool,
    #[serde(default)]
    pub metadata: Value,
}

impl Default for OrganizationSettingsDto {
    fn default() -> Self {
        Self {
            default_timezone: "UTC".to_owned(),
            public_forms_enabled: true,
            default_public_protection_level:
                crate::api_types::enums::PublicProtectionLevel::Standard,
            require_audit_for_public_protection_disable: true,
            metadata: Value::Object(Default::default()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct OrganizationDto {
    pub id: Uuid,
    pub parent_organization_id: Option<Uuid>,
    pub name: String,
    pub slug: String,
    pub settings: OrganizationSettingsDto,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct OrganizationRoleDto {
    pub id: Uuid,
    pub organization_id: Option<Uuid>,
    pub name: UserRole,
    pub display_name: String,
    pub is_system: bool,
    #[serde(default)]
    pub default_permissions: Vec<PermissionAction>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct RoleRuleDto {
    pub role: UserRole,
    pub can_create_forms: bool,
    pub can_publish_forms: bool,
    pub requires_approval_to_publish: bool,
    pub two_step_approval_required: bool,
    pub can_change_scoring: bool,
    pub approver_roles: Vec<UserRole>,
    pub allowed_field_types: Vec<FieldType>,
    pub denied_field_types: Vec<FieldType>,
    #[serde(default)]
    pub metadata: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct UpdateRoleRulesRequest {
    #[validate(length(min = 1))]
    pub rules: Vec<RoleRuleDto>,
}
