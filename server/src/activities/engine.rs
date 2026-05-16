use crate::{
    api_types::{
        activities::ActivityRuleDto,
        enums::{
            enum_from_str, enum_to_string, ActivityActionType, ActivityStatus, ActivityTriggerType,
        },
        forms::FormDetailDto,
        scoring::ScoreResultDto,
        submissions::AnswerDto,
    },
    app_state::AppState,
    error::AppError,
};
use serde_json::{json, Value};
use sqlx::Row;
use uuid::Uuid;

pub async fn run_activity_rules(
    state: &AppState,
    form: &FormDetailDto,
    submission_id: Uuid,
    score: &ScoreResultDto,
    answers: &[AnswerDto],
) -> Result<(), AppError> {
    let rows = sqlx::query("select id, form_id, trigger_type, condition, action_type, action_config, enabled, created_at, updated_at from activity_rules where form_id=$1 and enabled=true and deleted_at is null")
        .bind(form.id).fetch_all(&state.db).await?;
    for row in rows {
        let rule = row_to_activity_rule(&row)?;
        if condition_matches(&rule, score, answers) {
            create_activity_from_rule(state, form, submission_id, &rule).await?;
        }
    }
    Ok(())
}

fn condition_matches(
    rule: &ActivityRuleDto,
    score: &ScoreResultDto,
    answers: &[AnswerDto],
) -> bool {
    match rule.trigger_type {
        ActivityTriggerType::SubmissionCreated => true,
        ActivityTriggerType::ScoreBelow => rule
            .condition
            .get("threshold")
            .and_then(Value::as_f64)
            .map(|t| score.total_score < t)
            .unwrap_or(false),
        ActivityTriggerType::ScoreAbove => rule
            .condition
            .get("threshold")
            .and_then(Value::as_f64)
            .map(|t| score.total_score > t)
            .unwrap_or(false),
        ActivityTriggerType::NpsLow => answers.iter().any(|a| {
            a.value
                .as_i64()
                .map(|v| {
                    v <= rule
                        .condition
                        .get("max")
                        .and_then(Value::as_i64)
                        .unwrap_or(6)
                })
                .unwrap_or(false)
        }),
        ActivityTriggerType::NpsHigh => answers.iter().any(|a| {
            a.value
                .as_i64()
                .map(|v| {
                    v >= rule
                        .condition
                        .get("min")
                        .and_then(Value::as_i64)
                        .unwrap_or(9)
                })
                .unwrap_or(false)
        }),
        ActivityTriggerType::AnswerEquals => {
            let field_id = rule
                .condition
                .get("field_id")
                .and_then(Value::as_str)
                .and_then(|s| Uuid::parse_str(s).ok());
            let value = rule.condition.get("value");
            field_id
                .zip(value)
                .map(|(fid, expected)| {
                    answers
                        .iter()
                        .any(|a| a.field_id == fid && &a.value == expected)
                })
                .unwrap_or(false)
        }
        ActivityTriggerType::AnswerContains => {
            let field_id = rule
                .condition
                .get("field_id")
                .and_then(Value::as_str)
                .and_then(|s| Uuid::parse_str(s).ok());
            let value = rule.condition.get("value");
            field_id
                .zip(value)
                .map(|(fid, expected)| {
                    answers.iter().any(|a| {
                        a.field_id == fid
                            && a.value
                                .as_array()
                                .map(|arr| arr.contains(expected))
                                .unwrap_or(false)
                    })
                })
                .unwrap_or(false)
        }
        ActivityTriggerType::SubmissionCountReached | ActivityTriggerType::FormClosed => false,
    }
}

async fn create_activity_from_rule(
    state: &AppState,
    form: &FormDetailDto,
    submission_id: Uuid,
    rule: &ActivityRuleDto,
) -> Result<(), AppError> {
    if !matches!(
        rule.action_type,
        ActivityActionType::CreateActivity
            | ActivityActionType::AssignFollowUp
            | ActivityActionType::NotifyManager
            | ActivityActionType::NotifyUser
            | ActivityActionType::MarkSubmission
    ) {
        return Ok(());
    }
    let title = rule
        .action_config
        .get("title")
        .and_then(Value::as_str)
        .unwrap_or("Feedback follow-up");
    let description = rule
        .action_config
        .get("description")
        .and_then(Value::as_str)
        .map(ToOwned::to_owned);
    let assigned_to = rule
        .action_config
        .get("assigned_to_user_id")
        .and_then(Value::as_str)
        .and_then(|s| Uuid::parse_str(s).ok());
    sqlx::query("insert into activities (organization_id, form_id, submission_id, assigned_to_user_id, title, description, status, metadata) values ($1,$2,$3,$4,$5,$6,$7,$8)")
        .bind(form.organization_id).bind(form.id).bind(submission_id).bind(assigned_to).bind(title).bind(description).bind(enum_to_string(&ActivityStatus::Open)).bind(json!({"rule_id": rule.id, "action_type": rule.action_type})).execute(&state.db).await?;
    Ok(())
}

pub fn row_to_activity_rule(row: &sqlx::postgres::PgRow) -> Result<ActivityRuleDto, AppError> {
    Ok(ActivityRuleDto {
        id: row.try_get("id")?,
        form_id: row.try_get("form_id")?,
        trigger_type: enum_from_str(&row.try_get::<String, _>("trigger_type")?)
            .unwrap_or(ActivityTriggerType::SubmissionCreated),
        condition: row.try_get("condition")?,
        action_type: enum_from_str(&row.try_get::<String, _>("action_type")?)
            .unwrap_or(ActivityActionType::CreateActivity),
        action_config: row.try_get("action_config")?,
        enabled: row.try_get("enabled")?,
        created_at: row.try_get("created_at")?,
        updated_at: row.try_get("updated_at")?,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api_types::{
        activities::ActivityRuleDto,
        enums::{ActivityActionType, ActivityTriggerType},
    };
    use chrono::Utc;

    #[test]
    fn score_below_condition_matches() {
        let rule = ActivityRuleDto {
            id: Uuid::new_v4(),
            form_id: Uuid::new_v4(),
            trigger_type: ActivityTriggerType::ScoreBelow,
            condition: json!({"threshold": 50}),
            action_type: ActivityActionType::CreateActivity,
            action_config: json!({}),
            enabled: true,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };
        let result = ScoreResultDto {
            total_score: 40.0,
            max_score: 100.0,
            percentage_score: 40.0,
            category: None,
            field_breakdowns: vec![],
            metadata: Default::default(),
        };
        assert!(condition_matches(&rule, &result, &[]));
    }
}
