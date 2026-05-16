use crate::{
    activities::engine as activity_engine,
    api_types::{
        common::{ListQuery, PaginationMeta},
        enums::*,
        submissions::*,
    },
    app_state::AppState,
    auth::{service as auth_service, AuthUser},
    error::AppError,
    forms::{service as form_service, visibility},
    scoring::engine as scoring_engine,
};
use axum::http::StatusCode;
use chrono::Utc;
use serde_json::{json, Value};
use sqlx::Row;
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct SubmissionAccessContext {
    pub public_token_id: Uuid,
    pub access_code_id: Option<Uuid>,
    pub respondent_mode: String,
    pub respondent_label: Option<String>,
}

pub async fn create_submission(
    state: &AppState,
    auth: Option<&AuthUser>,
    form_id: Uuid,
    request: CreateSubmissionRequest,
    public_context: Option<SubmissionAccessContext>,
) -> Result<SubmissionDetailDto, AppError> {
    let form = form_service::load_form_detail(state, form_id).await?;
    let user = auth;
    let has_public_access_context = public_context.is_some();
    if !has_public_access_context
        && !visibility::can_answer_form(
            form.status,
            form.creator_id,
            form.organization_id,
            &form.visibility,
            user,
        )
    {
        return Err(AppError::with_details(
            StatusCode::FORBIDDEN,
            if form.status != FormStatus::Published {
                ErrorCode::FormNotPublished
            } else {
                ErrorCode::PermissionDenied
            },
            "This form cannot be answered by this principal",
            json!({}),
        ));
    }
    if form.status != FormStatus::Published {
        return Err(AppError::new(
            StatusCode::CONFLICT,
            ErrorCode::FormNotPublished,
            "Form is not published",
        ));
    }
    if let Some(start) = form.settings.start_at {
        if Utc::now() < start {
            return Err(AppError::conflict("Form is not open yet"));
        }
    }
    if let Some(end) = form.settings.end_at {
        if Utc::now() > end {
            return Err(AppError::new(
                StatusCode::CONFLICT,
                ErrorCode::FormClosed,
                "Form is closed",
            ));
        }
    }
    if form.settings.one_submission_per_user {
        if let Some(u) = user {
            let exists: bool = sqlx::query_scalar("select exists(select 1 from form_submissions where form_id=$1 and respondent_user_id=$2 and deleted_at is null)").bind(form_id).bind(u.user_id).fetch_one(&state.db).await.unwrap_or(false);
            if exists {
                return Err(AppError::conflict("User has already submitted this form"));
            }
        }
    }
    validate_answers(&form.fields, &request.answers)?;
    let score_result = scoring_engine::calculate_submission_score(
        &form.fields,
        &request.answers,
        form.scoring_mode,
    );
    if request.anonymous.unwrap_or(false)
        && !(form.visibility.anonymous_allowed || form.settings.allow_anonymous_answers)
    {
        return Err(AppError::with_details(
            StatusCode::FORBIDDEN,
            ErrorCode::PublicAccessDenied,
            "Anonymous answers are not enabled for this form",
            json!({ "field": "anonymous" }),
        ));
    }
    let anonymous = request.anonymous.unwrap_or(user.is_none());
    let public_token_id = public_context.as_ref().map(|ctx| ctx.public_token_id);
    let access_code_id = public_context.as_ref().and_then(|ctx| ctx.access_code_id);
    let respondent_mode = public_context
        .as_ref()
        .map(|ctx| ctx.respondent_mode.clone())
        .unwrap_or_else(|| {
            if anonymous {
                "anonymous".to_owned()
            } else {
                "authenticated".to_owned()
            }
        });
    let respondent_label = public_context
        .as_ref()
        .and_then(|ctx| ctx.respondent_label.clone())
        .or_else(|| request.respondent_name.as_ref().map(|n| n.trim().to_owned()).filter(|n| !n.is_empty()));
    let mut tx = state.db.begin().await?;
    let row = sqlx::query("insert into form_submissions (form_id, respondent_user_id, guest_token_id, access_code_id, respondent_mode, respondent_label, anonymous, fingerprint_token, valid, total_score, max_score, percentage_score, score_category) values ($1,$2,$3,$4,$5,$6,$7,$8,true,$9,$10,$11,$12) returning id, form_id, respondent_user_id, guest_token_id, access_code_id, respondent_mode, respondent_label, anonymous, valid, total_score, max_score, percentage_score, score_category, submitted_at, updated_at")
        .bind(form_id).bind(user.map(|u| u.user_id)).bind(public_token_id).bind(access_code_id).bind(respondent_mode).bind(respondent_label).bind(anonymous).bind(request.fingerprint_token)
        .bind(score_result.total_score).bind(score_result.max_score).bind(score_result.percentage_score).bind(score_result.category.as_ref().map(|c| c.label.clone()))
        .fetch_one(&mut *tx).await?;
    let submission_id: Uuid = row.try_get("id")?;
    let mut answers = vec![];
    for ans in request.answers {
        let arow = sqlx::query("insert into form_answers (submission_id, field_id, value, metadata) values ($1,$2,$3,$4) returning id, submission_id, field_id, value, metadata, created_at")
            .bind(submission_id).bind(ans.field_id).bind(ans.value).bind(ans.metadata).fetch_one(&mut *tx).await?;
        answers.push(row_to_answer(&arow)?);
    }
    sqlx::query("insert into score_breakdowns (submission_id, result) values ($1,$2)")
        .bind(submission_id)
        .bind(json!(score_result))
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    activity_engine::run_activity_rules(state, &form, submission_id, &score_result, &answers)
        .await?;
    auth_service::audit(
        state,
        Some(form.organization_id),
        user.map(|u| u.user_id),
        AuditAction::SubmissionCreated,
        "submission",
        Some(submission_id),
        json!({"form_id": form_id}),
    )
    .await?;
    load_submission(state, submission_id).await
}

