use crate::api_types::*;
use utoipa::openapi::security::{Http, HttpAuthScheme, SecurityScheme};
use utoipa::{Modify, OpenApi};

pub struct SecurityAddon;

impl Modify for SecurityAddon {
    fn modify(&self, openapi: &mut utoipa::openapi::OpenApi) {
        let components = openapi.components.get_or_insert_with(Default::default);
        components.add_security_scheme(
            "bearer_auth",
            SecurityScheme::Http(Http::new(HttpAuthScheme::Bearer)),
        );
    }
}

#[derive(OpenApi)]
#[openapi(
    info(
        title = "FeedbackFlow Server API",
        version = "0.1.0",
        description = "OpenAPI 3.1 contract for Flutter/Dart clients of the FeedbackFlow multi-role form platform. All successful single-resource responses use ApiResponse<T>. All list responses use ApiListResponse<T>. All errors use ApiErrorResponse with success=false, data=null, error, and meta."
    ),
    paths(
        register_doc,
        login_doc,
        refresh_doc,
        logout_doc,
        get_me_doc,
        get_user_me_doc,
        update_my_profile_doc,
        get_user_doc,
        get_subordinates_doc,
        get_organization_doc,
        get_organization_roles_doc,
        update_role_rules_doc,
        get_effective_permissions_doc,
        get_field_type_permissions_doc,
        update_field_type_permissions_doc,
        get_publishing_rules_doc,
        update_publishing_rules_doc,
        create_form_doc,
        list_forms_doc,
        get_form_doc,
        update_form_doc,
        delete_form_doc,
        create_form_field_doc,
        update_form_field_doc,
        delete_form_field_doc,
        duplicate_form_doc,
        submit_for_approval_doc,
        approve_form_doc,
        reject_form_doc,
        publish_form_doc,
        close_form_doc,
        archive_form_doc,
        update_form_visibility_doc,
        list_form_access_codes_doc,
        set_form_access_codes_doc,
        update_public_protection_doc,
        get_dashboard_analytics_doc,
        get_form_analytics_doc,
        get_public_form_doc,
        submit_public_form_doc,
        validate_public_form_access_doc,
        create_submission_doc,
        list_submissions_doc,
        get_submission_doc,
        update_submission_doc,
        delete_submission_doc,
        get_score_breakdown_doc,
        list_score_templates_doc,
        create_score_template_doc,
        get_score_template_doc,
        update_score_template_doc,
        delete_score_template_doc,
        list_activities_doc,
        get_activity_doc,
        update_activity_doc,
        list_activity_rules_doc,
        create_activity_rule_doc,
        update_activity_rule_doc,
        delete_activity_rule_doc,
        list_audit_logs_doc
    ),
    components(schemas(
        ApiErrorDto,
        ApiErrorResponse,
        LogoutResponse,
        UpdateResultDto,
        DeleteResultDto,
        OperationStatusDto,
        PaginationMeta,
        ListMetaDto,
        UserRole,
        PermissionAction,
        ResourceType,
        FormStatus,
        ApprovalStatus,
        PublishMode,
        VisibilityMode,
        SubmissionMode,
        FieldType,
        SortOrder,
        FormAudienceType,
        AnswerVisibility,
        ScoringMode,
        ScoreRuleType,
        ActivityTriggerType,
        ActivityActionType,
        ActivityStatus,
        PublicProtectionLevel,
        RateLimitStrategy,
        AuditAction,
        ErrorCode,
        RegisterRequest,
        RegisterResponse,
        LoginRequest,
        LoginResponse,
        RefreshTokenRequest,
        RefreshTokenResponse,
        LogoutRequest,
        MeResponse,
        UserSummaryDto,
        UserDetailDto,
        UserProfileDto,
        UpdateUserProfileRequest,
        UserRelationshipDto,
        SubordinateUserDto,
        OrganizationDto,
        OrganizationSettingsDto,
        OrganizationRoleDto,
        UpdateRoleRulesRequest,
        RoleRuleDto,
        EffectivePermissionsDto,
        PermissionDto,
        RolePermissionDto,
        FieldTypePermissionDto,
        UpdateFieldTypePermissionsRequest,
        PublishingRuleDto,
        UpdatePublishingRulesRequest,
        ApprovalRuleDto,
        CreateFormRequest,
        UpdateFormRequest,
        FormSummaryDto,
        FormDetailDto,
        DuplicateFormRequest,
        FormSettingsDto,
        FormVisibilityDto,
        UpdateFormVisibilityRequest,
        PublicProtectionSettingsDto,
        FormAccessCodeDto,
        FormAccessCodeInputDto,
        SharedFormPasswordInputDto,
        SetFormAccessCodesRequest,
        FormAccessCodesResponse,
        UpdatePublicProtectionRequest,
        SubmitForApprovalRequest,
        ApproveFormRequest,
        RejectFormRequest,
        PublishFormRequest,
        CloseFormRequest,
        ArchiveFormRequest,
        AudienceRuleDto,
        FormFieldDto,
        CreateFormFieldRequest,
        UpdateFormFieldRequest,
        FieldConfigDto,
        FieldValidationDto,
        FieldOptionDto,
        FieldVisibilityConditionDto,
        ConditionalLogicRuleDto,
        FieldScoringConfigDto,
        FieldPermissionConfigDto,
        CreateSubmissionRequest,
        UpdateSubmissionRequest,
        SubmissionSummaryDto,
        SubmissionDetailDto,
        AnswerDto,
        AnswerInputDto,
        SubmissionScoreDto,
        ScoreBreakdownDto,
        PublicFormDto,
        PublicFormAccessPolicyDto,
        PublicFormAccessDto,
        ValidatePublicFormAccessRequest,
        ValidatePublicFormAccessResponse,
        PublicSubmissionRequest,
        PublicSubmissionResponse,
        ScoreTemplateDto,
        CreateScoreTemplateRequest,
        UpdateScoreTemplateRequest,
        ScoreRuleDto,
        ScoreCategoryDto,
        ScoreResultDto,
        FieldScoreBreakdownDto,
        ActivityRuleDto,
        CreateActivityRuleRequest,
        UpdateActivityRuleRequest,
        ActivityDto,
        UpdateActivityRequest,
        ActivitySummaryDto,
        FormAnalyticsDto,
        DashboardAnalyticsDto,
        DashboardTopFormDto,
        AnalyticsBucketDto,
        AnalyticsTimeseriesPointDto,
        FieldAnalyticsDto,
        ScoreAnalyticsDto,
        SubmissionCountAnalyticsDto,
        CompletionRateAnalyticsDto,
        AuditLogDto,
        AuditLogSummaryDto,
        RateLimitInfoDto,
        PublicRateLimitStatusDto
    )),
    tags(
        (name = "Auth"),
        (name = "Users"),
        (name = "Organizations"),
        (name = "Permissions"),
        (name = "Forms"),
        (name = "Fields"),
        (name = "Submissions"),
        (name = "PublicForms"),
        (name = "Scoring"),
        (name = "Activities"),
        (name = "Analytics"),
        (name = "Audit")
    ),
    modifiers(&SecurityAddon)
)]
pub struct ApiDoc;

