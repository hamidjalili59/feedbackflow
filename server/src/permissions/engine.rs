use crate::{
    api_types::{
        enums::*,
        organizations::RoleRuleDto,
        permissions::{ApprovalRuleDto, EffectivePermissionsDto, PublishingRuleDto},
    },
    app_state::AppState,
    auth::AuthUser,
    error::AppError,
};
use axum::http::StatusCode;
use serde_json::{json, Value};
use sqlx::Row;
use std::collections::HashSet;
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct ResourceAttrs {
    pub organization_id: Option<Uuid>,
    pub owner_id: Option<Uuid>,
    pub form_status: Option<FormStatus>,
    pub visibility_mode: Option<VisibilityMode>,
    pub publish_mode: Option<PublishMode>,
    pub target_user_id: Option<Uuid>,
    pub public_link: bool,
}

impl Default for ResourceAttrs {
    fn default() -> Self {
        Self {
            organization_id: None,
            owner_id: None,
            form_status: None,
            visibility_mode: None,
            publish_mode: None,
            target_user_id: None,
            public_link: false,
        }
    }
}

pub async fn effective_permissions_for_user(
    state: &AppState,
    user: &AuthUser,
) -> Result<EffectivePermissionsDto, AppError> {
    let field_types = allowed_field_types_for_role(state, user.organization_id, user.role)
        .await
        .unwrap_or_else(|_| default_field_types_for_role(user.role));
    let publishing_rules = publishing_rules_for_org(state, user.organization_id)
        .await
        .unwrap_or_else(|_| default_publishing_rules());
    let actions = default_actions_for_role(user.role);
    let resources = default_resources_for_role(user.role);
    Ok(EffectivePermissionsDto {
        user_id: user.user_id,
        organization_id: user.organization_id,
        role: user.role,
        can_manage_permissions: actions.contains(&PermissionAction::ManagePermissions),
        can_manage_scoring: actions.contains(&PermissionAction::ManageScoring),
        can_manage_public_protection: actions.contains(&PermissionAction::ManagePublicProtection),
        actions,
        resources,
        field_types,
        publishing_rules,
        abac_context: json!({"organization_boundary": user.organization_id}),
    })
}

pub fn default_actions_for_role(role: UserRole) -> Vec<PermissionAction> {
    use PermissionAction::*;
    match role {
        UserRole::Guest => vec![Read, Answer],
        UserRole::Parent | UserRole::Student => vec![Read, Answer],
        UserRole::Teacher => vec![Create, Read, Update, Delete, Publish, Answer, ViewResults],
        UserRole::Manager => vec![
            Create,
            Read,
            Update,
            Delete,
            Publish,
            Approve,
            Reject,
            Answer,
            ViewResults,
            Export,
            ManageScoring,
            ManagePublicProtection,
        ],
        UserRole::Admin => vec![
            Create,
            Read,
            Update,
            Delete,
            Publish,
            Approve,
            Reject,
            Answer,
            ViewResults,
            Export,
            ManagePermissions,
            ManageScoring,
            ManagePublicProtection,
        ],
        UserRole::Ceo | UserRole::SuperAdmin => vec![
            Create,
            Read,
            Update,
            Delete,
            Publish,
            Approve,
            Reject,
            Answer,
            ViewResults,
            Export,
            ManagePermissions,
            ManageScoring,
            ManagePublicProtection,
        ],
    }
}

pub fn default_resources_for_role(role: UserRole) -> Vec<ResourceType> {
    use ResourceType::*;
    match role {
        UserRole::Guest => vec![Form, Submission],
        UserRole::Parent | UserRole::Student => vec![Form, Submission, User],
        UserRole::Teacher => vec![Form, FormField, Submission, Activity, User],
        UserRole::Manager => vec![
            Form,
            FormField,
            Submission,
            Activity,
            User,
            Organization,
            ScoreTemplate,
            Metric,
            AudienceSegment,
        ],
        UserRole::Admin | UserRole::Ceo | UserRole::SuperAdmin => vec![
            Form,
            FormField,
            Submission,
            Activity,
            User,
            Organization,
            Permission,
            ScoreTemplate,
            Metric,
            AudienceSegment,
            AuditLog,
        ],
    }
}

