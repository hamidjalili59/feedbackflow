use crate::{
    api_types::{
        analytics::AnalyticsBucketDto,
        dashboard::*,
        enums::{enum_from_str, FormStatus, UserRole},
        forms::FormVisibilityDto,
        metrics::{MetricAggregationMethod, MetricDefinitionDto, MetricMappingSourceType, MetricPositiveDirection},
    },
    app_state::AppState,
    audience::service as audience_service,
    auth::AuthUser,
    error::AppError,
    forms::visibility,
    metrics::service as metric_service,
};
use chrono::{DateTime, Datelike, Duration, NaiveDate, TimeZone, Utc};
use serde_json::{json, Value};
use sqlx::Row;
use std::collections::BTreeMap;
use uuid::Uuid;

pub async fn dashboard_me(
    state: &AppState,
    auth: &AuthUser,
    q: DashboardQuery,
) -> Result<DashboardResponseDto, AppError> {
    let period = q.period.unwrap_or_else(|| "this_month".to_owned());
    let children = if auth.role == UserRole::Parent {
        children_for_parent(state, auth).await?
    } else {
        vec![]
    };
    let selected_child_id = q.child_id.or_else(|| children.first().map(|child| child.id));
    let latest_surveys = my_surveys(
        state,
        auth,
        MySurveysQuery {
            status: None,
            period: Some(period.clone()),
            child_id: selected_child_id,
            limit: 8,
        },
    )
    .await?;
    let survey_summary = summarize_surveys(&latest_surveys);
    let metrics = dashboard_metrics(state, auth, &period).await?;
    let charts = vec![timeseries(
        state,
        auth,
        TimeseriesQuery {
            metric: Some("participation".to_owned()),
            period: Some(period.clone()),
            compare: q.compare,
            granularity: Some("month".to_owned()),
            scope: q.scope,
            scope_id: q.scope_id,
        },
    )
    .await?];
    let activities = activity_feed(state, auth, 10).await?;
    let rankings = if matches!(
        auth.role,
        UserRole::Manager | UserRole::Admin | UserRole::Ceo | UserRole::SuperAdmin
    ) {
        vec![rankings(
            state,
            auth,
            RankingQuery {
                metric: Some("satisfaction".to_owned()),
                dimension: Some("teacher".to_owned()),
                period: Some(period.clone()),
                order: Some("best".to_owned()),
                limit: 5,
            },
        )
        .await?]
    } else {
        vec![]
    };
    let distributions = role_distribution(state, auth).await.unwrap_or_default();
    Ok(DashboardResponseDto {
        role: auth.role,
        period,
        children,
        selected_child_id,
        survey_summary,
        latest_surveys,
        metrics,
        charts,
        activities,
        rankings,
        distributions,
        metadata: json!({
            "dynamic_metrics": true,
            "targeted_assignments": true,
            "audience_segments": true
        }),
    })
}

pub async fn children_for_parent(
    state: &AppState,
    auth: &AuthUser,
) -> Result<Vec<ChildProfileDto>, AppError> {
    let org_id = auth
        .organization_id
        .ok_or_else(|| AppError::forbidden("Children require an organization"))?;
    let rows = sqlx::query(
        "select u.id, u.display_name, u.profile, \
                g.id class_id, g.name class_name, \
                null::uuid branch_id, null::text branch_name \
         from user_relationships ur \
         join users u on u.id=ur.child_user_id and u.deleted_at is null \
         left join lateral ( \
           select g.id, g.name from group_members gm join groups g on g.id=gm.group_id \
           where gm.user_id=u.id and g.group_type='class' and g.deleted_at is null \
           order by gm.created_at desc limit 1 \
         ) g on true \
         where ur.organization_id=$1 and ur.parent_user_id=$2 \
         order by u.display_name asc",
    )
    .bind(org_id)
    .bind(auth.user_id)
    .fetch_all(&state.db)
    .await?;
    rows.iter()
        .map(|row| {
            let profile: Value = row.try_get("profile").unwrap_or_else(|_| json!({}));
            Ok(ChildProfileDto {
                id: row.try_get("id")?,
                display_name: row.try_get("display_name")?,
                avatar_url: profile
                    .get("avatar_url")
                    .and_then(|v| v.as_str())
                    .map(str::to_owned),
                grade_label: profile
                    .get("metadata")
                    .and_then(|m| m.get("grade_label").or_else(|| m.get("grade")))
                    .and_then(|v| v.as_str())
                    .map(str::to_owned),
                class_id: row.try_get("class_id")?,
                class_name: row.try_get("class_name")?,
                branch_id: row.try_get("branch_id")?,
                branch_name: row.try_get("branch_name")?,
                metadata: profile.get("metadata").cloned().unwrap_or_else(|| json!({})),
            })
        })
        .collect()
}

