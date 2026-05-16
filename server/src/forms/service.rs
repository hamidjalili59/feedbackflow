use crate::{
    api_types::{
        analytics::*,
        common::{ListQuery, PaginationMeta},
        enums::*,
        fields::*,
        forms::*,
    },
    app_state::AppState,
    auth::{password, service as auth_service, AuthUser},
    error::AppError,
    fields::service as field_service,
    forms::visibility,
    permissions::engine,
};
use axum::http::StatusCode;
use chrono::Utc;
use serde_json::{json, Value};
use sqlx::Row;
use uuid::Uuid;

pub async fn create_form(
    state: &AppState,
    auth: &AuthUser,
    request: CreateFormRequest,
) -> Result<FormDetailDto, AppError> {
    let org_id = auth
        .organization_id
        .ok_or_else(|| AppError::forbidden("Creating forms requires an organization"))?;
    engine::require_permission(
        auth,
        PermissionAction::Create,
        ResourceType::Form,
        &engine::ResourceAttrs {
            organization_id: Some(org_id),
            ..Default::default()
        },
    )?;
    let category = normalize_category(request.category);
    let tags = normalize_tags(request.tags);
    let row = sqlx::query("insert into forms (organization_id, creator_id, title, description, category, tags, status, visibility_mode, publish_mode, settings, visibility, public_protection, scoring_mode, scoring_config) values ($1,$2,$3,$4,$5,$6,'draft',$7,'private',$8,$9,$10,$11,$12) returning *")
        .bind(org_id)
        .bind(auth.user_id)
        .bind(request.title)
        .bind(request.description)
        .bind(category)
        .bind(tags)
        .bind(enum_to_string(&request.visibility.mode))
        .bind(json!(request.settings))
        .bind(json!(request.visibility))
        .bind(json!(PublicProtectionSettingsDto::default()))
        .bind(enum_to_string(&request.scoring_mode.unwrap_or(ScoringMode::None)))
        .bind(request.scoring_config)
        .fetch_one(&state.db).await?;
    let id: Uuid = row.try_get("id")?;
    auth_service::audit(
        state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::Created,
        "form",
        Some(id),
        json!({}),
    )
    .await?;
    load_form_detail(state, id).await
}

pub async fn list_forms(
    state: &AppState,
    auth: &AuthUser,
    q: &ListQuery,
) -> Result<(Vec<FormSummaryDto>, PaginationMeta), AppError> {
    let org_id = auth.organization_id;
    let search = q.search.clone().unwrap_or_default();
    let category = q.category.clone().unwrap_or_default();
    let tags = parse_tag_filter(q.tags.as_deref());
    let tags_empty = tags.is_empty();
    let order_by = form_sort_column(q.sort_by.as_deref());
    let direction = match q.sort_order.unwrap_or(SortOrder::Desc) {
        SortOrder::Asc => "asc",
        SortOrder::Desc => "desc",
    };
    let rows = if matches!(auth.role, UserRole::Ceo | UserRole::SuperAdmin) && org_id.is_none() {
        let sql = format!("select f.*, (select token from public_form_tokens p where p.form_id=f.id and p.enabled=true limit 1) public_token, (select count(*) from form_submissions s where s.form_id=f.id and s.deleted_at is null) submissions_count from forms f where f.deleted_at is null and ($1='' or f.title ilike '%'||$1||'%' or coalesce(f.description,'') ilike '%'||$1||'%' or coalesce(f.category,'') ilike '%'||$1||'%' or exists (select 1 from unnest(f.tags) tag where tag ilike '%'||$1||'%')) and ($2='' or lower(coalesce(f.category,''))=lower($2)) and ($3 or exists (select 1 from unnest(f.tags) tag where lower(tag)=any($4))) order by {order_by} {direction}, f.id asc limit $5 offset $6");
        sqlx::query(&sql)
            .bind(&search)
            .bind(&category)
            .bind(tags_empty)
            .bind(&tags)
            .bind(q.limit())
            .bind(q.offset())
            .fetch_all(&state.db)
            .await?
    } else {
        let sql = format!("select f.*, (select token from public_form_tokens p where p.form_id=f.id and p.enabled=true limit 1) public_token, (select count(*) from form_submissions s where s.form_id=f.id and s.deleted_at is null) submissions_count from forms f where f.deleted_at is null and f.organization_id=$1 and ($2='' or f.title ilike '%'||$2||'%' or coalesce(f.description,'') ilike '%'||$2||'%' or coalesce(f.category,'') ilike '%'||$2||'%' or exists (select 1 from unnest(f.tags) tag where tag ilike '%'||$2||'%')) and ($3='' or lower(coalesce(f.category,''))=lower($3)) and ($4 or exists (select 1 from unnest(f.tags) tag where lower(tag)=any($5))) order by {order_by} {direction}, f.id asc limit $6 offset $7");
        sqlx::query(&sql)
            .bind(org_id)
            .bind(&search)
            .bind(&category)
            .bind(tags_empty)
            .bind(&tags)
            .bind(q.limit())
            .bind(q.offset())
            .fetch_all(&state.db)
            .await?
    };
    let total: i64 = if let Some(org_id) = org_id {
        sqlx::query_scalar("select count(*) from forms f where f.deleted_at is null and f.organization_id=$1 and ($2='' or f.title ilike '%'||$2||'%' or coalesce(f.description,'') ilike '%'||$2||'%' or coalesce(f.category,'') ilike '%'||$2||'%' or exists (select 1 from unnest(f.tags) tag where tag ilike '%'||$2||'%')) and ($3='' or lower(coalesce(f.category,''))=lower($3)) and ($4 or exists (select 1 from unnest(f.tags) tag where lower(tag)=any($5)))").bind(org_id).bind(&search).bind(&category).bind(tags_empty).bind(&tags).fetch_one(&state.db).await.unwrap_or(0)
    } else {
        sqlx::query_scalar("select count(*) from forms f where f.deleted_at is null and ($1='' or f.title ilike '%'||$1||'%' or coalesce(f.description,'') ilike '%'||$1||'%' or coalesce(f.category,'') ilike '%'||$1||'%' or exists (select 1 from unnest(f.tags) tag where tag ilike '%'||$1||'%')) and ($2='' or lower(coalesce(f.category,''))=lower($2)) and ($3 or exists (select 1 from unnest(f.tags) tag where lower(tag)=any($4)))").bind(&search).bind(&category).bind(tags_empty).bind(&tags).fetch_one(&state.db).await.unwrap_or(0)
    };
    let mut data = vec![];
    for row in rows {
        data.push(row_to_form_summary(&row)?);
    }
    Ok((data, PaginationMeta::new(q.page, q.limit(), total)))
}