pub fn all_field_types() -> Vec<FieldType> {
    use FieldType::*;
    vec![
        ShortText,
        LongText,
        Email,
        Phone,
        Number,
        Decimal,
        Date,
        Time,
        DateTime,
        SingleChoice,
        MultipleChoice,
        Dropdown,
        RatingStars,
        NumericRating,
        Slider,
        LikertScale,
        MatrixSingleChoice,
        MatrixMultipleChoice,
        YesNo,
        BooleanSwitch,
        Nps,
        EmojiReaction,
        FileUpload,
        ImageUpload,
        Signature,
        Location,
        Ranking,
        SectionTitle,
        DescriptionBlock,
        Divider,
        ConsentCheckbox,
        TermsAcceptance,
        Hidden,
        Calculated,
        ConditionalLogic,
        ScoreDisplay,
        QuizQuestion,
        PageBreak,
    ]
}

pub fn default_field_types_for_role(role: UserRole) -> Vec<FieldType> {
    use FieldType::*;
    match role {
        UserRole::Guest | UserRole::Parent | UserRole::Student => vec![],
        UserRole::Teacher => vec![
            ShortText,
            LongText,
            Email,
            Phone,
            Number,
            Date,
            Time,
            SingleChoice,
            MultipleChoice,
            Dropdown,
            RatingStars,
            NumericRating,
            Slider,
            LikertScale,
            YesNo,
            BooleanSwitch,
            Nps,
            EmojiReaction,
            SectionTitle,
            DescriptionBlock,
            Divider,
            ConsentCheckbox,
            TermsAcceptance,
            PageBreak,
        ],
        UserRole::Manager | UserRole::Admin | UserRole::Ceo | UserRole::SuperAdmin => {
            all_field_types()
        }
    }
}

pub fn default_publishing_rules() -> Vec<PublishingRuleDto> {
    use PublishMode::*;
    vec![
        PublishingRuleDto {
            role: UserRole::Teacher,
            can_publish_directly: false,
            allowed_publish_modes: vec![Private, Subordinates, RoleBased, Organization],
            approval_rule: ApprovalRuleDto {
                role: UserRole::Teacher,
                approval_required: true,
                two_step_required: true,
                approver_roles: vec![
                    UserRole::Manager,
                    UserRole::Admin,
                    UserRole::Ceo,
                    UserRole::SuperAdmin,
                ],
            },
            can_disable_public_protection: false,
        },
        PublishingRuleDto {
            role: UserRole::Manager,
            can_publish_directly: true,
            allowed_publish_modes: vec![Private, Subordinates, RoleBased, Organization, PublicLink],
            approval_rule: ApprovalRuleDto {
                role: UserRole::Manager,
                approval_required: false,
                two_step_required: false,
                approver_roles: vec![UserRole::Admin, UserRole::Ceo, UserRole::SuperAdmin],
            },
            can_disable_public_protection: true,
        },
        PublishingRuleDto {
            role: UserRole::Admin,
            can_publish_directly: true,
            allowed_publish_modes: vec![Private, Subordinates, RoleBased, Organization, PublicLink],
            approval_rule: ApprovalRuleDto {
                role: UserRole::Admin,
                approval_required: false,
                two_step_required: false,
                approver_roles: vec![UserRole::Ceo, UserRole::SuperAdmin],
            },
            can_disable_public_protection: true,
        },
        PublishingRuleDto {
            role: UserRole::Ceo,
            can_publish_directly: true,
            allowed_publish_modes: vec![Private, Subordinates, RoleBased, Organization, PublicLink],
            approval_rule: ApprovalRuleDto {
                role: UserRole::Ceo,
                approval_required: false,
                two_step_required: false,
                approver_roles: vec![UserRole::SuperAdmin],
            },
            can_disable_public_protection: true,
        },
        PublishingRuleDto {
            role: UserRole::SuperAdmin,
            can_publish_directly: true,
            allowed_publish_modes: vec![Private, Subordinates, RoleBased, Organization, PublicLink],
            approval_rule: ApprovalRuleDto {
                role: UserRole::SuperAdmin,
                approval_required: false,
                two_step_required: false,
                approver_roles: vec![UserRole::SuperAdmin],
            },
            can_disable_public_protection: true,
        },
    ]
}

