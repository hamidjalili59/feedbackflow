use chrono::Utc;
use feedbackflow_server::{
    api_types::{
        enums::*,
        forms::{
            AudienceRuleDto, FormAnswerAccessDto, FormDetailDto, FormVisibilityDto,
            PublicProtectionSettingsDto,
        },
    },
    auth::AuthUser,
    forms::visibility,
    permissions::engine,
};
use serde_json::json;
use uuid::Uuid;

#[test]
fn teacher_requiring_approval_cannot_publish_directly_by_default() {
    let rule = engine::default_publishing_rules()
        .into_iter()
        .find(|r| r.role == UserRole::Teacher)
        .unwrap();
    assert!(rule.approval_rule.approval_required);
    assert!(!rule.can_publish_directly);
}

#[test]
fn admin_and_ceo_can_change_permission_rules() {
    assert!(engine::can_rbac(
        UserRole::Admin,
        PermissionAction::ManagePermissions,
        ResourceType::Permission
    ));
    assert!(engine::can_rbac(
        UserRole::Ceo,
        PermissionAction::ManagePermissions,
        ResourceType::Permission
    ));
}

#[test]
fn private_form_cannot_be_answered_by_guest() {
    let org = Uuid::new_v4();
    let vis = FormVisibilityDto {
        mode: VisibilityMode::Private,
        ..Default::default()
    };
    assert!(!visibility::can_answer_form(
        FormStatus::Published,
        Uuid::new_v4(),
        org,
        &vis,
        None
    ));
}

#[test]
fn public_link_can_be_answered_by_guest_only_when_enabled() {
    let org = Uuid::new_v4();
    let mut vis = FormVisibilityDto {
        mode: VisibilityMode::PublicLink,
        guest_can_answer: false,
        ..Default::default()
    };
    assert!(!visibility::can_answer_form(
        FormStatus::Published,
        Uuid::new_v4(),
        org,
        &vis,
        None
    ));
    vis.guest_can_answer = true;
    assert!(visibility::can_answer_form(
        FormStatus::Published,
        Uuid::new_v4(),
        org,
        &vis,
        None
    ));
}

#[test]
fn role_exclusion_overrides_role_inclusion() {
    let org = Uuid::new_v4();
    let user = AuthUser {
        user_id: Uuid::new_v4(),
        organization_id: Some(org),
        role: UserRole::Parent,
    };
    let vis = FormVisibilityDto {
        mode: VisibilityMode::SelectedRoles,
        can_answer: vec![AudienceRuleDto {
            audience_type: FormAudienceType::Role,
            id: None,
            role: Some(UserRole::Parent),
            label: None,
        }],
        cannot_answer: vec![AudienceRuleDto {
            audience_type: FormAudienceType::Role,
            id: None,
            role: Some(UserRole::Parent),
            label: None,
        }],
        ..Default::default()
    };
    assert!(!visibility::can_answer_form(
        FormStatus::Published,
        Uuid::new_v4(),
        org,
        &vis,
        Some(&user)
    ));
}

#[test]
fn answer_access_serializes_current_user_submission_id() {
    let submission_id = Uuid::new_v4();
    let dto = FormAnswerAccessDto {
        allowed: false,
        can_view: true,
        can_edit_workspace: false,
        requires_public_link: false,
        my_submission_id: Some(submission_id),
        reason: Some("already submitted".to_owned()),
        reason_code: Some("already_submitted".to_owned()),
    };

    let value = serde_json::to_value(dto).unwrap();
    assert_eq!(value["my_submission_id"], json!(submission_id));
    assert_eq!(value["reason_code"], json!("already_submitted"));
}

#[test]
fn form_detail_serializes_current_user_submission_id() {
    let submission_id = Uuid::new_v4();
    let now = Utc::now();
    let dto = FormDetailDto {
        id: Uuid::new_v4(),
        organization_id: Uuid::new_v4(),
        creator_id: Uuid::new_v4(),
        title: "Parent survey".to_owned(),
        description: None,
        category: None,
        tags: vec![],
        status: FormStatus::Published,
        visibility_mode: VisibilityMode::Organization,
        publish_mode: PublishMode::Organization,
        settings: Default::default(),
        visibility: FormVisibilityDto {
            mode: VisibilityMode::Organization,
            ..Default::default()
        },
        public_protection: PublicProtectionSettingsDto::default(),
        scoring_mode: ScoringMode::None,
        scoring_config: json!({}),
        fields: vec![],
        public_token: None,
        my_submission_id: Some(submission_id),
        approved_at: None,
        published_at: Some(now),
        closed_at: None,
        created_at: now,
        updated_at: now,
    };

    let value = serde_json::to_value(dto).unwrap();
    assert_eq!(value["my_submission_id"], json!(submission_id));
}