pub async fn get_form(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
) -> Result<FormDetailDto, AppError> {
    let detail = load_form_detail(state, id).await?;
    if !visibility::can_see_form(
        detail.status,
        detail.creator_id,
        detail.organization_id,
        &detail.visibility,
        Some(auth),
    ) {
        return Err(AppError::forbidden("You cannot view this form"));
    }
    Ok(detail)
}

pub async fn update_form(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    request: UpdateFormRequest,
) -> Result<FormDetailDto, AppError> {
    let attrs = attrs_for_form(state, id).await?;
    engine::require_permission(auth, PermissionAction::Update, ResourceType::Form, &attrs)?;
    let current = load_form_detail(state, id).await?;
    let settings = request.settings.unwrap_or(current.settings);
    let visibility = request.visibility.unwrap_or(current.visibility);
    let scoring_mode = request.scoring_mode.unwrap_or(current.scoring_mode);
    let scoring_config = request.scoring_config.unwrap_or(current.scoring_config);
    let category = normalize_category(request.category).or(current.category);
    let tags = request.tags.map(normalize_tags).unwrap_or(current.tags);
    if scoring_mode != ScoringMode::None
        && !matches!(
            auth.role,
            UserRole::Manager | UserRole::Admin | UserRole::Ceo | UserRole::SuperAdmin
        )
    {
        return Err(AppError::forbidden("This role cannot change scoring"));
    }
    sqlx::query("update forms set title=coalesce($2,title), description=coalesce($3,description), category=$4, tags=$5, settings=$6, visibility=$7, visibility_mode=$8, scoring_mode=$9, scoring_config=$10, updated_at=now() where id=$1 and deleted_at is null")
        .bind(id).bind(request.title).bind(request.description).bind(category).bind(tags).bind(json!(settings)).bind(json!(visibility)).bind(enum_to_string(&visibility.mode)).bind(enum_to_string(&scoring_mode)).bind(scoring_config).execute(&state.db).await?;
    auth_service::audit(
        state,
        Some(current.organization_id),
        Some(auth.user_id),
        AuditAction::Updated,
        "form",
        Some(id),
        json!({}),
    )
    .await?;
    load_form_detail(state, id).await
}

pub async fn delete_form(state: &AppState, auth: &AuthUser, id: Uuid) -> Result<(), AppError> {
    let attrs = attrs_for_form(state, id).await?;
    engine::require_permission(auth, PermissionAction::Delete, ResourceType::Form, &attrs)?;
    sqlx::query(
        "update forms set deleted_at=now(), updated_at=now() where id=$1 and deleted_at is null",
    )
    .bind(id)
    .execute(&state.db)
    .await?;
    auth_service::audit(
        state,
        attrs.organization_id,
        Some(auth.user_id),
        AuditAction::Deleted,
        "form",
        Some(id),
        json!({}),
    )
    .await?;
    Ok(())
}

pub async fn duplicate_form(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    request: DuplicateFormRequest,
) -> Result<FormDetailDto, AppError> {
    let src = get_form(state, auth, id).await?;
    engine::require_permission(
        auth,
        PermissionAction::Create,
        ResourceType::Form,
        &engine::ResourceAttrs {
            organization_id: Some(src.organization_id),
            ..Default::default()
        },
    )?;
    let title = request
        .title
        .unwrap_or_else(|| format!("{} Copy", src.title));
    let form = create_form(
        state,
        auth,
        CreateFormRequest {
            title,
            description: src.description.clone(),
            category: src.category.clone(),
            tags: src.tags.clone(),
            settings: src.settings.clone(),
            visibility: if request.include_visibility {
                src.visibility.clone()
            } else {
                FormVisibilityDto::default()
            },
            scoring_mode: Some(src.scoring_mode),
            scoring_config: src.scoring_config.clone(),
        },
    )
    .await?;
    if request.include_fields {
        for f in src.fields {
            let req = CreateFormFieldRequest {
                field_type: f.field_type,
                label: f.label,
                description: f.description,
                placeholder: f.placeholder,
                required: f.required,
                order_index: f.order_index,
                config: f.config,
                validation: f.validation,
                visibility_conditions: f.visibility_conditions,
                scoring_config: f.scoring_config,
                permissions: f.permissions,
            };
            let _ = field_service::create_field(state, auth, form.id, req).await?;
        }
    }
    load_form_detail(state, form.id).await
}

