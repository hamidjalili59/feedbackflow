use crate::{
    api_types::{
        common::{DeleteResultDto, ListQuery},
        fields::{CreateFormFieldRequest, UpdateFormFieldRequest},
        forms::*,
    },
    app_state::AppState,
    auth::AuthUser,
    error::AppError,
    fields::service as field_service,
    forms::service,
    response,
};
use axum::{
    extract::{Path, Query, State},
    routing::{get, patch, post},
    Json, Router,
};
use serde::Deserialize;
use uuid::Uuid;
use validator::Validate;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/forms", post(create_form).get(list_forms))
        .route("/forms/tags", get(list_form_tags))
        .route("/dashboard/analytics", get(get_dashboard_analytics))
        .route(
            "/forms/{id}",
            get(get_form).patch(update_form).delete(delete_form),
        )
        .route("/forms/{id}/answer-access", get(get_answer_access))
        .route("/forms/{id}/fields", post(create_field))
        .route(
            "/forms/{id}/fields/{field_id}",
            patch(update_field).delete(delete_field),
        )
        .route("/forms/{id}/duplicate", post(duplicate_form))
        .route("/forms/{id}/submit-for-approval", post(submit_for_approval))
        .route("/forms/{id}/approve", post(approve_form))
        .route("/forms/{id}/reject", post(reject_form))
        .route("/forms/{id}/publish", post(publish_form))
        .route("/forms/{id}/close", post(close_form))
        .route("/forms/{id}/archive", post(archive_form))
        .route("/forms/{id}/visibility", patch(update_visibility))
        .route(
            "/forms/{id}/access-codes",
            get(list_access_codes).put(set_access_codes),
        )
        .route(
            "/forms/{id}/public-protection",
            patch(update_public_protection),
        )
        .route("/forms/{id}/analytics", get(get_analytics))
}

pub async fn list_form_tags(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(q): Query<ListQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(
        service::list_form_tags(&state, &auth, q.search).await?,
    ))
}

pub async fn create_form(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(payload): Json<CreateFormRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::created(
        service::create_form(&state, &auth, payload).await?,
    ))
}
pub async fn list_forms(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(q): Query<ListQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    let (items, meta) = service::list_forms(&state, &auth, &q).await?;
    Ok(response::list(items, meta))
}
pub async fn get_form(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Query(q): Query<FormContextQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(
        service::get_form_with_child(&state, &auth, id, q.child_id).await?,
    ))
}

pub async fn get_answer_access(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Query(q): Query<FormContextQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(
        service::answer_access_with_child(&state, &auth, id, q.child_id).await?,
    ))
}

#[derive(Debug, Deserialize)]
pub struct FormContextQuery {
    pub child_id: Option<Uuid>,
}
pub async fn update_form(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateFormRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(
        service::update_form(&state, &auth, id, payload).await?,
    ))
}
pub async fn delete_form(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    service::delete_form(&state, &auth, id).await?;
    Ok(response::ok(DeleteResultDto { deleted: true }))
}
pub async fn create_field(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<CreateFormFieldRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::created(
        field_service::create_field(&state, &auth, id, payload).await?,
    ))
}
pub async fn update_field(
    State(state): State<AppState>,
    auth: AuthUser,
    Path((id, field_id)): Path<(Uuid, Uuid)>,
    Json(payload): Json<UpdateFormFieldRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(
        field_service::update_field(&state, &auth, id, field_id, payload).await?,
    ))
}
pub async fn delete_field(
    State(state): State<AppState>,
    auth: AuthUser,
    Path((id, field_id)): Path<(Uuid, Uuid)>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    field_service::delete_field(&state, &auth, id, field_id).await?;
    Ok(response::ok(DeleteResultDto { deleted: true }))
}
pub async fn duplicate_form(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<DuplicateFormRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::created(
        service::duplicate_form(&state, &auth, id, payload).await?,
    ))
}
pub async fn submit_for_approval(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<SubmitForApprovalRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(
        service::submit_for_approval(&state, &auth, id, payload).await?,
    ))
}
pub async fn approve_form(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<ApproveFormRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(
        service::approve_form(&state, &auth, id, payload).await?,
    ))
}
pub async fn reject_form(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<RejectFormRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(
        service::reject_form(&state, &auth, id, payload).await?,
    ))
}
pub async fn publish_form(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<PublishFormRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(
        service::publish_form(&state, &auth, id, payload).await?,
    ))
}
pub async fn close_form(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<CloseFormRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(
        service::close_form(&state, &auth, id, payload).await?,
    ))
}
pub async fn archive_form(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<ArchiveFormRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(
        service::archive_form(&state, &auth, id, payload).await?,
    ))
}
pub async fn update_visibility(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateFormVisibilityRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(
        service::update_visibility(&state, &auth, id, payload).await?,
    ))
}
pub async fn list_access_codes(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(
        service::list_access_codes(&state, &auth, id).await?,
    ))
}
pub async fn set_access_codes(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<SetFormAccessCodesRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(
        service::set_access_codes(&state, &auth, id, payload).await?,
    ))
}
pub async fn update_public_protection(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdatePublicProtectionRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(
        service::update_public_protection(&state, &auth, id, payload).await?,
    ))
}
pub async fn get_analytics(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(service::analytics(&state, &auth, id).await?))
}

pub async fn get_dashboard_analytics(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(
        service::dashboard_analytics(&state, &auth).await?,
    ))
}
