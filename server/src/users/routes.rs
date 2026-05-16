use crate::{
    api_types::{
        common::{ListQuery, PaginationMeta},
        enums::{
            enum_from_str, enum_to_string, AuditAction, PermissionAction, ResourceType, SortOrder,
            UserRole,
        },
        users::*,
    },
    app_state::AppState,
    auth::{
        password::hash_secret,
        service::{
            audit, normalize_optional_email, normalize_optional_gender, normalize_phone,
            row_to_user_detail,
        },
        AuthUser,
    },
    error::AppError,
    permissions::engine::{self, ResourceAttrs},
    response,
};
use axum::{
    extract::{Path, Query, State},
    routing::get,
    Json, Router,
};
use serde_json::json;
use sqlx::Row;
use uuid::Uuid;
use validator::Validate;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/users", get(list_users).post(create_user))
        .route("/users/me", get(get_my_user).patch(update_my_profile))
        .route("/users/{id}", get(get_user).patch(update_user))
        .route("/users/{id}/subordinates", get(get_subordinates))
}

pub async fn list_users(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(q): Query<ListQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    let roles = manageable_roles(auth.role);
    if roles.is_empty() {
        return Err(AppError::forbidden("This role cannot manage users"));
    }
    let role_strings = roles.iter().map(enum_to_string).collect::<Vec<_>>();
    let search = q
        .search
        .as_deref()
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .map(|value| format!("%{}%", value));
    let sort = match q.sort_by.as_deref() {
        Some("created") | Some("created_at") => "created_at",
        Some("updated") | Some("updated_at") => "updated_at",
        Some("role") | Some("primary_role") => "primary_role",
        Some("status") => "status",
        _ => "display_name",
    };
    let dir = if matches!(q.sort_order, Some(SortOrder::Desc)) {
        "desc"
    } else {
        "asc"
    };
    let sql = format!(
        "select id, organization_id, phone, email, display_name, gender, primary_role, status \
         from users \
         where deleted_at is null \
           and primary_role = any($1) \
           and ($2::uuid is null or organization_id = $2) \
           and ($3::text is null or display_name ilike $3 or phone ilike $3 or email::text ilike $3) \
         order by {sort} {dir}, id asc \
         limit $4 offset $5"
    );
    let org_filter = if matches!(auth.role, UserRole::SuperAdmin) {
        None
    } else {
        Some(
            auth.organization_id
                .ok_or_else(|| AppError::forbidden("Managing users requires an organization"))?,
        )
    };
    let rows = sqlx::query(&sql)
        .bind(&role_strings)
        .bind(org_filter)
        .bind(search.as_deref())
        .bind(q.limit())
        .bind(q.offset())
        .fetch_all(&state.db)
        .await?;
    let count: i64 = sqlx::query_scalar(
        "select count(*) from users \
         where deleted_at is null \
           and primary_role = any($1) \
           and ($2::uuid is null or organization_id = $2) \
           and ($3::text is null or display_name ilike $3 or phone ilike $3 or email::text ilike $3)",
    )
    .bind(&role_strings)
    .bind(org_filter)
    .bind(search.as_deref())
    .fetch_one(&state.db)
    .await?;
    let data = rows
        .iter()
        .map(row_to_user_summary)
        .collect::<Result<Vec<_>, _>>()?;
    Ok(response::list(
        data,
        PaginationMeta::new(q.page, q.limit(), count),
    ))
}

