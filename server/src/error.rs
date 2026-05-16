use crate::{
    api_types::{common::ApiErrorDto, enums::ErrorCode},
    response::error_response,
};
use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
};
use serde_json::{json, Value};
use thiserror::Error;

#[derive(Debug, Error)]
pub enum AppError {
    #[error("{message}")]
    Api {
        status: StatusCode,
        code: ErrorCode,
        message: String,
        details: Value,
    },
    #[error("database error")]
    Sqlx(#[from] sqlx::Error),
    #[error("validation error")]
    Validation(#[from] validator::ValidationErrors),
    #[error("internal error")]
    Anyhow(#[from] anyhow::Error),
    #[error("jwt error")]
    Jwt(#[from] jsonwebtoken::errors::Error),
}

impl AppError {
    pub fn new(status: StatusCode, code: ErrorCode, message: impl Into<String>) -> Self {
        Self::Api {
            status,
            code,
            message: message.into(),
            details: json!({}),
        }
    }

    pub fn with_details(
        status: StatusCode,
        code: ErrorCode,
        message: impl Into<String>,
        details: Value,
    ) -> Self {
        Self::Api {
            status,
            code,
            message: message.into(),
            details,
        }
    }

    pub fn unauthorized(message: impl Into<String>) -> Self {
        Self::new(StatusCode::UNAUTHORIZED, ErrorCode::Unauthorized, message)
    }

    pub fn forbidden(message: impl Into<String>) -> Self {
        Self::new(StatusCode::FORBIDDEN, ErrorCode::PermissionDenied, message)
    }

    pub fn not_found(resource: &str) -> Self {
        Self::new(
            StatusCode::NOT_FOUND,
            ErrorCode::NotFound,
            format!("{resource} not found"),
        )
    }

    pub fn conflict(message: impl Into<String>) -> Self {
        Self::new(StatusCode::CONFLICT, ErrorCode::Conflict, message)
    }

    pub fn validation(message: impl Into<String>, details: Value) -> Self {
        Self::with_details(
            StatusCode::BAD_REQUEST,
            ErrorCode::ValidationError,
            message,
            details,
        )
    }

    fn status_and_error(&self) -> (StatusCode, ApiErrorDto) {
        match self {
            AppError::Api {
                status,
                code,
                message,
                details,
            } => (
                *status,
                ApiErrorDto {
                    code: *code,
                    message: message.clone(),
                    details: details.clone(),
                },
            ),
            AppError::Sqlx(sqlx::Error::RowNotFound) => (
                StatusCode::NOT_FOUND,
                ApiErrorDto {
                    code: ErrorCode::NotFound,
                    message: "Resource not found".to_owned(),
                    details: json!({}),
                },
            ),
            AppError::Sqlx(_) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                ApiErrorDto {
                    code: ErrorCode::InternalServerError,
                    message: "Database operation failed".to_owned(),
                    details: json!({}),
                },
            ),
            AppError::Validation(err) => (
                StatusCode::BAD_REQUEST,
                ApiErrorDto {
                    code: ErrorCode::ValidationError,
                    message: "Validation failed".to_owned(),
                    details: json!(err),
                },
            ),
            AppError::Anyhow(_) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                ApiErrorDto {
                    code: ErrorCode::InternalServerError,
                    message: "Internal server error".to_owned(),
                    details: json!({}),
                },
            ),
            AppError::Jwt(_) => (
                StatusCode::UNAUTHORIZED,
                ApiErrorDto {
                    code: ErrorCode::InvalidToken,
                    message: "Invalid token".to_owned(),
                    details: json!({}),
                },
            ),
        }
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, error) = self.status_and_error();
        error_response(status, error)
    }
}