pub async fn my_surveys(
    state: &AppState,
    auth: &AuthUser,
    q: MySurveysQuery,
) -> Result<Vec<SurveyCardDto>, AppError> {
    let org_id = auth
        .organization_id
        .ok_or_else(|| AppError::forbidden("Surveys require an organization"))?;
    let limit = q.limit.clamp(1, 200);
    let period_bounds = q.period.as_deref().map(period_range);
    let rows = sqlx::query(
        "select f.id, f.creator_id, f.organization_id, f.title, f.description, f.category, f.tags, f.status, f.visibility, \
                f.scheduled_at, f.published_at, f.closed_at, f.settings, \
                (select count(*) from form_fields ff where ff.form_id=f.id and ff.deleted_at is null and ff.field_type not in ('section_title','description_block','divider','page_break','hidden','calculated','score_display','conditional_logic')) question_count, \
                (select s.id from form_submissions s where s.form_id=f.id and s.respondent_user_id=$2 and s.deleted_at is null order by s.submitted_at desc limit 1) my_submission_id \
         from forms f \
         where f.organization_id=$1 and f.deleted_at is null and f.status in ('published','scheduled','closed') \
         order by coalesce(f.published_at, f.scheduled_at, f.updated_at) desc limit 250",
    )
    .bind(org_id)
    .bind(auth.user_id)
    .fetch_all(&state.db)
    .await?;
    let mut out = Vec::new();
    for row in rows {
        let form_id: Uuid = row.try_get("id")?;
        let creator_id: Uuid = row.try_get("creator_id")?;
        let form_org_id: Uuid = row.try_get("organization_id")?;
        let status: FormStatus = enum_from_str(&row.try_get::<String, _>("status")?)
            .unwrap_or(FormStatus::Draft);
        let vis_value: Value = row.try_get("visibility").unwrap_or_else(|_| json!({}));
        let visibility_dto: FormVisibilityDto = serde_json::from_value(vis_value).unwrap_or_default();
        let visible_by_json = visibility::can_see_form(
            status,
            creator_id,
            form_org_id,
            &visibility_dto,
            Some(auth),
        );
        let visible_by_assignment = audience_service::user_matches_form_assignment(
            state,
            form_id,
            auth,
            false,
        )
        .await
        .unwrap_or(false);
        if !visible_by_json && !visible_by_assignment {
            continue;
        }
        let my_submission_id: Option<Uuid> = row.try_get("my_submission_id")?;
        let scheduled_at: Option<DateTime<Utc>> = row.try_get("scheduled_at")?;
        let published_at: Option<DateTime<Utc>> = row.try_get("published_at")?;
        let closed_at: Option<DateTime<Utc>> = row.try_get("closed_at")?;
        if let Some((start, end)) = &period_bounds {
            let Some(dt) = published_at.as_ref().or(scheduled_at.as_ref()).or(closed_at.as_ref()) else {
                continue;
            };
            if dt < start || dt >= end {
                continue;
            }
        }
        let survey_status = survey_status(status, my_submission_id, scheduled_at.clone());
        if let Some(filter) = q.status.as_deref() {
            if filter != survey_status {
                continue;
            }
        }
        let settings: Value = row.try_get("settings").unwrap_or_else(|_| json!({}));
        let labels = audience_service::assignment_labels_for_user(state, form_id, auth)
            .await
            .unwrap_or_default();
        out.push(SurveyCardDto {
            form_id,
            title: row.try_get("title")?,
            description: row.try_get("description")?,
            category: row.try_get("category").ok(),
            tags: row.try_get("tags").unwrap_or_default(),
            status: survey_status.to_owned(),
            my_submission_id,
            progress: if my_submission_id.is_some() { 100.0 } else { 0.0 },
            question_count: row.try_get("question_count").unwrap_or(0),
            estimated_minutes: settings
                .get("metadata")
                .and_then(|m| m.get("estimated_minutes"))
                .and_then(|v| v.as_i64()),
            cta: if my_submission_id.is_some() { "view" } else { "start" }.to_owned(),
            date_label: date_label(published_at.clone().or(scheduled_at.clone())),
            scheduled_at,
            published_at,
            closed_at,
            assigned_reason: if labels.is_empty() { None } else { Some(labels.join(", ")) },
            metadata: settings.get("metadata").cloned().unwrap_or_else(|| json!({})),
        });
        if out.len() >= limit as usize {
            break;
        }
    }
    Ok(out)
}

