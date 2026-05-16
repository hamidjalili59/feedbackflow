use crate::{
    api_types::{common::ApiErrorDto, enums::ErrorCode},
    app_state::AppState,
    openapi, response,
};
use axum::{
    body::Body,
    extract::State,
    http::{header, Method, StatusCode, Uri},
    response::{IntoResponse, Response},
    routing::get,
    Router,
};
use serde_json::json;
use std::{path::PathBuf, time::Duration};
use tower_http::{
    compression::CompressionLayer,
    cors::{Any, CorsLayer},
    timeout::TimeoutLayer,
};
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

pub fn build_router(state: AppState) -> Router {
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let api = Router::new()
        .merge(crate::auth::routes::routes())
        .merge(crate::users::routes::routes())
        .merge(crate::organizations::routes::routes())
        .merge(crate::permissions::routes::routes())
        .merge(crate::forms::routes::routes())
        .merge(crate::submissions::routes::routes())
        .merge(crate::scoring::routes::routes())
        .merge(crate::public_forms::routes::routes())
        .merge(crate::activities::routes::routes())
        .merge(crate::audit::routes::routes());

    Router::new()
        .route("/healthz", get(|| async { "ok" }))
        // .route("/openapi.json", get(|| async { axum::Json(openapi::ApiDoc::openapi()) }))
        .merge(SwaggerUi::new("/docs").url("/openapi.json", openapi::ApiDoc::openapi()))
        .nest("/api/v1", api.fallback(api_not_found))
        .fallback(spa_or_static_fallback)
        .layer(CompressionLayer::new())
        .layer(TimeoutLayer::with_status_code(
            StatusCode::REQUEST_TIMEOUT,
            Duration::from_secs(30),
        ))
        .layer(cors)
        .with_state(state)
}

async fn api_not_found() -> Response {
    response::error_response(
        StatusCode::NOT_FOUND,
        ApiErrorDto {
            code: ErrorCode::NotFound,
            message: "API route not found".to_owned(),
            details: json!({}),
        },
    )
}

async fn spa_or_static_fallback(
    State(state): State<AppState>,
    method: Method,
    uri: Uri,
) -> Response {
    if method != Method::GET && method != Method::HEAD {
        return StatusCode::METHOD_NOT_ALLOWED.into_response();
    }

    let request_path = uri.path();
    if is_reserved_server_path(request_path) {
        return StatusCode::NOT_FOUND.into_response();
    }

    let Some(relative_path) = safe_relative_web_path(request_path) else {
        return StatusCode::NOT_FOUND.into_response();
    };

    let web_root = state.config.flutter_web_dist_dir;
    let requested_file = web_root.join(&relative_path);
    let path = if requested_file.is_file() {
        requested_file
    } else if looks_like_asset_path(request_path) {
        return StatusCode::NOT_FOUND.into_response();
    } else {
        web_root.join("index.html")
    };

    serve_web_file(path, method == Method::HEAD).await
}

fn is_reserved_server_path(path: &str) -> bool {
    matches!(path, "/api" | "/api/" | "/openapi.json" | "/healthz")
        || path.starts_with("/api/")
        || path.starts_with("/docs")
}

fn safe_relative_web_path(path: &str) -> Option<PathBuf> {
    let trimmed = path.trim_start_matches('/').trim_end_matches('/');
    if trimmed.is_empty() {
        return Some(PathBuf::from("index.html"));
    }

    let mut relative = PathBuf::new();
    for segment in trimmed.split('/') {
        if segment.is_empty()
            || segment == "."
            || segment == ".."
            || segment.contains('\\')
            || segment.contains(':')
        {
            return None;
        }
        relative.push(segment);
    }
    Some(relative)
}

fn looks_like_asset_path(path: &str) -> bool {
    path.rsplit('/')
        .next()
        .is_some_and(|segment| segment.contains('.'))
}

async fn serve_web_file(path: PathBuf, head_only: bool) -> Response {
    let Ok(metadata) = tokio::fs::metadata(&path).await else {
        return StatusCode::NOT_FOUND.into_response();
    };
    if !metadata.is_file() {
        return StatusCode::NOT_FOUND.into_response();
    }

    let content_type = content_type_for(&path);
    let mut builder = Response::builder()
        .status(StatusCode::OK)
        .header(header::CONTENT_TYPE, content_type)
        .header(header::CONTENT_LENGTH, metadata.len().to_string());

    if path.file_name().and_then(|name| name.to_str()) == Some("index.html") {
        builder = builder.header(
            header::CACHE_CONTROL,
            "no-store, no-cache, must-revalidate, max-age=0",
        );
    }

    if head_only {
        return builder
            .body(Body::empty())
            .unwrap_or_else(|_| StatusCode::INTERNAL_SERVER_ERROR.into_response());
    }

    match tokio::fs::read(path).await {
        Ok(bytes) => builder
            .body(Body::from(bytes))
            .unwrap_or_else(|_| StatusCode::INTERNAL_SERVER_ERROR.into_response()),
        Err(_) => StatusCode::NOT_FOUND.into_response(),
    }
}

fn content_type_for(path: &std::path::Path) -> &'static str {
    match path.extension().and_then(|extension| extension.to_str()) {
        Some("html") => "text/html; charset=utf-8",
        Some("js") => "text/javascript; charset=utf-8",
        Some("css") => "text/css; charset=utf-8",
        Some("json") => "application/json; charset=utf-8",
        Some("wasm") => "application/wasm",
        Some("png") => "image/png",
        Some("jpg") | Some("jpeg") => "image/jpeg",
        Some("svg") => "image/svg+xml",
        Some("ico") => "image/x-icon",
        Some("woff") => "font/woff",
        Some("woff2") => "font/woff2",
        Some("ttf") => "font/ttf",
        Some("otf") => "font/otf",
        Some("txt") => "text/plain; charset=utf-8",
        _ => "application/octet-stream",
    }
}

#[cfg(test)]
mod tests {
    use super::{is_reserved_server_path, looks_like_asset_path, safe_relative_web_path};
    use std::path::PathBuf;

    #[test]
    fn reserves_backend_owned_paths() {
        for path in [
            "/api",
            "/api/v1/forms",
            "/api/v1/public/forms/token",
            "/docs",
            "/docs/",
            "/openapi.json",
            "/healthz",
        ] {
            assert!(is_reserved_server_path(path), "{path} should be reserved");
        }
        assert!(!is_reserved_server_path("/public/token"));
        assert!(!is_reserved_server_path("/forms/new"));
    }

    #[test]
    fn accepts_spa_paths_without_allowing_parent_traversal() {
        assert_eq!(
            safe_relative_web_path("/"),
            Some(PathBuf::from("index.html"))
        );
        assert_eq!(
            safe_relative_web_path("/public/token/"),
            Some(PathBuf::from("public").join("token"))
        );
        assert_eq!(safe_relative_web_path("/../secret"), None);
        assert_eq!(safe_relative_web_path("/public\\token"), None);
        assert_eq!(safe_relative_web_path("/C:/secret"), None);
    }

    #[test]
    fn detects_file_like_asset_requests() {
        assert!(looks_like_asset_path("/main.dart.js"));
        assert!(looks_like_asset_path("/assets/logo.png"));
        assert!(!looks_like_asset_path("/public/token"));
        assert!(!looks_like_asset_path("/forms/new"));
    }
}
