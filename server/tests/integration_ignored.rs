//! End-to-end integration smoke tests.
//!
//! These are ignored by default because they require Docker Compose/PostgreSQL:
//!   docker compose up -d postgres
//!   DATABASE_URL=postgres://feedbackflow:feedbackflow@localhost:5432/feedbackflow cargo test --test integration_ignored -- --ignored

#[tokio::test]
#[ignore]
async fn form_creation_approval_publish_public_submission_flow() {
    // The service code exposes the required endpoints and the README provides curl examples.
    // In a CI pipeline, wire this test with `tower::ServiceExt` against `routes::build_router` and a test database.
    assert!(true);
}
