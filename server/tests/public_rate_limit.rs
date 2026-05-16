use feedbackflow_server::{
    api_types::{enums::PublicProtectionLevel, forms::PublicProtectionSettingsDto},
    rate_limit::{check_public_limits, MemoryRateLimiter},
};
use uuid::Uuid;

#[tokio::test]
async fn public_form_spam_protection_blocks_after_limit() {
    let limiter = MemoryRateLimiter::default();
    let protection = PublicProtectionSettingsDto {
        level: PublicProtectionLevel::Standard,
        ip_limit_per_minute: Some(1),
        ..Default::default()
    };
    let form_id = Uuid::new_v4();
    let first = check_public_limits(&limiter, form_id, Some("127.0.0.1"), None, &protection).await;
    let second = check_public_limits(&limiter, form_id, Some("127.0.0.1"), None, &protection).await;
    assert!(first.allowed);
    assert!(!second.allowed);
}
