use crate::api_types::enums::{FieldType, PermissionAction, ResourceType, UserRole};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use utoipa::ToSchema;
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct PermissionDto {
    pub id: Uuid,
    pub action: PermissionAction,
    pub resource_type: ResourceType,
    pub key: String,
    pub description: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct RolePermissionDto {
    pub role: UserRole,
    pub permission: PermissionDto,
    pub allowed: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FieldTypePermissionDto {
    pub role: UserRole,
    pub field_type: FieldType,
    pub allowed: bool,
    pub reason: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct UpdateFieldTypePermissionsRequest {
    #[validate(length(min = 1))]
    pub permissions: Vec<FieldTypePermissionDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ApprovalRuleDto {
    pub role: UserRole,
    pub approval_required: bool,
    pub two_step_required: bool,
    pub approver_roles: Vec<UserRole>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct PublishingRuleDto {
    pub role: UserRole,
    pub can_publish_directly: bool,
    pub allowed_publish_modes: Vec<crate::api_types::enums::PublishMode>,
    pub approval_rule: ApprovalRuleDto,
    pub can_disable_public_protection: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate, ToSchema)]
pub struct UpdatePublishingRulesRequest {
    #[validate(length(min = 1))]
    pub rules: Vec<PublishingRuleDto>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct EffectivePermissionsDto {
    pub user_id: Uuid,
    pub organization_id: Option<Uuid>,
    pub role: UserRole,
    pub actions: Vec<PermissionAction>,
    pub resources: Vec<ResourceType>,
    pub field_types: Vec<FieldType>,
    pub publishing_rules: Vec<PublishingRuleDto>,
    pub can_manage_permissions: bool,
    pub can_manage_scoring: bool,
    pub can_manage_public_protection: bool,
    #[serde(default)]
    pub abac_context: Value,
}
