use crate::{
    api_types::{
        audience::*,
        common::PaginationMeta,
        enums::{
            enum_from_str, enum_to_string, AuditAction, PermissionAction, ResourceType, UserRole,
        },
    },
    app_state::AppState,
    auth::{service as auth_service, AuthUser},
    error::AppError,
    forms::service as form_service,
    permissions::engine,
};
use serde_json::{json, Value};
use sqlx::Row;
use std::collections::HashSet;
use uuid::Uuid;

pub fn require_audience_manager(auth: &AuthUser) -> Result<(), AppError> {
    if matches!(
        auth.role,
        UserRole::Manager | UserRole::Admin | UserRole::Ceo | UserRole::SuperAdmin
    ) {
        Ok(())
    } else {
        Err(AppError::forbidden(
            "Only managers/admins/CEO can manage audience groups, segments, and assignments",
        ))
    }
}

pub async fn list_segments(
    state: &AppState,
    auth: &AuthUser,
    q: &AudienceSegmentQuery,
) -> Result<(Vec<AudienceSegmentDto>, PaginationMeta), AppError> {
    require_audience_manager(auth)?;
    let org_id = scoped_org(auth)?;
    let search = q.search.clone().unwrap_or_default();
    let segment_type = q.segment_type.clone().unwrap_or_default();
    let rows = sqlx::query(
        "select s.*, (select count(*) from audience_segment_members m where m.segment_id=s.id) member_count \
         from audience_segments s \
         where s.deleted_at is null and s.organization_id=$1 \
           and ($2='' or s.name ilike '%'||$2||'%' or s.slug ilike '%'||$2||'%' or coalesce(s.description,'') ilike '%'||$2||'%') \
           and ($3='' or s.segment_type=$3) \
           and ($4::bool is null or s.enabled=$4) \
         order by s.updated_at desc, s.name asc limit $5 offset $6",
    )
    .bind(org_id)
    .bind(&search)
    .bind(&segment_type)
    .bind(q.enabled)
    .bind(q.limit())
    .bind(q.offset())
    .fetch_all(&state.db)
    .await?;
    let total: i64 = sqlx::query_scalar(
        "select count(*) from audience_segments s \
         where s.deleted_at is null and s.organization_id=$1 \
           and ($2='' or s.name ilike '%'||$2||'%' or s.slug ilike '%'||$2||'%' or coalesce(s.description,'') ilike '%'||$2||'%') \
           and ($3='' or s.segment_type=$3) \
           and ($4::bool is null or s.enabled=$4)",
    )
    .bind(org_id)
    .bind(&search)
    .bind(&segment_type)
    .bind(q.enabled)
    .fetch_one(&state.db)
    .await?;
    let items = rows
        .iter()
        .map(row_to_segment)
        .collect::<Result<Vec<_>, _>>()?;
    Ok((items, PaginationMeta::new(q.page, q.limit(), total)))
}

pub async fn create_segment(
    state: &AppState,
    auth: &AuthUser,
    request: CreateAudienceSegmentRequest,
) -> Result<AudienceSegmentDto, AppError> {
    require_audience_manager(auth)?;
    let org_id = scoped_org(auth)?;
    let slug = normalize_slug(request.slug.as_deref().unwrap_or(&request.name));
    let segment_type = request.segment_type.unwrap_or(AudienceSegmentType::Static);
    let mut tx = state.db.begin().await?;
    let row = sqlx::query(
        "insert into audience_segments \
         (organization_id, name, slug, description, segment_type, rules, metadata, enabled, created_by_user_id, updated_by_user_id) \
         values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$9) \
         returning *, 0::bigint member_count",
    )
    .bind(org_id)
    .bind(request.name.trim())
    .bind(slug)
    .bind(request.description)
    .bind(enum_to_string(&segment_type))
    .bind(default_object(request.rules))
    .bind(default_object(request.metadata))
    .bind(request.enabled.unwrap_or(true))
    .bind(auth.user_id)
    .fetch_one(&mut *tx)
    .await?;
    let segment_id: Uuid = row.try_get("id")?;
    upsert_segment_members_tx(&mut tx, org_id, segment_id, request.member_user_ids).await?;
    tx.commit().await?;
    auth_service::audit(
        state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::Created,
        "audience_segment",
        Some(segment_id),
        json!({}),
    )
    .await?;
    load_segment(state, org_id, segment_id).await
}

