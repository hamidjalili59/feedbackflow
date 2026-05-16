//! Middleware extension points.
//!
//! Authentication is implemented as an Axum extractor in `auth::jwt::AuthUser`.
//! RBAC/ABAC authorization is centralized in `permissions::engine` so handlers
//! can perform resource-aware checks close to each mutation/read.