pub async fn survey_calendar(
    state: &AppState,
    auth: &AuthUser,
    q: CalendarQuery,
) -> Result<CalendarResponseDto, AppError> {
    let period = q.period.unwrap_or_else(|| "this_month".to_owned());
    let (default_start, default_end) = period_range(&period);
    let start_date = q
        .start_date
        .as_deref()
        .and_then(|value| NaiveDate::parse_from_str(value, "%Y-%m-%d").ok())
        .unwrap_or_else(|| default_start.date_naive());
    let end_date_exclusive = q
        .end_date
        .as_deref()
        .and_then(|value| NaiveDate::parse_from_str(value, "%Y-%m-%d").ok())
        .map(|date| date + Duration::days(1))
        .unwrap_or_else(|| default_end.date_naive());

    let surveys = my_surveys(
        state,
        auth,
        MySurveysQuery {
            status: None,
            period: Some(period.clone()),
            child_id: None,
            limit: 500,
        },
    )
    .await?;

    let mut by_date: BTreeMap<String, Vec<SurveyCardDto>> = BTreeMap::new();
    for survey in surveys {
        let Some(dt) = survey.scheduled_at.as_ref().or(survey.published_at.as_ref()).or(survey.closed_at.as_ref()) else {
            continue;
        };
        let day = dt.date_naive();
        if day < start_date || day >= end_date_exclusive {
            continue;
        }
        by_date.entry(day.format("%Y-%m-%d").to_string()).or_default().push(survey);
    }

    let mut days = Vec::new();
    let today = Utc::now().date_naive();
    let max_days = 370_i64;
    let mut cursor = start_date;
    let mut emitted = 0_i64;
    while cursor < end_date_exclusive && emitted < max_days {
        let date = cursor.format("%Y-%m-%d").to_string();
        let surveys_for_day = by_date.remove(&date).unwrap_or_default();
        let count = surveys_for_day.len() as i64;
        let completed = surveys_for_day.iter().any(|survey| survey.status == "completed");
        let pending = surveys_for_day.iter().any(|survey| survey.status == "new" || survey.status == "pending" || survey.status == "in_progress");
        let status = if count == 0 {
            "empty"
        } else if completed && !pending {
            "completed"
        } else if pending {
            "pending"
        } else {
            "closed"
        };
        days.push(CalendarDayDto {
            label: cursor.day().to_string(),
            weekday: Some(persian_weekday(cursor.weekday().number_from_monday())),
            status: status.to_owned(),
            count,
            highlight: cursor == today || count > 0,
            date,
            surveys: surveys_for_day
                .into_iter()
                .map(|survey| CalendarSurveyDto {
                    form_id: survey.form_id,
                    title: survey.title,
                    status: survey.status,
                    date_label: survey.date_label,
                })
                .collect(),
        });
        cursor = cursor + Duration::days(1);
        emitted += 1;
    }

    Ok(CalendarResponseDto { period, days })
}

pub async fn timeseries(
    state: &AppState,
    auth: &AuthUser,
    q: TimeseriesQuery,
) -> Result<TimeseriesResponseDto, AppError> {
    let org_id = auth
        .organization_id
        .ok_or_else(|| AppError::forbidden("Analytics require an organization"))?;
    let metric = q.metric.unwrap_or_else(|| "participation".to_owned());
    let period = q.period.unwrap_or_else(|| "this_month".to_owned());
    let granularity = q.granularity.unwrap_or_else(|| "day".to_owned());
    let (start, end) = period_range(&period);
    let points = if metric == "participation" || metric == "submissions" {
        submission_timeseries(state, org_id, start, end, &granularity).await?
    } else {
        metric_timeseries(state, org_id, &metric, start, end, &granularity).await?
    };
    Ok(TimeseriesResponseDto {
        metric,
        period,
        granularity,
        series: vec![TimeseriesSeriesDto {
            key: "current".to_owned(),
            label: "Current".to_owned(),
            points,
        }],
    })
}