pub async fn get_segment(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
) -> Result<AudienceSegmentDto, AppError> {
    require_audience_manager(auth)?;
    load_segment(state, scoped_org(auth)?, id).await
}

pub async fn update_segment(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    request: UpdateAudienceSegmentRequest,
) -> Result<AudienceSegmentDto, AppError> {
    require_audience_manager(auth)?;
    let org_id = scoped_org(auth)?;
    let current = load_segment(state, org_id, id).await?;
    let segment_type = request.segment_type.unwrap_or(current.segment_type);
    let slug = request
        .slug
        .as_deref()
        .map(normalize_slug)
        .unwrap_or(current.slug);
    let rules = request.rules.unwrap_or(current.rules);
    let metadata = request.metadata.unwrap_or(current.metadata);
    sqlx::query(
        "update audience_segments set \
         name=coalesce($3,name), slug=$4, description=coalesce($5,description), segment_type=$6, \
         rules=$7, metadata=$8, enabled=coalesce($9,enabled), updated_by_user_id=$10, updated_at=now() \
         where id=$1 and organization_id=$2 and deleted_at is null",
    )
    .bind(id)
    .bind(org_id)
    .bind(request.name)
    .bind(slug)
    .bind(request.description)
    .bind(enum_to_string(&segment_type))
    .bind(default_object(rules))
    .bind(default_object(metadata))
    .bind(request.enabled)
    .bind(auth.user_id)
    .execute(&state.db)
    .await?;
    auth_service::audit(
        state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::Updated,
        "audience_segment",
        Some(id),
        json!({}),
    )
    .await?;
    load_segment(state, org_id, id).await
}

pub async fn delete_segment(state: &AppState, auth: &AuthUser, id: Uuid) -> Result<(), AppError> {
    require_audience_manager(auth)?;
    let org_id = scoped_org(auth)?;
    sqlx::query(
        "update audience_segments set deleted_at=now(), updated_at=now(), updated_by_user_id=$3 where id=$1 and organization_id=$2 and deleted_at is null",
    )
    .bind(id)
    .bind(org_id)
    .bind(auth.user_id)
    .execute(&state.db)
    .await?;
    auth_service::audit(
        state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::Deleted,
        "audience_segment",
        Some(id),
        json!({}),
    )
    .await?;
    Ok(())
}

pub async fn list_segment_members(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
) -> Result<Vec<AudienceSegmentMemberDto>, AppError> {
    require_audience_manager(auth)?;
    let org_id = scoped_org(auth)?;
    ensure_segment_in_org(state, org_id, id).await?;
    let rows = sqlx::query(
        "select m.user_id, m.role_snapshot, m.metadata, m.created_at, u.display_name, u.primary_role \
         from audience_segment_members m join users u on u.id=m.user_id \
         where m.segment_id=$1 and u.deleted_at is null order by u.display_name asc",
    )
    .bind(id)
    .fetch_all(&state.db)
    .await?;
    rows.iter()
        .map(row_to_segment_member)
        .collect::<Result<Vec<_>, _>>()
}

pub async fn set_segment_members(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    request: SetAudienceSegmentMembersRequest,
) -> Result<Vec<AudienceSegmentMemberDto>, AppError> {
    require_audience_manager(auth)?;
    let org_id = scoped_org(auth)?;
    ensure_segment_in_org(state, org_id, id).await?;
    let mut tx = state.db.begin().await?;
    sqlx::query("delete from audience_segment_members where segment_id=$1")
        .bind(id)
        .execute(&mut *tx)
        .await?;
    upsert_segment_members_tx(&mut tx, org_id, id, request.user_ids).await?;
    sqlx::query("update audience_segments set updated_at=now(), updated_by_user_id=$2 where id=$1")
        .bind(id)
        .bind(auth.user_id)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    auth_service::audit(
        state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::Updated,
        "audience_segment_members",
        Some(id),
        json!({}),
    )
    .await?;
    list_segment_members(state, auth, id).await
}