#[utoipa::path(
    post,
    path = "/api/v1/auth/register",
    tag = "Auth",
    operation_id = "register",
    description = "Public phone/password registration endpoint. Phone is required and becomes the primary authentication identifier. Email is optional profile/contact information. Send either organization_id to join an existing organization or organization_name to create or join by slug. Do not send both; doing so returns VALIDATION_ERROR. Privileged roles cannot self-register.",
    request_body = RegisterRequest,
    responses(
        (status = 201, body = ApiResponse<RegisterResponse>),
        (status = 400, body = ApiErrorResponse),
        (status = 403, body = ApiErrorResponse),
        (status = 409, body = ApiErrorResponse)
    )
)]
pub async fn register_doc() {}

#[utoipa::path(
    post,
    path = "/api/v1/auth/login",
    tag = "Auth",
    operation_id = "login",
    description = "Phone/password login. Email is optional profile/contact information and is not used for authentication. Returns JWT access token and rotating refresh token.",
    request_body = LoginRequest,
    responses((status = 200, body = ApiResponse<LoginResponse>), (status = 401, body = ApiErrorResponse))
)]
pub async fn login_doc() {}

#[utoipa::path(
    post,
    path = "/api/v1/auth/refresh",
    tag = "Auth",
    operation_id = "refreshToken",
    description = "Refresh access token. Refresh tokens are rotated server-side.",
    request_body = RefreshTokenRequest,
    responses((status = 200, body = ApiResponse<RefreshTokenResponse>), (status = 401, body = ApiErrorResponse))
)]
pub async fn refresh_doc() {}

