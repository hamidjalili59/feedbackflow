use crate::{
    api_types::{
        common::{PaginationMeta, UpdateResultDto},
        enums::{AuditAction, PermissionAction, ResourceType, UserRole},
        organizations::*,
    },
    app_state::AppState,
    auth::{service as auth_service, AuthUser},
    error::AppError,
    permissions::engine::{self, ResourceAttrs},
    response,
};
use axum::{
    extract::{Path, State},
    routing::{get, patch},
    Json, Router,
};
use serde_json::json;
use sqlx::Row;
use uuid::Uuid;
use validator::Validate;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/organizations/{id}", get(get_organization))
        .route("/organizations/{id}/roles", get(get_organization_roles))
        .route("/organizations/{id}/role-rules", patch(update_role_rules))
}

pub async fn get_organization(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    engine::require_permission(
        &auth,
        PermissionAction::Read,
        ResourceType::Organization,
        &ResourceAttrs {
            organization_id: Some(id),
            ..Default::default()
        },
    )?;
    let row = sqlx::query("select id, parent_organization_id, name, slug, settings, created_at, updated_at from organizations where id=$1 and deleted_at is null")
        .bind(id).fetch_one(&state.db).await?;
    Ok(response::ok(row_to_org(&row)?))
}

pub async fn get_organization_roles(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    engine::require_permission(
        &auth,
        PermissionAction::Read,
        ResourceType::Permission,
        &ResourceAttrs {
            organization_id: Some(id),
            ..Default::default()
        },
    )?;
    let rows = sqlx::query("select id, organization_id, name, display_name, default_permissions, is_system from roles where organization_id is null or organization_id=$1 order by is_system desc, name asc")
        .bind(id).fetch_all(&state.db).await?;
    let mut items = vec![];
    for row in rows {
        let role: UserRole =
            crate::api_types::enums::enum_from_str(&row.try_get::<String, _>("name")?)
                .unwrap_or(UserRole::Parent);
        let perms_value: serde_json::Value = row
            .try_get("default_permissions")
            .unwrap_or_else(|_| json!([]));
        let default_permissions: Vec<PermissionAction> =
            serde_json::from_value(perms_value).unwrap_or_default();
        items.push(OrganizationRoleDto {
            id: row.try_get("id")?,
            organization_id: row.try_get("organization_id")?,
            name: role,
            display_name: row.try_get("display_name")?,
            is_system: row.try_get("is_system")?,
            default_permissions,
        });
    }
    Ok(response::list(items, PaginationMeta::new(1, 100, 7)))
}

pub async fn update_role_rules(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateRoleRulesRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    engine::require_permission(
        &auth,
        PermissionAction::ManagePermissions,
        ResourceType::Permission,
        &ResourceAttrs {
            organization_id: Some(id),
            ..Default::default()
        },
    )?;
    for rule in payload.rules.iter() {
        sqlx::query("insert into organization_role_rules (organization_id, role, rules) values ($1,$2,$3) on conflict (organization_id, role) do update set rules=excluded.rules, updated_at=now()")
            .bind(id).bind(crate::api_types::enums::enum_to_string(&rule.role)).bind(json!(rule)).execute(&state.db).await?;
    }
    auth_service::audit(
        &state,
        Some(id),
        Some(auth.user_id),
        AuditAction::PermissionChanged,
        "organization_role_rules",
        Some(id),
        json!({"count": payload.rules.len()}),
    )
    .await?;
    Ok(response::ok(UpdateResultDto { updated: true }))
}

pub fn row_to_org(row: &sqlx::postgres::PgRow) -> Result<OrganizationDto, AppError> {
    let settings_value: serde_json::Value = row.try_get("settings").unwrap_or_else(|_| json!({}));
    let settings: OrganizationSettingsDto =
        serde_json::from_value(settings_value).unwrap_or_default();
    Ok(OrganizationDto {
        id: row.try_get("id")?,
        parent_organization_id: row.try_get("parent_organization_id")?,
        name: row.try_get("name")?,
        slug: row.try_get("slug")?,
        settings,
        created_at: row.try_get("created_at")?,
        updated_at: row.try_get("updated_at")?,
    })
}