pub async fn list_group_options(
    state: &AppState,
    auth: &AuthUser,
    q: &AudienceGroupQuery,
) -> Result<(Vec<AudienceGroupOptionDto>, PaginationMeta), AppError> {
    require_audience_manager(auth)?;
    let org_id = scoped_org(auth)?;
    let search = q.search.clone().unwrap_or_default();
    let group_type = q.group_type.clone().unwrap_or_default();
    let rows = sqlx::query(
        "select g.id, g.name, g.group_type, g.metadata, count(gm.user_id)::bigint member_count \
         from groups g \
         left join group_members gm on gm.group_id=g.id \
         where g.organization_id=$1 and g.deleted_at is null \
           and ($2='' or g.name ilike '%'||$2||'%' or coalesce(g.metadata->>'code','') ilike '%'||$2||'%') \
           and ($3='' or g.group_type=$3) \
         group by g.id \
         order by g.group_type asc, g.name asc \
         limit $4 offset $5",
    )
    .bind(org_id)
    .bind(&search)
    .bind(&group_type)
    .bind(q.limit())
    .bind(q.offset())
    .fetch_all(&state.db)
    .await?;
    let total: i64 = sqlx::query_scalar(
        "select count(*) from groups g \
         where g.organization_id=$1 and g.deleted_at is null \
           and ($2='' or g.name ilike '%'||$2||'%' or coalesce(g.metadata->>'code','') ilike '%'||$2||'%') \
           and ($3='' or g.group_type=$3)",
    )
    .bind(org_id)
    .bind(&search)
    .bind(&group_type)
    .fetch_one(&state.db)
    .await?;
    let items = rows
        .iter()
        .map(|row| {
            Ok(AudienceGroupOptionDto {
                id: row.try_get("id")?,
                name: row.try_get("name")?,
                group_type: row.try_get("group_type")?,
                member_count: row.try_get("member_count")?,
                metadata: row.try_get("metadata").unwrap_or_else(|_| json!({})),
            })
        })
        .collect::<Result<Vec<_>, AppError>>()?;
    Ok((items, PaginationMeta::new(q.page, q.limit(), total)))
}

pub async fn create_group(
    state: &AppState,
    auth: &AuthUser,
    request: CreateAudienceGroupRequest,
) -> Result<AudienceGroupDto, AppError> {
    require_audience_manager(auth)?;
    let org_id = scoped_org(auth)?;
    if let Some(parent_id) = request.parent_group_id {
        ensure_group_in_org(state, org_id, parent_id).await?;
    }
    let group_type = request.group_type.unwrap_or(AudienceGroupType::Class);
    let mut tx = state.db.begin().await?;
    let row = sqlx::query(
        "insert into groups (organization_id, parent_group_id, group_type, name, metadata) \
         values ($1,$2,$3,$4,$5) \
         returning *, 0::bigint member_count",
    )
    .bind(org_id)
    .bind(request.parent_group_id)
    .bind(enum_to_string(&group_type))
    .bind(request.name.trim())
    .bind(default_object(request.metadata))
    .fetch_one(&mut *tx)
    .await?;
    let group_id: Uuid = row.try_get("id")?;
    let members = request
        .member_user_ids
        .into_iter()
        .map(|user_id| AudienceGroupMemberInputDto {
            user_id,
            role_in_group: None,
        })
        .collect::<Vec<_>>();
    upsert_group_members_tx(&mut tx, org_id, group_id, members).await?;
    tx.commit().await?;
    auth_service::audit(
        state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::Created,
        "audience_group",
        Some(group_id),
        json!({"group_type": enum_to_string(&group_type)}),
    )
    .await?;
    load_group(state, org_id, group_id).await
}

pub async fn get_group(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
) -> Result<AudienceGroupDto, AppError> {
    require_audience_manager(auth)?;
    let org_id = scoped_org(auth)?;
    load_group(state, org_id, id).await
}

pub async fn update_group(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    request: UpdateAudienceGroupRequest,
) -> Result<AudienceGroupDto, AppError> {
    require_audience_manager(auth)?;
    let org_id = scoped_org(auth)?;
    ensure_group_in_org(state, org_id, id).await?;
    if let Some(parent_id) = request.parent_group_id {
        if parent_id == id {
            return Err(AppError::validation(
                "A group cannot be its own parent",
                json!({}),
            ));
        }
        ensure_group_in_org(state, org_id, parent_id).await?;
    }
    sqlx::query(
        "update groups set \
           name=coalesce($3, name), \
           group_type=coalesce($4, group_type), \
           parent_group_id=coalesce($5, parent_group_id), \
           metadata=coalesce($6, metadata), \
           updated_at=now() \
         where id=$1 and organization_id=$2 and deleted_at is null",
    )
    .bind(id)
    .bind(org_id)
    .bind(request.name.as_deref().map(str::trim))
    .bind(request.group_type.map(|value| enum_to_string(&value)))
    .bind(request.parent_group_id)
    .bind(request.metadata.map(default_object))
    .execute(&state.db)
    .await?;
    auth_service::audit(
        state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::Updated,
        "audience_group",
        Some(id),
        json!({}),
    )
    .await?;
    load_group(state, org_id, id).await
}

