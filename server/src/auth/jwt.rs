use crate::{api_types::enums::UserRole, app_state::AppState, error::AppError};
use axum::{
    extract::FromRequestParts,
    http::{header, request::Parts},
};
use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub sub: Uuid,
    pub org_id: Option<Uuid>,
    pub role: UserRole,
    pub iss: String,
    pub iat: i64,
    pub exp: i64,
}

#[derive(Debug, Clone)]
pub struct AuthUser {
    pub user_id: Uuid,
    pub organization_id: Option<Uuid>,
    pub role: UserRole,
}

#[derive(Debug, Clone)]
pub struct OptionalAuthUser(pub Option<AuthUser>);

pub fn issue_access_token(
    state: &AppState,
    user_id: Uuid,
    org_id: Option<Uuid>,
    role: UserRole,
) -> Result<String, AppError> {
    let now = Utc::now();
    let claims = Claims {
        sub: user_id,
        org_id,
        role,
        iss: state.config.jwt_issuer.clone(),
        iat: now.timestamp(),
        exp: (now + Duration::seconds(state.config.access_token_ttl_seconds)).timestamp(),
    };
    Ok(encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(state.config.jwt_access_secret.as_bytes()),
    )?)
}

pub fn decode_access_token(state: &AppState, token: &str) -> Result<Claims, AppError> {
    let mut validation = Validation::default();
    validation.set_issuer(&[state.config.jwt_issuer.clone()]);
    let data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(state.config.jwt_access_secret.as_bytes()),
        &validation,
    )?;
    Ok(data.claims)
}

impl FromRequestParts<AppState> for AuthUser {
    type Rejection = AppError;

    async fn from_request_parts(
        parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        let auth = parts
            .headers
            .get(header::AUTHORIZATION)
            .and_then(|h| h.to_str().ok())
            .ok_or_else(|| AppError::unauthorized("Missing bearer token"))?;
        let token = auth
            .strip_prefix("Bearer ")
            .ok_or_else(|| AppError::unauthorized("Invalid Authorization header"))?;
        let claims = decode_access_token(state, token)?;
        Ok(Self {
            user_id: claims.sub,
            organization_id: claims.org_id,
            role: claims.role,
        })
    }
}

impl FromRequestParts<AppState> for OptionalAuthUser {
    type Rejection = AppError;

    async fn from_request_parts(
        parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        let Some(auth) = parts
            .headers
            .get(header::AUTHORIZATION)
            .and_then(|h| h.to_str().ok())
        else {
            return Ok(Self(None));
        };
        let Some(token) = auth.strip_prefix("Bearer ") else {
            return Ok(Self(None));
        };
        let claims = match decode_access_token(state, token) {
            Ok(claims) => claims,
            Err(_) => return Ok(Self(None)),
        };
        Ok(Self(Some(AuthUser {
            user_id: claims.sub,
            organization_id: claims.org_id,
            role: claims.role,
        })))
    }
}
