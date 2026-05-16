use crate::api_types::{
    enums::{PublicProtectionLevel, RateLimitStrategy},
    forms::PublicProtectionSettingsDto,
    rate_limit::{PublicRateLimitStatusDto, RateLimitInfoDto},
};
use chrono::{DateTime, Duration, Utc};
use std::{collections::HashMap, sync::Arc};
use tokio::sync::RwLock;

#[derive(Debug, Clone)]
struct WindowCounter {
    count: i64,
    reset_at: DateTime<Utc>,
}

#[derive(Debug, Clone)]
struct RateLimitDecision {
    info: RateLimitInfoDto,
    exceeded: bool,
}

#[derive(Default)]
pub struct MemoryRateLimiter {
    counters: Arc<RwLock<HashMap<String, WindowCounter>>>,
}

impl MemoryRateLimiter {
    async fn check_and_increment_decision(
        &self,
        key: &str,
        strategy: RateLimitStrategy,
        limit: i64,
        window_seconds: i64,
    ) -> RateLimitDecision {
        let now = Utc::now();
        let safe_limit = limit.max(1);
        let safe_window_seconds = window_seconds.max(1);

        let mut counters = self.counters.write().await;
        let entry = counters
            .entry(format!(
                "{}:{}",
                crate::api_types::enums::enum_to_string(&strategy),
                key
            ))
            .or_insert(WindowCounter {
                count: 0,
                reset_at: now + Duration::seconds(safe_window_seconds),
            });

        if entry.reset_at <= now {
            entry.count = 0;
            entry.reset_at = now + Duration::seconds(safe_window_seconds);
        }

        entry.count += 1;

        let exceeded = entry.count > safe_limit;
        let remaining = if exceeded {
            0
        } else {
            (safe_limit - entry.count).max(0)
        };

        RateLimitDecision {
            info: RateLimitInfoDto {
                strategy,
                limit: safe_limit,
                remaining,
                reset_at: entry.reset_at,
            },
            exceeded,
        }
    }

    pub async fn check_and_increment(
        &self,
        key: &str,
        strategy: RateLimitStrategy,
        limit: i64,
        window_seconds: i64,
    ) -> RateLimitInfoDto {
        self.check_and_increment_decision(key, strategy, limit, window_seconds)
            .await
            .info
    }
}

pub async fn check_public_limits(
    limiter: &MemoryRateLimiter,
    form_id: uuid::Uuid,
    ip: Option<&str>,
    fingerprint: Option<&str>,
    protection: &PublicProtectionSettingsDto,
) -> PublicRateLimitStatusDto {
    if protection.level == PublicProtectionLevel::None {
        return PublicRateLimitStatusDto {
            allowed: true,
            limits: vec![],
            retry_after_seconds: None,
        };
    }

    let mut decisions = vec![];

    if !protection.disabled_limits.contains(&RateLimitStrategy::Ip) {
        if let Some(ip) = ip {
            decisions.push(
                limiter
                    .check_and_increment_decision(
                        &format!("form:{form_id}:ip:{ip}"),
                        RateLimitStrategy::Ip,
                        protection.ip_limit_per_minute.unwrap_or(20),
                        60,
                    )
                    .await,
            );
        }
    }

    if !protection
        .disabled_limits
        .contains(&RateLimitStrategy::Fingerprint)
    {
        if let Some(fp) = fingerprint {
            decisions.push(
                limiter
                    .check_and_increment_decision(
                        &format!("form:{form_id}:fp:{fp}"),
                        RateLimitStrategy::Fingerprint,
                        protection.max_submissions_per_fingerprint.unwrap_or(5),
                        86_400,
                    )
                    .await,
            );
        }
    }

    let blocked = decisions.iter().any(|decision| decision.exceeded);

    let retry_after_seconds = decisions
        .iter()
        .filter(|decision| decision.exceeded)
        .map(|decision| (decision.info.reset_at - Utc::now()).num_seconds().max(1))
        .max();

    let limits = decisions
        .into_iter()
        .map(|decision| decision.info)
        .collect();

    PublicRateLimitStatusDto {
        allowed: !blocked,
        limits,
        retry_after_seconds,
    }
}
