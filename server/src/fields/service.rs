use crate::{
    api_types::{
        enums::{
            enum_from_str, enum_to_string, ErrorCode, FieldType, PermissionAction, ResourceType,
        },
        fields::*,
    },
    app_state::AppState,
    auth::AuthUser,
    error::AppError,
    permissions::engine,
};
use axum::http::StatusCode;
use regex::Regex;
use serde_json::{json, Value};
use sqlx::Row;
use std::collections::HashSet;
use uuid::Uuid;

pub fn row_to_field(row: &sqlx::postgres::PgRow) -> Result<FormFieldDto, AppError> {
    let field_type: FieldType =
        enum_from_str(&row.try_get::<String, _>("field_type")?).unwrap_or(FieldType::ShortText);
    Ok(FormFieldDto {
        id: row.try_get("id")?,
        form_id: row.try_get("form_id")?,
        field_type,
        label: row.try_get("label")?,
        description: row.try_get("description")?,
        placeholder: row.try_get("placeholder")?,
        required: row.try_get("required")?,
        order_index: row.try_get("order_index")?,
        config: serde_json::from_value(
            row.try_get::<Value, _>("config")
                .unwrap_or_else(|_| json!({})),
        )
        .unwrap_or_default(),
        validation: serde_json::from_value(
            row.try_get::<Value, _>("validation")
                .unwrap_or_else(|_| json!({})),
        )
        .unwrap_or_default(),
        visibility_conditions: serde_json::from_value(
            row.try_get::<Value, _>("visibility_conditions")
                .unwrap_or_else(|_| json!([])),
        )
        .unwrap_or_default(),
        scoring_config: serde_json::from_value(
            row.try_get::<Value, _>("scoring_config")
                .unwrap_or_else(|_| json!({})),
        )
        .unwrap_or_default(),
        permissions: serde_json::from_value(
            row.try_get::<Value, _>("permissions")
                .unwrap_or_else(|_| json!({})),
        )
        .unwrap_or_default(),
        created_at: row.try_get("created_at")?,
        updated_at: row.try_get("updated_at")?,
    })
}

pub async fn load_fields(state: &AppState, form_id: Uuid) -> Result<Vec<FormFieldDto>, AppError> {
    let rows = sqlx::query("select id, form_id, field_type, label, description, placeholder, required, order_index, config, validation, visibility_conditions, scoring_config, permissions, created_at, updated_at from form_fields where form_id=$1 and deleted_at is null order by order_index asc, created_at asc")
        .bind(form_id).fetch_all(&state.db).await?;
    rows.iter().map(row_to_field).collect()
}

pub async fn create_field(
    state: &AppState,
    auth: &AuthUser,
    form_id: Uuid,
    request: CreateFormFieldRequest,
) -> Result<FormFieldDto, AppError> {
    validate_field_request(
        state,
        auth,
        form_id,
        request.field_type,
        &request.config,
        &request.validation,
        &request.visibility_conditions,
        &request.scoring_config,
    )
    .await?;
    let row = sqlx::query("insert into form_fields (form_id, field_type, label, description, placeholder, required, order_index, config, validation, visibility_conditions, scoring_config, permissions) values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) returning id, form_id, field_type, label, description, placeholder, required, order_index, config, validation, visibility_conditions, scoring_config, permissions, created_at, updated_at")
        .bind(form_id)
        .bind(enum_to_string(&request.field_type))
        .bind(request.label)
        .bind(request.description)
        .bind(request.placeholder)
        .bind(request.required)
        .bind(request.order_index)
        .bind(json!(request.config))
        .bind(json!(request.validation))
        .bind(json!(request.visibility_conditions))
        .bind(json!(request.scoring_config))
        .bind(json!(request.permissions))
        .fetch_one(&state.db).await?;
    Ok(row_to_field(&row)?)
}

pub async fn update_field(
    state: &AppState,
    auth: &AuthUser,
    form_id: Uuid,
    field_id: Uuid,
    request: UpdateFormFieldRequest,
) -> Result<FormFieldDto, AppError> {
    let current = sqlx::query("select id, form_id, field_type, label, description, placeholder, required, order_index, config, validation, visibility_conditions, scoring_config, permissions, created_at, updated_at from form_fields where form_id=$1 and id=$2 and deleted_at is null")
        .bind(form_id).bind(field_id).fetch_one(&state.db).await?;
    let current_field = row_to_field(&current)?;
    let field_type = request.field_type.unwrap_or(current_field.field_type);
    let config = request.config.unwrap_or(current_field.config);
    let validation = request.validation.unwrap_or(current_field.validation);
    let logic = request
        .visibility_conditions
        .unwrap_or(current_field.visibility_conditions);
    let scoring = request
        .scoring_config
        .unwrap_or(current_field.scoring_config);
    let permissions = request.permissions.unwrap_or(current_field.permissions);
    validate_field_request(
        state,
        auth,
        form_id,
        field_type,
        &config,
        &validation,
        &logic,
        &scoring,
    )
    .await?;
    let row = sqlx::query("update form_fields set field_type=$3, label=coalesce($4,label), description=$5, placeholder=$6, required=coalesce($7,required), order_index=coalesce($8,order_index), config=$9, validation=$10, visibility_conditions=$11, scoring_config=$12, permissions=$13, updated_at=now() where form_id=$1 and id=$2 and deleted_at is null returning id, form_id, field_type, label, description, placeholder, required, order_index, config, validation, visibility_conditions, scoring_config, permissions, created_at, updated_at")
        .bind(form_id).bind(field_id).bind(enum_to_string(&field_type)).bind(request.label)
        .bind(request.description).bind(request.placeholder).bind(request.required).bind(request.order_index)
        .bind(json!(config)).bind(json!(validation)).bind(json!(logic)).bind(json!(scoring)).bind(json!(permissions))
        .fetch_one(&state.db).await?;
    Ok(row_to_field(&row)?)
}

