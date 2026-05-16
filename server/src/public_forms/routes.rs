use crate::{
    api_types::{
        enums::{ErrorCode, FormStatus, PublicProtectionLevel, PublishMode},
        public_forms::*,
        submissions::CreateSubmissionRequest,
    },
    app_state::AppState,
    auth::{password, OptionalAuthUser},
    error::AppError,
    forms::service as form_service,
    rate_limit, response,
    submissions::service as submission_service,
};
use axum::{
    extract::{Path, State},
    http::{HeaderMap, StatusCode},
    routing::{get, post},
    Json, Router,
};
use serde_json::json;
use sqlx::Row;
use uuid::Uuid;
use validator::Validate;

const PUBLIC_ACCESS_TOKEN_TTL_MINUTES: i64 = 15;

#[derive(Debug, Clone)]
struct PublicAccessGrant {
    access_code_id: Option<Uuid>,
    identity_label: Option<String>,
}

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/public/forms/{public_token}", get(get_public_form))
        .route(
            "/public/forms/{public_token}/submissions",
            post(submit_public_form),
        )
        .route(
            "/public/forms/{public_token}/validate-access",
            post(validate_public_access),
        )
}

pub async fn get_public_form(
    State(state): State<AppState>,
    Path(public_token): Path<String>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    let (form_id, _) = resolve_public_token(&state, &public_token).await?;
    let form = form_service::load_form_detail(&state, form_id).await?;
    if form.status != FormStatus::Published || form.publish_mode != PublishMode::PublicLink {
        return Err(AppError::new(
            StatusCode::CONFLICT,
            ErrorCode::FormNotPublished,
            "Public form is not published",
        ));
    }
    let access_policy = form_service::public_access_policy(&state, &form).await?;
    Ok(response::ok(PublicFormDto {
        id: form.id,
        title: form.title,
        description: form.description.clone(),
        settings: form.settings.clone(),
        visibility: form.visibility.clone(),
        public_protection: form.public_protection.clone(),
        fields: form.fields.clone(),
        access_policy,
        start_at: form.settings.start_at,
        end_at: form.settings.end_at,
    }))
}

pub async fn validate_public_access(
    State(state): State<AppState>,
    Path(public_token): Path<String>,
    OptionalAuthUser(auth): OptionalAuthUser,
    headers: HeaderMap,
    Json(payload): Json<ValidatePublicFormAccessRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    let (form_id, token_id) = resolve_public_token(&state, &public_token).await?;
    let form = form_service::load_form_detail(&state, form_id).await?;
    let mode = normalize_respondent_mode(payload.respondent_mode.as_deref(), &form, auth.as_ref())?;
    let identity = validate_form_gate(&state, form.id, &mode, &payload).await?;
    let ip = client_ip(&headers);
    let status = rate_limit::check_public_limits(
        &state.public_rate_limiter,
        form.id,
        ip.as_deref(),
        payload.fingerprint_token.as_deref(),
        &form.public_protection,
    )
    .await;

    let access_token = if status.allowed {
        let token = Uuid::new_v4().simple().to_string();
        sqlx::query(
            "insert into rate_limit_events (form_id, public_token_id, strategy, key_hash, allowed, metadata) values ($1, $2, 'token', $3, true, $4)",
        )
        .bind(form.id)
        .bind(token_id)
        .bind(&token)
        .bind(json!({
            "purpose": "public_access_validation",
            "expires_in_minutes": PUBLIC_ACCESS_TOKEN_TTL_MINUTES,
            "respondent_mode": mode,
            "access_code_id": identity.as_ref().and_then(|v| v.0).map(|v| v.to_string()),
            "identity_label": identity.as_ref().and_then(|v| v.1.clone())
        }))
        .execute(&state.db)
        .await?;
        Some(token)
    } else {
        None
    };

    Ok(response::ok(ValidatePublicFormAccessResponse {
        allowed: status.allowed,
        reason: if status.allowed {
            None
        } else {
            Some("rate_limited".into())
        },
        access_token,
        respondent_mode: Some(mode),
        identity_label: identity.and_then(|v| v.1),
        rate_limit: status,
    }))
}

