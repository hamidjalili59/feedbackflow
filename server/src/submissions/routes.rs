use crate::{
    api_types::{
        common::{DeleteResultDto, ListQuery},
        submissions::{CreateSubmissionRequest, UpdateSubmissionRequest},
    },
    app_state::AppState,
    auth::AuthUser,
    error::AppError,
    response,
    submissions::service,
};
use axum::{
    extract::{Path, Query, State},
    routing::{get, post},
    Json, Router,
};
use uuid::Uuid;
use validator::Validate;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route(
            "/forms/{id}/submissions",
            post(create_submission).get(list_submissions),
        )
        .route(
            "/submissions/{id}",
            get(get_submission)
                .patch(update_submission)
                .delete(delete_submission),
        )
        .route(
            "/submissions/{id}/score-breakdown",
            get(get_score_breakdown),
        )
}

pub async fn create_submission(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<CreateSubmissionRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::created(
        service::create_submission(&state, Some(&auth), id, payload, None).await?,
    ))
}
pub async fn list_submissions(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Query(q): Query<ListQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    let (items, meta) = service::list_submissions(&state, &auth, id, &q).await?;
    Ok(response::list(items, meta))
}
pub async fn get_submission(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(
        service::get_submission(&state, &auth, id).await?,
    ))
}
pub async fn update_submission(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateSubmissionRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(
        service::update_submission(&state, &auth, id, payload).await?,
    ))
}
pub async fn delete_submission(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    service::delete_submission(&state, &auth, id).await?;
    Ok(response::ok(DeleteResultDto { deleted: true }))
}
pub async fn get_score_breakdown(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(
        service::score_breakdown(&state, &auth, id).await?,
    ))
}