pub async fn rankings(
    state: &AppState,
    auth: &AuthUser,
    q: RankingQuery,
) -> Result<RankingResponseDto, AppError> {
    if !matches!(
        auth.role,
        UserRole::Manager | UserRole::Admin | UserRole::Ceo | UserRole::SuperAdmin
    ) {
        return Err(AppError::forbidden("Rankings require a management role"));
    }
    let org_id = auth
        .organization_id
        .ok_or_else(|| AppError::forbidden("Rankings require an organization"))?;
    let metric = q.metric.unwrap_or_else(|| "satisfaction".to_owned());
    let dimension = q.dimension.unwrap_or_else(|| "teacher".to_owned());
    let period = q.period.unwrap_or_else(|| "this_month".to_owned());
    let order = q.order.unwrap_or_else(|| "best".to_owned());
    let (start, end) = period_range(&period);
    let direction = if order == "worst" { "asc" } else { "desc" };
    let limit = q.limit.clamp(1, 50);
    let rows = if dimension == "teacher" {
        let sql = format!(
            "select u.id entity_id, u.display_name title, coalesce(u.profile->>'avatar_url','') avatar_url, \
                    coalesce(avg(s.percentage_score),0) score, count(s.id) count \
             from users u \
             left join forms f on f.creator_id=u.id and f.deleted_at is null \
             left join form_submissions s on s.form_id=f.id and s.deleted_at is null and s.submitted_at >= $2 and s.submitted_at < $3 \
             where u.organization_id=$1 and u.primary_role='teacher' and u.deleted_at is null \
             group by u.id, u.display_name, u.profile order by score {direction}, count desc, title asc limit $4"
        );
        sqlx::query(&sql)
            .bind(org_id)
            .bind(start)
            .bind(end)
            .bind(limit)
            .fetch_all(&state.db)
            .await?
    } else {
        let sql = format!(
            "select g.id entity_id, g.name title, '' avatar_url, coalesce(avg(s.percentage_score),0) score, count(s.id) count \
             from groups g \
             left join group_members gm on gm.group_id=g.id \
             left join form_submissions s on s.respondent_user_id=gm.user_id and s.deleted_at is null and s.submitted_at >= $2 and s.submitted_at < $3 \
             where g.organization_id=$1 and g.deleted_at is null and ($5='' or g.group_type=$5) \
             group by g.id, g.name order by score {direction}, count desc, title asc limit $4"
        );
        let group_type = match dimension.as_str() {
            "class" => "class",
            "department" => "department",
            _ => "",
        };
        sqlx::query(&sql)
            .bind(org_id)
            .bind(start)
            .bind(end)
            .bind(limit)
            .bind(group_type)
            .fetch_all(&state.db)
            .await?
    };
    let items = rows
        .iter()
        .enumerate()
        .map(|(idx, row)| {
            let avatar: String = row.try_get("avatar_url").unwrap_or_default();
            Ok(RankingItemDto {
                rank: (idx + 1) as i64,
                entity_id: row.try_get("entity_id")?,
                entity_type: dimension.clone(),
                title: row.try_get("title")?,
                subtitle: Some(format!("{} submissions", row.try_get::<i64, _>("count").unwrap_or(0))),
                score: row.try_get::<f64, _>("score").unwrap_or(0.0),
                trend: None,
                avatar_url: if avatar.is_empty() { None } else { Some(avatar) },
                metadata: json!({}),
            })
        })
        .collect::<Result<Vec<_>, AppError>>()?;
    Ok(RankingResponseDto {
        metric,
        dimension,
        period,
        items,
    })
}