pub async fn delete_group(state: &AppState, auth: &AuthUser, id: Uuid) -> Result<(), AppError> {
    require_audience_manager(auth)?;
    let org_id = scoped_org(auth)?;
    let rows = sqlx::query(
        "update groups set deleted_at=now(), updated_at=now() \
         where id=$1 and organization_id=$2 and deleted_at is null",
    )
    .bind(id)
    .bind(org_id)
    .execute(&state.db)
    .await?
    .rows_affected();
    if rows == 0 {
        return Err(AppError::not_found("Audience group"));
    }
    auth_service::audit(
        state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::Deleted,
        "audience_group",
        Some(id),
        json!({}),
    )
    .await?;
    Ok(())
}

pub async fn list_group_members(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
) -> Result<Vec<AudienceGroupMemberDto>, AppError> {
    require_audience_manager(auth)?;
    let org_id = scoped_org(auth)?;
    ensure_group_in_org(state, org_id, id).await?;
    let rows = sqlx::query(
        "select gm.user_id, u.display_name, u.primary_role, gm.role_in_group, gm.created_at \
         from group_members gm \
         join users u on u.id=gm.user_id \
         where gm.group_id=$1 and u.organization_id=$2 and u.deleted_at is null \
         order by u.display_name asc",
    )
    .bind(id)
    .bind(org_id)
    .fetch_all(&state.db)
    .await?;
    rows.iter()
        .map(row_to_group_member)
        .collect::<Result<Vec<_>, AppError>>()
}

pub async fn set_group_members(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    request: SetAudienceGroupMembersRequest,
) -> Result<Vec<AudienceGroupMemberDto>, AppError> {
    require_audience_manager(auth)?;
    let org_id = scoped_org(auth)?;
    ensure_group_in_org(state, org_id, id).await?;
    let mut tx = state.db.begin().await?;
    sqlx::query("delete from group_members where group_id=$1")
        .bind(id)
        .execute(&mut *tx)
        .await?;
    upsert_group_members_tx(&mut tx, org_id, id, request.members).await?;
    sqlx::query("update groups set updated_at=now() where id=$1 and organization_id=$2")
        .bind(id)
        .bind(org_id)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    auth_service::audit(
        state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::Updated,
        "audience_group_members",
        Some(id),
        json!({}),
    )
    .await?;
    list_group_members(state, auth, id).await
}

pub async fn add_group_member(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    member: AudienceGroupMemberInputDto,
) -> Result<Vec<AudienceGroupMemberDto>, AppError> {
    require_audience_manager(auth)?;
    let org_id = scoped_org(auth)?;
    ensure_group_in_org(state, org_id, id).await?;
    let mut tx = state.db.begin().await?;
    upsert_group_members_tx(&mut tx, org_id, id, vec![member]).await?;
    sqlx::query("update groups set updated_at=now() where id=$1 and organization_id=$2")
        .bind(id)
        .bind(org_id)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    auth_service::audit(
        state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::Updated,
        "audience_group_members",
        Some(id),
        json!({"operation":"add"}),
    )
    .await?;
    list_group_members(state, auth, id).await
}

pub async fn remove_group_member(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    user_id: Uuid,
) -> Result<Vec<AudienceGroupMemberDto>, AppError> {
    require_audience_manager(auth)?;
    let org_id = scoped_org(auth)?;
    ensure_group_in_org(state, org_id, id).await?;
    sqlx::query("delete from group_members where group_id=$1 and user_id=$2")
        .bind(id)
        .bind(user_id)
        .execute(&state.db)
        .await?;
    sqlx::query("update groups set updated_at=now() where id=$1 and organization_id=$2")
        .bind(id)
        .bind(org_id)
        .execute(&state.db)
        .await?;
    auth_service::audit(
        state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::Updated,
        "audience_group_members",
        Some(id),
        json!({"operation":"remove", "user_id": user_id}),
    )
    .await?;
    list_group_members(state, auth, id).await
}

