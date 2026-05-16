use crate::{
    api_types::{
        common::{ListQuery, UpdateResultDto},
        enums::{AuditAction, FieldType, PermissionAction, ResourceType, UserRole},
        permissions::*,
    },
    app_state::AppState,
    auth::{service as auth_service, AuthUser},
    error::AppError,
    permissions::engine,
    response,
};
use axum::{
    extract::{Query, State},
    routing::get,
    Json, Router,
};
use serde_json::json;
use validator::Validate;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/permissions/effective", get(get_effective_permissions))
        .route(
            "/permissions/field-types",
            get(get_field_type_permissions).patch(update_field_type_permissions),
        )
        .route(
            "/permissions/publishing-rules",
            get(get_publishing_rules).patch(update_publishing_rules),
        )
}

pub async fn get_effective_permissions(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(
        engine::effective_permissions_for_user(&state, &auth).await?,
    ))
}

pub async fn get_field_type_permissions(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(_q): Query<ListQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    let mut items = vec![];
    for role in [
        UserRole::Parent,
        UserRole::Student,
        UserRole::Teacher,
        UserRole::Manager,
        UserRole::Admin,
        UserRole::Ceo,
        UserRole::SuperAdmin,
    ] {
        let allowed = engine::allowed_field_types_for_role(&state, auth.organization_id, role)
            .await
            .unwrap_or_else(|_| engine::default_field_types_for_role(role));
        for field_type in engine::all_field_types() {
            items.push(FieldTypePermissionDto {
                role,
                field_type,
                allowed: allowed.contains(&field_type),
                reason: None,
            });
        }
    }
    Ok(response::ok(items))
}

pub async fn update_field_type_permissions(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(payload): Json<UpdateFieldTypePermissionsRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    engine::require_permission(
        &auth,
        PermissionAction::ManagePermissions,
        ResourceType::Permission,
        &engine::ResourceAttrs {
            organization_id: auth.organization_id,
            ..Default::default()
        },
    )?;
    let org_id = auth
        .organization_id
        .ok_or_else(|| AppError::forbidden("Organization context is required"))?;
    for role in [
        UserRole::Parent,
        UserRole::Student,
        UserRole::Teacher,
        UserRole::Manager,
        UserRole::Admin,
        UserRole::Ceo,
        UserRole::SuperAdmin,
    ] {
        let allowed: Vec<FieldType> = payload
            .permissions
            .iter()
            .filter(|p| p.role == role && p.allowed)
            .map(|p| p.field_type)
            .collect();
        let denied: Vec<FieldType> = payload
            .permissions
            .iter()
            .filter(|p| p.role == role && !p.allowed)
            .map(|p| p.field_type)
            .collect();
        let rule = crate::api_types::organizations::RoleRuleDto {
            role,
            can_create_forms: !allowed.is_empty(),
            can_publish_forms: matches!(
                role,
                UserRole::Manager | UserRole::Admin | UserRole::Ceo | UserRole::SuperAdmin
            ),
            requires_approval_to_publish: matches!(role, UserRole::Teacher),
            two_step_approval_required: matches!(role, UserRole::Teacher),
            can_change_scoring: matches!(
                role,
                UserRole::Manager | UserRole::Admin | UserRole::Ceo | UserRole::SuperAdmin
            ),
            approver_roles: vec![
                UserRole::Manager,
                UserRole::Admin,
                UserRole::Ceo,
                UserRole::SuperAdmin,
            ],
            allowed_field_types: allowed,
            denied_field_types: denied,
            metadata: json!({}),
        };
        sqlx::query("insert into organization_role_rules (organization_id, role, rules) values ($1,$2,$3) on conflict (organization_id, role) do update set rules=excluded.rules, updated_at=now()")
            .bind(org_id).bind(crate::api_types::enums::enum_to_string(&role)).bind(json!(rule)).execute(&state.db).await?;
    }
    auth_service::audit(
        &state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::PermissionChanged,
        "permission",
        None,
        json!({"change":"field_type_permissions"}),
    )
    .await?;
    Ok(response::ok(UpdateResultDto { updated: true }))
}

pub async fn get_publishing_rules(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(
        engine::publishing_rules_for_org(&state, auth.organization_id).await?,
    ))
}

pub async fn update_publishing_rules(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(payload): Json<UpdatePublishingRulesRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    engine::require_permission(
        &auth,
        PermissionAction::ManagePermissions,
        ResourceType::Permission,
        &engine::ResourceAttrs {
            organization_id: auth.organization_id,
            ..Default::default()
        },
    )?;
    let org_id = auth
        .organization_id
        .ok_or_else(|| AppError::forbidden("Organization context is required"))?;
    for rule in payload.rules.iter() {
        let role_rule = crate::api_types::organizations::RoleRuleDto {
            role: rule.role,
            can_create_forms: !matches!(
                rule.role,
                UserRole::Guest | UserRole::Parent | UserRole::Student
            ),
            can_publish_forms: rule.can_publish_directly,
            requires_approval_to_publish: rule.approval_rule.approval_required,
            two_step_approval_required: rule.approval_rule.two_step_required,
            can_change_scoring: matches!(
                rule.role,
                UserRole::Manager | UserRole::Admin | UserRole::Ceo | UserRole::SuperAdmin
            ),
            approver_roles: rule.approval_rule.approver_roles.clone(),
            allowed_field_types: engine::default_field_types_for_role(rule.role),
            denied_field_types: vec![],
            metadata: json!({"allowed_publish_modes": rule.allowed_publish_modes, "can_disable_public_protection": rule.can_disable_public_protection}),
        };
        sqlx::query("insert into organization_role_rules (organization_id, role, rules) values ($1,$2,$3) on conflict (organization_id, role) do update set rules=excluded.rules, updated_at=now()")
            .bind(org_id).bind(crate::api_types::enums::enum_to_string(&rule.role)).bind(json!(role_rule)).execute(&state.db).await?;
    }
    auth_service::audit(
        &state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::PermissionChanged,
        "permission",
        None,
        json!({"change":"publishing_rules"}),
    )
    .await?;
    Ok(response::ok(UpdateResultDto { updated: true }))
}