pub async fn submit_public_form(
    State(state): State<AppState>,
    Path(public_token): Path<String>,
    OptionalAuthUser(auth): OptionalAuthUser,
    headers: HeaderMap,
    Json(payload): Json<PublicSubmissionRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    let (form_id, token_id) = resolve_public_token(&state, &public_token).await?;
    let form = form_service::load_form_detail(&state, form_id).await?;
    let mode = normalize_respondent_mode(payload.respondent_mode.as_deref(), &form, auth.as_ref())?;
    let access_required = public_access_validation_required(&form.public_protection)
        || form_gate_required(&state, form.id).await?;

    let grant = if access_required {
        Some(
            validate_public_access_token(
                &state,
                form.id,
                token_id,
                &mode,
                payload.public_access_token.as_deref(),
            )
            .await?,
        )
    } else {
        None
    };

    let ip = client_ip(&headers);
    let status = rate_limit::check_public_limits(
        &state.public_rate_limiter,
        form.id,
        ip.as_deref(),
        payload.fingerprint_token.as_deref(),
        &form.public_protection,
    )
    .await;
    if !status.allowed {
        return Err(AppError::with_details(
            StatusCode::TOO_MANY_REQUESTS,
            ErrorCode::RateLimited,
            "Public form rate limit exceeded",
            json!({ "rate_limit": status }),
        ));
    }
    let create = CreateSubmissionRequest {
        answers: payload.answers,
        anonymous: Some(mode == "anonymous"),
        fingerprint_token: payload.fingerprint_token,
    };
    let submission = submission_service::create_submission(
        &state,
        if mode == "authenticated" {
            auth.as_ref()
        } else {
            None
        },
        form_id,
        create,
        Some(submission_service::SubmissionAccessContext {
            public_token_id: token_id,
            access_code_id: grant.as_ref().and_then(|v| v.access_code_id),
            respondent_mode: mode,
            respondent_label: grant.and_then(|v| v.identity_label),
        }),
    )
    .await?;
    Ok(response::created(PublicSubmissionResponse {
        submission,
        message: "Submission accepted".into(),
    }))
}

async fn resolve_public_token(state: &AppState, token: &str) -> Result<(Uuid, Uuid), AppError> {
    let row = sqlx::query(
        "select id, form_id from public_form_tokens where token=$1 and enabled=true and revoked_at is null and (expires_at is null or expires_at > now())",
    )
    .bind(token)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::new(StatusCode::NOT_FOUND, ErrorCode::InvalidToken, "Public form token not found"))?;
    Ok((row.try_get("form_id")?, row.try_get("id")?))
}

fn public_access_validation_required(
    protection: &crate::api_types::forms::PublicProtectionSettingsDto,
) -> bool {
    protection.level != PublicProtectionLevel::None
        || protection.captcha_enabled
        || protection.email_verification_enabled
        || protection.phone_verification_enabled
}

async fn validate_public_access_token(
    state: &AppState,
    form_id: Uuid,
    public_token_id: Uuid,
    respondent_mode: &str,
    access_token: Option<&str>,
) -> Result<PublicAccessGrant, AppError> {
    let Some(access_token) = access_token.filter(|token| !token.trim().is_empty()) else {
        return Err(AppError::with_details(
            StatusCode::FORBIDDEN,
            ErrorCode::PublicAccessDenied,
            "public_access_token is required. Call validatePublicFormAccess before submitPublicForm.",
            json!({ "field": "public_access_token" }),
        ));
    };

    let row = sqlx::query(
        "select metadata from rate_limit_events
            where form_id=$1
              and public_token_id=$2
              and strategy='token'
              and key_hash=$3
              and allowed=true
              and metadata->>'purpose'='public_access_validation'
              and metadata->>'respondent_mode'=$5
              and created_at > now() - ($4::text || ' minutes')::interval
            order by created_at desc
            limit 1",
    )
    .bind(form_id)
    .bind(public_token_id)
    .bind(access_token)
    .bind(PUBLIC_ACCESS_TOKEN_TTL_MINUTES.to_string())
    .bind(respondent_mode)
    .fetch_optional(&state.db)
    .await?;

    let Some(row) = row else {
        return Err(AppError::with_details(
            StatusCode::UNAUTHORIZED,
            ErrorCode::InvalidToken,
            "public_access_token is invalid or expired",
            json!({ "field": "public_access_token" }),
        ));
    };

    let metadata: serde_json::Value = row.try_get("metadata").unwrap_or_else(|_| json!({}));
    let access_code_id = metadata
        .get("access_code_id")
        .and_then(|v| v.as_str())
        .and_then(|v| Uuid::parse_str(v).ok());
    let identity_label = metadata
        .get("identity_label")
        .and_then(|v| v.as_str())
        .map(ToOwned::to_owned);

    Ok(PublicAccessGrant {
        access_code_id,
        identity_label,
    })
}

