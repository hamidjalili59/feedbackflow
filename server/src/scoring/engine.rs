use crate::api_types::{
    enums::{FieldType, ScoreRuleType, ScoringMode},
    fields::FormFieldDto,
    scoring::{FieldScoreBreakdownDto, ScoreCategoryDto, ScoreResultDto},
    submissions::AnswerInputDto,
};
use serde_json::{json, Value};
use std::collections::BTreeMap;

pub fn calculate_submission_score(
    fields: &[FormFieldDto],
    answers: &[AnswerInputDto],
    mode: ScoringMode,
) -> ScoreResultDto {
    if mode == ScoringMode::None {
        return ScoreResultDto {
            total_score: 0.0,
            max_score: 0.0,
            percentage_score: 0.0,
            category: None,
            field_breakdowns: vec![],
            metadata: BTreeMap::new(),
        };
    }
    let mut total = 0.0;
    let mut max_total = 0.0;
    let mut breakdowns = vec![];
    for field in fields.iter().filter(|f| f.scoring_config.enabled) {
        let answer = answers.iter().find(|a| a.field_id == field.id);
        let field_max = field
            .scoring_config
            .max_score
            .unwrap_or_else(|| infer_max_score(field));
        let raw_score = answer.map(|a| score_field(field, &a.value)).unwrap_or(0.0);
        let weight = field.scoring_config.weight.unwrap_or(1.0);
        let weighted_score = raw_score * weight;
        total += weighted_score;
        max_total += field_max * weight;
        breakdowns.push(FieldScoreBreakdownDto {
            field_id: field.id,
            label: field.label.clone(),
            score: raw_score,
            max_score: field_max,
            weighted_score,
            rule_id: None,
            details: json!({"weight": weight}),
        });
    }
    let percentage = if max_total > 0.0 {
        (total / max_total * 100.0).clamp(0.0, 100.0)
    } else {
        0.0
    };
    let category = fields
        .iter()
        .flat_map(|f| f.scoring_config.categories.clone())
        .find(|c| percentage >= c.min_percentage && percentage <= c.max_percentage);
    ScoreResultDto {
        total_score: round2(total),
        max_score: round2(max_total),
        percentage_score: round2(percentage),
        category,
        field_breakdowns: breakdowns,
        metadata: BTreeMap::new(),
    }
}

fn score_field(field: &FormFieldDto, value: &Value) -> f64 {
    for rule in &field.scoring_config.rules {
        match rule.rule_type {
            ScoreRuleType::Fixed => return rule.score,
            ScoreRuleType::OptionBased => {
                if let Some(expected) = &rule.value {
                    if expected == value {
                        return rule.score;
                    }
                    if let Some(arr) = value.as_array() {
                        if arr.contains(expected) {
                            return rule.score;
                        }
                    }
                }
            }
            ScoreRuleType::RangeBased => {
                let Some(number) = value.as_f64() else {
                    continue;
                };
                if rule.min.map(|m| number >= m).unwrap_or(true)
                    && rule.max.map(|m| number <= m).unwrap_or(true)
                {
                    return rule.score;
                }
            }
            ScoreRuleType::Weighted => return rule.score * rule.weight.unwrap_or(1.0),
            ScoreRuleType::NegativeScore => return -rule.score.abs(),
            ScoreRuleType::Formula => continue,
        }
    }
    match field.field_type {
        FieldType::SingleChoice
        | FieldType::Dropdown
        | FieldType::QuizQuestion
        | FieldType::YesNo
        | FieldType::EmojiReaction => score_single_option(field, value),
        FieldType::MultipleChoice | FieldType::Ranking => value
            .as_array()
            .map(|arr| arr.iter().map(|v| score_single_option(field, v)).sum())
            .unwrap_or(0.0),
        FieldType::RatingStars
        | FieldType::NumericRating
        | FieldType::Slider
        | FieldType::Nps
        | FieldType::Number
        | FieldType::Decimal => value.as_f64().unwrap_or(0.0),
        _ => 0.0,
    }
}

fn score_single_option(field: &FormFieldDto, value: &Value) -> f64 {
    let key = if let Some(s) = value.as_str() {
        s.to_owned()
    } else {
        value.to_string().trim_matches('"').to_owned()
    };
    field
        .scoring_config
        .option_scores
        .get(&key)
        .copied()
        .or_else(|| {
            field
                .config
                .options
                .iter()
                .find(|o| o.id == key || o.value == *value)
                .and_then(|o| o.score)
        })
        .unwrap_or(0.0)
}

fn infer_max_score(field: &FormFieldDto) -> f64 {
    let option_max = field
        .config
        .options
        .iter()
        .filter_map(|o| o.score)
        .fold(0.0, f64::max);
    let explicit_max = field
        .scoring_config
        .option_scores
        .values()
        .copied()
        .fold(0.0, f64::max);
    let rules_max = field
        .scoring_config
        .rules
        .iter()
        .map(|r| r.score)
        .fold(0.0, f64::max);
    option_max
        .max(explicit_max)
        .max(rules_max)
        .max(field.config.max.unwrap_or(0.0))
}

fn round2(v: f64) -> f64 {
    (v * 100.0).round() / 100.0
}

pub fn category_from_percentage(
    categories: &[ScoreCategoryDto],
    percentage: f64,
) -> Option<ScoreCategoryDto> {
    categories
        .iter()
        .find(|c| percentage >= c.min_percentage && percentage <= c.max_percentage)
        .cloned()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api_types::{
        enums::FieldType,
        fields::{
            FieldConfigDto, FieldOptionDto, FieldPermissionConfigDto, FieldScoringConfigDto,
            FieldValidationDto,
        },
    };
    use chrono::Utc;
    use uuid::Uuid;

    #[test]
    fn calculates_choice_score() {
        let field_id = Uuid::new_v4();
        let field = FormFieldDto {
            id: field_id,
            form_id: Uuid::new_v4(),
            field_type: FieldType::SingleChoice,
            label: "Q".into(),
            description: None,
            placeholder: None,
            required: true,
            order_index: 0,
            config: FieldConfigDto {
                options: vec![FieldOptionDto {
                    id: "a".into(),
                    label: "A".into(),
                    value: json!("a"),
                    order_index: 0,
                    score: Some(10.0),
                    metadata: json!({}),
                }],
                ..Default::default()
            },
            validation: FieldValidationDto::default(),
            visibility_conditions: vec![],
            scoring_config: FieldScoringConfigDto {
                enabled: true,
                max_score: Some(10.0),
                ..Default::default()
            },
            permissions: FieldPermissionConfigDto::default(),
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };
        let result = calculate_submission_score(
            &[field],
            &[AnswerInputDto {
                field_id,
                value: json!("a"),
                metadata: json!({}),
            }],
            ScoringMode::Quiz,
        );
        assert_eq!(result.total_score, 10.0);
        assert_eq!(result.percentage_score, 100.0);
    }
}