#[utoipa::path(
    post,
    path = "/api/v1/auth/logout",
    tag = "Auth",
    operation_id = "logout",
    description = "Requires Bearer JWT. Revokes the provided refresh token.",
    security(("bearer_auth" = [])),
    request_body = LogoutRequest,
    responses((status = 200, body = ApiResponse<LogoutResponse>), (status = 401, body = ApiErrorResponse))
)]
pub async fn logout_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/auth/me",
    tag = "Auth",
    operation_id = "getMe",
    description = "Requires Bearer JWT. Returns current user and effective RBAC/ABAC permissions.",
    security(("bearer_auth" = [])),
    responses((status = 200, body = ApiResponse<MeResponse>), (status = 401, body = ApiErrorResponse))
)]
pub async fn get_me_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/users/me",
    tag = "Users",
    operation_id = "getMyUser",
    description = "Requires Bearer JWT. Returns the current user profile.",
    security(("bearer_auth" = [])),
    responses((status = 200, body = ApiResponse<UserDetailDto>), (status = 401, body = ApiErrorResponse))
)]
pub async fn get_user_me_doc() {}

#[utoipa::path(
    patch,
    path = "/api/v1/users/me",
    tag = "Users",
    operation_id = "updateMyProfile",
    description = "Requires Bearer JWT. Updates the current user's display name, optional email, and profile fields. Phone changes should be handled by a future verification flow and are not accepted here.",
    security(("bearer_auth" = [])),
    request_body = UpdateUserProfileRequest,
    responses(
        (status = 200, body = ApiResponse<UserDetailDto>),
        (status = 400, body = ApiErrorResponse),
        (status = 401, body = ApiErrorResponse)
    )
)]
pub async fn update_my_profile_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/users/{id}",
    tag = "Users",
    operation_id = "getUser",
    description = "Requires PermissionAction::Read on ResourceType::User and organization boundary access.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "User id")),
    responses((status = 200, body = ApiResponse<UserDetailDto>), (status = 403, body = ApiErrorResponse), (status = 404, body = ApiErrorResponse))
)]
pub async fn get_user_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/users/{id}/subordinates",
    tag = "Users",
    operation_id = "getUserSubordinates",
    description = "Requires Bearer JWT. Managers/Admins/CEOs can inspect another user's subordinates; users can inspect their own hierarchy.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "User id"), ListQuery),
    responses((status = 200, body = ApiListResponse<SubordinateUserDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn get_subordinates_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/organizations/{id}",
    tag = "Organizations",
    operation_id = "getOrganization",
    description = "Requires PermissionAction::Read on ResourceType::Organization inside the caller organization boundary.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Organization id")),
    responses((status = 200, body = ApiResponse<OrganizationDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn get_organization_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/organizations/{id}/roles",
    tag = "Organizations",
    operation_id = "getOrganizationRoles",
    description = "Requires PermissionAction::Read on ResourceType::Permission for the organization.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Organization id")),
    responses((status = 200, body = ApiListResponse<OrganizationRoleDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn get_organization_roles_doc() {}

#[utoipa::path(
    patch,
    path = "/api/v1/organizations/{id}/role-rules",
    tag = "Organizations",
    operation_id = "updateRoleRules",
    description = "Requires PermissionAction::ManagePermissions on ResourceType::Permission. Admin/CEO/Super Admin use this to configure role rules.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Organization id")),
    request_body = UpdateRoleRulesRequest,
    responses((status = 200, body = ApiResponse<UpdateResultDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn update_role_rules_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/permissions/effective",
    tag = "Permissions",
    operation_id = "getEffectivePermissions",
    description = "Requires Bearer JWT. Returns effective RBAC/ABAC permissions for the caller.",
    security(("bearer_auth" = [])),
    responses((status = 200, body = ApiResponse<EffectivePermissionsDto>), (status = 401, body = ApiErrorResponse))
)]
pub async fn get_effective_permissions_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/permissions/field-types",
    tag = "Permissions",
    operation_id = "getFieldTypePermissions",
    description = "Requires Bearer JWT. Returns field type permissions by role for the caller organization.",
    security(("bearer_auth" = [])),
    params(ListQuery),
    responses((status = 200, body = ApiResponse<Vec<FieldTypePermissionDto>>), (status = 403, body = ApiErrorResponse))
)]
pub async fn get_field_type_permissions_doc() {}