pub async fn submit_for_approval(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    request: SubmitForApprovalRequest,
) -> Result<FormDetailDto, AppError> {
    let attrs = attrs_for_form(state, id).await?;
    engine::require_permission(auth, PermissionAction::Update, ResourceType::Form, &attrs)?;
    let required = engine::role_requires_approval(state, attrs.organization_id, auth.role).await?;
    let status = if required {
        FormStatus::PendingReview
    } else {
        FormStatus::Approved
    };
    sqlx::query("update forms set status=$2, updated_at=now(), approved_at=case when $2='approved' then now() else approved_at end where id=$1")
        .bind(id).bind(enum_to_string(&status)).execute(&state.db).await?;
    sqlx::query("insert into form_approval_requests (form_id, requester_id, status, note) values ($1,$2,$3,$4)")
        .bind(id).bind(auth.user_id).bind(if required { "pending" } else { "not_required" }).bind(request.note).execute(&state.db).await?;
    auth_service::audit(
        state,
        attrs.organization_id,
        Some(auth.user_id),
        AuditAction::SubmittedForApproval,
        "form",
        Some(id),
        json!({"required": required}),
    )
    .await?;
    load_form_detail(state, id).await
}

pub async fn approve_form(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    request: ApproveFormRequest,
) -> Result<FormDetailDto, AppError> {
    let attrs = attrs_for_form(state, id).await?;
    engine::require_permission(auth, PermissionAction::Approve, ResourceType::Form, &attrs)?;
    sqlx::query("update form_approval_requests set status='approved', reviewer_id=$2, reviewed_at=now(), reviewer_comment=$3 where form_id=$1 and status='pending'")
        .bind(id).bind(auth.user_id).bind(request.comment).execute(&state.db).await?;
    sqlx::query(
        "update forms set status='approved', approved_at=now(), updated_at=now() where id=$1",
    )
    .bind(id)
    .execute(&state.db)
    .await?;
    auth_service::audit(
        state,
        attrs.organization_id,
        Some(auth.user_id),
        AuditAction::Approved,
        "form",
        Some(id),
        json!({}),
    )
    .await?;
    if request.publish_after_approval.unwrap_or(false) {
        publish_form(
            state,
            auth,
            id,
            PublishFormRequest {
                publish_mode: PublishMode::Organization,
                visibility: None,
                public_protection: None,
                scheduled_at: None,
            },
        )
        .await
    } else {
        load_form_detail(state, id).await
    }
}

pub async fn reject_form(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    request: RejectFormRequest,
) -> Result<FormDetailDto, AppError> {
    let attrs = attrs_for_form(state, id).await?;
    engine::require_permission(auth, PermissionAction::Reject, ResourceType::Form, &attrs)?;
    sqlx::query("update form_approval_requests set status='rejected', reviewer_id=$2, reviewed_at=now(), reviewer_comment=$3 where form_id=$1 and status='pending'")
        .bind(id).bind(auth.user_id).bind(&request.reason).execute(&state.db).await?;
    sqlx::query("update forms set status='rejected', updated_at=now() where id=$1")
        .bind(id)
        .execute(&state.db)
        .await?;
    auth_service::audit(
        state,
        attrs.organization_id,
        Some(auth.user_id),
        AuditAction::Rejected,
        "form",
        Some(id),
        json!({"reason": request.reason}),
    )
    .await?;
    load_form_detail(state, id).await
}

pub async fn publish_form(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    request: PublishFormRequest,
) -> Result<FormDetailDto, AppError> {
    let current = load_form_detail(state, id).await?;
    let attrs = engine::ResourceAttrs {
        organization_id: Some(current.organization_id),
        owner_id: Some(current.creator_id),
        form_status: Some(current.status),
        publish_mode: Some(request.publish_mode),
        ..Default::default()
    };
    engine::require_permission(auth, PermissionAction::Publish, ResourceType::Form, &attrs)?;
    let direct = engine::can_publish_directly(
        state,
        Some(current.organization_id),
        auth.role,
        request.publish_mode,
    )
    .await?;
    if !direct
        && current.status != FormStatus::Approved
        && !matches!(
            auth.role,
            UserRole::Manager | UserRole::Admin | UserRole::Ceo | UserRole::SuperAdmin
        )
    {
        return Err(AppError::with_details(
            StatusCode::CONFLICT,
            ErrorCode::ApprovalRequired,
            "This form requires approval before publishing",
            json!({"status": enum_to_string(&current.status)}),
        ));
    }
    let visibility = request.visibility.unwrap_or(current.visibility);
    let protection = request
        .public_protection
        .unwrap_or(current.public_protection);
    if request.publish_mode == PublishMode::PublicLink
        && protection.level == PublicProtectionLevel::None
        && !engine::can_disable_public_protection(state, Some(current.organization_id), auth.role)
            .await?
    {
        return Err(AppError::with_details(
            StatusCode::FORBIDDEN,
            ErrorCode::PublicProtectionRequired,
            "Public forms must keep rate limits unless a permitted publisher disables them",
            json!({}),
        ));
    }
    if request.publish_mode == PublishMode::PublicLink
        && protection.level == PublicProtectionLevel::None
    {
        auth_service::audit(
            state,
            Some(current.organization_id),
            Some(auth.user_id),
            AuditAction::PublicProtectionDisabled,
            "form",
            Some(id),
            json!({"reason":"publish with level none"}),
        )
        .await?;
    }
    let status = if request
        .scheduled_at
        .map(|d| d > Utc::now())
        .unwrap_or(false)
    {
        FormStatus::Scheduled
    } else {
        FormStatus::Published
    };
    sqlx::query("update forms set status=$2, publish_mode=$3, visibility_mode=$4, visibility=$5, public_protection=$6, scheduled_at=$7, published_at=case when $2='published' then now() else published_at end, updated_at=now() where id=$1")
        .bind(id).bind(enum_to_string(&status)).bind(enum_to_string(&request.publish_mode)).bind(enum_to_string(&visibility.mode)).bind(json!(visibility)).bind(json!(protection)).bind(request.scheduled_at).execute(&state.db).await?;
    if request.publish_mode == PublishMode::PublicLink {
        ensure_public_token(state, id).await?;
    }
    auth_service::audit(
        state,
        Some(current.organization_id),
        Some(auth.user_id),
        AuditAction::Published,
        "form",
        Some(id),
        json!({"publish_mode": enum_to_string(&request.publish_mode)}),
    )
    .await?;
    load_form_detail(state, id).await
}

