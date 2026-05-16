use crate::{
    activities::engine::row_to_activity_rule,
    api_types::{
        activities::*,
        common::{DeleteResultDto, ListQuery, PaginationMeta},
        enums::{enum_from_str, enum_to_string, ActivityStatus, PermissionAction, ResourceType},
    },
    app_state::AppState,
    auth::AuthUser,
    error::AppError,
    forms::service as form_service,
    permissions::engine,
    response,
};
use axum::{
    extract::{Path, Query, State},
    routing::{get, patch},
    Json, Router,
};
use serde_json::json;
use sqlx::Row;
use uuid::Uuid;
use validator::Validate;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/activities", get(list_activities))
        .route("/activities/{id}", get(get_activity).patch(update_activity))
        .route(
            "/forms/{id}/activity-rules",
            get(list_activity_rules).post(create_activity_rule),
        )
        .route(
            "/activity-rules/{id}",
            patch(update_activity_rule).delete(delete_activity_rule),
        )
}

pub async fn list_activities(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(q): Query<ListQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    let org_id = auth.organization_id;
    let rows = sqlx::query("select id, organization_id, form_id, submission_id, assigned_to_user_id, title, status, due_at, created_at from activities where ($1::uuid is null or organization_id=$1) and deleted_at is null order by created_at desc limit $2 offset $3")
        .bind(org_id).bind(q.limit()).bind(q.offset()).fetch_all(&state.db).await?;
    let total: i64 = sqlx::query_scalar("select count(*) from activities where ($1::uuid is null or organization_id=$1) and deleted_at is null").bind(org_id).fetch_one(&state.db).await.unwrap_or(0);
    let mut items = vec![];
    for row in rows {
        items.push(ActivitySummaryDto {
            id: row.try_get("id")?,
            form_id: row.try_get("form_id")?,
            title: row.try_get("title")?,
            status: enum_from_str(&row.try_get::<String, _>("status")?)
                .unwrap_or(ActivityStatus::Open),
            assigned_to_user_id: row.try_get("assigned_to_user_id")?,
            due_at: row.try_get("due_at")?,
            created_at: row.try_get("created_at")?,
        });
    }
    Ok(response::list(
        items,
        PaginationMeta::new(q.page, q.limit(), total),
    ))
}

pub async fn get_activity(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    let row = sqlx::query("select id, organization_id, form_id, submission_id, assigned_to_user_id, title, description, status, due_at, metadata, created_at, updated_at from activities where id=$1 and deleted_at is null")
        .bind(id).fetch_one(&state.db).await?;
    let org_id: Uuid = row.try_get("organization_id")?;
    engine::require_permission(
        &auth,
        PermissionAction::Read,
        ResourceType::Activity,
        &engine::ResourceAttrs {
            organization_id: Some(org_id),
            ..Default::default()
        },
    )?;
    Ok(response::ok(row_to_activity(&row)?))
}

pub async fn update_activity(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateActivityRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    let current =
        sqlx::query("select organization_id from activities where id=$1 and deleted_at is null")
            .bind(id)
            .fetch_one(&state.db)
            .await?;
    let org_id: Uuid = current.try_get("organization_id")?;
    engine::require_permission(
        &auth,
        PermissionAction::Update,
        ResourceType::Activity,
        &engine::ResourceAttrs {
            organization_id: Some(org_id),
            ..Default::default()
        },
    )?;
    let row = sqlx::query("update activities set title=coalesce($2,title), description=coalesce($3,description), status=coalesce($4,status), assigned_to_user_id=coalesce($5,assigned_to_user_id), due_at=coalesce($6,due_at), metadata=coalesce($7,metadata), updated_at=now() where id=$1 returning id, organization_id, form_id, submission_id, assigned_to_user_id, title, description, status, due_at, metadata, created_at, updated_at")
        .bind(id)
        .bind(payload.title)
        .bind(payload.description)
        .bind(payload.status.map(|value| enum_to_string(&value)))
        .bind(payload.assigned_to_user_id)
        .bind(payload.due_at)
        .bind(payload.metadata)
        .fetch_one(&state.db)
        .await?;
    Ok(response::ok(row_to_activity(&row)?))
}