pub async fn list_submissions(
    state: &AppState,
    auth: &AuthUser,
    form_id: Uuid,
    q: &ListQuery,
) -> Result<(Vec<SubmissionSummaryDto>, PaginationMeta), AppError> {
    let form = form_service::get_form(state, auth, form_id).await?;
    crate::permissions::engine::require_permission(
        auth,
        PermissionAction::ViewResults,
        ResourceType::Submission,
        &crate::permissions::engine::ResourceAttrs {
            organization_id: Some(form.organization_id),
            owner_id: Some(form.creator_id),
            ..Default::default()
        },
    )?;
    let rows = sqlx::query("select id, form_id, respondent_user_id, access_code_id, respondent_mode, respondent_label, anonymous, valid, total_score, max_score, percentage_score, score_category, submitted_at from form_submissions where form_id=$1 and deleted_at is null order by submitted_at desc limit $2 offset $3")
        .bind(form_id).bind(q.limit()).bind(q.offset()).fetch_all(&state.db).await?;
    let total: i64 = sqlx::query_scalar(
        "select count(*) from form_submissions where form_id=$1 and deleted_at is null",
    )
    .bind(form_id)
    .fetch_one(&state.db)
    .await
    .unwrap_or(0);
    let mut items = vec![];
    for row in rows {
        items.push(row_to_submission_summary(&row)?);
    }
    Ok((items, PaginationMeta::new(q.page, q.limit(), total)))
}

pub async fn load_submission(state: &AppState, id: Uuid) -> Result<SubmissionDetailDto, AppError> {
    let row = sqlx::query("select id, form_id, respondent_user_id, guest_token_id, access_code_id, respondent_mode, respondent_label, anonymous, valid, total_score, max_score, percentage_score, score_category, submitted_at, updated_at from form_submissions where id=$1 and deleted_at is null")
        .bind(id).fetch_one(&state.db).await?;
    let answers = load_answers(state, id).await?;
    Ok(row_to_submission_detail(&row, answers)?)
}