#[utoipa::path(
    patch,
    path = "/api/v1/permissions/field-types",
    tag = "Permissions",
    operation_id = "updateFieldTypePermissions",
    description = "Requires PermissionAction::ManagePermissions on ResourceType::Permission.",
    security(("bearer_auth" = [])),
    request_body = UpdateFieldTypePermissionsRequest,
    responses((status = 200, body = ApiResponse<UpdateResultDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn update_field_type_permissions_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/permissions/publishing-rules",
    tag = "Permissions",
    operation_id = "getPublishingRules",
    description = "Requires Bearer JWT. Returns effective publishing and approval rules for the caller organization.",
    security(("bearer_auth" = [])),
    responses((status = 200, body = ApiResponse<Vec<PublishingRuleDto>>), (status = 401, body = ApiErrorResponse))
)]
pub async fn get_publishing_rules_doc() {}

#[utoipa::path(
    patch,
    path = "/api/v1/permissions/publishing-rules",
    tag = "Permissions",
    operation_id = "updatePublishingRules",
    description = "Requires PermissionAction::ManagePermissions on ResourceType::Permission. Configures direct publish, approval, and public protection permissions.",
    security(("bearer_auth" = [])),
    request_body = UpdatePublishingRulesRequest,
    responses((status = 200, body = ApiResponse<UpdateResultDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn update_publishing_rules_doc() {}

#[utoipa::path(
    post,
    path = "/api/v1/forms",
    tag = "Forms",
    operation_id = "createForm",
    description = "Requires PermissionAction::Create on ResourceType::Form and field/scoring configuration permissions.",
    security(("bearer_auth" = [])),
    request_body = CreateFormRequest,
    responses((status = 201, body = ApiResponse<FormDetailDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn create_form_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/forms",
    tag = "Forms",
    operation_id = "listForms",
    description = "Requires Bearer JWT. Returns forms visible to the caller according to organization and visibility rules.",
    security(("bearer_auth" = [])),
    params(ListQuery),
    responses((status = 200, body = ApiListResponse<FormSummaryDto>), (status = 401, body = ApiErrorResponse))
)]
pub async fn list_forms_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/forms/{id}",
    tag = "Forms",
    operation_id = "getForm",
    description = "Requires PermissionAction::Read on ResourceType::Form. Visibility exclusions override inclusions.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    responses((status = 200, body = ApiResponse<FormDetailDto>), (status = 403, body = ApiErrorResponse), (status = 404, body = ApiErrorResponse))
)]
pub async fn get_form_doc() {}