pub async fn list_activity_rules(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(form_id): Path<Uuid>,
    Query(q): Query<ListQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    let form = form_service::get_form(&state, &auth, form_id).await?;
    engine::require_permission(
        &auth,
        PermissionAction::Read,
        ResourceType::Activity,
        &engine::ResourceAttrs {
            organization_id: Some(form.organization_id),
            owner_id: Some(form.creator_id),
            ..Default::default()
        },
    )?;
    let rows = sqlx::query("select id, form_id, trigger_type, condition, action_type, action_config, enabled, created_at, updated_at from activity_rules where form_id=$1 and deleted_at is null order by created_at desc limit $2 offset $3")
        .bind(form_id).bind(q.limit()).bind(q.offset()).fetch_all(&state.db).await?;
    let total: i64 = sqlx::query_scalar(
        "select count(*) from activity_rules where form_id=$1 and deleted_at is null",
    )
    .bind(form_id)
    .fetch_one(&state.db)
    .await
    .unwrap_or(0);
    let mut items = vec![];
    for row in rows {
        items.push(row_to_activity_rule(&row)?);
    }
    Ok(response::list(
        items,
        PaginationMeta::new(q.page, q.limit(), total),
    ))
}

pub async fn create_activity_rule(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(form_id): Path<Uuid>,
    Json(payload): Json<CreateActivityRuleRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    let form = form_service::get_form(&state, &auth, form_id).await?;
    engine::require_permission(
        &auth,
        PermissionAction::Update,
        ResourceType::Activity,
        &engine::ResourceAttrs {
            organization_id: Some(form.organization_id),
            owner_id: Some(form.creator_id),
            ..Default::default()
        },
    )?;
    let row = sqlx::query("insert into activity_rules (form_id, trigger_type, condition, action_type, action_config, enabled) values ($1,$2,$3,$4,$5,$6) returning id, form_id, trigger_type, condition, action_type, action_config, enabled, created_at, updated_at")
        .bind(form_id).bind(enum_to_string(&payload.trigger_type)).bind(payload.condition).bind(enum_to_string(&payload.action_type)).bind(payload.action_config).bind(payload.enabled).fetch_one(&state.db).await?;
    Ok(response::created(row_to_activity_rule(&row)?))
}

pub async fn update_activity_rule(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateActivityRuleRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    let row = sqlx::query("select ar.id, ar.form_id, f.organization_id, f.creator_id from activity_rules ar join forms f on f.id=ar.form_id where ar.id=$1 and ar.deleted_at is null").bind(id).fetch_one(&state.db).await?;
    engine::require_permission(
        &auth,
        PermissionAction::Update,
        ResourceType::Activity,
        &engine::ResourceAttrs {
            organization_id: Some(row.try_get("organization_id")?),
            owner_id: Some(row.try_get("creator_id")?),
            ..Default::default()
        },
    )?;
    let updated = sqlx::query("update activity_rules set trigger_type=coalesce($2,trigger_type), condition=coalesce($3,condition), action_type=coalesce($4,action_type), action_config=coalesce($5,action_config), enabled=coalesce($6,enabled), updated_at=now() where id=$1 returning id, form_id, trigger_type, condition, action_type, action_config, enabled, created_at, updated_at")
        .bind(id).bind(payload.trigger_type.map(|v| enum_to_string(&v))).bind(payload.condition).bind(payload.action_type.map(|v| enum_to_string(&v))).bind(payload.action_config).bind(payload.enabled).fetch_one(&state.db).await?;
    Ok(response::ok(row_to_activity_rule(&updated)?))
}

pub async fn delete_activity_rule(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    let row = sqlx::query("select ar.form_id, f.organization_id, f.creator_id from activity_rules ar join forms f on f.id=ar.form_id where ar.id=$1 and ar.deleted_at is null").bind(id).fetch_one(&state.db).await?;
    engine::require_permission(
        &auth,
        PermissionAction::Delete,
        ResourceType::Activity,
        &engine::ResourceAttrs {
            organization_id: Some(row.try_get("organization_id")?),
            owner_id: Some(row.try_get("creator_id")?),
            ..Default::default()
        },
    )?;
    sqlx::query("update activity_rules set deleted_at=now(), updated_at=now() where id=$1")
        .bind(id)
        .execute(&state.db)
        .await?;
    Ok(response::ok(DeleteResultDto { deleted: true }))
}

fn row_to_activity(row: &sqlx::postgres::PgRow) -> Result<ActivityDto, AppError> {
    Ok(ActivityDto {
        id: row.try_get("id")?,
        organization_id: row.try_get("organization_id")?,
        form_id: row.try_get("form_id")?,
        submission_id: row.try_get("submission_id")?,
        assigned_to_user_id: row.try_get("assigned_to_user_id")?,
        title: row.try_get("title")?,
        description: row.try_get("description")?,
        status: enum_from_str(&row.try_get::<String, _>("status")?).unwrap_or(ActivityStatus::Open),
        due_at: row.try_get("due_at")?,
        metadata: row.try_get("metadata").unwrap_or_else(|_| json!({})),
        created_at: row.try_get("created_at")?,
        updated_at: row.try_get("updated_at")?,
    })
}
