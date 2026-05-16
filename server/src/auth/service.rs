use crate::{
    api_types::{
        auth::*,
        enums::{enum_from_str, enum_to_string, AuditAction, UserRole},
        permissions::EffectivePermissionsDto,
        users::{UserDetailDto, UserProfileDto},
    },
    app_state::AppState,
    auth::{
        jwt::issue_access_token,
        password::{hash_secret, verify_secret},
    },
    error::AppError,
    permissions::engine,
};
use chrono::{Duration, Utc};
use rand::{distributions::Alphanumeric, Rng};
use serde_json::{json, Value};
use sqlx::Row;
use uuid::Uuid;

pub async fn register(
    state: &AppState,
    request: RegisterRequest,
) -> Result<RegisterResponse, AppError> {
    let phone = normalize_phone(&request.phone)?;
    let email = normalize_optional_email(request.email.as_deref())?;
    let gender = normalize_optional_gender(request.gender.as_deref())?;
    let role = request.role.unwrap_or(UserRole::Parent);
    if matches!(
        role,
        UserRole::Ceo | UserRole::SuperAdmin | UserRole::Admin | UserRole::Manager
    ) {
        // Production systems should use an invitation/bootstrap flow for privileged users.
        return Err(AppError::forbidden("Privileged roles cannot self-register"));
    }

    let mut tx = state.db.begin().await?;
    let mut organization = None;
    let org_id = if request.organization_id.is_some() && request.organization_name.is_some() {
        return Err(AppError::validation(
            "Send either organization_id or organization_name, not both",
            json!({
                "organization_id": "Cannot be combined with organization_name",
                "organization_name": "Cannot be combined with organization_id"
            }),
        ));
    } else if let Some(org_id) = request.organization_id {
        let row = sqlx::query(
            "select id, parent_organization_id, name, slug, settings, created_at, updated_at from organizations where id = $1 and deleted_at is null",
        )
        .bind(org_id)
        .fetch_optional(&mut *tx)
        .await?;

        let row = row.ok_or_else(|| {
            AppError::validation(
                "Organization does not exist",
                json!({ "organization_id": org_id }),
            )
        })?;
        organization = Some(crate::organizations::routes::row_to_org(&row)?);
        Some(org_id)
    } else if let Some(name) = request.organization_name.clone() {
        let slug = slugify(&name);
        let row = sqlx::query(
            "select id, parent_organization_id, name, slug, settings, created_at, updated_at from organizations where slug = $1 and deleted_at is null",
        )
        .bind(&slug)
        .fetch_optional(&mut *tx)
        .await?;

        let row = if let Some(row) = row {
            row
        } else {
            sqlx::query(
                "insert into organizations (name, slug, settings) values ($1, $2, $3) returning id, parent_organization_id, name, slug, settings, created_at, updated_at",
            )
            .bind(&name)
            .bind(&slug)
            .bind(json!({}))
            .fetch_one(&mut *tx)
            .await?
        };
        let org = crate::organizations::routes::row_to_org(&row)?;
        let org_id = org.id;
        organization = Some(org);
        Some(org_id)
    } else {
        None
    };

    let existing_phone: Option<Uuid> =
        sqlx::query_scalar("select id from users where phone = $1 and deleted_at is null")
            .bind(&phone)
            .fetch_optional(&mut *tx)
            .await?;
    if existing_phone.is_some() {
        return Err(AppError::conflict(
            "A user with this phone number already exists",
        ));
    }

    if let Some(email) = &email {
        let existing_email: Option<Uuid> = sqlx::query_scalar(
            "select id from users where lower(email::text)=lower($1) and deleted_at is null",
        )
        .bind(email)
        .fetch_optional(&mut *tx)
        .await?;
        if existing_email.is_some() {
            return Err(AppError::conflict(
                "A user with this email address already exists",
            ));
        }
    }

    let password_hash = hash_secret(&request.password)?;
    let row = sqlx::query("insert into users (organization_id, phone, email, password_hash, display_name, gender, primary_role, profile, status) values ($1, $2, $3, $4, $5, $6, $7, $8, 'active') returning id, organization_id, phone, email, display_name, gender, primary_role, profile, status, created_at, updated_at")
        .bind(org_id)
        .bind(&phone)
        .bind(&email)
        .bind(password_hash)
        .bind(&request.display_name)
        .bind(&gender)
        .bind(enum_to_string(&role))
        .bind(json!({}))
        .fetch_one(&mut *tx).await?;
    let user = row_to_user_detail(&row)?;
    audit_tx(
        &mut tx,
        org_id,
        Some(user.id),
        AuditAction::Created,
        "user",
        Some(user.id),
        json!({"source":"register"}),
    )
    .await?;
    tx.commit().await?;
    Ok(RegisterResponse { user, organization })
}