pub async fn list_form_assignments(
    state: &AppState,
    auth: &AuthUser,
    form_id: Uuid,
) -> Result<Vec<FormAssignmentDto>, AppError> {
    let attrs = form_service::attrs_for_form(state, form_id).await?;
    engine::require_permission(auth, PermissionAction::Update, ResourceType::Form, &attrs)?;
    let rows = sqlx::query(
        "select * from form_assignments where form_id=$1 and deleted_at is null order by created_at asc",
    )
    .bind(form_id)
    .fetch_all(&state.db)
    .await?;
    rows.iter()
        .map(row_to_assignment)
        .collect::<Result<Vec<_>, _>>()
}

pub async fn set_form_assignments(
    state: &AppState,
    auth: &AuthUser,
    form_id: Uuid,
    request: SetFormAssignmentsRequest,
) -> Result<Vec<FormAssignmentDto>, AppError> {
    require_audience_manager(auth)?;
    let attrs = form_service::attrs_for_form(state, form_id).await?;
    engine::require_permission(auth, PermissionAction::Update, ResourceType::Form, &attrs)?;
    let org_id = attrs
        .organization_id
        .ok_or_else(|| AppError::forbidden("Form assignments require an organization"))?;
    if !matches!(auth.role, UserRole::SuperAdmin | UserRole::Ceo)
        && auth.organization_id != Some(org_id)
    {
        return Err(AppError::forbidden(
            "You can only assign forms in your organization",
        ));
    }
    validate_assignment_targets(state, org_id, &request.assignments).await?;
    let mut tx = state.db.begin().await?;
    sqlx::query("update form_assignments set deleted_at=now(), updated_at=now() where form_id=$1 and deleted_at is null")
        .bind(form_id)
        .execute(&mut *tx)
        .await?;
    for assignment in request.assignments {
        sqlx::query(
            "insert into form_assignments \
             (organization_id, form_id, audience_type, audience_user_id, audience_role, audience_group_id, audience_segment_id, label, can_see, can_answer, assigned_by_user_id, metadata) \
             values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)",
        )
        .bind(org_id)
        .bind(form_id)
        .bind(enum_to_string(&assignment.audience_type))
        .bind(assignment.audience_user_id)
        .bind(assignment.audience_role.map(|role| enum_to_string(&role)))
        .bind(assignment.audience_group_id)
        .bind(assignment.audience_segment_id)
        .bind(assignment.label)
        .bind(assignment.can_see.unwrap_or(true))
        .bind(assignment.can_answer.unwrap_or(true))
        .bind(auth.user_id)
        .bind(default_object(assignment.metadata))
        .execute(&mut *tx)
        .await?;
    }
    tx.commit().await?;
    auth_service::audit(
        state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::Updated,
        "form_assignments",
        Some(form_id),
        json!({}),
    )
    .await?;
    list_form_assignments(state, auth, form_id).await
}

pub async fn user_matches_form_assignment(
    state: &AppState,
    form_id: Uuid,
    auth: &AuthUser,
    require_answer: bool,
) -> Result<bool, AppError> {
    let gate = if require_answer {
        "fa.can_answer=true"
    } else {
        "(fa.can_see=true or fa.can_answer=true)"
    };
    let sql = format!(
        "select exists( \
          select 1 from form_assignments fa \
          where fa.form_id=$1 and fa.deleted_at is null and {gate} and ( \
            fa.audience_type='organization' \
            or fa.audience_user_id=$2 \
            or fa.audience_role=$3 \
            or fa.audience_group_id in (select gm.group_id from group_members gm join groups g on g.id=gm.group_id and g.deleted_at is null where gm.user_id=$2) \
            or fa.audience_segment_id in (select sm.segment_id from audience_segment_members sm join audience_segments seg on seg.id=sm.segment_id and seg.enabled=true and seg.deleted_at is null where sm.user_id=$2) \
          ) \
        )"
    );
    Ok(sqlx::query_scalar::<_, bool>(&sql)
        .bind(form_id)
        .bind(auth.user_id)
        .bind(enum_to_string(&auth.role))
        .fetch_one(&state.db)
        .await?)
}

