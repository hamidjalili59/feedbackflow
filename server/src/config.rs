use anyhow::{Context, Result};
use std::path::PathBuf;

#[derive(Debug, Clone)]
pub struct Config {
    pub app_env: String,
    pub app_host: String,
    pub app_port: u16,
    pub database_url: String,
    pub database_max_connections: u32,
    pub jwt_access_secret: String,
    pub jwt_issuer: String,
    pub access_token_ttl_seconds: i64,
    pub refresh_token_ttl_seconds: i64,
    pub cors_allowed_origins: Vec<String>,
    pub flutter_web_dist_dir: PathBuf,
    pub run_migrations: bool,
}

impl Config {
    pub fn from_env() -> Result<Self> {
        Ok(Self {
            app_env: env("APP_ENV", "local"),
            app_host: env("APP_HOST", "0.0.0.0"),
            app_port: env("APP_PORT", "8080")
                .parse()
                .context("APP_PORT must be a u16")?,
            database_url: std::env::var("DATABASE_URL").context("DATABASE_URL is required")?,
            database_max_connections: env("DATABASE_MAX_CONNECTIONS", "10")
                .parse()
                .context("DATABASE_MAX_CONNECTIONS must be an integer")?,
            jwt_access_secret: std::env::var("JWT_ACCESS_SECRET")
                .context("JWT_ACCESS_SECRET is required")?,
            jwt_issuer: env("JWT_ISSUER", "feedbackflow-server"),
            access_token_ttl_seconds: env("ACCESS_TOKEN_TTL_SECONDS", "3600")
                .parse()
                .context("ACCESS_TOKEN_TTL_SECONDS must be an integer")?,
            refresh_token_ttl_seconds: env("REFRESH_TOKEN_TTL_SECONDS", "604800")
                .parse()
                .context("REFRESH_TOKEN_TTL_SECONDS must be an integer")?,
            cors_allowed_origins: env("CORS_ALLOWED_ORIGINS", "http://localhost:3000")
                .split(',')
                .map(|s| s.trim().to_owned())
                .filter(|s| !s.is_empty())
                .collect(),
            flutter_web_dist_dir: PathBuf::from(env(
                "FLUTTER_WEB_DIST_DIR",
                "./web",
            )),
            run_migrations: env("RUN_MIGRATIONS", "true").parse().unwrap_or(true),
        })
    }
}

fn env(key: &str, default: &str) -> String {
    std::env::var(key).unwrap_or_else(|_| default.to_owned())
}