pub async fn alerts(
    state: &AppState,
    auth: &AuthUser,
    q: AlertQuery,
) -> Result<AnalyticsAlertsResponseDto, AppError> {
    if !matches!(
        auth.role,
        UserRole::Manager | UserRole::Admin | UserRole::Ceo | UserRole::SuperAdmin
    ) {
        return Err(AppError::forbidden("Alerts require a management role"));
    }
    let period = q.period.unwrap_or_else(|| "this_month".to_owned());
    let metrics = dashboard_metrics(state, auth, &period).await?;
    let mut items = Vec::new();
    for metric in metrics {
        if let Some(value) = metric.value {
            let bad = match metric.status.as_deref() {
                Some("danger") | Some("warning") => true,
                _ => value < 50.0,
            };
            if bad {
                items.push(AnalyticsAlertDto {
                    id: format!("metric:{}", metric.key),
                    severity: metric.status.clone().unwrap_or_else(|| "warning".to_owned()),
                    title: format!("{} needs attention", metric.title),
                    description: Some(format!("Current value is {:.1}", value)),
                    entity_id: Some(metric.metric_id),
                    entity_type: Some("metric".to_owned()),
                    metric_key: Some(metric.key),
                    value: Some(value),
                    threshold: Some(50.0),
                    metadata: metric.display,
                });
            }
        }
        if items.len() >= q.limit.clamp(1, 50) as usize {
            break;
        }
    }
    Ok(AnalyticsAlertsResponseDto { period, items })
}

async fn dashboard_metrics(
    state: &AppState,
    auth: &AuthUser,
    period: &str,
) -> Result<Vec<DashboardMetricValueDto>, AppError> {
    let org_id = auth
        .organization_id
        .ok_or_else(|| AppError::forbidden("Metrics require an organization"))?;
    let metrics = metric_service::load_active_metrics_for_org(state, org_id).await?;
    let (start, end) = period_range(period);
    let mut out = Vec::new();
    for metric in metrics {
        let value = compute_metric_value(state, org_id, &metric, start, end).await?;
        let (label, status) = metric_label_status(&metric, value);
        out.push(DashboardMetricValueDto {
            metric_id: metric.id,
            key: metric.key,
            title: metric.title,
            value,
            label,
            unit: metric.display.get("unit").and_then(|v| v.as_str()).map(str::to_owned),
            scale_min: metric.scale_min,
            scale_max: metric.scale_max,
            status,
            trend: None,
            display: metric.display,
        });
    }
    Ok(out)
}

async fn compute_metric_value(
    state: &AppState,
    org_id: Uuid,
    metric: &MetricDefinitionDto,
    start: DateTime<Utc>,
    end: DateTime<Utc>,
) -> Result<Option<f64>, AppError> {
    let mappings = metric_service::load_mappings(state, org_id, metric.id).await?;
    let mut values = Vec::new();
    for mapping in mappings.into_iter().filter(|m| m.enabled) {
        match mapping.source_type {
            MetricMappingSourceType::FieldAnswer => {
                if let Some(field_id) = mapping.field_id {
                    let rows = sqlx::query(
                        "select a.value from form_answers a \
                         join form_submissions s on s.id=a.submission_id \
                         join forms f on f.id=s.form_id \
                         where a.field_id=$1 and s.deleted_at is null and f.organization_id=$2 \
                           and s.submitted_at >= $3 and s.submitted_at < $4",
                    )
                    .bind(field_id)
                    .bind(org_id)
                    .bind(start)
                    .bind(end)
                    .fetch_all(&state.db)
                    .await?;
                    for row in rows {
                        let value: Value = row.try_get("value")?;
                        if let Some(n) = json_to_f64(&value) {
                            values.push(n * mapping.weight);
                        }
                    }
                }
            }
            MetricMappingSourceType::SubmissionScore | MetricMappingSourceType::SubmissionPercentage => {
                let column = if mapping.source_type == MetricMappingSourceType::SubmissionScore {
                    "total_score"
                } else {
                    "percentage_score"
                };
                let form_clause = if mapping.form_id.is_some() { "and f.id=$4" } else { "" };
                let sql = format!(
                    "select s.{column} value from form_submissions s join forms f on f.id=s.form_id \
                     where s.deleted_at is null and f.organization_id=$1 and s.submitted_at >= $2 and s.submitted_at < $3 {form_clause}"
                );
                let mut query = sqlx::query(&sql)
                    .bind(org_id)
                    .bind(start)
                    .bind(end);
                if let Some(form_id) = mapping.form_id {
                    query = query.bind(form_id);
                }
                let rows = query.fetch_all(&state.db).await?;
                for row in rows {
                    let n: f64 = row.try_get("value").unwrap_or(0.0);
                    values.push(n * mapping.weight);
                }
            }
            MetricMappingSourceType::SubmissionCount => {
                let form_clause = if mapping.form_id.is_some() { "and f.id=$4" } else { "" };
                let sql = format!(
                    "select count(*)::double precision value from form_submissions s join forms f on f.id=s.form_id \
                     where s.deleted_at is null and f.organization_id=$1 and s.submitted_at >= $2 and s.submitted_at < $3 {form_clause}"
                );
                let mut query = sqlx::query(&sql).bind(org_id).bind(start).bind(end);
                if let Some(form_id) = mapping.form_id {
                    query = query.bind(form_id);
                }
                let row = query.fetch_one(&state.db).await?;
                let n: f64 = row.try_get("value").unwrap_or(0.0);
                values.push(n * mapping.weight);
            }
            MetricMappingSourceType::Custom => {}
        }
    }
    aggregate_values(&values, metric.aggregation_method.clone())
}