pub async fn close_form(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    _request: CloseFormRequest,
) -> Result<FormDetailDto, AppError> {
    let attrs = attrs_for_form(state, id).await?;
    engine::require_permission(auth, PermissionAction::Update, ResourceType::Form, &attrs)?;
    sqlx::query("update forms set status='closed', closed_at=now(), updated_at=now() where id=$1")
        .bind(id)
        .execute(&state.db)
        .await?;
    auth_service::audit(
        state,
        attrs.organization_id,
        Some(auth.user_id),
        AuditAction::Closed,
        "form",
        Some(id),
        json!({}),
    )
    .await?;
    load_form_detail(state, id).await
}

pub async fn archive_form(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    _request: ArchiveFormRequest,
) -> Result<FormDetailDto, AppError> {
    let attrs = attrs_for_form(state, id).await?;
    engine::require_permission(auth, PermissionAction::Delete, ResourceType::Form, &attrs)?;
    sqlx::query("update forms set status='archived', updated_at=now() where id=$1")
        .bind(id)
        .execute(&state.db)
        .await?;
    auth_service::audit(
        state,
        attrs.organization_id,
        Some(auth.user_id),
        AuditAction::Archived,
        "form",
        Some(id),
        json!({}),
    )
    .await?;
    load_form_detail(state, id).await
}

pub async fn update_visibility(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    request: UpdateFormVisibilityRequest,
) -> Result<FormDetailDto, AppError> {
    let attrs = attrs_for_form(state, id).await?;
    engine::require_permission(auth, PermissionAction::Update, ResourceType::Form, &attrs)?;
    sqlx::query("update forms set visibility=$2, visibility_mode=$3, updated_at=now() where id=$1")
        .bind(id)
        .bind(json!(request.visibility))
        .bind(enum_to_string(&request.visibility.mode))
        .execute(&state.db)
        .await?;
    load_form_detail(state, id).await
}

pub async fn update_public_protection(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    request: UpdatePublicProtectionRequest,
) -> Result<FormDetailDto, AppError> {
    let detail = load_form_detail(state, id).await?;
    let attrs = engine::ResourceAttrs {
        organization_id: Some(detail.organization_id),
        owner_id: Some(detail.creator_id),
        form_status: Some(detail.status),
        ..Default::default()
    };
    engine::require_permission(auth, PermissionAction::Update, ResourceType::Form, &attrs)?;
    let disabled = request.public_protection.level == PublicProtectionLevel::None
        || !request.public_protection.disabled_limits.is_empty();
    if disabled
        && !engine::can_disable_public_protection(state, Some(detail.organization_id), auth.role)
            .await?
    {
        return Err(AppError::with_details(
            StatusCode::FORBIDDEN,
            ErrorCode::PublicProtectionRequired,
            "You cannot disable public protection",
            json!({}),
        ));
    }
    sqlx::query("update forms set public_protection=$2, updated_at=now() where id=$1")
        .bind(id)
        .bind(json!(request.public_protection))
        .execute(&state.db)
        .await?;
    if disabled {
        auth_service::audit(
            state,
            Some(detail.organization_id),
            Some(auth.user_id),
            AuditAction::PublicProtectionDisabled,
            "form",
            Some(id),
            json!({"reason": request.reason}),
        )
        .await?;
    }
    load_form_detail(state, id).await
}

pub async fn list_access_codes(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
) -> Result<FormAccessCodesResponse, AppError> {
    let detail = get_form(state, auth, id).await?;
    let attrs = engine::ResourceAttrs {
        organization_id: Some(detail.organization_id),
        owner_id: Some(detail.creator_id),
        form_status: Some(detail.status),
        ..Default::default()
    };
    engine::require_permission(auth, PermissionAction::Update, ResourceType::Form, &attrs)?;
    load_access_codes(state, id).await
}

pub async fn set_access_codes(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    request: SetFormAccessCodesRequest,
) -> Result<FormAccessCodesResponse, AppError> {
    let detail = load_form_detail(state, id).await?;
    let attrs = engine::ResourceAttrs {
        organization_id: Some(detail.organization_id),
        owner_id: Some(detail.creator_id),
        form_status: Some(detail.status),
        ..Default::default()
    };
    engine::require_permission(auth, PermissionAction::Update, ResourceType::Form, &attrs)?;

    let mut seen = std::collections::HashSet::new();
    for code in &request.identity_codes {
        let label = code.label.trim().to_lowercase();
        if label.is_empty() || !seen.insert(label) {
            return Err(AppError::validation(
                "Identity code labels must be unique",
                json!({"field": "identity_codes"}),
            ));
        }
    }

    let mut tx = state.db.begin().await?;
    if request.clear_shared_password.unwrap_or(false) || request.shared_password.is_some() {
        sqlx::query("update form_access_codes set deleted_at=now(), updated_at=now() where form_id=$1 and code_type='shared_password' and deleted_at is null")
            .bind(id)
            .execute(&mut *tx)
            .await?;
    }
    if let Some(shared) = request.shared_password {
        let hash = password::hash_secret(shared.code.trim()).map_err(AppError::from)?;
        sqlx::query("insert into form_access_codes (form_id, code_type, label, secret_hash, enabled) values ($1,'shared_password',null,$2,$3)")
            .bind(id)
            .bind(hash)
            .bind(shared.enabled.unwrap_or(true))
            .execute(&mut *tx)
            .await?;
    }

    sqlx::query("update form_access_codes set deleted_at=now(), updated_at=now() where form_id=$1 and code_type='identity_code' and deleted_at is null")
        .bind(id)
        .execute(&mut *tx)
        .await?;
    for code in request.identity_codes {
        let hash = password::hash_secret(code.code.trim()).map_err(AppError::from)?;
        sqlx::query("insert into form_access_codes (form_id, code_type, label, secret_hash, enabled) values ($1,'identity_code',$2,$3,$4)")
            .bind(id)
            .bind(code.label.trim())
            .bind(hash)
            .bind(code.enabled.unwrap_or(true))
            .execute(&mut *tx)
            .await?;
    }
    tx.commit().await?;

    auth_service::audit(
        state,
        Some(detail.organization_id),
        Some(auth.user_id),
        AuditAction::Updated,
        "form_access_codes",
        Some(id),
        json!({}),
    )
    .await?;
    load_access_codes(state, id).await
}

