use crate::{config::Config, rate_limit::MemoryRateLimiter};
use sqlx::PgPool;
use std::sync::Arc;

#[derive(Clone)]
pub struct AppState {
    pub config: Config,
    pub db: PgPool,
    pub public_rate_limiter: Arc<MemoryRateLimiter>,
}

impl AppState {
    pub fn new(config: Config, db: PgPool) -> Self {
        Self {
            config,
            db,
            public_rate_limiter: Arc::new(MemoryRateLimiter::default()),
        }
    }
}
