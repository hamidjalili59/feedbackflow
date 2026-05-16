use crate::{
    api_types::{
        audit::AuditLogDto,
        common::{ListQuery, PaginationMeta},
        enums::{enum_from_str, AuditAction, PermissionAction, ResourceType},
    },
    app_state::AppState,
    auth::AuthUser,
    error::AppError,
    permissions::engine,
    response,
};
use axum::{
    extract::{Query, State},
    routing::get,
    Router,
};
use serde_json::json;
use sqlx::Row;

pub fn routes() -> Router<AppState> {
    Router::new().route("/audit-logs", get(list_audit_logs))
}

pub async fn list_audit_logs(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(q): Query<ListQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    engine::require_permission(
        &auth,
        PermissionAction::Read,
        ResourceType::AuditLog,
        &engine::ResourceAttrs {
            organization_id: auth.organization_id,
            ..Default::default()
        },
    )?;
    let rows = sqlx::query("select id, organization_id, actor_user_id, action, resource_type, resource_id, ip_address, user_agent, details, created_at from audit_logs where ($1::uuid is null or organization_id=$1) order by created_at desc limit $2 offset $3")
        .bind(auth.organization_id).bind(q.limit()).bind(q.offset()).fetch_all(&state.db).await?;
    let total: i64 = sqlx::query_scalar(
        "select count(*) from audit_logs where ($1::uuid is null or organization_id=$1)",
    )
    .bind(auth.organization_id)
    .fetch_one(&state.db)
    .await
    .unwrap_or(0);
    let mut items = vec![];
    for row in rows {
        items.push(AuditLogDto {
            id: row.try_get("id")?,
            organization_id: row.try_get("organization_id")?,
            actor_user_id: row.try_get("actor_user_id")?,
            action: enum_from_str(&row.try_get::<String, _>("action")?)
                .unwrap_or(AuditAction::Updated),
            resource_type: row.try_get("resource_type")?,
            resource_id: row.try_get("resource_id")?,
            ip_address: row.try_get("ip_address")?,
            user_agent: row.try_get("user_agent")?,
            details: row.try_get("details").unwrap_or_else(|_| json!({})),
            created_at: row.try_get("created_at")?,
        });
    }
    Ok(response::list(
        items,
        PaginationMeta::new(q.page, q.limit(), total),
    ))
}