pub fn can_rbac(role: UserRole, action: PermissionAction, resource: ResourceType) -> bool {
    default_actions_for_role(role).contains(&action)
        && default_resources_for_role(role).contains(&resource)
}

pub fn can_abac(
    user: &AuthUser,
    action: PermissionAction,
    resource: ResourceType,
    attrs: &ResourceAttrs,
) -> bool {
    if matches!(user.role, UserRole::Ceo | UserRole::SuperAdmin) {
        return true;
    }
    if matches!(user.role, UserRole::Admin) {
        return attrs.organization_id.is_none() || attrs.organization_id == user.organization_id;
    }
    if attrs.organization_id.is_some() && attrs.organization_id != user.organization_id {
        return false;
    }
    match (action, resource) {
        (
            PermissionAction::Update | PermissionAction::Delete | PermissionAction::Publish,
            ResourceType::Form,
        ) => attrs.owner_id == Some(user.user_id) || matches!(user.role, UserRole::Manager),
        (PermissionAction::Approve | PermissionAction::Reject, ResourceType::Form) => {
            matches!(user.role, UserRole::Manager | UserRole::Admin)
        }
        (PermissionAction::Answer, ResourceType::Form) => {
            attrs.form_status == Some(FormStatus::Published)
        }
        (PermissionAction::ManagePermissions, _) => matches!(user.role, UserRole::Admin),
        _ => true,
    }
}

pub fn require_permission(
    user: &AuthUser,
    action: PermissionAction,
    resource: ResourceType,
    attrs: &ResourceAttrs,
) -> Result<(), AppError> {
    if can_rbac(user.role, action, resource) && can_abac(user, action, resource, attrs) {
        Ok(())
    } else {
        Err(AppError::with_details(
            StatusCode::FORBIDDEN,
            ErrorCode::PermissionDenied,
            "Permission denied",
            json!({"action": enum_to_string(&action), "resource": enum_to_string(&resource)}),
        ))
    }
}

pub async fn role_requires_approval(
    state: &AppState,
    org_id: Option<Uuid>,
    role: UserRole,
) -> Result<bool, AppError> {
    let rules = publishing_rules_for_org(state, org_id)
        .await
        .unwrap_or_else(|_| default_publishing_rules());
    Ok(rules
        .iter()
        .find(|r| r.role == role)
        .map(|r| r.approval_rule.approval_required || r.approval_rule.two_step_required)
        .unwrap_or(false))
}

pub async fn can_publish_directly(
    state: &AppState,
    org_id: Option<Uuid>,
    role: UserRole,
    mode: PublishMode,
) -> Result<bool, AppError> {
    let rules = publishing_rules_for_org(state, org_id)
        .await
        .unwrap_or_else(|_| default_publishing_rules());
    Ok(rules
        .iter()
        .find(|r| r.role == role)
        .map(|r| r.can_publish_directly && r.allowed_publish_modes.contains(&mode))
        .unwrap_or(false))
}