pub async fn form_has_assignments(state: &AppState, form_id: Uuid) -> Result<bool, AppError> {
    Ok(sqlx::query_scalar::<_, bool>(
        "select exists(select 1 from form_assignments where form_id=$1 and deleted_at is null)",
    )
    .bind(form_id)
    .fetch_one(&state.db)
    .await?)
}

pub async fn assignment_labels_for_user(
    state: &AppState,
    form_id: Uuid,
    auth: &AuthUser,
) -> Result<Vec<String>, AppError> {
    let rows = sqlx::query(
        "select coalesce(fa.label, fa.audience_type) label from form_assignments fa \
         where fa.form_id=$1 and fa.deleted_at is null and (fa.can_see=true or fa.can_answer=true) and ( \
           fa.audience_type='organization' \
           or fa.audience_user_id=$2 \
           or fa.audience_role=$3 \
           or fa.audience_group_id in (select gm.group_id from group_members gm join groups g on g.id=gm.group_id and g.deleted_at is null where gm.user_id=$2) \
           or fa.audience_segment_id in (select sm.segment_id from audience_segment_members sm join audience_segments seg on seg.id=sm.segment_id and seg.enabled=true and seg.deleted_at is null where sm.user_id=$2) \
         ) order by fa.created_at asc limit 5",
    )
    .bind(form_id)
    .bind(auth.user_id)
    .bind(enum_to_string(&auth.role))
    .fetch_all(&state.db)
    .await?;
    rows.iter()
        .map(|row| row.try_get("label").map_err(AppError::from))
        .collect()
}

async fn validate_assignment_targets(
    state: &AppState,
    org_id: Uuid,
    assignments: &[FormAssignmentInputDto],
) -> Result<(), AppError> {
    for assignment in assignments {
        match assignment.audience_type {
            AssignmentAudienceType::User => {
                let id = assignment.audience_user_id.ok_or_else(|| {
                    AppError::validation("User assignment requires audience_user_id", json!({}))
                })?;
                let ok: bool = sqlx::query_scalar(
                    "select exists(select 1 from users where id=$1 and organization_id=$2 and deleted_at is null)",
                )
                .bind(id)
                .bind(org_id)
                .fetch_one(&state.db)
                .await?;
                if !ok {
                    return Err(AppError::not_found("Assignment user"));
                }
            }
            AssignmentAudienceType::Role => {
                if assignment.audience_role.is_none() {
                    return Err(AppError::validation(
                        "Role assignment requires audience_role",
                        json!({}),
                    ));
                }
            }
            AssignmentAudienceType::Group
            | AssignmentAudienceType::Class
            | AssignmentAudienceType::Department => {
                let id = assignment.audience_group_id.ok_or_else(|| {
                    AppError::validation(
                        "Group/class/department assignment requires audience_group_id",
                        json!({}),
                    )
                })?;
                let ok: bool = sqlx::query_scalar(
                    "select exists(select 1 from groups where id=$1 and organization_id=$2 and deleted_at is null)",
                )
                .bind(id)
                .bind(org_id)
                .fetch_one(&state.db)
                .await?;
                if !ok {
                    return Err(AppError::not_found("Assignment group"));
                }
            }
            AssignmentAudienceType::Segment => {
                let id = assignment.audience_segment_id.ok_or_else(|| {
                    AppError::validation(
                        "Segment assignment requires audience_segment_id",
                        json!({}),
                    )
                })?;
                ensure_segment_in_org(state, org_id, id).await?;
            }
            AssignmentAudienceType::Organization => {}
        }
    }
    Ok(())
}

async fn upsert_segment_members_tx(
    tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    org_id: Uuid,
    segment_id: Uuid,
    user_ids: Vec<Uuid>,
) -> Result<(), AppError> {
    let mut seen = HashSet::new();
    for user_id in user_ids.into_iter().filter(|id| seen.insert(*id)) {
        let row = sqlx::query(
            "select primary_role from users where id=$1 and organization_id=$2 and deleted_at is null",
        )
        .bind(user_id)
        .bind(org_id)
        .fetch_optional(&mut **tx)
        .await?
        .ok_or_else(|| AppError::not_found("Segment member user"))?;
        let role: String = row.try_get("primary_role")?;
        sqlx::query(
            "insert into audience_segment_members (segment_id, user_id, role_snapshot, metadata) values ($1,$2,$3,'{}'::jsonb) \
             on conflict (segment_id, user_id) do update set role_snapshot=excluded.role_snapshot",
        )
        .bind(segment_id)
        .bind(user_id)
        .bind(role)
        .execute(&mut **tx)
        .await?;
    }
    Ok(())
}