pub async fn create_user(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(payload): Json<CreateUserRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    let target_role = payload.primary_role;
    if !can_create_role(auth.role, target_role) {
        return Err(AppError::forbidden(
            "This role cannot create the requested user role",
        ));
    }

    engine::require_permission(
        &auth,
        PermissionAction::Create,
        ResourceType::User,
        &ResourceAttrs {
            organization_id: auth.organization_id.or(payload.organization_id),
            ..Default::default()
        },
    )?;

    let org_id = if matches!(auth.role, UserRole::SuperAdmin) {
        payload.organization_id.or(auth.organization_id)
    } else {
        auth.organization_id
    }
    .ok_or_else(|| AppError::forbidden("Creating users requires an organization"))?;

    if payload.organization_id.is_some() && !matches!(auth.role, UserRole::SuperAdmin) {
        if payload.organization_id != Some(org_id) {
            return Err(AppError::forbidden(
                "You can only create users in your organization",
            ));
        }
    }

    let phone = normalize_phone(&payload.phone)?;
    let email = normalize_optional_email(payload.email.as_deref())?;
    let gender = normalize_optional_gender(payload.gender.as_deref())?;
    let existing_phone: Option<Uuid> =
        sqlx::query_scalar("select id from users where phone=$1 and deleted_at is null")
            .bind(&phone)
            .fetch_optional(&state.db)
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
        .fetch_optional(&state.db)
        .await?;
        if existing_email.is_some() {
            return Err(AppError::conflict(
                "A user with this email address already exists",
            ));
        }
    }

    let row = sqlx::query("insert into users (organization_id, phone, email, password_hash, display_name, gender, primary_role, profile, status) values ($1,$2,$3,$4,$5,$6,$7,$8,'active') returning id, organization_id, phone, email, display_name, gender, primary_role, profile, status, created_at, updated_at")
        .bind(org_id)
        .bind(&phone)
        .bind(&email)
        .bind(hash_secret(&payload.password)?)
        .bind(&payload.display_name)
        .bind(&gender)
        .bind(enum_to_string(&target_role))
        .bind(json!(payload.profile.unwrap_or(UserProfileDto {
            phone: Some(phone.clone()),
            avatar_url: None,
            locale: None,
            timezone: None,
            metadata: json!({}),
        })))
        .fetch_one(&state.db)
        .await?;
    let created = row_to_user_detail(&row)?;
    audit(
        &state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::Created,
        "user",
        Some(created.id),
        json!({"source":"privileged_create_user","role": enum_to_string(&target_role)}),
    )
    .await?;
    Ok(response::created(created))
}

