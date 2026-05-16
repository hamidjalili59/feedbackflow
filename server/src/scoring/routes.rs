use crate::{
    api_types::{
        common::{DeleteResultDto, ListQuery, PaginationMeta},
        enums::{
            enum_from_str, enum_to_string, FieldType, PermissionAction, ResourceType, ScoringMode,
        },
        scoring::{CreateScoreTemplateRequest, ScoreTemplateDto, UpdateScoreTemplateRequest},
    },
    app_state::AppState,
    auth::AuthUser,
    error::AppError,
    permissions::engine::{self, ResourceAttrs},
    response,
};
use axum::{
    extract::{Path, Query, State},
    routing::get,
    Json, Router,
};
use serde_json::json;
use sqlx::Row;
use uuid::Uuid;
use validator::Validate;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route(
            "/score-templates",
            get(list_score_templates).post(create_score_template),
        )
        .route(
            "/score-templates/{id}",
            get(get_score_template)
                .patch(update_score_template)
                .delete(delete_score_template),
        )
}

pub async fn list_score_templates(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(q): Query<ListQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    engine::require_permission(
        &auth,
        PermissionAction::Read,
        ResourceType::ScoreTemplate,
        &ResourceAttrs {
            organization_id: auth.organization_id,
            ..Default::default()
        },
    )?;
    let rows = sqlx::query(
        "select id, organization_id, field_type, scoring_mode, name, config, is_default from score_templates where organization_id is null or organization_id=$1 order by is_default desc, name asc limit $2 offset $3",
    )
    .bind(auth.organization_id)
    .bind(q.limit())
    .bind(q.offset())
    .fetch_all(&state.db)
    .await?;
    let total: i64 = sqlx::query_scalar(
        "select count(*) from score_templates where organization_id is null or organization_id=$1",
    )
    .bind(auth.organization_id)
    .fetch_one(&state.db)
    .await
    .unwrap_or(0);
    let mut items = vec![];
    for row in rows {
        items.push(row_to_score_template(&row)?);
    }
    Ok(response::list(
        items,
        PaginationMeta::new(q.page, q.limit(), total),
    ))
}

pub async fn create_score_template(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(payload): Json<CreateScoreTemplateRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    engine::require_permission(
        &auth,
        PermissionAction::ManageScoring,
        ResourceType::ScoreTemplate,
        &ResourceAttrs {
            organization_id: auth.organization_id,
            ..Default::default()
        },
    )?;
    let row = sqlx::query(
        "insert into score_templates (organization_id, field_type, scoring_mode, name, config, is_default) values ($1, $2, $3, $4, $5, $6) returning id, organization_id, field_type, scoring_mode, name, config, is_default",
    )
    .bind(auth.organization_id)
    .bind(payload.field_type.map(|value| enum_to_string(&value)))
    .bind(enum_to_string(&payload.scoring_mode))
    .bind(payload.name)
    .bind(payload.config)
    .bind(payload.is_default)
    .fetch_one(&state.db)
    .await?;
    Ok(response::created(row_to_score_template(&row)?))
}

pub async fn get_score_template(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    let row = sqlx::query(
        "select id, organization_id, field_type, scoring_mode, name, config, is_default from score_templates where id=$1 and (organization_id is null or organization_id=$2)",
    )
    .bind(id)
    .bind(auth.organization_id)
    .fetch_one(&state.db)
    .await?;
    let organization_id: Option<Uuid> = row.try_get("organization_id")?;
    engine::require_permission(
        &auth,
        PermissionAction::Read,
        ResourceType::ScoreTemplate,
        &ResourceAttrs {
            organization_id,
            ..Default::default()
        },
    )?;
    Ok(response::ok(row_to_score_template(&row)?))
}

pub async fn update_score_template(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateScoreTemplateRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    engine::require_permission(
        &auth,
        PermissionAction::ManageScoring,
        ResourceType::ScoreTemplate,
        &ResourceAttrs {
            organization_id: auth.organization_id,
            ..Default::default()
        },
    )?;
    let row = sqlx::query(
        "update score_templates set field_type=coalesce($2, field_type), scoring_mode=coalesce($3, scoring_mode), name=coalesce($4, name), config=coalesce($5, config), is_default=coalesce($6, is_default), updated_at=now() where id=$1 and organization_id=$7 returning id, organization_id, field_type, scoring_mode, name, config, is_default",
    )
    .bind(id)
    .bind(payload.field_type.map(|value| enum_to_string(&value)))
    .bind(payload.scoring_mode.map(|value| enum_to_string(&value)))
    .bind(payload.name)
    .bind(payload.config)
    .bind(payload.is_default)
    .bind(auth.organization_id)
    .fetch_one(&state.db)
    .await?;
    Ok(response::ok(row_to_score_template(&row)?))
}

pub async fn delete_score_template(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    engine::require_permission(
        &auth,
        PermissionAction::ManageScoring,
        ResourceType::ScoreTemplate,
        &ResourceAttrs {
            organization_id: auth.organization_id,
            ..Default::default()
        },
    )?;
    sqlx::query("delete from score_templates where id=$1 and organization_id=$2")
        .bind(id)
        .bind(auth.organization_id)
        .execute(&state.db)
        .await?;
    Ok(response::ok(DeleteResultDto { deleted: true }))
}

fn row_to_score_template(row: &sqlx::postgres::PgRow) -> Result<ScoreTemplateDto, AppError> {
    let field_type = row
        .try_get::<Option<String>, _>("field_type")?
        .and_then(|value| enum_from_str::<FieldType>(&value).ok());
    let scoring_mode = enum_from_str::<ScoringMode>(&row.try_get::<String, _>("scoring_mode")?)
        .unwrap_or(ScoringMode::None);
    Ok(ScoreTemplateDto {
        id: row.try_get("id")?,
        organization_id: row.try_get("organization_id")?,
        field_type,
        scoring_mode,
        name: row.try_get("name")?,
        config: row.try_get("config").unwrap_or_else(|_| json!({})),
        is_default: row.try_get("is_default")?,
    })
}