pub async fn public_access_policy(
    state: &AppState,
    form: &FormDetailDto,
) -> Result<crate::api_types::public_forms::PublicFormAccessPolicyDto, AppError> {
    let requires_form_password = has_enabled_access_code(state, form.id, "shared_password").await?;
    let identity_codes_enabled = has_enabled_access_code(state, form.id, "identity_code").await?;
    let mut respondent_modes = Vec::new();
    if form.visibility.anonymous_allowed || form.settings.allow_anonymous_answers {
        respondent_modes.push("anonymous".to_owned());
    }
    if form.visibility.guest_can_answer || form.settings.guests_can_answer {
        respondent_modes.push("guest".to_owned());
    }
    if identity_codes_enabled {
        respondent_modes.push("identity_code".to_owned());
    }
    respondent_modes.push("authenticated".to_owned());

    Ok(crate::api_types::public_forms::PublicFormAccessPolicyDto {
        respondent_modes,
        requires_form_password,
        identity_codes_enabled,
        public_access_validation_required: form.public_protection.level
            != PublicProtectionLevel::None
            || form.public_protection.captcha_enabled
            || form.public_protection.email_verification_enabled
            || form.public_protection.phone_verification_enabled,
    })
}

pub async fn analytics(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
) -> Result<FormAnalyticsDto, AppError> {
    let detail = get_form(state, auth, id).await?;
    engine::require_permission(
        auth,
        PermissionAction::ViewResults,
        ResourceType::Submission,
        &engine::ResourceAttrs {
            organization_id: Some(detail.organization_id),
            owner_id: Some(detail.creator_id),
            ..Default::default()
        },
    )?;
    let row = sqlx::query("select count(*) total, count(*) filter (where valid=true) valid, count(*) filter (where anonymous=true) anonymous, count(*) filter (where submitted_at >= date_trunc('day', now())) today, count(*) filter (where submitted_at >= date_trunc('week', now())) this_week, count(*) filter (where submitted_at >= date_trunc('month', now())) this_month, coalesce(avg(total_score),0) avg_score, coalesce(max(max_score),0) max_score, coalesce(avg(percentage_score),0) avg_pct from form_submissions where form_id=$1 and deleted_at is null")
        .bind(id).fetch_one(&state.db).await?;
    let total: i64 = row.try_get("total")?;
    let valid: i64 = row.try_get("valid")?;
    let by_day = analytics_timeseries(
        state,
        "select to_char(date_trunc('day', submitted_at), 'YYYY-MM-DD') date, count(*) count from form_submissions where form_id=$1 and deleted_at is null and submitted_at >= now() - interval '30 days' group by 1 order by 1 asc",
        Some(id),
    )
    .await?;
    Ok(FormAnalyticsDto {
        form_id: id,
        submissions: SubmissionCountAnalyticsDto {
            total,
            valid,
            anonymous: row.try_get("anonymous")?,
            by_day,
            today: row.try_get("today")?,
            this_week: row.try_get("this_week")?,
            this_month: row.try_get("this_month")?,
        },
        completion: CompletionRateAnalyticsDto {
            started: total,
            completed: valid,
            completion_rate: percentage(valid, total),
        },
        score: ScoreAnalyticsDto {
            average_score: row.try_get::<f64, _>("avg_score").unwrap_or(0.0),
            max_score: row.try_get::<f64, _>("max_score").unwrap_or(0.0),
            average_percentage: row.try_get::<f64, _>("avg_pct").unwrap_or(0.0),
            category_distribution: json!({}),
        },
        fields: vec![],
        respondent_modes: analytics_buckets(
            state,
            "select coalesce(nullif(respondent_mode,''),'authenticated') key, count(*) count from form_submissions where form_id=$1 and deleted_at is null group by 1 order by count desc, key asc",
            Some(id),
            total,
        )
        .await?,
        gender_distribution: analytics_buckets(
            state,
            "select coalesce(u.gender, 'unknown') key, count(*) count from form_submissions s left join users u on u.id=s.respondent_user_id where s.form_id=$1 and s.deleted_at is null group by 1 order by count desc, key asc",
            Some(id),
            total,
        )
        .await?,
        user_role_distribution: analytics_buckets(
            state,
            "select coalesce(u.primary_role, s.respondent_mode, 'unknown') key, count(*) count from form_submissions s left join users u on u.id=s.respondent_user_id where s.form_id=$1 and s.deleted_at is null group by 1 order by count desc, key asc",
            Some(id),
            total,
        )
        .await?,
        access_code_distribution: analytics_buckets(
            state,
            "select coalesce(nullif(s.respondent_label,''), case when s.access_code_id is null then 'no_code' else 'unlabeled_code' end) key, count(*) count from form_submissions s where s.form_id=$1 and s.deleted_at is null group by 1 order by count desc, key asc",
            Some(id),
            total,
        )
        .await?,
    })
}

