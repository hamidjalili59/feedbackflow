use crate::{
    api_types::{auth::*, common::LogoutResponse},
    app_state::AppState,
    auth::{jwt::AuthUser, service},
    error::AppError,
    response,
};
use axum::{
    extract::State,
    routing::{get, post},
    Json, Router,
};
use validator::Validate;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/auth/register", post(register))
        .route("/auth/login", post(login))
        .route("/auth/guest", post(guest_login))
        .route("/auth/refresh", post(refresh))
        .route("/auth/logout", post(logout))
        .route("/auth/me", get(get_me))
}

pub async fn register(
    State(state): State<AppState>,
    Json(payload): Json<RegisterRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    let data = service::register(&state, payload).await?;
    Ok(response::created(data))
}

pub async fn login(
    State(state): State<AppState>,
    Json(payload): Json<LoginRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(service::login(&state, payload).await?))
}

pub async fn guest_login(
    State(state): State<AppState>,
    Json(payload): Json<GuestLoginRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(service::guest_login(&state, payload).await?))
}

pub async fn refresh(
    State(state): State<AppState>,
    Json(payload): Json<RefreshTokenRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    Ok(response::ok(service::refresh(&state, payload).await?))
}

pub async fn logout(
    State(state): State<AppState>,
    Json(payload): Json<LogoutRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    service::logout(&state, payload).await?;
    Ok(response::ok(LogoutResponse { logged_out: true }))
}

pub async fn get_me(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(service::me(&state, auth.user_id).await?))
}
