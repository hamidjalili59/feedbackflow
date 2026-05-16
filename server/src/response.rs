use crate::api_types::common::{
    ApiErrorDto, ApiErrorResponse, ApiListResponse, ApiResponse, ListMetaDto, PaginationMeta,
};
use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use serde_json::{json, Value};

pub fn ok<T: Serialize>(data: T) -> Json<ApiResponse<T>> {
    Json(ApiResponse {
        success: true,
        data: Some(data),
        error: None,
        meta: json!({}),
    })
}

pub fn created<T: Serialize>(data: T) -> (StatusCode, Json<ApiResponse<T>>) {
    (StatusCode::CREATED, ok(data))
}

pub fn list<T: Serialize>(items: Vec<T>, pagination: PaginationMeta) -> Json<ApiListResponse<T>> {
    Json(ApiListResponse {
        success: true,
        data: items,
        error: None,
        meta: ListMetaDto { pagination },
    })
}

pub fn error_response(status: StatusCode, error: ApiErrorDto) -> Response {
    (
        status,
        Json(ApiErrorResponse {
            success: false,
            data: None::<Value>,
            error,
            meta: json!({}),
        }),
    )
        .into_response()
}