pub async fn get_submission(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
) -> Result<SubmissionDetailDto, AppError> {
    let detail = load_submission(state, id).await?;
    let form = form_service::load_form_detail(state, detail.form_id).await?;
    if detail.respondent_user_id == Some(auth.user_id)
        || matches!(
            auth.role,
            UserRole::Manager | UserRole::Admin | UserRole::Ceo | UserRole::SuperAdmin
        )
        || form.creator_id == auth.user_id
    {
        Ok(detail)
    } else {
        Err(AppError::forbidden("You cannot view this submission"))
    }
}

pub async fn update_submission(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
    request: UpdateSubmissionRequest,
) -> Result<SubmissionDetailDto, AppError> {
    let current = load_submission(state, id).await?;
    let form = form_service::load_form_detail(state, current.form_id).await?;
    if !form.settings.answers_editable_after_submission
        && !matches!(
            auth.role,
            UserRole::Admin | UserRole::Manager | UserRole::Ceo | UserRole::SuperAdmin
        )
    {
        return Err(AppError::forbidden(
            "Answers cannot be edited after submission",
        ));
    }
    if current.respondent_user_id != Some(auth.user_id)
        && !matches!(
            auth.role,
            UserRole::Admin | UserRole::Manager | UserRole::Ceo | UserRole::SuperAdmin
        )
    {
        return Err(AppError::forbidden("You cannot update this submission"));
    }
    validate_answers(&form.fields, &request.answers)?;
    let score_result = scoring_engine::calculate_submission_score(
        &form.fields,
        &request.answers,
        form.scoring_mode,
    );
    let mut tx = state.db.begin().await?;
    sqlx::query("delete from form_answers where submission_id=$1")
        .bind(id)
        .execute(&mut *tx)
        .await?;
    for ans in request.answers {
        sqlx::query("insert into form_answers (submission_id, field_id, value, metadata) values ($1,$2,$3,$4)").bind(id).bind(ans.field_id).bind(ans.value).bind(ans.metadata).execute(&mut *tx).await?;
    }
    sqlx::query("update form_submissions set total_score=$2, max_score=$3, percentage_score=$4, score_category=$5, updated_at=now() where id=$1")
        .bind(id).bind(score_result.total_score).bind(score_result.max_score).bind(score_result.percentage_score).bind(score_result.category.as_ref().map(|c| c.label.clone())).execute(&mut *tx).await?;
    sqlx::query("insert into score_breakdowns (submission_id, result) values ($1,$2) on conflict (submission_id) do update set result=excluded.result, created_at=now()").bind(id).bind(json!(score_result)).execute(&mut *tx).await?;
    tx.commit().await?;
    load_submission(state, id).await
}

pub async fn delete_submission(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
) -> Result<(), AppError> {
    let detail = load_submission(state, id).await?;
    if detail.respondent_user_id != Some(auth.user_id)
        && !matches!(
            auth.role,
            UserRole::Admin | UserRole::Manager | UserRole::Ceo | UserRole::SuperAdmin
        )
    {
        return Err(AppError::forbidden("You cannot delete this submission"));
    }
    sqlx::query("update form_submissions set deleted_at=now(), updated_at=now() where id=$1")
        .bind(id)
        .execute(&state.db)
        .await?;
    Ok(())
}

pub async fn score_breakdown(
    state: &AppState,
    auth: &AuthUser,
    id: Uuid,
) -> Result<ScoreBreakdownDto, AppError> {
    let _ = get_submission(state, auth, id).await?;
    let result: Value =
        sqlx::query_scalar("select result from score_breakdowns where submission_id=$1")
            .bind(id)
            .fetch_one(&state.db)
            .await?;
    Ok(ScoreBreakdownDto {
        submission_id: id,
        result: serde_json::from_value(result).map_err(|e| {
            AppError::validation("Invalid score breakdown", json!({"error": e.to_string()}))
        })?,
    })
}