async fn load_segment(
    state: &AppState,
    org_id: Uuid,
    id: Uuid,
) -> Result<AudienceSegmentDto, AppError> {
    let row = sqlx::query(
        "select s.*, (select count(*) from audience_segment_members m where m.segment_id=s.id) member_count \
         from audience_segments s where s.id=$1 and s.organization_id=$2 and s.deleted_at is null",
    )
    .bind(id)
    .bind(org_id)
    .fetch_one(&state.db)
    .await?;
    row_to_segment(&row)
}

async fn load_group(state: &AppState, org_id: Uuid, id: Uuid) -> Result<AudienceGroupDto, AppError> {
    let row = sqlx::query(
        "select g.*, count(gm.user_id)::bigint member_count \
         from groups g \
         left join group_members gm on gm.group_id=g.id \
         where g.id=$1 and g.organization_id=$2 and g.deleted_at is null \
         group by g.id",
    )
    .bind(id)
    .bind(org_id)
    .fetch_one(&state.db)
    .await?;
    row_to_group(&row)
}

async fn ensure_group_in_org(state: &AppState, org_id: Uuid, id: Uuid) -> Result<(), AppError> {
    let ok: bool = sqlx::query_scalar(
        "select exists(select 1 from groups where id=$1 and organization_id=$2 and deleted_at is null)",
    )
    .bind(id)
    .bind(org_id)
    .fetch_one(&state.db)
    .await?;
    if ok {
        Ok(())
    } else {
        Err(AppError::not_found("Audience group"))
    }
}

async fn upsert_group_members_tx(
    tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    org_id: Uuid,
    group_id: Uuid,
    members: Vec<AudienceGroupMemberInputDto>,
) -> Result<(), AppError> {
    let mut seen = HashSet::new();
    for member in members.into_iter().filter(|item| seen.insert(item.user_id)) {
        let ok: bool = sqlx::query_scalar(
            "select exists(select 1 from users where id=$1 and organization_id=$2 and deleted_at is null)",
        )
        .bind(member.user_id)
        .bind(org_id)
        .fetch_one(&mut **tx)
        .await?;
        if !ok {
            return Err(AppError::not_found("Group member user"));
        }
        sqlx::query(
            "insert into group_members (group_id, user_id, role_in_group) values ($1,$2,$3) \
             on conflict (group_id, user_id) do update set role_in_group=excluded.role_in_group",
        )
        .bind(group_id)
        .bind(member.user_id)
        .bind(member.role_in_group.as_deref().map(str::trim))
        .execute(&mut **tx)
        .await?;
    }
    Ok(())
}

async fn ensure_segment_in_org(state: &AppState, org_id: Uuid, id: Uuid) -> Result<(), AppError> {
    let ok: bool = sqlx::query_scalar(
        "select exists(select 1 from audience_segments where id=$1 and organization_id=$2 and deleted_at is null)",
    )
    .bind(id)
    .bind(org_id)
    .fetch_one(&state.db)
    .await?;
    if ok {
        Ok(())
    } else {
        Err(AppError::not_found("Audience segment"))
    }
}

fn scoped_org(auth: &AuthUser) -> Result<Uuid, AppError> {
    auth.organization_id
        .ok_or_else(|| AppError::forbidden("This operation requires an organization"))
}

fn normalize_slug(input: &str) -> String {
    let mut slug = input
        .trim()
        .to_lowercase()
        .chars()
        .map(|c| if c.is_alphanumeric() { c } else { '-' })
        .collect::<String>();
    while slug.contains("--") {
        slug = slug.replace("--", "-");
    }
    let slug = slug.trim_matches('-').to_owned();
    if slug.is_empty() {
        Uuid::new_v4().simple().to_string()
    } else {
        slug.chars().take(180).collect()
    }
}

fn default_object(value: Value) -> Value {
    match value {
        Value::Null => json!({}),
        other => other,
    }
}

