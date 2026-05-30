use crate::{
    api_types::dashboard::*,
    app_state::AppState,
    auth::AuthUser,
    dashboard::service,
    error::AppError,
    response,
};
use axum::{
    extract::{Query, State},
    routing::get,
    Router,
};

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/home", get(get_home))
        .route("/dashboards/me", get(get_home))
        .route("/users/me/children", get(get_children))
        .route("/surveys/me", get(get_my_surveys))
        .route("/surveys/calendar", get(get_survey_calendar))
        .route("/analytics/timeseries", get(get_timeseries))
        .route("/analytics/rankings", get(get_rankings))
        .route("/analytics/alerts", get(get_alerts))
}

async fn get_home(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(q): Query<DashboardQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(service::dashboard_me(&state, &auth, q).await?))
}

async fn get_children(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(service::children_for_parent(&state, &auth).await?))
}

async fn get_my_surveys(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(q): Query<MySurveysQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(service::my_surveys(&state, &auth, q).await?))
}

async fn get_survey_calendar(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(q): Query<CalendarQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(service::survey_calendar(&state, &auth, q).await?))
}

async fn get_timeseries(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(q): Query<TimeseriesQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(service::timeseries(&state, &auth, q).await?))
}

async fn get_rankings(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(q): Query<RankingQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(service::rankings(&state, &auth, q).await?))
}

async fn get_alerts(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(q): Query<AlertQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    Ok(response::ok(service::alerts(&state, &auth, q).await?))
}
