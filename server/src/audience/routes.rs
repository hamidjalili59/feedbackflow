use crate::{
    api_types::{audience::*, common::DeleteResultDto},
    app_state::AppState,
    audience::service,
    auth::AuthUser,
    error::AppError,
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
        .route("/audience-segments", get(list_segments).post(create_segment))
        .route(
            "/audience-segments/{id}",
            get(get_segment).patch(update_segment).delete(delete_segment),
        )
        .route(
            "/audience-segments/{id}/members",
            get(list_segment_members).put(set_segment_members),
        )
        .route(
            "/forms/{id}/assignments",
            get(list_form_assignments).put(set_form_assignments),
        )
}

async fn list_segments(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(q): Query<AudienceSegmentQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    let (items, meta) = service::list_segments(&state, &auth, &q).await?;
    Ok(response::list(items, meta))
}

async fn create_segment(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(payload): Json<CreateAudienceSegmentRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::created(
        service::create_segment(&state, &auth, payload).await?,
    ))
}

async fn get_segment(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(service::get_segment(&state, &auth, id).await?))
}

async fn update_segment(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateAudienceSegmentRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(
        service::update_segment(&state, &auth, id, payload).await?,
    ))
}

async fn delete_segment(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    service::delete_segment(&state, &auth, id).await?;
    Ok(response::ok(DeleteResultDto { deleted: true }))
}

async fn list_segment_members(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(
        service::list_segment_members(&state, &auth, id).await?,
    ))
}

async fn set_segment_members(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<SetAudienceSegmentMembersRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(
        service::set_segment_members(&state, &auth, id, payload).await?,
    ))
}

async fn list_form_assignments(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(
        service::list_form_assignments(&state, &auth, id).await?,
    ))
}

async fn set_form_assignments(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<SetFormAssignmentsRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(
        service::set_form_assignments(&state, &auth, id, payload).await?,
    ))
}