async fn metric_timeseries(
    state: &AppState,
    org_id: Uuid,
    metric_key: &str,
    start: DateTime<Utc>,
    end: DateTime<Utc>,
    granularity: &str,
) -> Result<Vec<TimeseriesPointDto>, AppError> {
    let metric_row = sqlx::query(
        "select m.*, (select count(*) from metric_mappings mp where mp.metric_id=m.id and mp.deleted_at is null) mapping_count \
         from metric_definitions m where m.organization_id=$1 and lower(m.key)=lower($2) and m.enabled=true and m.deleted_at is null",
    )
    .bind(org_id)
    .bind(metric_key)
    .fetch_optional(&state.db)
    .await?;
    let Some(row) = metric_row else {
        return Ok(vec![]);
    };
    let metric = crate::metrics::service::load_metric(state, org_id, row.try_get("id")?).await?;
    let mappings = metric_service::load_mappings(state, org_id, metric.id).await?;
    let bucket_expr = bucket_sql(granularity, "s.submitted_at");
    let mut points = BTreeMap::<String, Vec<f64>>::new();
    for mapping in mappings.into_iter().filter(|m| m.enabled) {
        if let Some(field_id) = mapping.field_id {
            let sql = format!(
                "select to_char({bucket_expr}, 'YYYY-MM-DD') bucket, a.value from form_answers a \
                 join form_submissions s on s.id=a.submission_id join forms f on f.id=s.form_id \
                 where a.field_id=$1 and s.deleted_at is null and f.organization_id=$2 and s.submitted_at >= $3 and s.submitted_at < $4 order by bucket asc"
            );
            let rows = sqlx::query(&sql)
                .bind(field_id)
                .bind(org_id)
                .bind(start)
                .bind(end)
                .fetch_all(&state.db)
                .await?;
            for row in rows {
                let bucket: String = row.try_get("bucket")?;
                let value: Value = row.try_get("value")?;
                if let Some(n) = json_to_f64(&value) {
                    points.entry(bucket).or_default().push(n * mapping.weight);
                }
            }
        }
    }
    Ok(points
        .into_iter()
        .map(|(date, values)| TimeseriesPointDto {
            label: date.clone(),
            date,
            value: aggregate_values(&values, metric.aggregation_method.clone())
                .unwrap_or(None)
                .unwrap_or(0.0),
        })
        .collect())
}

async fn submission_timeseries(
    state: &AppState,
    org_id: Uuid,
    start: DateTime<Utc>,
    end: DateTime<Utc>,
    granularity: &str,
) -> Result<Vec<TimeseriesPointDto>, AppError> {
    let bucket_expr = bucket_sql(granularity, "s.submitted_at");
    let rows = sqlx::query(&format!(
        "select to_char({bucket_expr}, 'YYYY-MM-DD') bucket, count(*)::double precision value \
         from form_submissions s join forms f on f.id=s.form_id \
         where s.deleted_at is null and f.organization_id=$1 and s.submitted_at >= $2 and s.submitted_at < $3 \
         group by 1 order by 1 asc"
    ))
    .bind(org_id)
    .bind(start)
    .bind(end)
    .fetch_all(&state.db)
    .await?;
    rows.iter()
        .map(|row| {
            let date: String = row.try_get("bucket")?;
            Ok(TimeseriesPointDto {
                label: date.clone(),
                date,
                value: row.try_get("value").unwrap_or(0.0),
            })
        })
        .collect()
}

