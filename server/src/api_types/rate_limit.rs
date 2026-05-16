use crate::api_types::enums::RateLimitStrategy;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct RateLimitInfoDto {
    pub strategy: RateLimitStrategy,
    pub limit: i64,
    pub remaining: i64,
    pub reset_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct PublicRateLimitStatusDto {
    pub allowed: bool,
    pub limits: Vec<RateLimitInfoDto>,
    pub retry_after_seconds: Option<i64>,
}