pub async fn login(state: &AppState, request: LoginRequest) -> Result<LoginResponse, AppError> {
    let phone = normalize_phone(&request.phone)?;
    let row = sqlx::query("select id, organization_id, phone, email, password_hash, display_name, gender, primary_role, profile, status, created_at, updated_at from users where phone=$1 and deleted_at is null")
        .bind(&phone)
        .fetch_optional(&state.db).await?
        .ok_or_else(|| AppError::unauthorized("Invalid phone or password"))?;
    let password_hash: String = row.try_get("password_hash")?;
    if !verify_secret(&request.password, &password_hash)? {
        return Err(AppError::unauthorized("Invalid phone or password"));
    }
    let user = row_to_user_detail(&row)?;
    let access_token = issue_access_token(state, user.id, user.organization_id, user.primary_role)?;
    let refresh_token = create_refresh_token(state, user.id).await?;
    audit(
        state,
        user.organization_id,
        Some(user.id),
        AuditAction::Login,
        "user",
        Some(user.id),
        json!({}),
    )
    .await?;
    Ok(LoginResponse {
        access_token,
        refresh_token,
        token_type: "Bearer".to_owned(),
        expires_in: state.config.access_token_ttl_seconds,
        user,
    })
}

pub async fn refresh(
    state: &AppState,
    request: RefreshTokenRequest,
) -> Result<RefreshTokenResponse, AppError> {
    let (token_id, secret) = parse_refresh_token(&request.refresh_token)?;
    let row = sqlx::query("select rt.id, rt.user_id, rt.token_hash, rt.expires_at, rt.revoked_at, u.organization_id, u.primary_role from refresh_tokens rt join users u on u.id = rt.user_id where rt.id = $1 and u.deleted_at is null")
        .bind(token_id)
        .fetch_optional(&state.db).await?
        .ok_or_else(|| AppError::unauthorized("Invalid refresh token"))?;
    let revoked_at: Option<chrono::DateTime<Utc>> = row.try_get("revoked_at")?;
    let expires_at: chrono::DateTime<Utc> = row.try_get("expires_at")?;
    if revoked_at.is_some() || expires_at <= Utc::now() {
        return Err(AppError::unauthorized("Refresh token expired or revoked"));
    }
    let hash: String = row.try_get("token_hash")?;
    if !verify_secret(&secret, &hash)? {
        return Err(AppError::unauthorized("Invalid refresh token"));
    }
    let user_id: Uuid = row.try_get("user_id")?;
    let org_id: Option<Uuid> = row.try_get("organization_id")?;
    let role: UserRole =
        enum_from_str(&row.try_get::<String, _>("primary_role")?).unwrap_or(UserRole::Parent);
    let new_refresh = create_refresh_token(state, user_id).await?;
    let (new_token_id, _) = parse_refresh_token(&new_refresh)?;
    sqlx::query(
        "update refresh_tokens set revoked_at = now(), replaced_by_token_id = $2 where id = $1",
    )
    .bind(token_id)
    .bind(new_token_id)
    .execute(&state.db)
    .await?;
    let access_token = issue_access_token(state, user_id, org_id, role)?;
    Ok(RefreshTokenResponse {
        access_token,
        refresh_token: new_refresh,
        token_type: "Bearer".to_owned(),
        expires_in: state.config.access_token_ttl_seconds,
    })
}

pub async fn logout(state: &AppState, request: LogoutRequest) -> Result<(), AppError> {
    if let Ok((token_id, _)) = parse_refresh_token(&request.refresh_token) {
        sqlx::query(
            "update refresh_tokens set revoked_at = now() where id = $1 and revoked_at is null",
        )
        .bind(token_id)
        .execute(&state.db)
        .await?;
    }
    Ok(())
}

pub async fn me(state: &AppState, user_id: Uuid) -> Result<MeResponse, AppError> {
    let row = sqlx::query("select id, organization_id, phone, email, display_name, gender, primary_role, profile, status, created_at, updated_at from users where id = $1 and deleted_at is null")
        .bind(user_id).fetch_one(&state.db).await?;
    let user = row_to_user_detail(&row)?;
    let effective_permissions = engine::effective_permissions_for_user(
        state,
        &crate::auth::jwt::AuthUser {
            user_id: user.id,
            organization_id: user.organization_id,
            role: user.primary_role,
        },
    )
    .await
    .unwrap_or_else(|_| EffectivePermissionsDto {
        user_id: user.id,
        organization_id: user.organization_id,
        role: user.primary_role,
        actions: vec![],
        resources: vec![],
        field_types: vec![],
        publishing_rules: vec![],
        can_manage_permissions: false,
        can_manage_scoring: false,
        can_manage_public_protection: false,
        abac_context: Value::Object(Default::default()),
    });
    Ok(MeResponse {
        user,
        effective_permissions,
    })
}

pub fn row_to_user_detail(row: &sqlx::postgres::PgRow) -> Result<UserDetailDto, AppError> {
    let role: UserRole =
        enum_from_str(&row.try_get::<String, _>("primary_role")?).unwrap_or(UserRole::Parent);
    let profile_value: Value = row.try_get("profile").unwrap_or_else(|_| json!({}));
    let profile: UserProfileDto = serde_json::from_value(profile_value).unwrap_or(UserProfileDto {
        phone: None,
        avatar_url: None,
        locale: None,
        timezone: None,
        metadata: json!({}),
    });
    Ok(UserDetailDto {
        id: row.try_get("id")?,
        organization_id: row.try_get("organization_id")?,
        phone: row.try_get("phone")?,
        email: row.try_get("email")?,
        display_name: row.try_get("display_name")?,
        gender: row.try_get("gender").ok(),
        primary_role: role,
        profile,
        status: row.try_get("status")?,
        created_at: row.try_get("created_at")?,
        updated_at: row.try_get("updated_at")?,
    })
}