fn normalize_respondent_mode(
    requested: Option<&str>,
    form: &crate::api_types::forms::FormDetailDto,
    auth: Option<&crate::auth::AuthUser>,
) -> Result<String, AppError> {
    let mode = requested.unwrap_or(if auth.is_some() {
        "authenticated"
    } else if form.visibility.anonymous_allowed || form.settings.allow_anonymous_answers {
        "anonymous"
    } else if form.visibility.guest_can_answer || form.settings.guests_can_answer {
        "guest"
    } else {
        "authenticated"
    });

    match mode {
        "anonymous"
            if form.visibility.anonymous_allowed || form.settings.allow_anonymous_answers =>
        {
            Ok("anonymous".to_owned())
        }
        "guest" if form.visibility.guest_can_answer || form.settings.guests_can_answer => {
            Ok("guest".to_owned())
        }
        "identity_code" => Ok("identity_code".to_owned()),
        "authenticated" if auth.is_some() => Ok("authenticated".to_owned()),
        "authenticated" => Err(AppError::with_details(
            StatusCode::UNAUTHORIZED,
            ErrorCode::Unauthorized,
            "Authentication is required before answering this form",
            json!({ "field": "respondent_mode" }),
        )),
        _ => Err(AppError::with_details(
            StatusCode::FORBIDDEN,
            ErrorCode::PublicAccessDenied,
            "This respondent mode is not enabled for this form",
            json!({ "field": "respondent_mode" }),
        )),
    }
}

async fn form_gate_required(state: &AppState, form_id: Uuid) -> Result<bool, AppError> {
    Ok(sqlx::query_scalar::<_, bool>(
        "select exists(select 1 from form_access_codes where form_id=$1 and enabled=true and deleted_at is null)",
    )
    .bind(form_id)
    .fetch_one(&state.db)
    .await?)
}

async fn validate_form_gate(
    state: &AppState,
    form_id: Uuid,
    respondent_mode: &str,
    payload: &ValidatePublicFormAccessRequest,
) -> Result<Option<(Option<Uuid>, Option<String>)>, AppError> {
    let shared = sqlx::query("select id, secret_hash from form_access_codes where form_id=$1 and code_type='shared_password' and enabled=true and deleted_at is null limit 1")
        .bind(form_id)
        .fetch_optional(&state.db)
        .await?;
    if let Some(row) = shared {
        let provided = payload
            .form_password
            .as_deref()
            .map(str::trim)
            .filter(|v| !v.is_empty())
            .ok_or_else(|| {
                AppError::with_details(
                    StatusCode::FORBIDDEN,
                    ErrorCode::PublicAccessDenied,
                    "Form password is required",
                    json!({ "field": "form_password" }),
                )
            })?;
        let hash: String = row.try_get("secret_hash")?;
        if !password::verify_secret(provided, &hash).unwrap_or(false) {
            return Err(AppError::with_details(
                StatusCode::UNAUTHORIZED,
                ErrorCode::InvalidToken,
                "Form password is invalid",
                json!({ "field": "form_password" }),
            ));
        }
    }

    if respondent_mode != "identity_code" {
        return Ok(None);
    }

    let code = payload
        .identity_code
        .as_deref()
        .map(str::trim)
        .filter(|v| !v.is_empty())
        .ok_or_else(|| {
            AppError::with_details(
                StatusCode::FORBIDDEN,
                ErrorCode::PublicAccessDenied,
                "Identity code is required",
                json!({ "field": "identity_code" }),
            )
        })?;

    let rows = sqlx::query("select id, label, secret_hash from form_access_codes where form_id=$1 and code_type='identity_code' and enabled=true and deleted_at is null")
        .bind(form_id)
        .fetch_all(&state.db)
        .await?;
    for row in rows {
        let hash: String = row.try_get("secret_hash")?;
        if password::verify_secret(code, &hash).unwrap_or(false) {
            return Ok(Some((row.try_get("id")?, row.try_get("label")?)));
        }
    }

    Err(AppError::with_details(
        StatusCode::UNAUTHORIZED,
        ErrorCode::InvalidToken,
        "Identity code is invalid",
        json!({ "field": "identity_code" }),
    ))
}

fn client_ip(headers: &HeaderMap) -> Option<String> {
    headers
        .get("x-forwarded-for")
        .and_then(|h| h.to_str().ok())
        .and_then(|s| s.split(',').next())
        .map(|s| s.trim().to_owned())
        .or_else(|| {
            headers
                .get("x-real-ip")
                .and_then(|h| h.to_str().ok())
                .map(ToOwned::to_owned)
        })
}
