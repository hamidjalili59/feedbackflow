use crate::{
    api_types::{
        common::{DeleteResultDto, ListQuery},
        submissions::{CreateSubmissionRequest, SaveAnswerDraftRequest, UpdateSubmissionRequest},
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
            "/forms/{id}/answer-draft",
            get(get_answer_draft).put(save_answer_draft).delete(delete_answer_draft),
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


pub async fn get_answer_draft(
    State(state): State<AppState>, auth: AuthUser, Path(id): Path<Uuid>,
    Query(q): Query<std::collections::HashMap<String, String>>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    let child_id = q.get("child_id").and_then(|v| Uuid::parse_str(v).ok());
    Ok(response::ok(service::get_answer_draft(&state, &auth, id, child_id).await?))
}

pub async fn save_answer_draft(
    State(state): State<AppState>, auth: AuthUser, Path(id): Path<Uuid>,
    Json(payload): Json<SaveAnswerDraftRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(service::save_answer_draft(&state, &auth, id, payload).await?))
}

pub async fn delete_answer_draft(
    State(state): State<AppState>, auth: AuthUser, Path(id): Path<Uuid>,
    Query(q): Query<std::collections::HashMap<String, String>>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    let child_id = q.get("child_id").and_then(|v| Uuid::parse_str(v).ok());
    service::delete_answer_draft(&state, &auth, id, child_id).await?;
    Ok(response::ok(DeleteResultDto { deleted: true }))
}