async fn create_refresh_token(state: &AppState, user_id: Uuid) -> Result<String, AppError> {
    let token_id = Uuid::new_v4();
    let secret: String = rand::thread_rng()
        .sample_iter(&Alphanumeric)
        .take(64)
        .map(char::from)
        .collect();
    let token_hash = hash_secret(&secret)?;
    let expires_at = Utc::now() + Duration::seconds(state.config.refresh_token_ttl_seconds);
    sqlx::query(
        "insert into refresh_tokens (id, user_id, token_hash, expires_at) values ($1, $2, $3, $4)",
    )
    .bind(token_id)
    .bind(user_id)
    .bind(token_hash)
    .bind(expires_at)
    .execute(&state.db)
    .await?;
    Ok(format!("{token_id}.{secret}"))
}

fn parse_refresh_token(token: &str) -> Result<(Uuid, String), AppError> {
    let (id, secret) = token
        .split_once('.')
        .ok_or_else(|| AppError::unauthorized("Invalid refresh token format"))?;
    Ok((
        Uuid::parse_str(id).map_err(|_| AppError::unauthorized("Invalid refresh token id"))?,
        secret.to_owned(),
    ))
}

pub fn normalize_optional_email(input: Option<&str>) -> Result<Option<String>, AppError> {
    let Some(email) = input else {
        return Ok(None);
    };
    let email = email.trim().to_lowercase();
    if email.is_empty() {
        return Ok(None);
    }
    if !email.contains('@') || email.starts_with('@') || email.ends_with('@') {
        return Err(AppError::validation(
            "Invalid email address",
            json!({ "email": "Email is optional, but when provided it must be a valid email address." }),
        ));
    }
    Ok(Some(email))
}

pub fn normalize_optional_gender(input: Option<&str>) -> Result<Option<String>, AppError> {
    let Some(gender) = input.map(str::trim).filter(|value| !value.is_empty()) else {
        return Ok(None);
    };
    let gender = gender.to_lowercase();
    if matches!(gender.as_str(), "female" | "male") {
        Ok(Some(gender))
    } else {
        Err(AppError::validation(
            "Invalid gender",
            json!({"gender":"Allowed values are female, male."}),
        ))
    }
}

pub fn normalize_phone(input: &str) -> Result<String, AppError> {
    let trimmed = input.trim();
    let mut phone = trimmed
        .chars()
        .filter(|c| !matches!(c, ' ' | '-' | '(' | ')'))
        .collect::<String>();

    if phone.starts_with("00") {
        phone = format!("+{}", &phone[2..]);
    }

    let digit_count = phone.chars().filter(|c| c.is_ascii_digit()).count();
    let valid = digit_count >= 6
        && digit_count <= 20
        && phone
            .chars()
            .enumerate()
            .all(|(idx, c)| c.is_ascii_digit() || (idx == 0 && c == '+'));

    if !valid {
        return Err(AppError::validation(
            "Invalid phone number",
            json!({
                "phone": "Use digits with an optional leading +. Spaces, hyphens, and parentheses are accepted and normalized."
            }),
        ));
    }

    Ok(phone)
}

fn slugify(input: &str) -> String {
    input
        .to_lowercase()
        .chars()
        .map(|c| if c.is_ascii_alphanumeric() { c } else { '-' })
        .collect::<String>()
        .split('-')
        .filter(|s| !s.is_empty())
        .collect::<Vec<_>>()
        .join("-")
}

pub async fn audit(
    state: &AppState,
    organization_id: Option<Uuid>,
    actor_user_id: Option<Uuid>,
    action: AuditAction,
    resource_type: &str,
    resource_id: Option<Uuid>,
    details: Value,
) -> Result<(), AppError> {
    sqlx::query("insert into audit_logs (organization_id, actor_user_id, action, resource_type, resource_id, details) values ($1,$2,$3,$4,$5,$6)")
        .bind(organization_id).bind(actor_user_id).bind(enum_to_string(&action)).bind(resource_type).bind(resource_id).bind(details).execute(&state.db).await?;
    Ok(())
}

pub async fn audit_tx(
    tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    organization_id: Option<Uuid>,
    actor_user_id: Option<Uuid>,
    action: AuditAction,
    resource_type: &str,
    resource_id: Option<Uuid>,
    details: Value,
) -> Result<(), AppError> {
    sqlx::query("insert into audit_logs (organization_id, actor_user_id, action, resource_type, resource_id, details) values ($1,$2,$3,$4,$5,$6)")
        .bind(organization_id).bind(actor_user_id).bind(enum_to_string(&action)).bind(resource_type).bind(resource_id).bind(details).execute(&mut **tx).await?;
    Ok(())
}
