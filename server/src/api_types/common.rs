use crate::api_types::enums::{ErrorCode, SortOrder};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use utoipa::{IntoParams, ToSchema};

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ApiErrorDto {
    pub code: ErrorCode,
    pub message: String,
    #[serde(default)]
    pub details: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ApiResponse<T> {
    pub success: bool,
    pub data: Option<T>,
    pub error: Option<ApiErrorDto>,
    #[serde(default)]
    pub meta: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ApiErrorResponse {
    pub success: bool,
    pub data: Option<Value>,
    pub error: ApiErrorDto,
    #[serde(default)]
    pub meta: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct LogoutResponse {
    pub logged_out: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct UpdateResultDto {
    pub updated: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct DeleteResultDto {
    pub deleted: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct OperationStatusDto {
    pub success: bool,
    pub message: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct PaginationMeta {
    pub page: i64,
    pub page_size: i64,
    pub total_items: i64,
    pub total_pages: i64,
    pub has_next: bool,
    pub has_previous: bool,
}

impl PaginationMeta {
    pub fn new(page: i64, page_size: i64, total_items: i64) -> Self {
        let page = page.max(1);
        let page_size = page_size.clamp(1, 100);
        let total_pages = if total_items == 0 {
            0
        } else {
            (total_items + page_size - 1) / page_size
        };
        Self {
            page,
            page_size,
            total_items,
            total_pages,
            has_next: total_pages > 0 && page < total_pages,
            has_previous: page > 1,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ListMetaDto {
    pub pagination: PaginationMeta,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ApiListResponse<T> {
    pub success: bool,
    pub data: Vec<T>,
    pub error: Option<ApiErrorDto>,
    pub meta: ListMetaDto,
}

#[derive(Debug, Clone, Deserialize, IntoParams)]
pub struct ListQuery {
    #[serde(default = "default_page")]
    pub page: i64,
    #[serde(default = "default_page_size")]
    pub page_size: i64,
    pub search: Option<String>,
    pub sort_by: Option<String>,
    #[serde(default)]
    pub sort_order: Option<SortOrder>,
    pub filters: Option<String>,
    pub category: Option<String>,
    pub tags: Option<String>,
}

impl ListQuery {
    pub fn limit(&self) -> i64 {
        self.page_size.clamp(1, 100)
    }

    pub fn offset(&self) -> i64 {
        (self.page.max(1) - 1) * self.limit()
    }
}

fn default_page() -> i64 {
    1
}

fn default_page_size() -> i64 {
    20
}
