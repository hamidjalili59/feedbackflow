use crate::{
    api_types::{
        common::PaginationMeta,
        enums::{
            enum_from_str, enum_to_string, AuditAction, PermissionAction, ResourceType, UserRole,
        },
        metrics::*,
    },
    app_state::AppState,
    auth::{service as auth_service, AuthUser},
    error::AppError,
    permissions::engine,
};
use serde_json::{json, Value};
use sqlx::Row;
use uuid::Uuid;

pub fn require_metric_manager(auth: &AuthUser) -> Result<(), AppError> {
    if matches!(
        auth.role,
        UserRole::Manager | UserRole::Admin | UserRole::Ceo | UserRole::SuperAdmin
    ) {
        Ok(())
    } else {
        Err(AppError::forbidden(
            "Only managers/admins/CEO can manage dashboard metrics",
        ))
    }
}

pub async fn list_metrics(
    state: &AppState,
    auth: &AuthUser,
    q: &MetricQuery,
) -> Result<(Vec<MetricDefinitionDto>, PaginationMeta), AppError> {
    require_metric_manager(auth)?;
    let org_id = scoped_org(auth)?;
    let search = q.search.clone().unwrap_or_default();
    let rows = sqlx::query(
        "select m.*, (select count(*) from metric_mappings mp where mp.metric_id=m.id and mp.deleted_at is null) mapping_count \
         from metric_definitions m \
         where m.deleted_at is null and m.organization_id=$1 \
           and ($2='' or m.key ilike '%'||$2||'%' or m.title ilike '%'||$2||'%' or coalesce(m.description,'') ilike '%'||$2||'%') \
           and ($3::bool is null or m.enabled=$3) \
         order by m.updated_at desc, m.title asc limit $4 offset $5",
    )
    .bind(org_id)
    .bind(&search)
    .bind(q.enabled)
    .bind(q.limit())
    .bind(q.offset())
    .fetch_all(&state.db)
    .await?;
    let total: i64 = sqlx::query_scalar(
        "select count(*) from metric_definitions m \
         where m.deleted_at is null and m.organization_id=$1 \
           and ($2='' or m.key ilike '%'||$2||'%' or m.title ilike '%'||$2||'%' or coalesce(m.description,'') ilike '%'||$2||'%') \
           and ($3::bool is null or m.enabled=$3)",
    )
    .bind(org_id)
    .bind(&search)
    .bind(q.enabled)
    .fetch_one(&state.db)
    .await?;
    let items = rows
        .iter()
        .map(row_to_metric)
        .collect::<Result<Vec<_>, _>>()?;
    Ok((items, PaginationMeta::new(q.page, q.limit(), total)))
}

pub async fn create_metric(
    state: &AppState,
    auth: &AuthUser,
    request: CreateMetricDefinitionRequest,
) -> Result<MetricDefinitionDto, AppError> {
    require_metric_manager(auth)?;
    engine::require_permission(
        auth,
        PermissionAction::ManageScoring,
        ResourceType::Metric,
        &engine::ResourceAttrs {
            organization_id: auth.organization_id,
            ..Default::default()
        },
    )?;
    let org_id = scoped_org(auth)?;
    validate_scale(request.scale_min, request.scale_max)?;
    let metric_type = request.metric_type.unwrap_or(MetricType::Score);
    let aggregation_method = request
        .aggregation_method
        .unwrap_or(MetricAggregationMethod::Avg);
    let positive_direction = request
        .positive_direction
        .unwrap_or(MetricPositiveDirection::HigherIsBetter);
    let row = sqlx::query(
        "insert into metric_definitions \
         (organization_id, key, title, description, metric_type, aggregation_method, scale_min, scale_max, positive_direction, thresholds, display, enabled, created_by_user_id, updated_by_user_id) \
         values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$13) \
         returning *, 0::bigint mapping_count",
    )
    .bind(org_id)
    .bind(normalize_key(&request.key))
    .bind(request.title.trim())
    .bind(request.description)
    .bind(enum_to_string(&metric_type))
    .bind(enum_to_string(&aggregation_method))
    .bind(request.scale_min)
    .bind(request.scale_max)
    .bind(enum_to_string(&positive_direction))
    .bind(default_array(request.thresholds))
    .bind(default_object(request.display))
    .bind(request.enabled.unwrap_or(true))
    .bind(auth.user_id)
    .fetch_one(&state.db)
    .await?;
    let id: Uuid = row.try_get("id")?;
    auth_service::audit(
        state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::Created,
        "metric_definition",
        Some(id),
        json!({}),
    )
    .await?;
    load_metric(state, org_id, id).await
}