async fn activity_feed(
    state: &AppState,
    auth: &AuthUser,
    limit: i64,
) -> Result<Vec<ActivityFeedItemDto>, AppError> {
    let org_id = auth
        .organization_id
        .ok_or_else(|| AppError::forbidden("Activities require an organization"))?;
    let rows = sqlx::query(
        "select id, title, description, status, metadata, created_at \
         from activities \
         where organization_id=$1 and deleted_at is null and (assigned_to_user_id is null or assigned_to_user_id=$2) \
         order by created_at desc limit $3",
    )
    .bind(org_id)
    .bind(auth.user_id)
    .bind(limit.clamp(1, 50))
    .fetch_all(&state.db)
    .await?;
    rows.iter()
        .map(|row| {
            let created_at: DateTime<Utc> = row.try_get("created_at")?;
            Ok(ActivityFeedItemDto {
                id: row.try_get("id")?,
                activity_type: "activity".to_owned(),
                title: row.try_get("title")?,
                subtitle: row.try_get("description")?,
                status: row.try_get("status")?,
                time_ago: Some(time_ago(created_at)),
                created_at,
                target_url: None,
                icon: None,
                metadata: row.try_get("metadata").unwrap_or_else(|_| json!({})),
            })
        })
        .collect()
}

async fn role_distribution(
    state: &AppState,
    auth: &AuthUser,
) -> Result<Vec<AnalyticsBucketDto>, AppError> {
    let org_id = auth
        .organization_id
        .ok_or_else(|| AppError::forbidden("Distribution requires an organization"))?;
    let rows = sqlx::query(
        "select primary_role key, count(*) count from users where organization_id=$1 and deleted_at is null group by 1 order by count desc",
    )
    .bind(org_id)
    .fetch_all(&state.db)
    .await?;
    let total: i64 = rows
        .iter()
        .map(|row| row.try_get::<i64, _>("count").unwrap_or(0))
        .sum();
    rows.iter()
        .map(|row| {
            let key: String = row.try_get("key")?;
            let count: i64 = row.try_get("count")?;
            Ok(AnalyticsBucketDto {
                label: key.clone(),
                key,
                count,
                percentage: if total > 0 {
                    (count as f64 / total as f64) * 100.0
                } else {
                    0.0
                },
            })
        })
        .collect()
}

fn summarize_surveys(surveys: &[SurveyCardDto]) -> SurveyStatusSummaryDto {
    SurveyStatusSummaryDto {
        completed: surveys.iter().filter(|s| s.status == "completed").count() as i64,
        in_progress: surveys.iter().filter(|s| s.status == "in_progress").count() as i64,
        pending: surveys.iter().filter(|s| s.status == "pending").count() as i64,
        new_items: surveys.iter().filter(|s| s.status == "new").count() as i64,
    }
}

fn survey_status(status: FormStatus, submission_id: Option<Uuid>, scheduled_at: Option<DateTime<Utc>>) -> &'static str {
    if submission_id.is_some() {
        "completed"
    } else if status == FormStatus::Scheduled || scheduled_at.map(|dt| dt > Utc::now()).unwrap_or(false) {
        "pending"
    } else if status == FormStatus::Closed {
        "closed"
    } else {
        "new"
    }
}

fn json_to_f64(value: &Value) -> Option<f64> {
    match value {
        Value::Number(n) => n.as_f64(),
        Value::String(s) => s.parse::<f64>().ok(),
        Value::Bool(b) => Some(if *b { 1.0 } else { 0.0 }),
        Value::Array(items) => {
            let nums: Vec<_> = items.iter().filter_map(json_to_f64).collect();
            if nums.is_empty() { None } else { Some(nums.iter().sum::<f64>() / nums.len() as f64) }
        }
        Value::Object(map) => ["score", "value", "rating", "percentage", "selected_score", "number"]
            .iter()
            .find_map(|key| map.get(*key).and_then(json_to_f64)),
        Value::Null => None,
    }
}

fn aggregate_values(values: &[f64], method: MetricAggregationMethod) -> Result<Option<f64>, AppError> {
    if values.is_empty() {
        return Ok(None);
    }
    let value = match method {
        MetricAggregationMethod::Avg => values.iter().sum::<f64>() / values.len() as f64,
        MetricAggregationMethod::Sum => values.iter().sum::<f64>(),
        MetricAggregationMethod::Count => values.len() as f64,
        MetricAggregationMethod::Min => values.iter().cloned().fold(f64::INFINITY, f64::min),
        MetricAggregationMethod::Max => values.iter().cloned().fold(f64::NEG_INFINITY, f64::max),
        MetricAggregationMethod::Latest => *values.last().unwrap_or(&0.0),
    };
    Ok(Some(value))
}