fn validate_answers(
    fields: &[crate::api_types::fields::FormFieldDto],
    answers: &[crate::api_types::submissions::AnswerInputDto],
) -> Result<(), AppError> {
    for field in fields.iter().filter(|f| f.required) {
        if !answers
            .iter()
            .any(|a| a.field_id == field.id && !a.value.is_null())
        {
            return Err(AppError::validation(
                "Required field is missing",
                json!({"field_id": field.id, "label": field.label}),
            ));
        }
    }
    for answer in answers {
        let Some(field) = fields.iter().find(|f| f.id == answer.field_id) else {
            return Err(AppError::validation(
                "Answer references unknown field",
                json!({"field_id": answer.field_id}),
            ));
        };
        if matches!(
            field.field_type,
            FieldType::SectionTitle
                | FieldType::DescriptionBlock
                | FieldType::Divider
                | FieldType::PageBreak
                | FieldType::ScoreDisplay
        ) {
            continue;
        }
        if let Some(max_len) = field.validation.max_length {
            if answer
                .value
                .as_str()
                .map(|s| s.len() as i64 > max_len)
                .unwrap_or(false)
            {
                return Err(AppError::validation(
                    "Text answer is too long",
                    json!({"field_id": field.id, "max_length": max_len}),
                ));
            }
        }
    }
    Ok(())
}

async fn load_answers(state: &AppState, submission_id: Uuid) -> Result<Vec<AnswerDto>, AppError> {
    let rows = sqlx::query("select id, submission_id, field_id, value, metadata, created_at from form_answers where submission_id=$1 order by created_at asc").bind(submission_id).fetch_all(&state.db).await?;
    rows.iter().map(row_to_answer).collect()
}

fn row_to_answer(row: &sqlx::postgres::PgRow) -> Result<AnswerDto, AppError> {
    Ok(AnswerDto {
        id: row.try_get("id")?,
        submission_id: row.try_get("submission_id")?,
        field_id: row.try_get("field_id")?,
        value: row.try_get("value")?,
        metadata: row.try_get("metadata").unwrap_or_else(|_| json!({})),
        created_at: row.try_get("created_at")?,
    })
}

fn row_to_submission_summary(
    row: &sqlx::postgres::PgRow,
) -> Result<SubmissionSummaryDto, AppError> {
    Ok(SubmissionSummaryDto {
        id: row.try_get("id")?,
        form_id: row.try_get("form_id")?,
        respondent_user_id: row.try_get("respondent_user_id")?,
        access_code_id: row.try_get("access_code_id")?,
        respondent_mode: row
            .try_get("respondent_mode")
            .unwrap_or_else(|_| "authenticated".to_owned()),
        respondent_label: row.try_get("respondent_label")?,
        anonymous: row.try_get("anonymous")?,
        valid: row.try_get("valid")?,
        submitted_at: row.try_get("submitted_at")?,
        score: SubmissionScoreDto {
            total_score: row.try_get("total_score")?,
            max_score: row.try_get("max_score")?,
            percentage_score: row.try_get("percentage_score")?,
            category_label: row.try_get("score_category")?,
        },
    })
}

fn row_to_submission_detail(
    row: &sqlx::postgres::PgRow,
    answers: Vec<AnswerDto>,
) -> Result<SubmissionDetailDto, AppError> {
    Ok(SubmissionDetailDto {
        id: row.try_get("id")?,
        form_id: row.try_get("form_id")?,
        respondent_user_id: row.try_get("respondent_user_id")?,
        guest_token_id: row.try_get("guest_token_id")?,
        access_code_id: row.try_get("access_code_id")?,
        respondent_mode: row
            .try_get("respondent_mode")
            .unwrap_or_else(|_| "authenticated".to_owned()),
        respondent_label: row.try_get("respondent_label")?,
        anonymous: row.try_get("anonymous")?,
        valid: row.try_get("valid")?,
        answers,
        score: SubmissionScoreDto {
            total_score: row.try_get("total_score")?,
            max_score: row.try_get("max_score")?,
            percentage_score: row.try_get("percentage_score")?,
            category_label: row.try_get("score_category")?,
        },
        submitted_at: row.try_get("submitted_at")?,
        updated_at: row.try_get("updated_at")?,
    })
}