fn row_to_group(row: &sqlx::postgres::PgRow) -> Result<AudienceGroupDto, AppError> {
    let group_type: AudienceGroupType = enum_from_str(&row.try_get::<String, _>("group_type")?)
        .unwrap_or(AudienceGroupType::Group);
    Ok(AudienceGroupDto {
        id: row.try_get("id")?,
        organization_id: row.try_get("organization_id")?,
        parent_group_id: row.try_get("parent_group_id")?,
        name: row.try_get("name")?,
        group_type,
        member_count: row.try_get("member_count").unwrap_or(0),
        metadata: row.try_get("metadata").unwrap_or_else(|_| json!({})),
        created_at: row.try_get("created_at")?,
        updated_at: row.try_get("updated_at")?,
    })
}

fn row_to_group_member(row: &sqlx::postgres::PgRow) -> Result<AudienceGroupMemberDto, AppError> {
    let primary_role: UserRole =
        enum_from_str(&row.try_get::<String, _>("primary_role")?).unwrap_or(UserRole::Student);
    Ok(AudienceGroupMemberDto {
        user_id: row.try_get("user_id")?,
        display_name: row.try_get("display_name")?,
        primary_role,
        role_in_group: row.try_get("role_in_group")?,
        created_at: row.try_get("created_at")?,
    })
}

fn row_to_segment(row: &sqlx::postgres::PgRow) -> Result<AudienceSegmentDto, AppError> {
    let segment_type: AudienceSegmentType =
        enum_from_str(&row.try_get::<String, _>("segment_type")?)
            .unwrap_or(AudienceSegmentType::Static);
    Ok(AudienceSegmentDto {
        id: row.try_get("id")?,
        organization_id: row.try_get("organization_id")?,
        name: row.try_get("name")?,
        slug: row.try_get("slug")?,
        description: row.try_get("description")?,
        segment_type,
        rules: row.try_get("rules").unwrap_or_else(|_| json!({})),
        metadata: row.try_get("metadata").unwrap_or_else(|_| json!({})),
        enabled: row.try_get("enabled")?,
        member_count: row.try_get("member_count").unwrap_or(0),
        created_by_user_id: row.try_get("created_by_user_id")?,
        updated_by_user_id: row.try_get("updated_by_user_id")?,
        created_at: row.try_get("created_at")?,
        updated_at: row.try_get("updated_at")?,
    })
}

fn row_to_segment_member(
    row: &sqlx::postgres::PgRow,
) -> Result<AudienceSegmentMemberDto, AppError> {
    let primary_role: UserRole =
        enum_from_str(&row.try_get::<String, _>("primary_role")?).unwrap_or(UserRole::Student);
    Ok(AudienceSegmentMemberDto {
        user_id: row.try_get("user_id")?,
        display_name: row.try_get("display_name")?,
        primary_role,
        role_snapshot: row.try_get("role_snapshot")?,
        metadata: row.try_get("metadata").unwrap_or_else(|_| json!({})),
        created_at: row.try_get("created_at")?,
    })
}

pub fn row_to_assignment(row: &sqlx::postgres::PgRow) -> Result<FormAssignmentDto, AppError> {
    let audience_type: AssignmentAudienceType =
        enum_from_str(&row.try_get::<String, _>("audience_type")?)
            .unwrap_or(AssignmentAudienceType::User);
    let audience_role: Option<String> = row.try_get("audience_role")?;
    Ok(FormAssignmentDto {
        id: row.try_get("id")?,
        organization_id: row.try_get("organization_id")?,
        form_id: row.try_get("form_id")?,
        audience_type,
        audience_user_id: row.try_get("audience_user_id")?,
        audience_role: audience_role
            .as_deref()
            .and_then(|value| enum_from_str::<UserRole>(value).ok()),
        audience_group_id: row.try_get("audience_group_id")?,
        audience_segment_id: row.try_get("audience_segment_id")?,
        label: row.try_get("label")?,
        can_see: row.try_get("can_see")?,
        can_answer: row.try_get("can_answer")?,
        assigned_by_user_id: row.try_get("assigned_by_user_id")?,
        metadata: row.try_get("metadata").unwrap_or_else(|_| json!({})),
        created_at: row.try_get("created_at")?,
        updated_at: row.try_get("updated_at")?,
    })
}
