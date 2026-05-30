use crate::{
    api_types::{
        enums::{FormAudienceType, FormStatus, UserRole, VisibilityMode},
        forms::{AudienceRuleDto, FormVisibilityDto},
    },
    auth::AuthUser,
};
use uuid::Uuid;

fn audience_matches(rule: &AudienceRuleDto, user: Option<&AuthUser>, org_id: Option<Uuid>) -> bool {
    match rule.audience_type {
        FormAudienceType::Public => true,
        FormAudienceType::Organization => rule.id.is_none() || rule.id == org_id,
        FormAudienceType::User => user.map(|u| rule.id == Some(u.user_id)).unwrap_or(false),
        FormAudienceType::Role => user.map(|u| rule.role == Some(u.role)).unwrap_or(false),
        FormAudienceType::Group
        | FormAudienceType::Class
        | FormAudienceType::Department
        | FormAudienceType::Segment => false,
    }
}

pub fn excluded_from_see(
    visibility: &FormVisibilityDto,
    user: Option<&AuthUser>,
    org_id: Option<Uuid>,
) -> bool {
    visibility
        .cannot_see
        .iter()
        .any(|r| audience_matches(r, user, org_id))
}

pub fn excluded_from_answer(
    visibility: &FormVisibilityDto,
    user: Option<&AuthUser>,
    org_id: Option<Uuid>,
) -> bool {
    visibility
        .cannot_answer
        .iter()
        .any(|r| audience_matches(r, user, org_id))
}

pub fn can_see_form(
    status: FormStatus,
    creator_id: Uuid,
    form_org_id: Uuid,
    visibility: &FormVisibilityDto,
    user: Option<&AuthUser>,
) -> bool {
    if let Some(u) = user {
        if matches!(u.role, UserRole::Ceo | UserRole::SuperAdmin) {
            return true;
        }
        if u.organization_id != Some(form_org_id) && visibility.mode != VisibilityMode::PublicLink {
            return false;
        }
        if u.user_id == creator_id || matches!(u.role, UserRole::Admin | UserRole::Manager) {
            return true;
        }
    }
    if status != FormStatus::Published {
        return false;
    }
    let org_id = user.and_then(|u| u.organization_id);
    if excluded_from_see(visibility, user, org_id) {
        return false;
    }
    match visibility.mode {
        VisibilityMode::Private => user.map(|u| u.user_id == creator_id).unwrap_or(false),
        VisibilityMode::PublicLink => true,
        VisibilityMode::Organization => user
            .map(|u| u.organization_id == Some(form_org_id))
            .unwrap_or(false),
        VisibilityMode::SelectedUsers
        | VisibilityMode::SelectedRoles
        | VisibilityMode::Subordinates => visibility
            .can_see
            .iter()
            .any(|r| audience_matches(r, user, org_id)),
    }
}

pub fn can_answer_form(
    status: FormStatus,
    creator_id: Uuid,
    form_org_id: Uuid,
    visibility: &FormVisibilityDto,
    user: Option<&AuthUser>,
) -> bool {
    if status != FormStatus::Published {
        return false;
    }
    let org_id = user.and_then(|u| u.organization_id);
    if excluded_from_answer(visibility, user, org_id) {
        return false;
    }
    if user.is_none() {
        return visibility.mode == VisibilityMode::PublicLink && visibility.guest_can_answer;
    }
    if visibility
        .can_answer
        .iter()
        .any(|r| audience_matches(r, user, org_id))
    {
        return true;
    }
    match visibility.mode {
        VisibilityMode::PublicLink => true,
        VisibilityMode::Organization => user
            .map(|u| u.organization_id == Some(form_org_id))
            .unwrap_or(false),
        VisibilityMode::Private => user.map(|u| u.user_id == creator_id).unwrap_or(false),
        VisibilityMode::SelectedUsers
        | VisibilityMode::SelectedRoles
        | VisibilityMode::Subordinates => false,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api_types::{
        enums::{FormAudienceType, UserRole},
        forms::AudienceRuleDto,
    };

    #[test]
    fn exclusion_overrides_inclusion() {
        let org = Uuid::new_v4();
        let user = AuthUser {
            user_id: Uuid::new_v4(),
            organization_id: Some(org),
            role: UserRole::Teacher,
        };
        let visibility = FormVisibilityDto {
            mode: VisibilityMode::Organization,
            can_see: vec![AudienceRuleDto {
                audience_type: FormAudienceType::Organization,
                id: Some(org),
                role: None,
                label: None,
            }],
            cannot_see: vec![AudienceRuleDto {
                audience_type: FormAudienceType::Role,
                id: None,
                role: Some(UserRole::Teacher),
                label: None,
            }],
            ..Default::default()
        };
        assert!(!can_see_form(
            FormStatus::Published,
            Uuid::new_v4(),
            org,
            &visibility,
            Some(&user)
        ));
    }
}