pub async fn get_my_user(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<impl axum::response::IntoResponse, AppError> {
    let row = sqlx::query("select id, organization_id, phone, email, display_name, gender, primary_role, profile, status, created_at, updated_at from users where id=$1 and deleted_at is null")
        .bind(auth.user_id).fetch_one(&state.db).await?;
    Ok(response::ok(row_to_user_detail(&row)?))
}

fn can_create_role(actor: UserRole, target: UserRole) -> bool {
    match actor {
        UserRole::Manager | UserRole::Admin => {
            matches!(target, UserRole::Teacher | UserRole::Student)
        }
        UserRole::Ceo => matches!(
            target,
            UserRole::Teacher | UserRole::Student | UserRole::Manager
        ),
        UserRole::SuperAdmin => matches!(
            target,
            UserRole::Teacher | UserRole::Student | UserRole::Manager | UserRole::Ceo
        ),
        _ => false,
    }
}

fn manageable_roles(actor: UserRole) -> Vec<UserRole> {
    match actor {
        UserRole::Manager | UserRole::Admin => vec![UserRole::Teacher, UserRole::Student],
        UserRole::Ceo => vec![UserRole::Teacher, UserRole::Student, UserRole::Manager],
        UserRole::SuperAdmin => vec![
            UserRole::Teacher,
            UserRole::Student,
            UserRole::Manager,
            UserRole::Ceo,
        ],
        _ => vec![],
    }
}

fn can_manage_role(actor: UserRole, target: UserRole) -> bool {
    manageable_roles(actor).contains(&target)
}

fn row_to_user_summary(row: &sqlx::postgres::PgRow) -> Result<UserSummaryDto, AppError> {
    let role: UserRole =
        enum_from_str(&row.try_get::<String, _>("primary_role")?).unwrap_or(UserRole::Parent);
    Ok(UserSummaryDto {
        id: row.try_get("id")?,
        organization_id: row.try_get("organization_id")?,
        phone: row.try_get("phone")?,
        email: row.try_get("email")?,
        display_name: row.try_get("display_name")?,
        gender: row.try_get("gender").ok(),
        primary_role: role,
        status: row.try_get("status")?,
    })
}

pub async fn update_my_profile(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(payload): Json<UpdateUserProfileRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    let current = sqlx::query(
        "select profile, display_name, email, gender from users where id=$1 and deleted_at is null",
    )
    .bind(auth.user_id)
    .fetch_one(&state.db)
    .await?;
    let profile = payload
        .profile
        .map(|p| json!(p))
        .unwrap_or_else(|| current.try_get("profile").unwrap_or_else(|_| json!({})));
    let display_name = payload
        .display_name
        .unwrap_or_else(|| current.try_get("display_name").unwrap_or_default());
    let email = if let Some(email) = payload.email {
        let email = email.trim().to_lowercase();
        if !email.contains('@') || email.starts_with('@') || email.ends_with('@') {
            return Err(AppError::validation(
                "Invalid email address",
                json!({ "email": "Email is optional, but when provided it must be a valid email address." }),
            ));
        }
        let owner_id: Option<Uuid> = sqlx::query_scalar(
            "select id from users where lower(email::text)=lower($1) and id <> $2 and deleted_at is null",
        )
        .bind(&email)
        .bind(auth.user_id)
        .fetch_optional(&state.db)
        .await?;
        if owner_id.is_some() {
            return Err(AppError::conflict(
                "A user with this email address already exists",
            ));
        }
        Some(email)
    } else {
        current.try_get("email").ok()
    };
    let gender = if payload.gender.is_some() {
        normalize_optional_gender(payload.gender.as_deref())?
    } else {
        current.try_get("gender").ok().flatten()
    };
    let row = sqlx::query("update users set display_name=$2, email=$3, profile=$4, gender=$5, updated_at=now() where id=$1 returning id, organization_id, phone, email, display_name, gender, primary_role, profile, status, created_at, updated_at")
        .bind(auth.user_id).bind(display_name).bind(email).bind(profile).bind(gender).fetch_one(&state.db).await?;
    Ok(response::ok(row_to_user_detail(&row)?))
}

pub async fn get_user(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    let row = sqlx::query("select id, organization_id, phone, email, display_name, gender, primary_role, profile, status, created_at, updated_at from users where id=$1 and deleted_at is null")
        .bind(id).fetch_one(&state.db).await?;
    let org_id: Option<Uuid> = row.try_get("organization_id")?;
    engine::require_permission(
        &auth,
        PermissionAction::Read,
        ResourceType::User,
        &ResourceAttrs {
            organization_id: org_id,
            target_user_id: Some(id),
            ..Default::default()
        },
    )?;
    Ok(response::ok(row_to_user_detail(&row)?))
}

pub async fn update_user(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateUserRequest>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    payload.validate()?;
    let current = sqlx::query("select id, organization_id, phone, email, display_name, gender, primary_role, profile, status, created_at, updated_at from users where id=$1 and deleted_at is null")
        .bind(id)
        .fetch_one(&state.db)
        .await?;
    let org_id: Option<Uuid> = current.try_get("organization_id")?;
    let current_role: UserRole =
        enum_from_str(&current.try_get::<String, _>("primary_role")?).unwrap_or(UserRole::Parent);
    if !can_manage_role(auth.role, current_role) {
        return Err(AppError::forbidden(
            "This role cannot manage the target user",
        ));
    }
    if !matches!(auth.role, UserRole::SuperAdmin) && auth.organization_id != org_id {
        return Err(AppError::forbidden(
            "You can only manage users in your organization",
        ));
    }

    let next_role = payload.primary_role.unwrap_or(current_role);
    if !can_manage_role(auth.role, next_role) {
        return Err(AppError::forbidden(
            "This role cannot assign the requested role",
        ));
    }

    let phone = if let Some(phone) = payload.phone {
        let phone = normalize_phone(&phone)?;
        let owner_id: Option<Uuid> = sqlx::query_scalar(
            "select id from users where phone=$1 and id <> $2 and deleted_at is null",
        )
        .bind(&phone)
        .bind(id)
        .fetch_optional(&state.db)
        .await?;
        if owner_id.is_some() {
            return Err(AppError::conflict(
                "A user with this phone number already exists",
            ));
        }
        phone
    } else {
        current.try_get("phone")?
    };

    let email = if payload.email.is_some() {
        let email = normalize_optional_email(payload.email.as_deref())?;
        if let Some(email) = &email {
            let owner_id: Option<Uuid> = sqlx::query_scalar(
                "select id from users where lower(email::text)=lower($1) and id <> $2 and deleted_at is null",
            )
            .bind(email)
            .bind(id)
            .fetch_optional(&state.db)
            .await?;
            if owner_id.is_some() {
                return Err(AppError::conflict(
                    "A user with this email address already exists",
                ));
            }
        }
        email
    } else {
        current.try_get("email")?
    };

    let status = payload.status.unwrap_or_else(|| {
        current
            .try_get("status")
            .unwrap_or_else(|_| "active".to_string())
    });
    if !matches!(status.as_str(), "active" | "inactive" | "suspended") {
        return Err(AppError::validation(
            "Invalid user status",
            json!({"status":"Allowed values are active, inactive, suspended."}),
        ));
    }
    let display_name = payload
        .display_name
        .unwrap_or_else(|| current.try_get("display_name").unwrap_or_default());
    let gender = if payload.gender.is_some() {
        normalize_optional_gender(payload.gender.as_deref())?
    } else {
        current.try_get("gender").ok().flatten()
    };
    let profile = payload
        .profile
        .map(|profile| json!(profile))
        .unwrap_or_else(|| current.try_get("profile").unwrap_or_else(|_| json!({})));

    let row = sqlx::query("update users set phone=$2, email=$3, display_name=$4, gender=$5, primary_role=$6, profile=$7, status=$8, updated_at=now() where id=$1 and deleted_at is null returning id, organization_id, phone, email, display_name, gender, primary_role, profile, status, created_at, updated_at")
        .bind(id)
        .bind(phone)
        .bind(email)
        .bind(display_name)
        .bind(gender)
        .bind(enum_to_string(&next_role))
        .bind(profile)
        .bind(status)
        .fetch_one(&state.db)
        .await?;
    audit(
        &state,
        org_id,
        Some(auth.user_id),
        AuditAction::Updated,
        "user",
        Some(id),
        json!({"source":"privileged_update_user"}),
    )
    .await?;
    Ok(response::ok(row_to_user_detail(&row)?))
}

pub async fn get_subordinates(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Query(q): Query<ListQuery>,
) -> Result<impl axum::response::IntoResponse, AppError> {
    if id != auth.user_id
        && !matches!(
            auth.role,
            UserRole::Manager | UserRole::Admin | UserRole::Ceo | UserRole::SuperAdmin
        )
    {
        return Err(AppError::forbidden(
            "Only managers/admins can inspect another user's subordinates",
        ));
    }
    let rows = sqlx::query("select u.id, u.organization_id, u.phone, u.email, u.display_name, u.gender, u.primary_role, u.status, ur.relationship_type from user_relationships ur join users u on u.id=ur.child_user_id where ur.parent_user_id=$1 and u.deleted_at is null order by u.display_name limit $2 offset $3")
        .bind(id).bind(q.limit()).bind(q.offset()).fetch_all(&state.db).await?;
    let count: i64 =
        sqlx::query_scalar("select count(*) from user_relationships where parent_user_id=$1")
            .bind(id)
            .fetch_one(&state.db)
            .await
            .unwrap_or(0);
    let mut data = vec![];
    for row in rows {
        let role: UserRole =
            crate::api_types::enums::enum_from_str(&row.try_get::<String, _>("primary_role")?)
                .unwrap_or(UserRole::Parent);
        data.push(SubordinateUserDto {
            user: UserSummaryDto {
                id: row.try_get("id")?,
                organization_id: row.try_get("organization_id")?,
                phone: row.try_get("phone")?,
                email: row.try_get("email")?,
                display_name: row.try_get("display_name")?,
                gender: row.try_get("gender").ok(),
                primary_role: role,
                status: row.try_get("status")?,
            },
            relationship_type: row.try_get("relationship_type")?,
            depth: 1,
        });
    }
    Ok(response::list(
        data,
        PaginationMeta::new(q.page, q.limit(), count),
    ))
}