pub async fn get_metric(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
) -> Result<MetricDefinitionDto, AppError> {
    require_metric_manager(auth)?;
    load_metric(state, scoped_org(auth)?, id).await
}

pub async fn update_metric(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    request: UpdateMetricDefinitionRequest,
) -> Result<MetricDefinitionDto, AppError> {
    require_metric_manager(auth)?;
    engine::require_permission(
        auth,
        PermissionAction::ManageScoring,
        ResourceType::Metric,
        &engine::ResourceAttrs {
            organization_id: auth.organization_id,
            ..Default::default()
        },
    )?;
    let org_id = scoped_org(auth)?;
    let current = load_metric(state, org_id, id).await?;
    let metric_type = request.metric_type.unwrap_or(current.metric_type);
    let aggregation_method = request
        .aggregation_method
        .unwrap_or(current.aggregation_method);
    let positive_direction = request
        .positive_direction
        .unwrap_or(current.positive_direction);
    let scale_min = request.scale_min.or(current.scale_min);
    let scale_max = request.scale_max.or(current.scale_max);
    validate_scale(scale_min, scale_max)?;
    let key = request
        .key
        .as_deref()
        .map(normalize_key)
        .unwrap_or(current.key);
    let thresholds = request.thresholds.unwrap_or(current.thresholds);
    let display = request.display.unwrap_or(current.display);
    sqlx::query(
        "update metric_definitions set \
         key=$3, title=coalesce($4,title), description=coalesce($5,description), metric_type=$6, aggregation_method=$7, \
         scale_min=$8, scale_max=$9, positive_direction=$10, thresholds=$11, display=$12, enabled=coalesce($13,enabled), \
         updated_by_user_id=$14, updated_at=now() \
         where id=$1 and organization_id=$2 and deleted_at is null",
    )
    .bind(id)
    .bind(org_id)
    .bind(key)
    .bind(request.title)
    .bind(request.description)
    .bind(enum_to_string(&metric_type))
    .bind(enum_to_string(&aggregation_method))
    .bind(scale_min)
    .bind(scale_max)
    .bind(enum_to_string(&positive_direction))
    .bind(default_array(thresholds))
    .bind(default_object(display))
    .bind(request.enabled)
    .bind(auth.user_id)
    .execute(&state.db)
    .await?;
    auth_service::audit(
        state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::Updated,
        "metric_definition",
        Some(id),
        json!({}),
    )
    .await?;
    load_metric(state, org_id, id).await
}

pub async fn delete_metric(state: &AppState, auth: &AuthUser, id: Uuid) -> Result<(), AppError> {
    require_metric_manager(auth)?;
    engine::require_permission(
        auth,
        PermissionAction::ManageScoring,
        ResourceType::Metric,
        &engine::ResourceAttrs {
            organization_id: auth.organization_id,
            ..Default::default()
        },
    )?;
    let org_id = scoped_org(auth)?;
    sqlx::query(
        "update metric_definitions set deleted_at=now(), updated_at=now(), updated_by_user_id=$3 where id=$1 and organization_id=$2 and deleted_at is null",
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
        "metric_definition",
        Some(id),
        json!({}),
    )
    .await?;
    Ok(())
}

pub async fn list_mappings(
    state: &AppState,
    auth: &AuthUser,
    metric_id: Uuid,
) -> Result<Vec<MetricMappingDto>, AppError> {
    require_metric_manager(auth)?;
    let org_id = scoped_org(auth)?;
    ensure_metric_in_org(state, org_id, metric_id).await?;
    load_mappings(state, org_id, metric_id).await
}

