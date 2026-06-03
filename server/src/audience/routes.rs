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
    routing::{delete, get},
    Json, Router,
};
use uuid::Uuid;
use validator::Validate;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route(
            "/audience-segments",
            get(list_segments).post(create_segment),
        )
        .route(
            "/audience-segments/{id}",
            get(get_segment)
                .patch(update_segment)
                .delete(delete_segment),
        )
        .route(
            "/audience-segments/{id}/members",
            get(list_segment_members).put(set_segment_members),
        )
        .route("/audience-groups", get(list_group_options).post(create_group))
        .route(
            "/audience-groups/{id}",
            get(get_group).patch(update_group).delete(delete_group),
        )
        .route(
            "/audience-groups/{id}/members",
            get(list_group_members).put(set_group_members).post(add_group_member),
        )
        .route(
            "/audience-groups/{id}/members/{user_id}",
            delete(remove_group_member),
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

async fn list_group_options(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(q): Query<AudienceGroupQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    let (items, meta) = service::list_group_options(&state, &auth, &q).await?;
    Ok(response::list(items, meta))
}

async fn create_group(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(payload): Json<CreateAudienceGroupRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::created(service::create_group(&state, &auth, payload).await?))
}

async fn get_group(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(service::get_group(&state, &auth, id).await?))
}

async fn update_group(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateAudienceGroupRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(service::update_group(&state, &auth, id, payload).await?))
}

async fn delete_group(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    service::delete_group(&state, &auth, id).await?;
    Ok(response::ok(DeleteResultDto { deleted: true }))
}

async fn list_group_members(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(service::list_group_members(&state, &auth, id).await?))
}

async fn set_group_members(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<SetAudienceGroupMembersRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(service::set_group_members(&state, &auth, id, payload).await?))
}

async fn add_group_member(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<AudienceGroupMemberInputDto>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(service::add_group_member(&state, &auth, id, payload).await?))
}

async fn remove_group_member(
    State(state): State<AppState>,
    auth: AuthUser,
    Path((id, user_id)): Path<(Uuid, Uuid)>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(service::remove_group_member(&state, &auth, id, user_id).await?))
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