pub async fn dashboard_analytics(
    state: &AppState,
    auth: &AuthUser,
) -> Result<DashboardAnalyticsDto, AppError> {
    let org_filter = if matches!(auth.role, UserRole::SuperAdmin) {
        auth.organization_id
    } else {
        Some(
            auth.organization_id
                .ok_or_else(|| AppError::forbidden("Dashboard requires an organization"))?,
        )
    };
    let row = sqlx::query(
        "select \
           (select count(*) from forms f where f.deleted_at is null and ($1::uuid is null or f.organization_id=$1)) total_forms, \
           (select count(*) from forms f where f.deleted_at is null and f.status in ('published','scheduled') and ($1::uuid is null or f.organization_id=$1)) published_forms, \
           (select count(*) from users u where u.deleted_at is null and ($1::uuid is null or u.organization_id=$1)) total_users, \
           count(s.id) total_submissions, \
           count(s.id) filter (where s.valid=true) valid_submissions, \
           count(s.id) filter (where s.submitted_at >= date_trunc('day', now())) today_submissions, \
           count(s.id) filter (where s.submitted_at >= date_trunc('week', now())) week_submissions, \
           count(s.id) filter (where s.submitted_at >= date_trunc('month', now())) month_submissions \
         from form_submissions s \
         join forms f on f.id=s.form_id \
         where s.deleted_at is null and f.deleted_at is null and ($1::uuid is null or f.organization_id=$1)",
    )
    .bind(org_filter)
    .fetch_one(&state.db)
    .await?;
    let total_users: i64 = row.try_get("total_users")?;
    let total_submissions: i64 = row.try_get("total_submissions")?;
    let by_day = dashboard_timeseries(state, org_filter).await?;
    let top_forms = dashboard_top_forms(state, org_filter).await?;
    Ok(DashboardAnalyticsDto {
        total_forms: row.try_get("total_forms")?,
        published_forms: row.try_get("published_forms")?,
        total_users,
        total_submissions,
        valid_submissions: row.try_get("valid_submissions")?,
        participation_rate: percentage(total_submissions, total_users),
        today_submissions: row.try_get("today_submissions")?,
        week_submissions: row.try_get("week_submissions")?,
        month_submissions: row.try_get("month_submissions")?,
        by_day,
        gender_distribution: dashboard_buckets(
            state,
            "select coalesce(u.gender, 'unknown') key, count(*) count from form_submissions s join forms f on f.id=s.form_id left join users u on u.id=s.respondent_user_id where s.deleted_at is null and f.deleted_at is null and ($1::uuid is null or f.organization_id=$1) group by 1 order by count desc, key asc",
            org_filter,
            total_submissions,
        )
        .await?,
        user_role_distribution: dashboard_buckets(
            state,
            "select coalesce(u.primary_role, s.respondent_mode, 'unknown') key, count(*) count from form_submissions s join forms f on f.id=s.form_id left join users u on u.id=s.respondent_user_id where s.deleted_at is null and f.deleted_at is null and ($1::uuid is null or f.organization_id=$1) group by 1 order by count desc, key asc",
            org_filter,
            total_submissions,
        )
        .await?,
        respondent_mode_distribution: dashboard_buckets(
            state,
            "select coalesce(nullif(s.respondent_mode,''),'authenticated') key, count(*) count from form_submissions s join forms f on f.id=s.form_id where s.deleted_at is null and f.deleted_at is null and ($1::uuid is null or f.organization_id=$1) group by 1 order by count desc, key asc",
            org_filter,
            total_submissions,
        )
        .await?,
        access_code_distribution: dashboard_buckets(
            state,
            "select coalesce(nullif(s.respondent_label,''), case when s.access_code_id is null then 'no_code' else 'unlabeled_code' end) key, count(*) count from form_submissions s join forms f on f.id=s.form_id where s.deleted_at is null and f.deleted_at is null and ($1::uuid is null or f.organization_id=$1) group by 1 order by count desc, key asc",
            org_filter,
            total_submissions,
        )
        .await?,
        top_forms,
    })
}

async fn analytics_timeseries(
    state: &AppState,
    sql: &str,
    form_id: Option<Uuid>,
) -> Result<Vec<AnalyticsTimeseriesPointDto>, AppError> {
    let rows = if let Some(form_id) = form_id {
        sqlx::query(sql).bind(form_id).fetch_all(&state.db).await?
    } else {
        sqlx::query(sql).fetch_all(&state.db).await?
    };
    rows.iter()
        .map(|row| {
            Ok(AnalyticsTimeseriesPointDto {
                date: row.try_get("date")?,
                count: row.try_get("count")?,
            })
        })
        .collect()
}

async fn analytics_buckets(
    state: &AppState,
    sql: &str,
    form_id: Option<Uuid>,
    total: i64,
) -> Result<Vec<AnalyticsBucketDto>, AppError> {
    let rows = if let Some(form_id) = form_id {
        sqlx::query(sql).bind(form_id).fetch_all(&state.db).await?
    } else {
        sqlx::query(sql).fetch_all(&state.db).await?
    };
    rows.iter().map(|row| row_to_bucket(row, total)).collect()
}

async fn dashboard_timeseries(
    state: &AppState,
    org_filter: Option<Uuid>,
) -> Result<Vec<AnalyticsTimeseriesPointDto>, AppError> {
    let rows = sqlx::query("select to_char(date_trunc('day', s.submitted_at), 'YYYY-MM-DD') date, count(*) count from form_submissions s join forms f on f.id=s.form_id where s.deleted_at is null and f.deleted_at is null and s.submitted_at >= now() - interval '30 days' and ($1::uuid is null or f.organization_id=$1) group by 1 order by 1 asc")
        .bind(org_filter)
        .fetch_all(&state.db)
        .await?;
    rows.iter()
        .map(|row| {
            Ok(AnalyticsTimeseriesPointDto {
                date: row.try_get("date")?,
                count: row.try_get("count")?,
            })
        })
        .collect()
}