pub async fn set_mappings(
    state: &AppState,
    auth: &AuthUser,
    metric_id: Uuid,
    request: SetMetricMappingsRequest,
) -> Result<Vec<MetricMappingDto>, AppError> {
    require_metric_manager(auth)?;
    engine::require_permission(
        auth,
        PermissionAction::ManageScoring,
        ResourceType::Metric,
        &engine::ResourceAttrs {
            organization_id: auth.organization_id,
            ..Default::default()
        },
    )?;
    let org_id = scoped_org(auth)?;
    ensure_metric_in_org(state, org_id, metric_id).await?;
    validate_mapping_targets(state, org_id, &request.mappings).await?;
    let mut tx = state.db.begin().await?;
    sqlx::query("update metric_mappings set deleted_at=now(), updated_at=now() where metric_id=$1 and deleted_at is null")
        .bind(metric_id)
        .execute(&mut *tx)
        .await?;
    for mapping in request.mappings {
        let source_type = mapping
            .source_type
            .unwrap_or(MetricMappingSourceType::FieldAnswer);
        sqlx::query(
            "insert into metric_mappings \
             (organization_id, metric_id, form_id, field_id, source_type, transform, weight, enabled) \
             values ($1,$2,$3,$4,$5,$6,$7,$8)",
        )
        .bind(org_id)
        .bind(metric_id)
        .bind(mapping.form_id)
        .bind(mapping.field_id)
        .bind(enum_to_string(&source_type))
        .bind(default_object(mapping.transform))
        .bind(mapping.weight.unwrap_or(1.0))
        .bind(mapping.enabled.unwrap_or(true))
        .execute(&mut *tx)
        .await?;
    }
    tx.commit().await?;
    auth_service::audit(
        state,
        Some(org_id),
        Some(auth.user_id),
        AuditAction::Updated,
        "metric_mappings",
        Some(metric_id),
        json!({}),
    )
    .await?;
    load_mappings(state, org_id, metric_id).await
}

pub async fn load_active_metrics_for_org(
    state: &AppState,
    org_id: Uuid,
) -> Result<Vec<MetricDefinitionDto>, AppError> {
    let rows = sqlx::query(
        "select m.*, (select count(*) from metric_mappings mp where mp.metric_id=m.id and mp.deleted_at is null) mapping_count \
         from metric_definitions m where m.organization_id=$1 and m.enabled=true and m.deleted_at is null order by m.created_at asc",
    )
    .bind(org_id)
    .fetch_all(&state.db)
    .await?;
    rows.iter()
        .map(row_to_metric)
        .collect::<Result<Vec<_>, _>>()
}

pub async fn load_mappings(
    state: &AppState,
    org_id: Uuid,
    metric_id: Uuid,
) -> Result<Vec<MetricMappingDto>, AppError> {
    let rows = sqlx::query(
        "select * from metric_mappings where organization_id=$1 and metric_id=$2 and deleted_at is null order by created_at asc",
    )
    .bind(org_id)
    .bind(metric_id)
    .fetch_all(&state.db)
    .await?;
    rows.iter()
        .map(row_to_mapping)
        .collect::<Result<Vec<_>, _>>()
}

pub async fn load_metric(
    state: &AppState,
    org_id: Uuid,
    id: Uuid,
) -> Result<MetricDefinitionDto, AppError> {
    let row = sqlx::query(
        "select m.*, (select count(*) from metric_mappings mp where mp.metric_id=m.id and mp.deleted_at is null) mapping_count \
         from metric_definitions m where m.id=$1 and m.organization_id=$2 and m.deleted_at is null",
    )
    .bind(id)
    .bind(org_id)
    .fetch_one(&state.db)
    .await?;
    row_to_metric(&row)
}

async fn ensure_metric_in_org(state: &AppState, org_id: Uuid, id: Uuid) -> Result<(), AppError> {
    let ok: bool = sqlx::query_scalar(
        "select exists(select 1 from metric_definitions where id=$1 and organization_id=$2 and deleted_at is null)",
    )
    .bind(id)
    .bind(org_id)
    .fetch_one(&state.db)
    .await?;
    if ok {
        Ok(())
    } else {
        Err(AppError::not_found("Metric"))
    }
}

