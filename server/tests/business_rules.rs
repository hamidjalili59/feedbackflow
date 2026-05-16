use feedbackflow_server::{
    api_types::{
        enums::*,
        forms::{AudienceRuleDto, FormVisibilityDto},
    },
    auth::AuthUser,
    forms::visibility,
    permissions::engine,
};
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