async fn dashboard_buckets(
    state: &AppState,
    sql: &str,
    org_filter: Option<Uuid>,
    total: i64,
) -> Result<Vec<AnalyticsBucketDto>, AppError> {
    let rows = sqlx::query(sql)
        .bind(org_filter)
        .fetch_all(&state.db)
        .await?;
    rows.iter().map(|row| row_to_bucket(row, total)).collect()
}

async fn dashboard_top_forms(
    state: &AppState,
    org_filter: Option<Uuid>,
) -> Result<Vec<DashboardTopFormDto>, AppError> {
    let rows = sqlx::query("select f.id form_id, f.title, count(s.id) submissions from forms f left join form_submissions s on s.form_id=f.id and s.deleted_at is null where f.deleted_at is null and ($1::uuid is null or f.organization_id=$1) group by f.id, f.title order by submissions desc, f.updated_at desc limit 5")
        .bind(org_filter)
        .fetch_all(&state.db)
        .await?;
    rows.iter()
        .map(|row| {
            Ok(DashboardTopFormDto {
                form_id: row.try_get("form_id")?,
                title: row.try_get("title")?,
                submissions: row.try_get("submissions")?,
            })
        })
        .collect()
}

fn row_to_bucket(row: &sqlx::postgres::PgRow, total: i64) -> Result<AnalyticsBucketDto, AppError> {
    let key: String = row.try_get("key")?;
    let count: i64 = row.try_get("count")?;
    Ok(AnalyticsBucketDto {
        label: analytics_bucket_label(&key),
        key,
        count,
        percentage: percentage(count, total),
    })
}

fn percentage(part: i64, total: i64) -> f64 {
    if total <= 0 {
        0.0
    } else {
        (part as f64 / total as f64) * 100.0
    }
}

fn analytics_bucket_label(key: &str) -> String {
    match key {
        "female" => "Female",
        "male" => "Male",
        "unknown" => "Unknown",
        "anonymous" => "Anonymous",
        "guest" => "Guest",
        "authenticated" => "Authenticated",
        "identity_code" => "Identity code",
        "teacher" => "Teacher",
        "student" => "Student",
        "manager" => "Manager",
        "admin" => "Admin",
        "ceo" => "CEO",
        "super_admin" => "Super admin",
        "parent" => "Parent",
        "no_code" => "No code",
        "unlabeled_code" => "Unlabeled code",
        value => value,
    }
    .to_owned()
}

pub async fn list_form_tags(
    state: &AppState,
    auth: &AuthUser,
    search: Option<String>,
) -> Result<Vec<String>, AppError> {
    let search = search.unwrap_or_default();
    let org_id = auth.organization_id;
    let rows = if matches!(auth.role, UserRole::Ceo | UserRole::SuperAdmin) && org_id.is_none() {
        sqlx::query("select distinct tag from forms f cross join lateral unnest(f.tags) tag where f.deleted_at is null and ($1='' or tag ilike '%'||$1||'%') order by tag limit 30")
            .bind(&search)
            .fetch_all(&state.db)
            .await?
    } else {
        sqlx::query("select distinct tag from forms f cross join lateral unnest(f.tags) tag where f.deleted_at is null and f.organization_id=$1 and ($2='' or tag ilike '%'||$2||'%') order by tag limit 30")
            .bind(org_id)
            .bind(&search)
            .fetch_all(&state.db)
            .await?
    };
    rows.into_iter()
        .map(|row| row.try_get("tag").map_err(AppError::from))
        .collect()
}

pub async fn load_form_detail(state: &AppState, id: Uuid) -> Result<FormDetailDto, AppError> {
    let row = sqlx::query("select f.*, (select token from public_form_tokens p where p.form_id=f.id and p.enabled=true limit 1) public_token from forms f where f.id=$1 and f.deleted_at is null")
        .bind(id).fetch_one(&state.db).await?;
    let mut detail = row_to_form_detail(&row)?;
    detail.fields = field_service::load_fields(state, id).await?;
    Ok(detail)
}

pub fn row_to_form_summary(row: &sqlx::postgres::PgRow) -> Result<FormSummaryDto, AppError> {
    Ok(FormSummaryDto {
        id: row.try_get("id")?,
        organization_id: row.try_get("organization_id")?,
        creator_id: row.try_get("creator_id")?,
        title: row.try_get("title")?,
        description: row.try_get("description")?,
        category: row.try_get("category").ok(),
        tags: row.try_get("tags").unwrap_or_default(),
        status: enum_from_str(&row.try_get::<String, _>("status")?).unwrap_or(FormStatus::Draft),
        visibility_mode: enum_from_str(&row.try_get::<String, _>("visibility_mode")?)
            .unwrap_or(VisibilityMode::Private),
        publish_mode: enum_from_str(&row.try_get::<String, _>("publish_mode")?)
            .unwrap_or(PublishMode::Private),
        scoring_mode: enum_from_str(&row.try_get::<String, _>("scoring_mode")?)
            .unwrap_or(ScoringMode::None),
        submissions_count: row.try_get("submissions_count").unwrap_or(0),
        public_token: row.try_get("public_token").ok(),
        created_at: row.try_get("created_at")?,
        updated_at: row.try_get("updated_at")?,
    })
}