#[utoipa::path(
    patch,
    path = "/api/v1/forms/{id}",
    tag = "Forms",
    operation_id = "updateForm",
    description = "Requires PermissionAction::Update on ResourceType::Form and ownership/organization boundary access.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    request_body = UpdateFormRequest,
    responses((status = 200, body = ApiResponse<FormDetailDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn update_form_doc() {}

#[utoipa::path(
    delete,
    path = "/api/v1/forms/{id}",
    tag = "Forms",
    operation_id = "deleteForm",
    description = "Requires PermissionAction::Delete on ResourceType::Form and ownership/organization boundary access. Soft deletes the form.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    responses((status = 200, body = ApiResponse<DeleteResultDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn delete_form_doc() {}

#[utoipa::path(
    post,
    path = "/api/v1/forms/{id}/fields",
    tag = "Fields",
    operation_id = "createFormField",
    description = "Requires PermissionAction::Update on ResourceType::FormField and allowed FieldType for the caller role.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    request_body = CreateFormFieldRequest,
    responses((status = 201, body = ApiResponse<FormFieldDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn create_form_field_doc() {}

#[utoipa::path(
    patch,
    path = "/api/v1/forms/{id}/fields/{field_id}",
    tag = "Fields",
    operation_id = "updateFormField",
    description = "Requires PermissionAction::Update on ResourceType::FormField and allowed field/scoring permissions.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id"), ("field_id" = Uuid, Path, description = "Field id")),
    request_body = UpdateFormFieldRequest,
    responses((status = 200, body = ApiResponse<FormFieldDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn update_form_field_doc() {}

#[utoipa::path(
    delete,
    path = "/api/v1/forms/{id}/fields/{field_id}",
    tag = "Fields",
    operation_id = "deleteFormField",
    description = "Requires PermissionAction::Delete on ResourceType::FormField. Soft deletes the field.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id"), ("field_id" = Uuid, Path, description = "Field id")),
    responses((status = 200, body = ApiResponse<DeleteResultDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn delete_form_field_doc() {}

#[utoipa::path(
    post,
    path = "/api/v1/forms/{id}/duplicate",
    tag = "Forms",
    operation_id = "duplicateForm",
    description = "Requires PermissionAction::Create on ResourceType::Form.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    request_body = DuplicateFormRequest,
    responses((status = 201, body = ApiResponse<FormDetailDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn duplicate_form_doc() {}

#[utoipa::path(
    post,
    path = "/api/v1/forms/{id}/submit-for-approval",
    tag = "Forms",
    operation_id = "submitFormForApproval",
    description = "Requires PermissionAction::Update on ResourceType::Form. Teacher may require two-step approval depending on organization role rules.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    request_body = SubmitForApprovalRequest,
    responses((status = 200, body = ApiResponse<FormDetailDto>), (status = 409, body = ApiErrorResponse))
)]
pub async fn submit_for_approval_doc() {}

#[utoipa::path(
    post,
    path = "/api/v1/forms/{id}/approve",
    tag = "Forms",
    operation_id = "approveForm",
    description = "Requires PermissionAction::Approve on ResourceType::Form. Usually Manager/Admin/CEO/Super Admin.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    request_body = ApproveFormRequest,
    responses((status = 200, body = ApiResponse<FormDetailDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn approve_form_doc() {}

#[utoipa::path(
    post,
    path = "/api/v1/forms/{id}/reject",
    tag = "Forms",
    operation_id = "rejectForm",
    description = "Requires PermissionAction::Reject on ResourceType::Form. Usually Manager/Admin/CEO/Super Admin.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    request_body = RejectFormRequest,
    responses((status = 200, body = ApiResponse<FormDetailDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn reject_form_doc() {}

#[utoipa::path(
    post,
    path = "/api/v1/forms/{id}/publish",
    tag = "Forms",
    operation_id = "publishForm",
    description = "Requires PermissionAction::Publish on ResourceType::Form. Teacher may require approval depending on organization role rules. Public-link publishing requires public protection unless a permitted publisher disables it.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    request_body = PublishFormRequest,
    responses((status = 200, body = ApiResponse<FormDetailDto>), (status = 403, body = ApiErrorResponse), (status = 409, body = ApiErrorResponse))
)]
pub async fn publish_form_doc() {}

#[utoipa::path(
    post,
    path = "/api/v1/forms/{id}/close",
    tag = "Forms",
    operation_id = "closeForm",
    description = "Requires PermissionAction::Update on ResourceType::Form.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    request_body = CloseFormRequest,
    responses((status = 200, body = ApiResponse<FormDetailDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn close_form_doc() {}

#[utoipa::path(
    post,
    path = "/api/v1/forms/{id}/archive",
    tag = "Forms",
    operation_id = "archiveForm",
    description = "Requires PermissionAction::Update on ResourceType::Form.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    request_body = ArchiveFormRequest,
    responses((status = 200, body = ApiResponse<FormDetailDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn archive_form_doc() {}

#[utoipa::path(
    patch,
    path = "/api/v1/forms/{id}/visibility",
    tag = "Forms",
    operation_id = "updateFormVisibility",
    description = "Requires PermissionAction::Update on ResourceType::Form. Visibility exclusions override inclusions.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    request_body = UpdateFormVisibilityRequest,
    responses((status = 200, body = ApiResponse<FormDetailDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn update_form_visibility_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/forms/{id}/access-codes",
    tag = "Forms",
    operation_id = "listFormAccessCodes",
    description = "Requires PermissionAction::Update on ResourceType::Form. Returns access-code metadata only; secrets are never returned.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    responses((status = 200, body = ApiResponse<FormAccessCodesResponse>), (status = 403, body = ApiErrorResponse))
)]
pub async fn list_form_access_codes_doc() {}

#[utoipa::path(
    put,
    path = "/api/v1/forms/{id}/access-codes",
    tag = "Forms",
    operation_id = "setFormAccessCodes",
    description = "Requires PermissionAction::Update on ResourceType::Form. Replaces labeled identity codes and optionally rotates or clears the shared form password.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    request_body = SetFormAccessCodesRequest,
    responses((status = 200, body = ApiResponse<FormAccessCodesResponse>), (status = 403, body = ApiErrorResponse))
)]
pub async fn set_form_access_codes_doc() {}

#[utoipa::path(
    patch,
    path = "/api/v1/forms/{id}/public-protection",
    tag = "Forms",
    operation_id = "updatePublicProtection",
    description = "Requires PermissionAction::ManagePublicProtection on ResourceType::Form/PublicProtection. Disabling public protection creates audit logs.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    request_body = UpdatePublicProtectionRequest,
    responses((status = 200, body = ApiResponse<FormDetailDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn update_public_protection_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/dashboard/analytics",
    tag = "Analytics",
    operation_id = "getDashboardAnalytics",
    description = "Requires Bearer JWT. Returns organization-level participation, respondent, user, and trend analytics for dashboard widgets.",
    security(("bearer_auth" = [])),
    responses((status = 200, body = ApiResponse<DashboardAnalyticsDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn get_dashboard_analytics_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/forms/{id}/analytics",
    tag = "Analytics",
    operation_id = "getFormAnalytics",
    description = "Requires PermissionAction::ViewResults on ResourceType::Form.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    responses((status = 200, body = ApiResponse<FormAnalyticsDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn get_form_analytics_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/public/forms/{public_token}",
    tag = "PublicForms",
    operation_id = "getPublicForm",
    description = "Public endpoint. Does not require Bearer JWT. Returns a published public-link form.",
    params(("public_token" = String, Path, description = "Public form token")),
    responses((status = 200, body = ApiResponse<PublicFormDto>), (status = 404, body = ApiErrorResponse), (status = 409, body = ApiErrorResponse))
)]
pub async fn get_public_form_doc() {}

#[utoipa::path(
    post,
    path = "/api/v1/public/forms/{public_token}/validate-access",
    tag = "PublicForms",
    operation_id = "validatePublicFormAccess",
    description = "Public endpoint. Performs public form throttling/captcha/email/phone validation abstractions and returns a short-lived public_access_token when allowed.",
    params(("public_token" = String, Path, description = "Public form token")),
    request_body = ValidatePublicFormAccessRequest,
    responses((status = 200, body = ApiResponse<ValidatePublicFormAccessResponse>), (status = 404, body = ApiErrorResponse), (status = 429, body = ApiErrorResponse))
)]
pub async fn validate_public_form_access_doc() {}

#[utoipa::path(
    post,
    path = "/api/v1/public/forms/{public_token}/submissions",
    tag = "PublicForms",
    operation_id = "submitPublicForm",
    description = "Public endpoint. If public protection requires validation, public_access_token from validatePublicFormAccess is required and must be valid. Guests may submit only when the form enables guest submissions.",
    params(("public_token" = String, Path, description = "Public form token")),
    request_body = PublicSubmissionRequest,
    responses((status = 201, body = ApiResponse<PublicSubmissionResponse>), (status = 401, body = ApiErrorResponse), (status = 403, body = ApiErrorResponse), (status = 429, body = ApiErrorResponse))
)]
pub async fn submit_public_form_doc() {}

#[utoipa::path(
    post,
    path = "/api/v1/forms/{id}/submissions",
    tag = "Submissions",
    operation_id = "createSubmission",
    description = "Requires PermissionAction::Answer on ResourceType::Form. The form must be published and visible to the caller.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    request_body = CreateSubmissionRequest,
    responses((status = 201, body = ApiResponse<SubmissionDetailDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn create_submission_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/forms/{id}/submissions",
    tag = "Submissions",
    operation_id = "listSubmissions",
    description = "Requires PermissionAction::ViewResults on ResourceType::Form.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id"), ListQuery),
    responses((status = 200, body = ApiListResponse<SubmissionSummaryDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn list_submissions_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/submissions/{id}",
    tag = "Submissions",
    operation_id = "getSubmission",
    description = "Requires PermissionAction::Read on ResourceType::Submission and form visibility/results access.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Submission id")),
    responses((status = 200, body = ApiResponse<SubmissionDetailDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn get_submission_doc() {}

#[utoipa::path(
    patch,
    path = "/api/v1/submissions/{id}",
    tag = "Submissions",
    operation_id = "updateSubmission",
    description = "Requires PermissionAction::Update on ResourceType::Submission. Editable only when form settings allow edits.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Submission id")),
    request_body = UpdateSubmissionRequest,
    responses((status = 200, body = ApiResponse<SubmissionDetailDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn update_submission_doc() {}

#[utoipa::path(
    delete,
    path = "/api/v1/submissions/{id}",
    tag = "Submissions",
    operation_id = "deleteSubmission",
    description = "Requires PermissionAction::Delete on ResourceType::Submission. Soft deletes the submission.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Submission id")),
    responses((status = 200, body = ApiResponse<DeleteResultDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn delete_submission_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/submissions/{id}/score-breakdown",
    tag = "Scoring",
    operation_id = "getSubmissionScoreBreakdown",
    description = "Requires PermissionAction::ViewResults on ResourceType::Submission/Form.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Submission id")),
    responses((status = 200, body = ApiResponse<ScoreBreakdownDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn get_score_breakdown_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/score-templates",
    tag = "Scoring",
    operation_id = "listScoreTemplates",
    description = "Requires PermissionAction::Read on ResourceType::ScoreTemplate. Returns global and organization score templates.",
    security(("bearer_auth" = [])),
    params(ListQuery),
    responses((status = 200, body = ApiListResponse<ScoreTemplateDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn list_score_templates_doc() {}

#[utoipa::path(
    post,
    path = "/api/v1/score-templates",
    tag = "Scoring",
    operation_id = "createScoreTemplate",
    description = "Requires PermissionAction::ManageScoring on ResourceType::ScoreTemplate.",
    security(("bearer_auth" = [])),
    request_body = CreateScoreTemplateRequest,
    responses((status = 201, body = ApiResponse<ScoreTemplateDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn create_score_template_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/score-templates/{id}",
    tag = "Scoring",
    operation_id = "getScoreTemplate",
    description = "Requires PermissionAction::Read on ResourceType::ScoreTemplate.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Score template id")),
    responses((status = 200, body = ApiResponse<ScoreTemplateDto>), (status = 403, body = ApiErrorResponse), (status = 404, body = ApiErrorResponse))
)]
pub async fn get_score_template_doc() {}

#[utoipa::path(
    patch,
    path = "/api/v1/score-templates/{id}",
    tag = "Scoring",
    operation_id = "updateScoreTemplate",
    description = "Requires PermissionAction::ManageScoring on ResourceType::ScoreTemplate.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Score template id")),
    request_body = UpdateScoreTemplateRequest,
    responses((status = 200, body = ApiResponse<ScoreTemplateDto>), (status = 403, body = ApiErrorResponse), (status = 404, body = ApiErrorResponse))
)]
pub async fn update_score_template_doc() {}

#[utoipa::path(
    delete,
    path = "/api/v1/score-templates/{id}",
    tag = "Scoring",
    operation_id = "deleteScoreTemplate",
    description = "Requires PermissionAction::ManageScoring on ResourceType::ScoreTemplate.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Score template id")),
    responses((status = 200, body = ApiResponse<DeleteResultDto>), (status = 403, body = ApiErrorResponse), (status = 404, body = ApiErrorResponse))
)]
pub async fn delete_score_template_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/activities",
    tag = "Activities",
    operation_id = "listActivities",
    description = "Requires Bearer JWT. Returns activities in the caller organization.",
    security(("bearer_auth" = [])),
    params(ListQuery),
    responses((status = 200, body = ApiListResponse<ActivitySummaryDto>), (status = 401, body = ApiErrorResponse))
)]
pub async fn list_activities_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/activities/{id}",
    tag = "Activities",
    operation_id = "getActivity",
    description = "Requires PermissionAction::Read on ResourceType::Activity.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Activity id")),
    responses((status = 200, body = ApiResponse<ActivityDto>), (status = 403, body = ApiErrorResponse), (status = 404, body = ApiErrorResponse))
)]
pub async fn get_activity_doc() {}