pub async fn can_disable_public_protection(
    state: &AppState,
    org_id: Option<Uuid>,
    role: UserRole,
) -> Result<bool, AppError> {
    let rules = publishing_rules_for_org(state, org_id)
        .await
        .unwrap_or_else(|_| default_publishing_rules());
    Ok(rules
        .iter()
        .find(|r| r.role == role)
        .map(|r| r.can_disable_public_protection)
        .unwrap_or(matches!(
            role,
            UserRole::Admin | UserRole::Ceo | UserRole::SuperAdmin
        )))
}

pub async fn allowed_field_types_for_role(
    state: &AppState,
    org_id: Option<Uuid>,
    role: UserRole,
) -> Result<Vec<FieldType>, AppError> {
    let Some(org_id) = org_id else {
        return Ok(default_field_types_for_role(role));
    };
    let row = sqlx::query(
        "select rules from organization_role_rules where organization_id=$1 and role=$2",
    )
    .bind(org_id)
    .bind(enum_to_string(&role))
    .fetch_optional(&state.db)
    .await?;
    if let Some(row) = row {
        let value: Value = row.try_get("rules")?;
        if let Ok(rule) = serde_json::from_value::<RoleRuleDto>(value) {
            let denied: HashSet<_> = rule.denied_field_types.into_iter().collect();
            return Ok(rule
                .allowed_field_types
                .into_iter()
                .filter(|ft| !denied.contains(ft))
                .collect());
        }
    }
    Ok(default_field_types_for_role(role))
}

pub async fn publishing_rules_for_org(
    state: &AppState,
    org_id: Option<Uuid>,
) -> Result<Vec<PublishingRuleDto>, AppError> {
    let Some(org_id) = org_id else {
        return Ok(default_publishing_rules());
    };
    let rows = sqlx::query("select rules from organization_role_rules where organization_id=$1")
        .bind(org_id)
        .fetch_all(&state.db)
        .await?;
    let mut out = vec![];
    for row in rows {
        let value: Value = row.try_get("rules")?;
        if let Ok(role_rule) = serde_json::from_value::<RoleRuleDto>(value) {
            out.push(PublishingRuleDto {
                role: role_rule.role,
                can_publish_directly: role_rule.can_publish_forms
                    && !role_rule.requires_approval_to_publish,
                allowed_publish_modes: vec![
                    PublishMode::Private,
                    PublishMode::Organization,
                    PublishMode::Subordinates,
                    PublishMode::RoleBased,
                    PublishMode::PublicLink,
                ],
                approval_rule: ApprovalRuleDto {
                    role: role_rule.role,
                    approval_required: role_rule.requires_approval_to_publish,
                    two_step_required: role_rule.two_step_approval_required,
                    approver_roles: role_rule.approver_roles,
                },
                can_disable_public_protection: matches!(
                    role_rule.role,
                    UserRole::Manager | UserRole::Admin | UserRole::Ceo | UserRole::SuperAdmin
                ),
            });
        }
    }
    if out.is_empty() {
        Ok(default_publishing_rules())
    } else {
        Ok(out)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn teacher_requires_approval_by_default() {
        let rule = default_publishing_rules()
            .into_iter()
            .find(|r| r.role == UserRole::Teacher)
            .unwrap();
        assert!(rule.approval_rule.approval_required);
        assert!(!rule.can_publish_directly);
    }

    #[test]
    fn admin_can_manage_permissions() {
        assert!(can_rbac(
            UserRole::Admin,
            PermissionAction::ManagePermissions,
            ResourceType::Permission
        ));
    }

    #[test]
    fn org_boundary_blocks_non_admin_cross_org() {
        let org_a = Uuid::new_v4();
        let org_b = Uuid::new_v4();
        let user = AuthUser {
            user_id: Uuid::new_v4(),
            organization_id: Some(org_a),
            role: UserRole::Teacher,
        };
        let attrs = ResourceAttrs {
            organization_id: Some(org_b),
            ..Default::default()
        };
        assert!(!can_abac(
            &user,
            PermissionAction::Read,
            ResourceType::Form,
            &attrs
        ));
    }
}