pub fn row_to_form_detail(row: &sqlx::postgres::PgRow) -> Result<FormDetailDto, AppError> {
    Ok(FormDetailDto {
        id: row.try_get("id")?,
        organization_id: row.try_get("organization_id")?,
        creator_id: row.try_get("creator_id")?,
        title: row.try_get("title")?,
        description: row.try_get("description")?,
        category: row.try_get("category").ok(),
        tags: row.try_get("tags").unwrap_or_default(),
        status: enum_from_str(&row.try_get::<String, _>("status")?).unwrap_or(FormStatus::Draft),
        visibility_mode: enum_from_str(&row.try_get::<String, _>("visibility_mode")?)
            .unwrap_or(VisibilityMode::Private),
        publish_mode: enum_from_str(&row.try_get::<String, _>("publish_mode")?)
            .unwrap_or(PublishMode::Private),
        settings: serde_json::from_value(
            row.try_get::<Value, _>("settings")
                .unwrap_or_else(|_| json!({})),
        )
        .unwrap_or_default(),
        visibility: serde_json::from_value(
            row.try_get::<Value, _>("visibility")
                .unwrap_or_else(|_| json!({})),
        )
        .unwrap_or_default(),
        public_protection: serde_json::from_value(
            row.try_get::<Value, _>("public_protection")
                .unwrap_or_else(|_| json!({})),
        )
        .unwrap_or_default(),
        scoring_mode: enum_from_str(&row.try_get::<String, _>("scoring_mode")?)
            .unwrap_or(ScoringMode::None),
        scoring_config: row.try_get("scoring_config").unwrap_or_else(|_| json!({})),
        fields: vec![],
        public_token: row.try_get("public_token").ok(),
        approved_at: row.try_get("approved_at")?,
        published_at: row.try_get("published_at")?,
        closed_at: row.try_get("closed_at")?,
        created_at: row.try_get("created_at")?,
        updated_at: row.try_get("updated_at")?,
    })
}

fn normalize_category(input: Option<String>) -> Option<String> {
    input.and_then(|value| {
        let trimmed = value.trim();
        if trimmed.is_empty() {
            None
        } else {
            Some(trimmed.chars().take(80).collect())
        }
    })
}

fn normalize_tags(input: Vec<String>) -> Vec<String> {
    let mut seen = std::collections::HashSet::new();
    input
        .into_iter()
        .filter_map(|value| {
            let tag = value.trim().trim_start_matches('#').to_lowercase();
            if tag.is_empty() || tag.len() > 50 || !seen.insert(tag.clone()) {
                None
            } else {
                Some(tag)
            }
        })
        .take(30)
        .collect()
}

async fn load_access_codes(
    state: &AppState,
    form_id: Uuid,
) -> Result<FormAccessCodesResponse, AppError> {
    let rows = sqlx::query("select id, code_type, label, enabled, created_at, updated_at from form_access_codes where form_id=$1 and deleted_at is null order by code_type, label nulls first, created_at")
        .bind(form_id)
        .fetch_all(&state.db)
        .await?;
    let mut shared_password = None;
    let mut identity_codes = Vec::new();
    for row in rows {
        let dto = FormAccessCodeDto {
            id: row.try_get("id")?,
            code_type: row.try_get("code_type")?,
            label: row.try_get("label")?,
            enabled: row.try_get("enabled")?,
            created_at: row.try_get("created_at")?,
            updated_at: row.try_get("updated_at")?,
        };
        if dto.code_type == "shared_password" {
            shared_password = Some(dto);
        } else {
            identity_codes.push(dto);
        }
    }
    Ok(FormAccessCodesResponse {
        shared_password,
        identity_codes,
    })
}

async fn has_enabled_access_code(
    state: &AppState,
    form_id: Uuid,
    code_type: &str,
) -> Result<bool, AppError> {
    Ok(sqlx::query_scalar::<_, bool>(
        "select exists(select 1 from form_access_codes where form_id=$1 and code_type=$2 and enabled=true and deleted_at is null)",
    )
    .bind(form_id)
    .bind(code_type)
    .fetch_one(&state.db)
    .await?)
}

fn parse_tag_filter(input: Option<&str>) -> Vec<String> {
    normalize_tags(
        input
            .unwrap_or_default()
            .split(',')
            .map(str::to_owned)
            .collect(),
    )
}

fn form_sort_column(input: Option<&str>) -> &'static str {
    match input.unwrap_or_default() {
        "title" => "lower(f.title)",
        "created_at" => "f.created_at",
        "updated_at" => "f.updated_at",
        "status" => "f.status",
        "category" => "lower(coalesce(f.category,''))",
        "submissions_count" => "submissions_count",
        _ => "f.updated_at",
    }
}

pub async fn attrs_for_form(state: &AppState, id: Uuid) -> Result<engine::ResourceAttrs, AppError> {
    let row = sqlx::query("select organization_id, creator_id, status, visibility_mode, publish_mode from forms where id=$1 and deleted_at is null")
        .bind(id).fetch_one(&state.db).await?;
    Ok(engine::ResourceAttrs {
        organization_id: Some(row.try_get("organization_id")?),
        owner_id: Some(row.try_get("creator_id")?),
        form_status: Some(
            enum_from_str(&row.try_get::<String, _>("status")?).unwrap_or(FormStatus::Draft),
        ),
        visibility_mode: Some(
            enum_from_str(&row.try_get::<String, _>("visibility_mode")?)
                .unwrap_or(VisibilityMode::Private),
        ),
        publish_mode: Some(
            enum_from_str(&row.try_get::<String, _>("publish_mode")?)
                .unwrap_or(PublishMode::Private),
        ),
        ..Default::default()
    })
}

async fn ensure_public_token(state: &AppState, form_id: Uuid) -> Result<String, AppError> {
    if let Some(token) = sqlx::query_scalar::<_, String>(
        "select token from public_form_tokens where form_id=$1 and enabled=true limit 1",
    )
    .bind(form_id)
    .fetch_optional(&state.db)
    .await?
    {
        return Ok(token);
    }
    let token = Uuid::new_v4().simple().to_string();
    sqlx::query("insert into public_form_tokens (form_id, token, enabled) values ($1,$2,true)")
        .bind(form_id)
        .bind(&token)
        .execute(&state.db)
        .await?;
    Ok(token)
}
