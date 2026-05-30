use crate::{
    api_types::{common::DeleteResultDto, metrics::*},
    app_state::AppState,
    auth::AuthUser,
    error::AppError,
    metrics::service,
    response,
};
use axum::{
    extract::{Path, Query, State},
    routing::get,
    Json, Router,
};
use uuid::Uuid;
use validator::Validate;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/metrics", get(list_metrics).post(create_metric))
        .route("/metrics/{id}", get(get_metric).patch(update_metric).delete(delete_metric))
        .route("/metrics/{id}/mappings", get(list_mappings).put(set_mappings))
}

async fn list_metrics(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(q): Query<MetricQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    let (items, meta) = service::list_metrics(&state, &auth, &q).await?;
    Ok(response::list(items, meta))
}

async fn create_metric(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(payload): Json<CreateMetricDefinitionRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::created(
        service::create_metric(&state, &auth, payload).await?,
    ))
}

async fn get_metric(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(service::get_metric(&state, &auth, id).await?))
}

async fn update_metric(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateMetricDefinitionRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(
        service::update_metric(&state, &auth, id, payload).await?,
    ))
}

async fn delete_metric(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    service::delete_metric(&state, &auth, id).await?;
    Ok(response::ok(DeleteResultDto { deleted: true }))
}

async fn list_mappings(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(service::list_mappings(&state, &auth, id).await?))
}

async fn set_mappings(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<SetMetricMappingsRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(
        service::set_mappings(&state, &auth, id, payload).await?,
    ))
}