async fn validate_mapping_targets(
    state: &AppState,
    org_id: Uuid,
    mappings: &[MetricMappingInputDto],
) -> Result<(), AppError> {
    for mapping in mappings {
        if let Some(form_id) = mapping.form_id {
            let ok: bool = sqlx::query_scalar(
                "select exists(select 1 from forms where id=$1 and organization_id=$2 and deleted_at is null)",
            )
            .bind(form_id)
            .bind(org_id)
            .fetch_one(&state.db)
            .await?;
            if !ok {
                return Err(AppError::not_found("Metric mapping form"));
            }
        }
        if let Some(field_id) = mapping.field_id {
            let ok: bool = sqlx::query_scalar(
                "select exists(select 1 from form_fields ff join forms f on f.id=ff.form_id where ff.id=$1 and f.organization_id=$2 and ff.deleted_at is null and f.deleted_at is null)",
            )
            .bind(field_id)
            .bind(org_id)
            .fetch_one(&state.db)
            .await?;
            if !ok {
                return Err(AppError::not_found("Metric mapping field"));
            }
        }
    }
    Ok(())
}

fn scoped_org(auth: &AuthUser) -> Result<Uuid, AppError> {
    auth.organization_id
        .ok_or_else(|| AppError::forbidden("This operation requires an organization"))
}

fn validate_scale(min: Option<f64>, max: Option<f64>) -> Result<(), AppError> {
    if let (Some(min), Some(max)) = (min, max) {
        if min >= max {
            return Err(AppError::validation(
                "scale_min must be lower than scale_max",
                json!({"scale_min": min, "scale_max": max}),
            ));
        }
    }
    Ok(())
}

fn normalize_key(input: &str) -> String {
    input
        .trim()
        .to_lowercase()
        .chars()
        .map(|c| {
            if c.is_ascii_alphanumeric() || c == '_' || c == '-' {
                c
            } else {
                '_'
            }
        })
        .collect::<String>()
        .trim_matches('_')
        .chars()
        .take(120)
        .collect()
}

fn default_object(value: Value) -> Value {
    match value {
        Value::Null => json!({}),
        other => other,
    }
}

fn default_array(value: Value) -> Value {
    match value {
        Value::Null => json!([]),
        other => other,
    }
}

fn row_to_metric(row: &sqlx::postgres::PgRow) -> Result<MetricDefinitionDto, AppError> {
    Ok(MetricDefinitionDto {
        id: row.try_get("id")?,
        organization_id: row.try_get("organization_id")?,
        key: row.try_get("key")?,
        title: row.try_get("title")?,
        description: row.try_get("description")?,
        metric_type: enum_from_str(&row.try_get::<String, _>("metric_type")?)
            .unwrap_or(MetricType::Score),
        aggregation_method: enum_from_str(&row.try_get::<String, _>("aggregation_method")?)
            .unwrap_or(MetricAggregationMethod::Avg),
        scale_min: row.try_get("scale_min")?,
        scale_max: row.try_get("scale_max")?,
        positive_direction: enum_from_str(&row.try_get::<String, _>("positive_direction")?)
            .unwrap_or(MetricPositiveDirection::HigherIsBetter),
        thresholds: row.try_get("thresholds").unwrap_or_else(|_| json!([])),
        display: row.try_get("display").unwrap_or_else(|_| json!({})),
        enabled: row.try_get("enabled")?,
        mapping_count: row.try_get("mapping_count").unwrap_or(0),
        created_by_user_id: row.try_get("created_by_user_id")?,
        updated_by_user_id: row.try_get("updated_by_user_id")?,
        created_at: row.try_get("created_at")?,
        updated_at: row.try_get("updated_at")?,
    })
}

fn row_to_mapping(row: &sqlx::postgres::PgRow) -> Result<MetricMappingDto, AppError> {
    Ok(MetricMappingDto {
        id: row.try_get("id")?,
        organization_id: row.try_get("organization_id")?,
        metric_id: row.try_get("metric_id")?,
        form_id: row.try_get("form_id")?,
        field_id: row.try_get("field_id")?,
        source_type: enum_from_str(&row.try_get::<String, _>("source_type")?)
            .unwrap_or(MetricMappingSourceType::FieldAnswer),
        transform: row.try_get("transform").unwrap_or_else(|_| json!({})),
        weight: row.try_get("weight")?,
        enabled: row.try_get("enabled")?,
        created_at: row.try_get("created_at")?,
        updated_at: row.try_get("updated_at")?,
    })
}