pub async fn delete_field(
    state: &AppState,
    _auth: &AuthUser,
    form_id: Uuid,
    field_id: Uuid,
) -> Result<(), AppError> {
    sqlx::query("update form_fields set deleted_at=now(), updated_at=now() where form_id=$1 and id=$2 and deleted_at is null")
        .bind(form_id).bind(field_id).execute(&state.db).await?;
    Ok(())
}

async fn validate_field_request(
    state: &AppState,
    auth: &AuthUser,
    form_id: Uuid,
    field_type: FieldType,
    config: &FieldConfigDto,
    validation: &FieldValidationDto,
    logic: &[ConditionalLogicRuleDto],
    scoring: &FieldScoringConfigDto,
) -> Result<(), AppError> {
    let form = sqlx::query(
        "select organization_id, creator_id, status from forms where id=$1 and deleted_at is null",
    )
    .bind(form_id)
    .fetch_one(&state.db)
    .await?;
    let org_id: Uuid = form.try_get("organization_id")?;
    let creator_id: Uuid = form.try_get("creator_id")?;
    let status = enum_from_str(&form.try_get::<String, _>("status")?)
        .unwrap_or(crate::api_types::enums::FormStatus::Draft);
    engine::require_permission(
        auth,
        PermissionAction::Update,
        ResourceType::FormField,
        &engine::ResourceAttrs {
            organization_id: Some(org_id),
            owner_id: Some(creator_id),
            form_status: Some(status),
            ..Default::default()
        },
    )?;

    let allowed = engine::allowed_field_types_for_role(state, Some(org_id), auth.role)
        .await
        .unwrap_or_else(|_| engine::default_field_types_for_role(auth.role));
    if !allowed.contains(&field_type) {
        return Err(AppError::with_details(
            StatusCode::FORBIDDEN,
            ErrorCode::PermissionDenied,
            "This role cannot use the requested field type",
            json!({"field_type": enum_to_string(&field_type)}),
        ));
    }
    validate_field_config(field_type, config, validation)?;
    validate_conditional_logic(state, form_id, logic).await?;
    if scoring.enabled
        && !matches!(
            auth.role,
            crate::api_types::enums::UserRole::Manager
                | crate::api_types::enums::UserRole::Admin
                | crate::api_types::enums::UserRole::Ceo
                | crate::api_types::enums::UserRole::SuperAdmin
        )
    {
        return Err(AppError::with_details(
            StatusCode::FORBIDDEN,
            ErrorCode::PermissionDenied,
            "This role cannot change scoring",
            json!({}),
        ));
    }
    Ok(())
}

pub fn validate_field_config(
    field_type: FieldType,
    config: &FieldConfigDto,
    validation: &FieldValidationDto,
) -> Result<(), AppError> {
    match field_type {
        FieldType::SingleChoice
        | FieldType::MultipleChoice
        | FieldType::Dropdown
        | FieldType::Ranking
        | FieldType::QuizQuestion => {
            if config.options.is_empty() {
                return Err(AppError::validation(
                    "Choice fields require at least one option",
                    json!({"field":"config.options"}),
                ));
            }
        }
        FieldType::MatrixSingleChoice
        | FieldType::MatrixMultipleChoice
        | FieldType::LikertScale => {
            if config.rows.is_empty() || config.columns.is_empty() {
                return Err(AppError::validation(
                    "Matrix/Likert fields require rows and columns",
                    json!({"fields":["config.rows","config.columns"]}),
                ));
            }
        }
        FieldType::Slider
        | FieldType::NumericRating
        | FieldType::Number
        | FieldType::Decimal
        | FieldType::RatingStars
        | FieldType::Nps => {
            if let (Some(min), Some(max)) = (config.min, config.max) {
                if min >= max {
                    return Err(AppError::validation(
                        "Numeric min must be less than max",
                        json!({"min":min,"max":max}),
                    ));
                }
            }
        }
        _ => {}
    }
    if let Some(pattern) = &validation.regex {
        Regex::new(pattern).map_err(|e| {
            AppError::validation(
                "Invalid validation regex",
                json!({"regex_error": e.to_string()}),
            )
        })?;
    }
    Ok(())
}

pub async fn validate_conditional_logic(
    state: &AppState,
    form_id: Uuid,
    logic: &[ConditionalLogicRuleDto],
) -> Result<(), AppError> {
    if logic.is_empty() {
        return Ok(());
    }
    let rows = sqlx::query("select id from form_fields where form_id=$1 and deleted_at is null")
        .bind(form_id)
        .fetch_all(&state.db)
        .await?;
    let valid: HashSet<Uuid> = rows
        .iter()
        .filter_map(|r| r.try_get::<Uuid, _>("id").ok())
        .collect();
    for rule in logic {
        for cond in &rule.conditions {
            if !valid.contains(&cond.source_field_id) {
                return Err(AppError::validation(
                    "Conditional logic references an unknown source field",
                    json!({"source_field_id": cond.source_field_id}),
                ));
            }
        }
        for target in &rule.target_field_ids {
            if !valid.contains(target) {
                return Err(AppError::validation(
                    "Conditional logic references an unknown target field",
                    json!({"target_field_id": target}),
                ));
            }
        }
    }
    Ok(())
}