#[utoipa::path(
    patch,
    path = "/api/v1/activities/{id}",
    tag = "Activities",
    operation_id = "updateActivity",
    description = "Requires PermissionAction::Update on ResourceType::Activity.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Activity id")),
    request_body = UpdateActivityRequest,
    responses((status = 200, body = ApiResponse<ActivityDto>), (status = 403, body = ApiErrorResponse), (status = 404, body = ApiErrorResponse))
)]
pub async fn update_activity_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/forms/{id}/activity-rules",
    tag = "Activities",
    operation_id = "listActivityRules",
    description = "Requires PermissionAction::Read on ResourceType::Activity for the target form.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id"), ListQuery),
    responses((status = 200, body = ApiListResponse<ActivityRuleDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn list_activity_rules_doc() {}

#[utoipa::path(
    post,
    path = "/api/v1/forms/{id}/activity-rules",
    tag = "Activities",
    operation_id = "createActivityRule",
    description = "Requires PermissionAction::Update on ResourceType::Activity for the target form.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Form id")),
    request_body = CreateActivityRuleRequest,
    responses((status = 201, body = ApiResponse<ActivityRuleDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn create_activity_rule_doc() {}

#[utoipa::path(
    patch,
    path = "/api/v1/activity-rules/{id}",
    tag = "Activities",
    operation_id = "updateActivityRule",
    description = "Requires PermissionAction::Update on ResourceType::Activity.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Activity rule id")),
    request_body = UpdateActivityRuleRequest,
    responses((status = 200, body = ApiResponse<ActivityRuleDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn update_activity_rule_doc() {}

#[utoipa::path(
    delete,
    path = "/api/v1/activity-rules/{id}",
    tag = "Activities",
    operation_id = "deleteActivityRule",
    description = "Requires PermissionAction::Delete on ResourceType::Activity. Soft deletes the activity rule.",
    security(("bearer_auth" = [])),
    params(("id" = Uuid, Path, description = "Activity rule id")),
    responses((status = 200, body = ApiResponse<DeleteResultDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn delete_activity_rule_doc() {}

#[utoipa::path(
    get,
    path = "/api/v1/audit-logs",
    tag = "Audit",
    operation_id = "listAuditLogs",
    description = "Requires PermissionAction::Read on ResourceType::AuditLog.",
    security(("bearer_auth" = [])),
    params(ListQuery),
    responses((status = 200, body = ApiListResponse<AuditLogDto>), (status = 403, body = ApiErrorResponse))
)]
pub async fn list_audit_logs_doc() {}