fn metric_label_status(metric: &MetricDefinitionDto, value: Option<f64>) -> (Option<String>, Option<String>) {
    let Some(value) = value else {
        return (None, None);
    };
    if let Value::Array(thresholds) = &metric.thresholds {
        for item in thresholds {
            let min_ok = item.get("min").and_then(|v| v.as_f64()).map(|min| value >= min).unwrap_or(true);
            let max_ok = item.get("max").and_then(|v| v.as_f64()).map(|max| value <= max).unwrap_or(true);
            if min_ok && max_ok {
                return (
                    item.get("label").and_then(|v| v.as_str()).map(str::to_owned),
                    item.get("status").and_then(|v| v.as_str()).map(str::to_owned),
                );
            }
        }
    }
    let status = match metric.positive_direction {
        MetricPositiveDirection::HigherIsBetter => {
            if value >= 80.0 { "success" } else if value >= 50.0 { "warning" } else { "danger" }
        }
        MetricPositiveDirection::LowerIsBetter => {
            if value <= 20.0 { "success" } else if value <= 50.0 { "warning" } else { "danger" }
        }
        MetricPositiveDirection::Neutral => "neutral",
    };
    (None, Some(status.to_owned()))
}

fn persian_weekday(number_from_monday: u32) -> String {
    match number_from_monday {
        1 => "دوشنبه",
        2 => "سه‌شنبه",
        3 => "چهارشنبه",
        4 => "پنجشنبه",
        5 => "جمعه",
        6 => "شنبه",
        7 => "یکشنبه",
        _ => "",
    }
    .to_owned()
}

fn period_range(period: &str) -> (DateTime<Utc>, DateTime<Utc>) {
    let now = Utc::now();
    let this_month_start = Utc.with_ymd_and_hms(now.year(), now.month(), 1, 0, 0, 0).unwrap();
    let this_month_end = if now.month() == 12 {
        Utc.with_ymd_and_hms(now.year() + 1, 1, 1, 0, 0, 0).unwrap()
    } else {
        Utc.with_ymd_and_hms(now.year(), now.month() + 1, 1, 0, 0, 0).unwrap()
    };
    match period {
        "today" => {
            let start = Utc.with_ymd_and_hms(now.year(), now.month(), now.day(), 0, 0, 0).unwrap();
            (start, start + Duration::days(1))
        }
        "last_month" => {
            let (year, month) = if now.month() == 1 { (now.year() - 1, 12) } else { (now.year(), now.month() - 1) };
            let start = Utc.with_ymd_and_hms(year, month, 1, 0, 0, 0).unwrap();
            (start, this_month_start)
        }
        "last_3_months" => {
            let mut year = now.year();
            let mut month = now.month() as i32 - 2;
            while month <= 0 {
                year -= 1;
                month += 12;
            }
            let start = Utc.with_ymd_and_hms(year, month as u32, 1, 0, 0, 0).unwrap();
            (start, this_month_end)
        }
        "this_year" => {
            let start = Utc.with_ymd_and_hms(now.year(), 1, 1, 0, 0, 0).unwrap();
            (start, Utc.with_ymd_and_hms(now.year() + 1, 1, 1, 0, 0, 0).unwrap())
        }
        "last_30_days" => (now - Duration::days(30), now + Duration::seconds(1)),
        _ => (this_month_start, this_month_end),
    }
}

fn bucket_sql(granularity: &str, column: &str) -> String {
    match granularity {
        "month" => format!("date_trunc('month', {column})"),
        "week" => format!("date_trunc('week', {column})"),
        _ => format!("date_trunc('day', {column})"),
    }
}

fn date_label(date: Option<DateTime<Utc>>) -> Option<String> {
    date.map(|dt| dt.format("%Y-%m-%d").to_string())
}

fn time_ago(date: DateTime<Utc>) -> String {
    let delta = Utc::now() - date;
    if delta.num_minutes() < 60 {
        format!("{} minutes ago", delta.num_minutes().max(1))
    } else if delta.num_hours() < 24 {
        format!("{} hours ago", delta.num_hours())
    } else {
        format!("{} days ago", delta.num_days())
    }
}
