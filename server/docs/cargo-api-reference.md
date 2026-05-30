# FeedbackFlow Server Cargo API Reference

This page is the human-readable API contract that appears on the crate landing page when you run:

```bash
cargo doc --no-deps --open
```

The generated OpenAPI/Swagger contract remains the machine-readable source for client generation. This Rustdoc page explains the same API in more detail for engineers: what every endpoint does, what each major request/response field means, which errors can happen, and how clients should react.

Base path:

```text
/api/v1
```

Private endpoints require:

```http
Authorization: Bearer <access_token>
```

Public form endpoints under `/public/forms/...` do not require a Bearer token, but they may require a public access token obtained from `validate-access`.

## Response Envelope

### Single Resource Success

All successful single-resource endpoints return `ApiResponse<T>`.

```json
{
  "success": true,
  "data": {
    "id": "11111111-1111-1111-1111-111111111111"
  },
  "error": null,
  "meta": {}
}
```

| Field | Type | Description |
| --- | --- | --- |
| `success` | `bool` | `true` for successful responses. |
| `data` | `T \| null` | The actual response payload. It is `null` on errors. |
| `error` | `ApiErrorDto \| null` | `null` on success; populated on failure. |
| `meta` | `object` | Additional metadata. Single-resource responses usually use `{}`. |

### List Success

List endpoints return `ApiListResponse<T>`.

```json
{
  "success": true,
  "data": [],
  "error": null,
  "meta": {
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total_items": 0,
      "total_pages": 0,
      "has_next": false,
      "has_previous": false
    }
  }
}
```

| Field | Type | Description |
| --- | --- | --- |
| `data` | `T[]` | The current page of resources. Empty arrays are valid. |
| `meta.pagination.page` | `integer` | Current page number, starting at `1`. |
| `meta.pagination.page_size` | `integer` | Page size. The server clamps it to `1..100`. |
| `meta.pagination.total_items` | `integer` | Total number of matching rows. |
| `meta.pagination.total_pages` | `integer` | Total page count after filtering. |
| `meta.pagination.has_next` | `bool` | Whether another page exists. |
| `meta.pagination.has_previous` | `bool` | Whether a previous page exists. |

### Error Response

All errors return `ApiErrorResponse`.

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": {
      "phone": "Phone must be 6..32 characters."
    }
  },
  "meta": {}
}
```

| Field | Type | Description |
| --- | --- | --- |
| `success` | `bool` | Always `false` for errors. |
| `data` | `null` | Errors never put business data here. |
| `error.code` | `ErrorCode` | Stable, machine-readable error code. Clients should branch on this field, not on `message`. |
| `error.message` | `string` | Short human-readable message. Suitable for logs or user-facing fallback text. |
| `error.details` | `object` | Structured details such as invalid fields, permission context, rate-limit state, or business-rule reason. |
| `meta` | `object` | Reserved for extra metadata. |

## Error Code Catalog

| Code | Common HTTP Status | Meaning | Client Guidance |
| --- | --- | --- | --- |
| `UNAUTHORIZED` | `401` | The request has no valid authentication context. This usually means missing Bearer token, bad credentials, or a token that cannot be accepted. | Redirect to login, clear local auth state, or attempt token refresh when appropriate. |
| `FORBIDDEN` | `403` | The user is authenticated but cannot perform the operation. | Hide or disable the action in the UI. Do not retry automatically. |
| `PERMISSION_DENIED` | `403` | RBAC/ABAC denied the requested action on the resource. | Check role, organization boundary, ownership, resource visibility, and feature-specific permission flags. |
| `VALIDATION_ERROR` | `400` | Request body, query, enum value, string length, or business input validation failed. | Display `details` next to form fields. The user can usually fix and retry. |
| `NOT_FOUND` | `404` | The resource does not exist, was soft-deleted, or is intentionally hidden by access boundaries. | Refresh local lists or show a not-found state. |
| `CONFLICT` | `409` | The operation conflicts with current state or a uniqueness rule, such as duplicate phone/email or invalid workflow transition. | Re-fetch the resource and show the conflict message. |
| `RATE_LIMITED` | `429` | Public access or submission throttling rejected the request. | Respect `retry_after_seconds` when present and avoid immediate retries. |
| `FORM_CLOSED` | `409` | The form is closed and cannot accept new submissions. | Render the form as read-only or show a closed-form message. |
| `FORM_NOT_PUBLISHED` | `409` | The form is not published and cannot be answered publicly or by regular respondents. | Keep users in preview/admin flow until published. |
| `APPROVAL_REQUIRED` | `409` | The requested publish/update workflow requires approval first. | Send the form through `submit-for-approval`. |
| `PUBLIC_PROTECTION_REQUIRED` | `403/409` | Public-link publishing or public submission requires protection settings. | Enable public protection or run the access-validation flow. |
| `PUBLIC_ACCESS_DENIED` | `401/403` | Public form access validation failed. Password, identity code, captcha, verification token, or access token may be missing/invalid. | Ask the user for the required access credential and call `validate-access` again. |
| `INVALID_TOKEN` | `401` | Access, refresh, or public access token is malformed, unknown, revoked, or otherwise invalid. | Discard the token and restart login/refresh/public validation. |
| `TOKEN_EXPIRED` | `401` | Token lifetime has ended. | Use refresh-token flow or request a new public access token. |
| `INTERNAL_SERVER_ERROR` | `500` | Unexpected server/database failure. The response intentionally hides internal details. | Show generic error text and inspect server logs. |
| `SERVICE_UNAVAILABLE` | `503` | A dependent service is temporarily unavailable. | Retry with backoff. |

## Shared List Query

`ListQuery` is reused by most list endpoints.

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `page` | `integer` | `1` | Requested page number. Values below `1` are treated as `1`. |
| `page_size` | `integer` | `20` | Requested page size. The server clamps it to `1..100`. |
| `search` | `string?` | `null` | Optional text search. The searched fields depend on the endpoint. |
| `sort_by` | `string?` | endpoint-specific | Optional sort column. Unsupported values fall back to the endpoint default. |
| `sort_order` | `asc \| desc?` | `asc` | Sort direction. |
| `filters` | `string?` | `null` | Reserved generic filter string for future structured filters. |
| `category` | `string?` | `null` | Category filter, mainly used by forms. |
| `tags` | `string?` | `null` | Tag filter, commonly comma-separated. |

Example:

```http
GET /api/v1/forms?page=1&page_size=20&search=survey&sort_by=created_at&sort_order=desc
Authorization: Bearer <access_token>
```

## Auth API

### `POST /auth/register`

Public phone/password registration. The phone number becomes the primary login identifier. Email is optional profile/contact data and is not used as the login key. The caller may send `organization_id` to join an existing organization or `organization_name` to create/find an organization by name/slug. Sending both organization fields is invalid. Privileged roles cannot self-register.

Request: `RegisterRequest`

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `phone` | `string` | Yes | Primary login identifier. Length: `6..32`. |
| `email` | `string?` | No | Optional contact/profile email. Must be unique when present. |
| `password` | `string` | Yes | Plain password submitted over HTTPS. Length: `8..256`; stored as a hash. |
| `display_name` | `string` | Yes | User-facing display name. Length: `1..160`. |
| `gender` | `string?` | No | Optional profile value normalized by the auth service. |
| `organization_id` | `uuid?` | No | Existing organization to join. Mutually exclusive with `organization_name`. |
| `organization_name` | `string?` | No | Organization name used to create or join by derived slug. |
| `role` | `UserRole?` | No | Requested role. Public self-registration must not request privileged management roles. |

Example request:

```json
{
  "phone": "+989121234567",
  "email": "parent@example.com",
  "password": "StrongPass123",
  "display_name": "Ali Ahmadi",
  "gender": "male",
  "organization_name": "Demo School",
  "role": "parent"
}
```

Example success:

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "11111111-1111-1111-1111-111111111111",
      "organization_id": "22222222-2222-2222-2222-222222222222",
      "phone": "+989121234567",
      "email": "parent@example.com",
      "display_name": "Ali Ahmadi",
      "gender": "male",
      "primary_role": "parent",
      "profile": {
        "phone": "+989121234567",
        "avatar_url": null,
        "locale": null,
        "timezone": null,
        "metadata": {}
      },
      "status": "active",
      "created_at": "2026-05-22T10:00:00Z",
      "updated_at": "2026-05-22T10:00:00Z"
    },
    "organization": {
      "id": "22222222-2222-2222-2222-222222222222",
      "parent_organization_id": null,
      "name": "Demo School",
      "slug": "demo-school",
      "settings": {
        "default_timezone": "UTC",
        "public_forms_enabled": true,
        "default_public_protection_level": "standard",
        "require_audit_for_public_protection_disable": true,
        "metadata": {}
      },
      "created_at": "2026-05-22T10:00:00Z",
      "updated_at": "2026-05-22T10:00:00Z"
    }
  },
  "error": null,
  "meta": {}
}
```

Example error:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "CONFLICT",
    "message": "A user with this phone number already exists",
    "details": {}
  },
  "meta": {}
}
```

Possible errors: `VALIDATION_ERROR`, `FORBIDDEN`, `CONFLICT`, `INTERNAL_SERVER_ERROR`.

### `POST /auth/login`

Authenticates by phone and password. Returns a JWT access token and a rotating refresh token.

Request: `LoginRequest`

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `phone` | `string` | Yes | Login phone number. |
| `password` | `string` | Yes | Plain password. |

Example request:

```json
{
  "phone": "+989121234567",
  "password": "StrongPass123"
}
```

Example success:

```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOi...",
    "refresh_token": "refresh_abc123",
    "token_type": "Bearer",
    "expires_in": 3600,
    "user": {
      "id": "11111111-1111-1111-1111-111111111111",
      "organization_id": "22222222-2222-2222-2222-222222222222",
      "phone": "+989121234567",
      "email": "parent@example.com",
      "display_name": "Ali Ahmadi",
      "gender": "male",
      "primary_role": "parent",
      "profile": {
        "phone": "+989121234567",
        "avatar_url": null,
        "locale": null,
        "timezone": null,
        "metadata": {}
      },
      "status": "active",
      "created_at": "2026-05-22T10:00:00Z",
      "updated_at": "2026-05-22T10:00:00Z"
    }
  },
  "error": null,
  "meta": {}
}
```

Possible errors: `VALIDATION_ERROR`, `UNAUTHORIZED`, `INTERNAL_SERVER_ERROR`.

### `POST /auth/refresh`

Rotates a refresh token and returns a new access token plus a new refresh token.

Request: `RefreshTokenRequest`

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `refresh_token` | `string` | Yes | Current refresh token. Minimum length: `16`. |

Possible errors: `VALIDATION_ERROR`, `INVALID_TOKEN`, `TOKEN_EXPIRED`, `UNAUTHORIZED`.

### `POST /auth/logout`

Revokes the submitted refresh token. Requires Bearer authentication.

Request: `LogoutRequest`

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `refresh_token` | `string` | Yes | Refresh token to revoke. |

Success body: `ApiResponse<LogoutResponse>` where `logged_out=true`.

### `GET /auth/me`

Returns the current user and their effective RBAC/ABAC permissions.

Success body: `ApiResponse<MeResponse>`.

Possible errors: `UNAUTHORIZED`, `INVALID_TOKEN`.

## Users API

### `GET /users`

Lists users manageable by the caller. Manager/Admin can manage Teacher and Student. CEO can manage Teacher, Student, and Manager. SuperAdmin can manage Teacher, Student, Manager, and CEO.

Query: `ListQuery`.

Success body: `ApiListResponse<UserSummaryDto>`.

Possible errors: `UNAUTHORIZED`, `FORBIDDEN`, `PERMISSION_DENIED`.

### `POST /users`

Creates a user from a privileged account. The target role must be creatable by the caller's role and must stay inside the caller's organization unless the caller is SuperAdmin.

Request: `CreateUserRequest`

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `organization_id` | `uuid?` | Sometimes | Target organization. Required when no caller organization can be inferred. Non-SuperAdmin callers cannot create users outside their organization. |
| `phone` | `string` | Yes | Unique login phone. Length: `6..32`. |
| `email` | `string?` | No | Optional unique email. |
| `display_name` | `string` | Yes | Display name. Length: `1..160`. |
| `gender` | `string?` | No | Optional normalized profile value. |
| `password` | `string` | Yes | Initial password. Length: `8..160`. |
| `primary_role` | `UserRole` | Yes | Role assigned to the new user. |
| `profile` | `UserProfileDto?` | No | Optional profile object. If omitted, defaults are generated. |

Possible errors: `VALIDATION_ERROR`, `FORBIDDEN`, `PERMISSION_DENIED`, `CONFLICT`.

### `GET /users/me`

Returns the current user's full profile.

Success body: `ApiResponse<UserDetailDto>`.

### `PATCH /users/me`

Updates the current user's editable profile fields. Phone number changes are intentionally not accepted here because they should go through a verification flow.

Request: `UpdateUserProfileRequest`

| Field | Type | Description |
| --- | --- | --- |
| `display_name` | `string?` | New display name. |
| `email` | `string?` | New optional email. Must be syntactically valid and unique. |
| `gender` | `string?` | Optional normalized profile value. |
| `profile` | `UserProfileDto?` | Replacement profile payload. |

Possible errors: `VALIDATION_ERROR`, `CONFLICT`, `UNAUTHORIZED`.

### `GET /users/{id}`

Returns a user by id after organization-boundary and permission checks.

Path params:

| Param | Type | Description |
| --- | --- | --- |
| `id` | `uuid` | Target user id. |

Success body: `ApiResponse<UserDetailDto>`.

Possible errors: `FORBIDDEN`, `PERMISSION_DENIED`, `NOT_FOUND`.

### `PATCH /users/{id}`

Updates a managed user. The caller must be allowed to manage the target user's current role and assign the requested next role.

Request: `UpdateUserRequest`

| Field | Type | Description |
| --- | --- | --- |
| `phone` | `string?` | New unique phone. |
| `email` | `string?` | New optional unique email. |
| `display_name` | `string?` | New display name. |
| `gender` | `string?` | Optional profile value. |
| `primary_role` | `UserRole?` | New role, if reassignment is allowed. |
| `status` | `string?` | One of `active`, `inactive`, `suspended`. |
| `profile` | `UserProfileDto?` | Replacement profile object. |

Possible errors: `VALIDATION_ERROR`, `FORBIDDEN`, `CONFLICT`, `NOT_FOUND`.

### `GET /users/{id}/subordinates`

Returns direct subordinate users. Regular users can inspect only their own hierarchy; manager-level roles can inspect another user's subordinates.

Success body: `ApiListResponse<SubordinateUserDto>`.

Possible errors: `FORBIDDEN`, `NOT_FOUND`.

## Organizations API

### `GET /organizations/{id}`

Returns organization details if the caller can read the organization inside their boundary.

Success body: `ApiResponse<OrganizationDto>`.

Possible errors: `FORBIDDEN`, `PERMISSION_DENIED`, `NOT_FOUND`.

### `GET /organizations/{id}/roles`

Returns organization roles and default permissions.

Success body: `ApiListResponse<OrganizationRoleDto>`.

### `PATCH /organizations/{id}/role-rules`

Updates role behavior such as form creation, publish approval, scoring changes, approver roles, and allowed/denied field types.

Request: `UpdateRoleRulesRequest`.

Possible errors: `VALIDATION_ERROR`, `FORBIDDEN`, `PERMISSION_DENIED`.

## Permissions API

### `GET /permissions/effective`

Returns the caller's effective permissions after combining role permissions, organization rules, field-type rules, publishing rules, and ABAC context.

Success body: `ApiResponse<EffectivePermissionsDto>`.

### `GET /permissions/field-types`

Returns field type permissions by role.

Success body: `ApiResponse<Vec<FieldTypePermissionDto>>`.

### `PATCH /permissions/field-types`

Updates role-based field type permissions.

Request: `UpdateFieldTypePermissionsRequest`.

### `GET /permissions/publishing-rules`

Returns effective publishing and approval rules for the caller organization.

Success body: `ApiResponse<Vec<PublishingRuleDto>>`.

### `PATCH /permissions/publishing-rules`

Updates direct-publish, approval, allowed publish modes, and public-protection permissions.

Request: `UpdatePublishingRulesRequest`.

## Forms API

### `POST /forms`

Creates a form. The caller must have `create` permission on `form` and must be allowed to use the requested field/scoring configuration.

Request: `CreateFormRequest`

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `title` | `string` | Yes | Form title. Length: `1..255`. |
| `description` | `string?` | No | Human-readable description shown to respondents/admins. |
| `category` | `string?` | No | Optional category used by filtering and dashboards. |
| `tags` | `string[]` | No | Search/filter labels. Defaults to `[]`. |
| `settings` | `FormSettingsDto` | No | Submission behavior, schedule, answer visibility, and guest/anonymous options. |
| `visibility` | `FormVisibilityDto` | No | Who can see and answer the form. Exclusions override inclusions. |
| `scoring_mode` | `ScoringMode?` | No | Scoring mode for this form. |
| `scoring_config` | `object` | No | Form-level scoring config. Defaults to `{}`. |

Example request:

```json
{
  "title": "Parent Satisfaction Survey",
  "description": "Monthly feedback",
  "category": "satisfaction",
  "tags": ["monthly", "parents"],
  "settings": {
    "allow_anonymous_answers": true,
    "one_submission_per_user": true,
    "answers_editable_after_submission": false,
    "start_at": null,
    "end_at": null,
    "max_submissions": null,
    "submission_cooldown_seconds": 30,
    "submission_mode": "single_submission",
    "answer_visibility": "visible_to_creator",
    "guests_can_answer": false,
    "metadata": {}
  },
  "visibility": {
    "mode": "organization",
    "can_see": [],
    "can_answer": [
      {
        "audience_type": "role",
        "id": null,
        "role": "parent",
        "label": "Parents"
      }
    ],
    "cannot_see": [],
    "cannot_answer": [],
    "guest_can_answer": false,
    "anonymous_allowed": true,
    "metadata": {}
  },
  "scoring_mode": "none",
  "scoring_config": {}
}
```

Example success:

```json
{
  "success": true,
  "data": {
    "id": "33333333-3333-3333-3333-333333333333",
    "organization_id": "22222222-2222-2222-2222-222222222222",
    "creator_id": "11111111-1111-1111-1111-111111111111",
    "title": "Parent Satisfaction Survey",
    "description": "Monthly feedback",
    "category": "satisfaction",
    "tags": ["monthly", "parents"],
    "status": "draft",
    "visibility_mode": "organization",
    "publish_mode": "private",
    "settings": {
      "allow_anonymous_answers": true,
      "one_submission_per_user": true,
      "answers_editable_after_submission": false,
      "start_at": null,
      "end_at": null,
      "max_submissions": null,
      "submission_cooldown_seconds": 30,
      "submission_mode": "single_submission",
      "answer_visibility": "visible_to_creator",
      "guests_can_answer": false,
      "metadata": {}
    },
    "visibility": {
      "mode": "organization",
      "can_see": [],
      "can_answer": [],
      "cannot_see": [],
      "cannot_answer": [],
      "guest_can_answer": false,
      "anonymous_allowed": true,
      "metadata": {}
    },
    "public_protection": {
      "level": "standard",
      "strategies": ["ip", "token", "fingerprint"],
      "ip_limit_per_minute": 20,
      "token_limit_per_day": 5,
      "access_limit_per_minute": 60,
      "cooldown_seconds": 30,
      "max_submissions_per_ip": 20,
      "max_submissions_per_fingerprint": 5,
      "captcha_enabled": false,
      "email_verification_enabled": false,
      "phone_verification_enabled": false,
      "disabled_limits": [],
      "metadata": {}
    },
    "scoring_mode": "none",
    "scoring_config": {},
    "fields": [],
    "public_token": null,
    "approved_at": null,
    "published_at": null,
    "closed_at": null,
    "created_at": "2026-05-22T10:00:00Z",
    "updated_at": "2026-05-22T10:00:00Z"
  },
  "error": null,
  "meta": {}
}
```

Example permission error:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "PERMISSION_DENIED",
    "message": "Permission denied",
    "details": {
      "action": "create",
      "resource_type": "form"
    }
  },
  "meta": {}
}
```

Possible errors: `VALIDATION_ERROR`, `FORBIDDEN`, `PERMISSION_DENIED`, `INTERNAL_SERVER_ERROR`.

### `GET /forms`

Lists forms visible to the caller according to organization and visibility rules.

Query: `ListQuery`.

Success body: `ApiListResponse<FormSummaryDto>`.

### `GET /forms/tags`

Returns known form tags, optionally filtered by search.

Success body: `ApiResponse<Vec<String>>`.

### `GET /forms/{id}`

Returns full form details including fields, visibility, settings, public protection, scoring config, and workflow timestamps.

Success body: `ApiResponse<FormDetailDto>`.

Possible errors: `FORBIDDEN`, `PERMISSION_DENIED`, `NOT_FOUND`.

### `PATCH /forms/{id}`

Updates form metadata, settings, visibility, or scoring configuration.

Request: `UpdateFormRequest`.

Possible errors: `VALIDATION_ERROR`, `FORBIDDEN`, `CONFLICT`, `NOT_FOUND`.

### `DELETE /forms/{id}`

Soft-deletes a form.

Success body: `ApiResponse<DeleteResultDto>`.

### Form Workflow Endpoints

| Endpoint | Request | Description | Common Errors |
| --- | --- | --- | --- |
| `POST /forms/{id}/duplicate` | `DuplicateFormRequest` | Creates a new form copied from an existing form. Can include fields, visibility, and activity rules. | `FORBIDDEN`, `NOT_FOUND` |
| `POST /forms/{id}/submit-for-approval` | `SubmitForApprovalRequest` | Moves a draft/updated form into approval flow. | `CONFLICT`, `APPROVAL_REQUIRED` |
| `POST /forms/{id}/approve` | `ApproveFormRequest` | Approves a pending form. Can publish immediately when `publish_after_approval=true`. | `FORBIDDEN`, `CONFLICT` |
| `POST /forms/{id}/reject` | `RejectFormRequest` | Rejects a pending form. `reason` is required. | `VALIDATION_ERROR`, `FORBIDDEN` |
| `POST /forms/{id}/publish` | `PublishFormRequest` | Publishes or schedules a form. Public links may require protection settings. | `FORBIDDEN`, `APPROVAL_REQUIRED`, `PUBLIC_PROTECTION_REQUIRED`, `CONFLICT` |
| `POST /forms/{id}/close` | `CloseFormRequest` | Closes a form so it no longer accepts submissions. | `FORBIDDEN`, `CONFLICT` |
| `POST /forms/{id}/archive` | `ArchiveFormRequest` | Archives a form. | `FORBIDDEN`, `CONFLICT` |

### Access Codes and Public Protection

| Endpoint | Request/Response | Description |
| --- | --- | --- |
| `GET /forms/{id}/access-codes` | `ApiResponse<FormAccessCodesResponse>` | Returns metadata for shared password and identity codes. Secrets are never returned. |
| `PUT /forms/{id}/access-codes` | `SetFormAccessCodesRequest` | Replaces identity codes and optionally rotates or clears the shared form password. |
| `PATCH /forms/{id}/public-protection` | `UpdatePublicProtectionRequest` | Updates public protection. Disabling protection is audited. |

## Fields API

Fields are managed under forms:

| Endpoint | Description |
| --- | --- |
| `POST /forms/{id}/fields` | Creates a field. |
| `PATCH /forms/{id}/fields/{field_id}` | Updates a field. |
| `DELETE /forms/{id}/fields/{field_id}` | Soft-deletes a field. |

Request fields for `CreateFormFieldRequest` and `UpdateFormFieldRequest`:

| JSON Field | Rust Field | Type | Description |
| --- | --- | --- | --- |
| `type` | `field_type` | `FieldType` | Field/input type. Serialized as `type` in JSON. |
| `label` | `label` | `string` | User-facing field label. |
| `description` | `description` | `string?` | Optional helper text. |
| `placeholder` | `placeholder` | `string?` | Placeholder text for text-like inputs. |
| `required` | `required` | `bool` | Whether an answer is required. |
| `order_index` | `order_index` | `integer` | Sort/display order inside the form. |
| `config` | `config` | `FieldConfigDto` | Type-specific options, ranges, defaults, file constraints, and static content. |
| `validation` | `validation` | `FieldValidationDto` | Input validation rules. |
| `visibility_conditions` | `visibility_conditions` | `ConditionalLogicRuleDto[]` | Conditional display/jump logic. |
| `scoring_config` | `scoring_config` | `FieldScoringConfigDto` | Field-level scoring rules and weights. |
| `permissions` | `permissions` | `FieldPermissionConfigDto` | Role-based field visibility/edit/answer restrictions. |

Example request:

```json
{
  "type": "single_choice",
  "label": "How satisfied are you?",
  "description": "Choose one option.",
  "placeholder": null,
  "required": true,
  "order_index": 1,
  "config": {
    "options": [
      {
        "id": "good",
        "label": "Good",
        "value": "good",
        "order_index": 1,
        "score": 5,
        "metadata": {}
      },
      {
        "id": "bad",
        "label": "Bad",
        "value": "bad",
        "order_index": 2,
        "score": 0,
        "metadata": {}
      }
    ],
    "rows": [],
    "columns": [],
    "min": null,
    "max": null,
    "step": null,
    "default_value": null,
    "accept_mime_types": null,
    "max_file_size_mb": null,
    "page_title": null,
    "static_text": null,
    "metadata": {}
  },
  "validation": {
    "min_length": null,
    "max_length": null,
    "regex": null,
    "min_number": null,
    "max_number": null,
    "min_items": null,
    "max_items": null,
    "required_message": "Please choose one option.",
    "custom": {}
  },
  "visibility_conditions": [],
  "scoring_config": {
    "enabled": true,
    "max_score": 5,
    "weight": 1,
    "option_scores": {
      "good": 5,
      "bad": 0
    },
    "rules": [],
    "categories": [],
    "metadata": {}
  },
  "permissions": {
    "visible_to_roles": [],
    "editable_by_roles": [],
    "answerable_by_roles": ["parent"],
    "hidden_from_roles": [],
    "metadata": {}
  }
}
```

Possible errors: `VALIDATION_ERROR`, `FORBIDDEN`, `PERMISSION_DENIED`, `NOT_FOUND`.

## Submissions API

### `POST /forms/{id}/submissions`

Creates an authenticated submission. The form must be published, open, visible, and answerable by the caller.

Request: `CreateSubmissionRequest`

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `answers` | `AnswerInputDto[]` | Yes | At least one answer. Each answer targets a `field_id`. |
| `anonymous` | `bool?` | No | Requests anonymous submission. Honored only if the form allows anonymous answers. |
| `fingerprint_token` | `string?` | No | Device/browser fingerprint token used by anti-abuse rules. |
| `respondent_name` | `string?` | No | Optional respondent label. |

Example request:

```json
{
  "anonymous": false,
  "fingerprint_token": "fp_abc",
  "respondent_name": "Ali Ahmadi",
  "answers": [
    {
      "field_id": "55555555-5555-5555-5555-555555555555",
      "value": "good",
      "metadata": {}
    }
  ]
}
```

Success body: `ApiResponse<SubmissionDetailDto>`.

Possible errors: `VALIDATION_ERROR`, `PERMISSION_DENIED`, `FORM_NOT_PUBLISHED`, `FORM_CLOSED`, `CONFLICT`, `NOT_FOUND`.

### `GET /forms/{id}/submissions`

Lists submissions for a form. Requires result-viewing permission.

Success body: `ApiListResponse<SubmissionSummaryDto>`.

### `GET /submissions/{id}`

Returns one submission and its answers.

Success body: `ApiResponse<SubmissionDetailDto>`.

### `PATCH /submissions/{id}`

Replaces submission answers. Allowed only when the form settings permit editing after submission.

Request: `UpdateSubmissionRequest`.

### `DELETE /submissions/{id}`

Soft-deletes a submission.

Success body: `ApiResponse<DeleteResultDto>`.

### `GET /submissions/{id}/score-breakdown`

Returns detailed scoring output for a submission.

Success body: `ApiResponse<ScoreBreakdownDto>`.

## Public Forms API

### `GET /public/forms/{public_token}`

Returns a published public-link form without Bearer authentication.

Path params:

| Param | Type | Description |
| --- | --- | --- |
| `public_token` | `string` | Public form token. |

Success body: `ApiResponse<PublicFormDto>`.

Possible errors: `NOT_FOUND`, `FORM_NOT_PUBLISHED`, `FORM_CLOSED`, `CONFLICT`.

### `POST /public/forms/{public_token}/validate-access`

Validates public access controls: form password, identity code, fingerprint, captcha, email verification, phone verification, and public rate limits. When access is allowed, the endpoint returns a short-lived `access_token`.

Request: `ValidatePublicFormAccessRequest`

| Field | Type | Description |
| --- | --- | --- |
| `respondent_mode` | `string?` | Requested public respondent mode, such as `guest`, `shared_password`, or `identity_code`. |
| `form_password` | `string?` | Shared form password, if required. |
| `identity_code` | `string?` | Labeled identity/access code, if enabled. |
| `fingerprint_token` | `string?` | Browser/device fingerprint token. |
| `captcha_token` | `string?` | Captcha provider token when captcha is enabled. |
| `email_verification_token` | `string?` | Email verification proof when enabled. |
| `phone_verification_token` | `string?` | Phone verification proof when enabled. |

Example success:

```json
{
  "success": true,
  "data": {
    "allowed": true,
    "reason": null,
    "access_token": "public_access_abc123",
    "respondent_mode": "identity_code",
    "identity_label": "Parent A",
    "rate_limit": {
      "allowed": true,
      "limits": [
        {
          "strategy": "ip",
          "limit": 20,
          "remaining": 19,
          "reset_at": "2026-05-22T10:01:00Z"
        }
      ],
      "retry_after_seconds": null
    }
  },
  "error": null,
  "meta": {}
}
```

Possible errors: `PUBLIC_ACCESS_DENIED`, `RATE_LIMITED`, `NOT_FOUND`, `FORM_CLOSED`.

### `POST /public/forms/{public_token}/submissions`

Creates a public submission. If public protection requires validation, `public_access_token` is required and must be valid.

Request: `PublicSubmissionRequest`

| Field | Type | Description |
| --- | --- | --- |
| `answers` | `AnswerInputDto[]` | Submitted answers. |
| `respondent_mode` | `string?` | Public respondent mode. |
| `anonymous` | `bool?` | Anonymous submission request. |
| `fingerprint_token` | `string?` | Fingerprint token for anti-abuse/rate limits. |
| `public_access_token` | `string?` | Token returned by `validate-access`. |
| `captcha_token` | `string?` | Captcha token when needed. |
| `respondent_name` | `string?` | Optional respondent label. |

Success body: `ApiResponse<PublicSubmissionResponse>` with HTTP `201`.

Possible errors: `VALIDATION_ERROR`, `PUBLIC_ACCESS_DENIED`, `RATE_LIMITED`, `FORM_CLOSED`, `FORM_NOT_PUBLISHED`.

## Scoring API

| Endpoint | Request | Response | Description |
| --- | --- | --- | --- |
| `GET /score-templates` | `ListQuery` | `ApiListResponse<ScoreTemplateDto>` | Lists global and organization-specific score templates. |
| `POST /score-templates` | `CreateScoreTemplateRequest` | `ApiResponse<ScoreTemplateDto>` | Creates a score template. Requires scoring management permission. |
| `GET /score-templates/{id}` | path `id` | `ApiResponse<ScoreTemplateDto>` | Returns one template. |
| `PATCH /score-templates/{id}` | `UpdateScoreTemplateRequest` | `ApiResponse<ScoreTemplateDto>` | Updates a template. |
| `DELETE /score-templates/{id}` | path `id` | `ApiResponse<DeleteResultDto>` | Deletes or deactivates a template. |

Possible errors: `VALIDATION_ERROR`, `FORBIDDEN`, `PERMISSION_DENIED`, `NOT_FOUND`.

## Activities API

| Endpoint | Request | Response | Description |
| --- | --- | --- | --- |
| `GET /activities` | `ListQuery` | `ApiListResponse<ActivitySummaryDto>` | Lists activities in the caller organization. |
| `GET /activities/{id}` | path `id` | `ApiResponse<ActivityDto>` | Returns a single activity. |
| `PATCH /activities/{id}` | `UpdateActivityRequest` | `ApiResponse<ActivityDto>` | Updates title, description, status, assignee, due date, or metadata. |
| `GET /forms/{id}/activity-rules` | `ListQuery` | `ApiListResponse<ActivityRuleDto>` | Lists automation rules for a form. |
| `POST /forms/{id}/activity-rules` | `CreateActivityRuleRequest` | `ApiResponse<ActivityRuleDto>` | Creates an automation rule. |
| `PATCH /activity-rules/{id}` | `UpdateActivityRuleRequest` | `ApiResponse<ActivityRuleDto>` | Updates an automation rule. |
| `DELETE /activity-rules/{id}` | path `id` | `ApiResponse<DeleteResultDto>` | Soft-deletes an automation rule. |

## Analytics API

### `GET /dashboard/analytics`

Returns organization-level dashboard metrics: forms, published forms, users, submissions, valid submissions, participation rate, date series, demographic distributions, respondent-mode distribution, access-code distribution, and top forms.

Success body: `ApiResponse<DashboardAnalyticsDto>`.

### `GET /forms/{id}/analytics`

Returns form-level analytics: submission counts, completion rate, score analytics, per-field summaries, respondent modes, gender distribution, role distribution, and access-code distribution.

Success body: `ApiResponse<FormAnalyticsDto>`.

## Audit API

### `GET /audit-logs`

Lists audit log entries. Requires permission to read audit logs.

Success body: `ApiListResponse<AuditLogDto>`.

Possible errors: `FORBIDDEN`, `PERMISSION_DENIED`.

## Detailed Concept Reference

This section explains fields whose meaning is not obvious from the type name alone. Client code should treat these rules as part of the contract, because they affect routing, access control, public links, form workflows, and anti-abuse behavior.

### Organization Identity and `slug`

An organization has both a human name and a stable URL-safe identifier.

| Field | Meaning | Practical Behavior |
| --- | --- | --- |
| `OrganizationDto.id` | Internal UUID primary key. | Use this for API calls, database relations, permissions, and ownership checks. |
| `OrganizationDto.name` | Human-readable organization name. | Can contain spaces, mixed case, and display formatting. Use it in UI labels. |
| `OrganizationDto.slug` | URL-safe normalized organization identifier. | Used when an organization must be referenced by a readable key instead of UUID, for example during registration by `organization_name`, future subdomain flows, invite links, or public URLs. |
| `OrganizationDto.parent_organization_id` | Optional parent organization. | Enables hierarchical organization structures such as network, school group, branch, department, or campus. `null` means this organization is a top-level organization. |

`slug` is not just a display field. It is a canonical, machine-friendly version of the organization name. A name such as `Demo School` may become `demo-school`. The slug should be unique in the scope enforced by the database/service. Clients should not assume they can freely edit it unless a dedicated endpoint exists.

Client guidance:

| Situation | Use |
| --- | --- |
| Calling organization APIs | Use `id`. |
| Showing the organization in UI | Use `name`. |
| Building readable links or matching registration organization names | Use `slug` only when the backend/API contract explicitly asks for it. |
| Comparing organizations for authorization | Use `id`, never `name` or `slug`. |

### Organization Settings

`OrganizationSettingsDto` controls default behavior for forms and public access inside an organization.

| Field | Detailed Explanation |
| --- | --- |
| `default_timezone` | The timezone used when the organization has date/time behavior and a user-specific timezone is not available. It should be an IANA value such as `UTC` or `Asia/Tehran`. It affects display and interpretation of scheduled publishing, form start/end dates, and analytics grouping when the server or client applies organization-local time. |
| `public_forms_enabled` | Global switch for public-link forms in the organization. If `false`, users should not be offered public publishing UI, even if a role otherwise has publish permissions. |
| `default_public_protection_level` | The protection level applied by default when a form is published publicly and the form does not provide a custom `public_protection`. See the protection level table below. |
| `require_audit_for_public_protection_disable` | When `true`, disabling or weakening public protection is treated as a sensitive action and should create an audit trail. Clients should require a visible reason/comment when the user disables public protection. |
| `metadata` | Flexible extension object. Use it for organization-specific flags that are not yet first-class fields. Do not put secrets here. |

### Public Protection Levels

`PublicProtectionLevel` is the high-level policy for public forms. The exact enforcement is controlled by `PublicProtectionSettingsDto`, but the level communicates the expected security posture.

| Level | Meaning | Typical Use | Client Behavior |
| --- | --- | --- | --- |
| `none` | No public protection beyond basic form availability checks. | Internal testing or intentionally open, low-risk forms. | Show a warning before publishing public links. This level may be blocked by permissions or organization policy. |
| `basic` | Minimal throttling/protection. | Low-risk public forms where ease of access matters more than strict abuse prevention. | Ask only for required lightweight fields. |
| `standard` | Balanced default protection. | Normal public surveys and feedback forms. | Recommended default. Usually includes IP/token/fingerprint limits. |
| `strict` | Stronger protection and lower tolerance for repeated attempts. | High-value, sensitive, graded, or abuse-prone public forms. | Expect more validation steps and stricter rate-limit messages. |
| `custom` | The form explicitly defines its own strategies and limits. | Advanced organization-specific policies. | Render the specific enabled strategies and numeric limits instead of assuming a preset. |

Important: `level` describes the policy tier, while `strategies` and numeric fields describe enforcement. For example, a `custom` policy may enable `ip` and `captcha` but disable `fingerprint`.

### Public Protection Settings

`PublicProtectionSettingsDto` defines how public form access and submissions are protected.

| Field | Detailed Explanation |
| --- | --- |
| `level` | Overall policy tier. Use it for UI presets and warnings. |
| `strategies` | Enabled anti-abuse strategies. The server may evaluate one or more strategies before allowing access or submission. |
| `ip_limit_per_minute` | Maximum public requests/submissions allowed per IP per minute. `null` means the limit is not configured at this layer. |
| `token_limit_per_day` | Maximum usage allowed for a public access token per day. Helps prevent a valid token from being reused indefinitely. |
| `access_limit_per_minute` | Maximum access-validation attempts per minute. Helps protect password/code/captcha validation endpoints. |
| `cooldown_seconds` | Minimum wait time between repeated attempts by the same tracked subject. |
| `max_submissions_per_ip` | Total public submissions allowed from one IP over the configured tracking window. |
| `max_submissions_per_fingerprint` | Total public submissions allowed from one browser/device fingerprint. |
| `captcha_enabled` | Requires a captcha token during validation/submission. The current DTO stores the token; provider verification is handled by service logic. |
| `email_verification_enabled` | Requires proof that the respondent controls an email address, represented by `email_verification_token`. |
| `phone_verification_enabled` | Requires proof that the respondent controls a phone number, represented by `phone_verification_token`. |
| `disabled_limits` | Strategies explicitly disabled even if the selected `level` would normally enable them. Useful for exceptions. |
| `metadata` | Extension object for provider-specific or organization-specific protection configuration. Do not store raw secrets. |

### Rate Limit Strategies

| Strategy | What It Tracks | What It Prevents |
| --- | --- | --- |
| `ip` | Request source IP. | High-volume submissions from the same network address. |
| `user` | Authenticated user id. | Repeated authenticated actions by the same account. |
| `token` | Public access token or similar issued token. | Reuse or sharing of a validated access token. |
| `fingerprint` | Browser/device fingerprint token supplied by client. | Repeated attempts from the same browser/device even when IP changes. |
| `captcha` | Captcha challenge result. | Automated bots and scripted access attempts. |
| `combined` | Multiple signals together. | Cases where no single signal is reliable enough alone. |

### Form Visibility Rules

`FormVisibilityDto` decides who can see a form and who can answer it. Visibility is evaluated separately from workflow state. A user may be allowed by visibility but still blocked because the form is draft, closed, archived, unpublished, outside its schedule, or missing required public access validation.

| Field | Detailed Explanation |
| --- | --- |
| `mode` | The main visibility model. It is a coarse preset such as private, organization-wide, role-based, subordinate-only, or public-link. |
| `can_see` | Inclusion rules for users/roles/groups that may view the form. |
| `can_answer` | Inclusion rules for users/roles/groups that may submit answers. Seeing a form does not automatically mean answering is allowed. |
| `cannot_see` | Exclusion rules for viewing. These override `can_see`. |
| `cannot_answer` | Exclusion rules for answering. These override `can_answer`. |
| `guest_can_answer` | Allows unauthenticated respondents, normally through public form flows. |
| `anonymous_allowed` | Allows answers to be stored without exposing the respondent identity to viewers, subject to server-side rules. |
| `metadata` | Extension object for client-specific targeting rules. |

Evaluation guidance:

1. Check workflow state: draft/pending forms are not generally answerable.
2. Check organization and ownership boundary.
3. Apply visibility inclusions.
4. Apply exclusions last; `cannot_*` wins over `can_*`.
5. For public forms, apply public protection and rate limits.

### Publish Modes vs Visibility Modes

`PublishMode` describes how a form is published. `VisibilityMode` describes who can see or answer it. They often align, but they are not identical.

| Concept | Example | Explanation |
| --- | --- | --- |
| `publish_mode = private` | Draft/internal form | The form is not broadly published. Visibility may still contain draft targeting data. |
| `publish_mode = organization` | Organization-wide survey | Published inside the organization. |
| `publish_mode = subordinates` | Manager asks direct reports | Published to a hierarchy boundary. |
| `publish_mode = role_based` | Parents only | Published to selected roles. |
| `publish_mode = public_link` | Anonymous public feedback link | Published through a tokenized public URL and may require public protection. |

### Form Status Workflow

| Status | Meaning | Typical Allowed Next Steps |
| --- | --- | --- |
| `draft` | Editable working version. Not generally answerable. | Update, duplicate, submit for approval, publish if direct publish is allowed. |
| `pending_review` | Waiting for approval. | Approve or reject. |
| `rejected` | Approval was denied. | Edit and resubmit. |
| `approved` | Approved but not necessarily published. | Publish or schedule. |
| `scheduled` | Publication is planned for a future time. | Wait, update schedule if allowed, or cancel/change. |
| `published` | Live and answerable if visibility/settings allow. | Close, archive, collect submissions. |
| `closed` | No longer accepts submissions. | Archive or inspect results. |
| `archived` | Removed from active workflows. | Usually read-only. |

### Access Codes

Public forms may use two kinds of access credentials.

| Type | Purpose | Returned By API? |
| --- | --- | --- |
| Shared form password | One shared secret for a form. Anyone with the password can pass that gate. | Metadata is returned, but the raw password is never returned. |
| Identity code | A labeled code assigned to a person/group/respondent bucket. It can identify the respondent label without requiring a user account. | Metadata and label are returned, but the raw code is never returned. |

`FormAccessCodeInputDto.code` is write-only in practice. The API accepts it when setting codes, hashes/stores it internally, and later returns only `FormAccessCodeDto` metadata.

### `metadata` Fields

Many DTOs include `metadata: object`. These fields are intentionally flexible extension points.

Rules for clients:

| Rule | Reason |
| --- | --- |
| Treat unknown keys as forward-compatible. | The backend or another client may add keys later. |
| Do not store secrets in metadata. | Metadata may be returned to clients or audit logs. |
| Namescape client-owned keys. | Use keys like `mobile_app`, `web_admin`, or `integration_x` to avoid collisions. |
| Do not rely on metadata for authorization. | Permissions must come from explicit fields and server checks. |

## DTO Field Reference

### Auth DTOs

| DTO | Field | Description |
| --- | --- | --- |
| `RegisterResponse` | `user` | Created user. |
| `RegisterResponse` | `organization` | Organization joined or created, if applicable. |
| `LoginResponse` | `access_token` | JWT used in Bearer authentication. |
| `LoginResponse` | `refresh_token` | Rotating token used to obtain new access tokens. |
| `LoginResponse` | `token_type` | Usually `Bearer`. |
| `LoginResponse` | `expires_in` | Access token lifetime in seconds. |
| `LoginResponse` | `user` | Authenticated user profile. |
| `MeResponse` | `user` | Current user. |
| `MeResponse` | `effective_permissions` | Effective permission model for the user. |

### User DTOs

| DTO | Field | Description |
| --- | --- | --- |
| `UserSummaryDto` | `id` | User id. |
| `UserSummaryDto` | `organization_id` | User organization or `null`. |
| `UserSummaryDto` | `phone` | Primary login phone. |
| `UserSummaryDto` | `email` | Optional contact email. |
| `UserSummaryDto` | `display_name` | Display name. |
| `UserSummaryDto` | `gender` | Optional profile gender value. |
| `UserSummaryDto` | `primary_role` | Main role. |
| `UserSummaryDto` | `status` | Account status: `active`, `inactive`, or `suspended`. |
| `UserProfileDto` | `phone` | Profile phone mirror/display value. |
| `UserProfileDto` | `avatar_url` | Avatar image URL. |
| `UserProfileDto` | `locale` | Locale such as `fa-IR` or `en-US`. |
| `UserProfileDto` | `timezone` | Time zone such as `Asia/Tehran`. |
| `UserProfileDto` | `metadata` | Flexible client/application metadata. |
| `UserDetailDto` | `profile` | Full profile object. |
| `UserDetailDto` | `created_at`, `updated_at` | Creation and last update timestamps. |
| `SubordinateUserDto` | `user` | Subordinate user summary. |
| `SubordinateUserDto` | `relationship_type` | Relationship name. |
| `SubordinateUserDto` | `depth` | Hierarchy depth. Current direct relationships usually use `1`. |

### Organization and Permission DTOs

| DTO | Field | Description |
| --- | --- | --- |
| `OrganizationSettingsDto` | `default_timezone` | Default organization time zone. |
| `OrganizationSettingsDto` | `public_forms_enabled` | Whether public forms are allowed. |
| `OrganizationSettingsDto` | `default_public_protection_level` | Default protection level for public forms. |
| `OrganizationSettingsDto` | `require_audit_for_public_protection_disable` | Whether disabling public protection must be audited. |
| `OrganizationDto` | `id` | Organization id. |
| `OrganizationDto` | `parent_organization_id` | Optional parent organization. |
| `OrganizationDto` | `name`, `slug` | Human name and URL-safe slug. |
| `OrganizationRoleDto` | `name` | System role enum. |
| `OrganizationRoleDto` | `display_name` | Human-readable role label. |
| `OrganizationRoleDto` | `is_system` | Whether the role is built in. |
| `OrganizationRoleDto` | `default_permissions` | Default permission actions. |
| `RoleRuleDto` | `can_create_forms`, `can_publish_forms` | Form creation/publishing capability. |
| `RoleRuleDto` | `requires_approval_to_publish` | Whether publish requires approval. |
| `RoleRuleDto` | `two_step_approval_required` | Whether two approvals are required. |
| `RoleRuleDto` | `can_change_scoring` | Whether the role can edit scoring. |
| `RoleRuleDto` | `approver_roles` | Roles allowed to approve. |
| `RoleRuleDto` | `allowed_field_types`, `denied_field_types` | Field type allow/deny lists. |
| `EffectivePermissionsDto` | `actions`, `resources`, `field_types` | Final allowed actions/resources/field types. |
| `EffectivePermissionsDto` | `publishing_rules` | Effective publish/approval rules. |
| `EffectivePermissionsDto` | `can_manage_permissions`, `can_manage_scoring`, `can_manage_public_protection` | High-level feature permissions. |
| `EffectivePermissionsDto` | `abac_context` | Attribute-based access context used by the permission engine. |

### Form DTOs

| DTO | Field | Description |
| --- | --- | --- |
| `AudienceRuleDto` | `audience_type` | Target audience type: user, role, group, class, department, organization, or public. |
| `AudienceRuleDto` | `id` | Target id when the audience type has one. |
| `AudienceRuleDto` | `role` | Target role for role-based audiences. |
| `AudienceRuleDto` | `label` | Display label. |
| `FormSettingsDto` | `allow_anonymous_answers` | Whether answers may be anonymous. |
| `FormSettingsDto` | `one_submission_per_user` | Whether each authenticated user is limited to one submission. |
| `FormSettingsDto` | `answers_editable_after_submission` | Whether submissions can be edited later. |
| `FormSettingsDto` | `start_at`, `end_at` | Availability window. |
| `FormSettingsDto` | `max_submissions` | Global submission cap. |
| `FormSettingsDto` | `submission_cooldown_seconds` | Minimum time between submissions. |
| `FormSettingsDto` | `submission_mode` | Single, multiple, editable, or anonymous submission mode. |
| `FormSettingsDto` | `answer_visibility` | Who can view answers. |
| `FormSettingsDto` | `guests_can_answer` | Whether guest respondents can answer. |
| `FormVisibilityDto` | `mode` | Main visibility strategy. |
| `FormVisibilityDto` | `can_see`, `can_answer` | Inclusion rules. |
| `FormVisibilityDto` | `cannot_see`, `cannot_answer` | Exclusion rules; these override inclusions. |
| `FormVisibilityDto` | `guest_can_answer`, `anonymous_allowed` | Public/anonymous answer flags. |
| `PublicProtectionSettingsDto` | `level` | Overall public protection level. |
| `PublicProtectionSettingsDto` | `strategies` | Enabled rate-limit/protection strategies. |
| `PublicProtectionSettingsDto` | `ip_limit_per_minute`, `token_limit_per_day`, `access_limit_per_minute` | Rate limits. |
| `PublicProtectionSettingsDto` | `cooldown_seconds` | Cooldown between attempts. |
| `PublicProtectionSettingsDto` | `captcha_enabled`, `email_verification_enabled`, `phone_verification_enabled` | Additional verification gates. |
| `FormAccessCodeDto` | `code_type` | Shared password or identity-code type. |
| `FormAccessCodeDto` | `label` | Human label. The secret itself is never returned. |
| `FormAccessCodeDto` | `enabled` | Whether this access credential is active. |
| `FormSummaryDto` | `status`, `publish_mode`, `visibility_mode` | Workflow and exposure state. |
| `FormSummaryDto` | `submissions_count` | Submission count summary. |
| `FormDetailDto` | `fields` | Full field list. |
| `FormDetailDto` | `approved_at`, `published_at`, `closed_at` | Workflow timestamps. |

### Field DTOs

| DTO | Field | Description |
| --- | --- | --- |
| `FieldOptionDto` | `id` | Stable option id used by answers and scoring maps. |
| `FieldOptionDto` | `label` | Display text. |
| `FieldOptionDto` | `value` | Stored JSON value. |
| `FieldOptionDto` | `order_index` | Display order. |
| `FieldOptionDto` | `score` | Optional score for this option. |
| `FieldConfigDto` | `options` | Choice/dropdown/rating options. |
| `FieldConfigDto` | `rows`, `columns` | Matrix field rows and columns. |
| `FieldConfigDto` | `min`, `max`, `step` | Numeric/range constraints. |
| `FieldConfigDto` | `default_value` | Default answer value. |
| `FieldConfigDto` | `accept_mime_types`, `max_file_size_mb` | File upload restrictions. |
| `FieldConfigDto` | `page_title`, `static_text` | Content for page/section/static fields. |
| `FieldValidationDto` | `min_length`, `max_length`, `regex` | Text validation. |
| `FieldValidationDto` | `min_number`, `max_number` | Numeric validation. |
| `FieldValidationDto` | `min_items`, `max_items` | Selection/file count validation. |
| `FieldValidationDto` | `required_message` | Custom required-field message. |
| `ConditionalLogicRuleDto` | `mode` | How conditions are combined, such as all/any. |
| `ConditionalLogicRuleDto` | `action` | What to do when conditions match. |
| `ConditionalLogicRuleDto` | `conditions` | Source field comparisons. |
| `ConditionalLogicRuleDto` | `target_field_ids`, `target_page_index` | Affected fields/page. |
| `FieldScoringConfigDto` | `enabled`, `max_score`, `weight` | Scoring activation and weighting. |
| `FieldScoringConfigDto` | `option_scores`, `rules`, `categories` | Option/rule/category scoring data. |
| `FieldPermissionConfigDto` | `visible_to_roles`, `editable_by_roles`, `answerable_by_roles`, `hidden_from_roles` | Role-specific field access. |

### Submission and Public DTOs

| DTO | Field | Description |
| --- | --- | --- |
| `AnswerInputDto` | `field_id` | Field being answered. |
| `AnswerInputDto` | `value` | JSON answer value. Shape depends on field type. |
| `AnswerInputDto` | `metadata` | Optional answer metadata. |
| `AnswerDto` | `id`, `submission_id`, `created_at` | Stored answer identity and timestamp. |
| `SubmissionScoreDto` | `total_score`, `max_score`, `percentage_score`, `category_label` | Submission score summary. |
| `SubmissionSummaryDto` | `respondent_user_id`, `access_code_id`, `respondent_mode`, `respondent_label` | Respondent identity context. |
| `SubmissionSummaryDto` | `anonymous`, `valid`, `submitted_at` | Submission state. |
| `SubmissionDetailDto` | `answers`, `score`, `updated_at` | Full submission detail. |
| `PublicFormDto` | `settings`, `visibility`, `public_protection`, `fields`, `access_policy` | Public form rendering and access data. |
| `PublicFormAccessPolicyDto` | `respondent_modes` | Allowed public respondent modes. |
| `PublicFormAccessPolicyDto` | `requires_form_password`, `identity_codes_enabled`, `public_access_validation_required` | Public access requirements. |
| `ValidatePublicFormAccessResponse` | `allowed`, `reason`, `access_token`, `respondent_mode`, `identity_label`, `rate_limit` | Access validation result. |
| `PublicSubmissionResponse` | `submission`, `message` | Created submission plus user-facing message. |

### Scoring, Activity, Analytics, Audit, and Rate Limit DTOs

| DTO | Field | Description |
| --- | --- | --- |
| `ScoreRuleDto` | `rule_type`, `min`, `max`, `value`, `score`, `weight`, `formula` | One scoring rule. |
| `ScoreCategoryDto` | `min_percentage`, `max_percentage`, `color`, `description` | Score category/range label. |
| `ScoreTemplateDto` | `organization_id`, `field_type`, `scoring_mode`, `config`, `is_default` | Reusable scoring configuration. |
| `FieldScoreBreakdownDto` | `field_id`, `label`, `score`, `max_score`, `weighted_score`, `rule_id`, `details` | Per-field scoring result. |
| `ScoreResultDto` | `total_score`, `max_score`, `percentage_score`, `category`, `field_breakdowns`, `metadata` | Full scoring result. |
| `ActivityRuleDto` | `trigger_type`, `condition`, `action_type`, `action_config`, `enabled` | Automation trigger/action rule. |
| `ActivityDto` | `form_id`, `submission_id`, `assigned_to_user_id`, `title`, `description`, `status`, `due_at`, `metadata` | Follow-up activity. |
| `AnalyticsBucketDto` | `key`, `label`, `count`, `percentage` | Distribution bucket. |
| `AnalyticsTimeseriesPointDto` | `date`, `count` | Timeseries point. |
| `FormAnalyticsDto` | `submissions`, `completion`, `score`, `fields`, distributions | Full form analytics. |
| `DashboardAnalyticsDto` | totals, distributions, `top_forms` | Organization dashboard analytics. |
| `AuditLogDto` | `actor_user_id`, `action`, `resource_type`, `resource_id`, `ip_address`, `user_agent`, `details`, `created_at` | Audit event. |
| `RateLimitInfoDto` | `strategy`, `limit`, `remaining`, `reset_at` | One rate-limit bucket. |
| `PublicRateLimitStatusDto` | `allowed`, `limits`, `retry_after_seconds` | Public rate-limit decision. |

## Enum Values

| Enum | JSON Values |
| --- | --- |
| `UserRole` | `guest`, `parent`, `student`, `teacher`, `manager`, `admin`, `ceo`, `super_admin` |
| `PermissionAction` | `create`, `read`, `update`, `delete`, `publish`, `approve`, `reject`, `answer`, `view_results`, `export`, `manage_permissions`, `manage_scoring`, `manage_public_protection` |
| `ResourceType` | `form`, `form_field`, `submission`, `activity`, `user`, `organization`, `permission`, `score_template`, `audit_log` |
| `FormStatus` | `draft`, `pending_review`, `rejected`, `approved`, `scheduled`, `published`, `closed`, `archived` |
| `ApprovalStatus` | `not_required`, `required`, `pending`, `approved`, `rejected`, `cancelled` |
| `PublishMode` | `private`, `organization`, `subordinates`, `role_based`, `public_link` |
| `VisibilityMode` | `private`, `selected_users`, `selected_roles`, `subordinates`, `organization`, `public_link` |
| `SubmissionMode` | `single_submission`, `multiple_submissions`, `editable_submission`, `anonymous_submission` |
| `FieldType` | `short_text`, `long_text`, `email`, `phone`, `number`, `decimal`, `date`, `time`, `date_time`, `single_choice`, `multiple_choice`, `dropdown`, `rating_stars`, `numeric_rating`, `slider`, `likert_scale`, `matrix_single_choice`, `matrix_multiple_choice`, `yes_no`, `boolean_switch`, `nps`, `emoji_reaction`, `file_upload`, `image_upload`, `signature`, `location`, `ranking`, `section_title`, `description_block`, `divider`, `consent_checkbox`, `terms_acceptance`, `hidden`, `calculated`, `conditional_logic`, `score_display`, `quiz_question`, `page_break` |
| `SortOrder` | `asc`, `desc` |
| `FormAudienceType` | `user`, `role`, `group`, `class`, `department`, `organization`, `public` |
| `AnswerVisibility` | `visible_to_creator`, `visible_to_admin`, `visible_to_manager`, `anonymous`, `private` |
| `ScoringMode` | `none`, `quiz`, `satisfaction`, `risk_assessment`, `weighted`, `custom` |
| `ScoreRuleType` | `fixed`, `option_based`, `range_based`, `formula`, `weighted`, `negative_score` |
| `ActivityTriggerType` | `submission_created`, `score_above`, `score_below`, `answer_equals`, `answer_contains`, `nps_low`, `nps_high`, `submission_count_reached`, `form_closed` |
| `ActivityActionType` | `create_activity`, `notify_user`, `notify_manager`, `send_email`, `send_webhook`, `mark_submission`, `assign_follow_up` |
| `ActivityStatus` | `open`, `in_progress`, `completed`, `cancelled` |
| `PublicProtectionLevel` | `none`, `basic`, `standard`, `strict`, `custom` |
| `RateLimitStrategy` | `ip`, `user`, `token`, `fingerprint`, `captcha`, `combined` |
| `AuditAction` | `created`, `updated`, `deleted`, `published`, `submitted_for_approval`, `approved`, `rejected`, `closed`, `archived`, `permission_changed`, `public_protection_disabled`, `login`, `logout`, `submission_created` |
| `ErrorCode` | `UNAUTHORIZED`, `FORBIDDEN`, `PERMISSION_DENIED`, `VALIDATION_ERROR`, `NOT_FOUND`, `CONFLICT`, `RATE_LIMITED`, `FORM_CLOSED`, `FORM_NOT_PUBLISHED`, `APPROVAL_REQUIRED`, `PUBLIC_PROTECTION_REQUIRED`, `PUBLIC_ACCESS_DENIED`, `INVALID_TOKEN`, `TOKEN_EXPIRED`, `INTERNAL_SERVER_ERROR`, `SERVICE_UNAVAILABLE` |

---

## Persian Reference

این سند برای خروجی `cargo doc` نوشته شده و قرارداد HTTP API، مدل پاسخ‌ها، خطاها، DTOها و معنی فیلدهای اصلی را توضیح می‌دهد.

برای ساخت مستندات:

```bash
cargo doc --no-deps --open
```

آدرس پایه‌ی همه‌ی APIها:

```text
/api/v1
```

همه‌ی endpointهای خصوصی به هدر زیر نیاز دارند:

```http
Authorization: Bearer <access_token>
```

## الگوی پاسخ‌ها

### پاسخ موفق تکی

همه‌ی پاسخ‌های موفق تکی با `ApiResponse<T>` برمی‌گردند.

```json
{
  "success": true,
  "data": {
    "id": "11111111-1111-1111-1111-111111111111"
  },
  "error": null,
  "meta": {}
}
```

فیلدها:

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `success` | `bool` | برای پاسخ موفق `true` است. |
| `data` | `T \| null` | بدنه‌ی واقعی پاسخ. در خطا `null` است. |
| `error` | `ApiErrorDto \| null` | در موفقیت `null` و در خطا پر می‌شود. |
| `meta` | `object` | اطلاعات جانبی. برای پاسخ تکی معمولا `{}` است. |

### پاسخ لیستی

همه‌ی پاسخ‌های لیستی با `ApiListResponse<T>` برمی‌گردند.

```json
{
  "success": true,
  "data": [],
  "error": null,
  "meta": {
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total_items": 0,
      "total_pages": 0,
      "has_next": false,
      "has_previous": false
    }
  }
}
```

فیلدهای صفحه‌بندی:

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `page` | `integer` | شماره صفحه، از ۱ شروع می‌شود. |
| `page_size` | `integer` | اندازه صفحه. سرور مقدار را بین ۱ تا ۱۰۰ محدود می‌کند. |
| `total_items` | `integer` | تعداد کل آیتم‌های قابل نمایش با فیلتر فعلی. |
| `total_pages` | `integer` | تعداد کل صفحات. |
| `has_next` | `bool` | آیا صفحه بعد وجود دارد. |
| `has_previous` | `bool` | آیا صفحه قبل وجود دارد. |

### پاسخ خطا

همه‌ی خطاها با `ApiErrorResponse` برمی‌گردند.

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": {
      "phone": "Phone must be 6..32 characters."
    }
  },
  "meta": {}
}
```

فیلدهای خطا:

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `error.code` | `ErrorCode` | کد ماشین‌خوان خطا. کلاینت باید روی این فیلد تصمیم بگیرد، نه متن پیام. |
| `error.message` | `string` | پیام انسانی و کوتاه برای نمایش یا لاگ. |
| `error.details` | `object` | جزئیات ساختاریافته مثل نام فیلد نامعتبر، محدودیت rate limit، یا دلیل business rule. |

## کدهای خطا

| کد | HTTP رایج | معنی | اقدام پیشنهادی کلاینت |
| --- | --- | --- | --- |
| `UNAUTHORIZED` | `401` | احراز هویت انجام نشده یا credential پذیرفته نشده است. | کاربر را به login بفرستید یا token جدید بگیرید. |
| `FORBIDDEN` | `403` | کاربر شناخته شده است ولی اجازه‌ی عملیات را ندارد. | UI عملیات را مخفی/غیرفعال کند. |
| `PERMISSION_DENIED` | `403` | RBAC/ABAC دسترسی را رد کرده است. | نقش، سازمان و مالکیت resource را بررسی کنید. |
| `VALIDATION_ERROR` | `400` | request از نظر شکل، طول، مقدار enum یا rule اعتبارسنجی رد شده است. | `details` را کنار فیلدهای فرم نمایش دهید. |
| `NOT_FOUND` | `404` | resource وجود ندارد یا به دلیل boundary دسترسی قابل مشاهده نیست. | صفحه not found یا refresh لیست. |
| `CONFLICT` | `409` | عملیات با وضعیت فعلی resource یا unique constraint ناسازگار است. | پیام تعارض را نشان دهید و state را دوباره واکشی کنید. |
| `RATE_LIMITED` | `429` | محدودیت عمومی یا public form فعال شده است. | طبق `retry_after_seconds` صبر کنید. |
| `FORM_CLOSED` | `409` | فرم بسته شده و ارسال جدید قبول نمی‌کند. | فرم را read-only نشان دهید. |
| `FORM_NOT_PUBLISHED` | `409` | فرم هنوز منتشر نشده است. | فقط preview/admin flow را فعال کنید. |
| `APPROVAL_REQUIRED` | `409` | انتشار یا تغییر نیازمند تایید است. | کاربر را به submit-for-approval هدایت کنید. |
| `PUBLIC_PROTECTION_REQUIRED` | `403/409` | public-link بدون protection مجاز نیست. | protection یا access validation را فعال کنید. |
| `PUBLIC_ACCESS_DENIED` | `401/403` | دسترسی عمومی به فرم تایید نشده است. | validate-access را اجرا کنید یا رمز/کد را دوباره بگیرید. |
| `INVALID_TOKEN` | `401` | access/refresh/public token نامعتبر است. | token را حذف و دوباره login/validate کنید. |
| `TOKEN_EXPIRED` | `401` | token منقضی شده است. | refresh یا validate-access جدید بگیرید. |
| `INTERNAL_SERVER_ERROR` | `500` | خطای غیرمنتظره‌ی سرور یا دیتابیس. | پیام عمومی نشان دهید و لاگ server را بررسی کنید. |
| `SERVICE_UNAVAILABLE` | `503` | سرویس وابسته در دسترس نیست. | retry با backoff. |

## Query مشترک لیست‌ها

`ListQuery` برای endpointهای لیستی استفاده می‌شود.

| فیلد | نوع | پیش‌فرض | توضیح |
| --- | --- | --- | --- |
| `page` | `integer` | `1` | صفحه‌ی مورد نظر. |
| `page_size` | `integer` | `20` | تعداد آیتم در صفحه؛ بین ۱ تا ۱۰۰ clamp می‌شود. |
| `search` | `string?` | - | جستجوی متنی. معنی دقیق به endpoint وابسته است. |
| `sort_by` | `string?` | - | ستون مرتب‌سازی مجاز برای endpoint. |
| `sort_order` | `asc \| desc?` | `asc` | جهت مرتب‌سازی. |
| `filters` | `string?` | - | فیلتر خام/کدگذاری‌شده برای توسعه‌های بعدی. |
| `category` | `string?` | - | فیلتر دسته‌بندی فرم‌ها. |
| `tags` | `string?` | - | فیلتر tagها، معمولا comma-separated. |

نمونه:

```http
GET /api/v1/forms?page=1&page_size=20&search=survey&sort_by=created_at&sort_order=desc
Authorization: Bearer <access_token>
```

## Auth API

### `POST /auth/register`

ثبت‌نام عمومی با شماره موبایل و رمز عبور. شماره موبایل شناسه اصلی ورود است. کاربر می‌تواند با `organization_id` به سازمان موجود وصل شود یا با `organization_name` سازمان بسازد/پیدا کند. ارسال هم‌زمان `organization_id` و `organization_name` خطای validation می‌دهد. نقش‌های سطح بالا نباید self-register شوند.

Request: `RegisterRequest`

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `phone` | `string` | شماره ورود؛ طول ۶ تا ۳۲. |
| `email` | `string?` | ایمیل اختیاری پروفایل؛ برای login استفاده نمی‌شود. |
| `password` | `string` | رمز عبور؛ طول ۸ تا ۲۵۶. |
| `display_name` | `string` | نام نمایشی؛ طول ۱ تا ۱۶۰. |
| `gender` | `string?` | جنسیت/برچسب پروفایل؛ توسط service normalize می‌شود. |
| `organization_id` | `uuid?` | عضویت در سازمان موجود. |
| `organization_name` | `string?` | ساخت یا اتصال به سازمان با نام/slug. |
| `role` | `UserRole?` | نقش درخواستی؛ self-register برای نقش‌های privileged رد می‌شود. |

Response: `ApiResponse<RegisterResponse>` با `201`.

```json
{
  "phone": "+989121234567",
  "email": "parent@example.com",
  "password": "StrongPass123",
  "display_name": "Ali Ahmadi",
  "organization_name": "Demo School",
  "role": "parent"
}
```

خطاهای مهم: `VALIDATION_ERROR` برای فیلد نامعتبر، `FORBIDDEN` برای نقش غیرمجاز، `CONFLICT` برای شماره/ایمیل تکراری.

### `POST /auth/login`

ورود با شماره موبایل و رمز. خروجی شامل access token، refresh token چرخشی و اطلاعات کاربر است.

Request: `LoginRequest`

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `phone` | `string` | شماره ورود. |
| `password` | `string` | رمز عبور. |

Response: `ApiResponse<LoginResponse>`.

```json
{
  "phone": "+989121234567",
  "password": "StrongPass123"
}
```

خطاهای مهم: `UNAUTHORIZED` یا `INVALID_TOKEN` برای credential/token نامعتبر، `VALIDATION_ERROR` برای بدنه ناقص.

### `POST /auth/refresh`

access token جدید می‌سازد و refresh token را rotate می‌کند.

Request: `RefreshTokenRequest`

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `refresh_token` | `string` | refresh token فعلی؛ حداقل طول ۱۶. |

Response: `ApiResponse<RefreshTokenResponse>`.

خطاهای مهم: `INVALID_TOKEN`, `TOKEN_EXPIRED`, `UNAUTHORIZED`.

### `POST /auth/logout`

refresh token داده‌شده را revoke می‌کند. نیازمند Bearer JWT است.

Request: `LogoutRequest`

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `refresh_token` | `string` | refresh token قابل revoke. |

Response: `ApiResponse<LogoutResponse>`.

```json
{ "refresh_token": "refresh-token-value" }
```

### `GET /auth/me`

کاربر فعلی و permissionهای موثر او را برمی‌گرداند.

Response: `ApiResponse<MeResponse>`.

خطاهای مهم: `UNAUTHORIZED`, `INVALID_TOKEN`.

## Users API

### `GET /users`

لیست کاربران قابل مدیریت توسط نقش فعلی را برمی‌گرداند. Manager/Admin می‌توانند Teacher/Student، CEO می‌تواند Teacher/Student/Manager و SuperAdmin می‌تواند Teacher/Student/Manager/CEO را ببیند.

Query: `ListQuery`.

Response: `ApiListResponse<UserSummaryDto>`.

خطاهای مهم: `PERMISSION_DENIED`, `FORBIDDEN`, `UNAUTHORIZED`.

### `POST /users`

ساخت کاربر توسط نقش مدیریتی.

Request: `CreateUserRequest`

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `organization_id` | `uuid?` | سازمان هدف؛ برای غیر SuperAdmin باید با سازمان خودش یکی باشد. |
| `phone` | `string` | شماره یکتا؛ طول ۶ تا ۳۲. |
| `email` | `string?` | ایمیل اختیاری و در صورت وجود یکتا. |
| `display_name` | `string` | نام نمایشی. |
| `gender` | `string?` | مقدار اختیاری پروفایل. |
| `password` | `string` | رمز اولیه کاربر. |
| `primary_role` | `UserRole` | نقش هدف؛ باید توسط نقش سازنده قابل ایجاد باشد. |
| `profile` | `UserProfileDto?` | پروفایل تکمیلی. |

Response: `ApiResponse<UserDetailDto>` با `201`.

خطاهای مهم: `VALIDATION_ERROR`, `FORBIDDEN`, `PERMISSION_DENIED`, `CONFLICT`.

### `GET /users/me`

پروفایل کاربر فعلی را برمی‌گرداند.

Response: `ApiResponse<UserDetailDto>`.

### `PATCH /users/me`

پروفایل کاربر فعلی را تغییر می‌دهد. تغییر شماره تلفن در این endpoint پذیرفته نمی‌شود.

Request: `UpdateUserProfileRequest`

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `display_name` | `string?` | نام نمایشی جدید. |
| `email` | `string?` | ایمیل اختیاری جدید؛ باید معتبر و یکتا باشد. |
| `gender` | `string?` | جنسیت/برچسب پروفایل. |
| `profile` | `UserProfileDto?` | جایگزینی پروفایل. |

Response: `ApiResponse<UserDetailDto>`.

### `GET /users/{id}`

اطلاعات یک کاربر را با رعایت permission و boundary سازمانی برمی‌گرداند.

Path: `id` شناسه کاربر.

Response: `ApiResponse<UserDetailDto>`.

خطاهای مهم: `FORBIDDEN`, `NOT_FOUND`.

### `PATCH /users/{id}`

ویرایش کاربر هدف توسط نقش مدیریتی.

Request: `UpdateUserRequest`

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `phone` | `string?` | شماره جدید؛ باید یکتا باشد. |
| `email` | `string?` | ایمیل جدید؛ باید یکتا باشد. |
| `display_name` | `string?` | نام نمایشی. |
| `gender` | `string?` | مقدار پروفایل. |
| `primary_role` | `UserRole?` | نقش جدید؛ باید توسط actor قابل assign باشد. |
| `status` | `string?` | یکی از `active`, `inactive`, `suspended`. |
| `profile` | `UserProfileDto?` | پروفایل جدید. |

Response: `ApiResponse<UserDetailDto>`.

### `GET /users/{id}/subordinates`

زیرمجموعه‌های مستقیم کاربر را می‌دهد. کاربران عادی فقط زیرمجموعه‌های خودشان را می‌بینند؛ نقش‌های مدیریتی می‌توانند دیگران را بررسی کنند.

Response: `ApiListResponse<SubordinateUserDto>`.

## Organizations API

### `GET /organizations/{id}`

اطلاعات سازمان را در صورت داشتن دسترسی برمی‌گرداند.

Response: `ApiResponse<OrganizationDto>`.

### `GET /organizations/{id}/roles`

نقش‌ها و permissionهای پیش‌فرض سازمان را برمی‌گرداند.

Response: `ApiListResponse<OrganizationRoleDto>`.

### `PATCH /organizations/{id}/role-rules`

قواعد نقش‌ها، publish و field typeهای مجاز را تنظیم می‌کند.

Request: `UpdateRoleRulesRequest`

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `rules` | `RoleRuleDto[]` | حداقل یک rule؛ جایگزین/به‌روزرسانی تنظیمات نقش‌ها. |

Response: `ApiResponse<UpdateResultDto>`.

خطاهای مهم: `FORBIDDEN`, `PERMISSION_DENIED`, `VALIDATION_ERROR`.

## Permissions API

### `GET /permissions/effective`

permissionهای موثر کاربر فعلی را بر اساس نقش، سازمان و context برمی‌گرداند.

Response: `ApiResponse<EffectivePermissionsDto>`.

### `GET /permissions/field-types`

field typeهای مجاز برای نقش‌ها را برمی‌گرداند.

Query: `ListQuery`.

Response: `ApiResponse<Vec<FieldTypePermissionDto>>`.

### `PATCH /permissions/field-types`

مجوزهای field type را تغییر می‌دهد.

Request: `UpdateFieldTypePermissionsRequest`

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `permissions` | `FieldTypePermissionDto[]` | حداقل یک permission برای role/field_type. |

### `GET /permissions/publishing-rules`

قواعد انتشار موثر سازمان را می‌دهد.

Response: `ApiResponse<Vec<PublishingRuleDto>>`.

### `PATCH /permissions/publishing-rules`

قواعد publish، approval و public protection را تغییر می‌دهد.

Request: `UpdatePublishingRulesRequest`.

## Forms API

### `POST /forms`

فرم جدید می‌سازد. نیازمند `create` روی `form` و رعایت مجوز field/scoring است.

Request: `CreateFormRequest`

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `title` | `string` | عنوان فرم؛ طول ۱ تا ۲۵۵. |
| `description` | `string?` | توضیح قابل نمایش. |
| `category` | `string?` | دسته‌بندی فرم. |
| `tags` | `string[]` | برچسب‌ها برای جستجو/فیلتر. |
| `settings` | `FormSettingsDto` | رفتار ارسال، زمان‌بندی و نمایش پاسخ‌ها. |
| `visibility` | `FormVisibilityDto` | اینکه چه کسانی می‌بینند/پاسخ می‌دهند. |
| `scoring_mode` | `ScoringMode?` | حالت امتیازدهی. |
| `scoring_config` | `object` | تنظیمات اختصاصی امتیازدهی. |

Example request:

```json
{
  "title": "Parent Satisfaction Survey",
  "description": "Monthly feedback",
  "category": "satisfaction",
  "tags": ["monthly", "parents"],
  "settings": {
    "allow_anonymous_answers": true,
    "one_submission_per_user": true,
    "answers_editable_after_submission": false,
    "start_at": null,
    "end_at": null,
    "max_submissions": null,
    "submission_cooldown_seconds": 30,
    "submission_mode": "single_submission",
    "answer_visibility": "visible_to_creator",
    "guests_can_answer": false,
    "metadata": {}
  },
  "visibility": {
    "mode": "organization",
    "can_see": [],
    "can_answer": [{ "audience_type": "role", "id": null, "role": "parent", "label": "Parents" }],
    "cannot_see": [],
    "cannot_answer": [],
    "guest_can_answer": false,
    "anonymous_allowed": true,
    "metadata": {}
  },
  "scoring_mode": "none",
  "scoring_config": {}
}
```

Example response:

```json
{
  "success": true,
  "data": {
    "id": "22222222-2222-2222-2222-222222222222",
    "organization_id": "33333333-3333-3333-3333-333333333333",
    "creator_id": "44444444-4444-4444-4444-444444444444",
    "title": "Parent Satisfaction Survey",
    "description": "Monthly feedback",
    "category": "satisfaction",
    "tags": ["monthly", "parents"],
    "status": "draft",
    "visibility_mode": "organization",
    "publish_mode": "private",
    "settings": {},
    "visibility": {},
    "public_protection": {},
    "scoring_mode": "none",
    "scoring_config": {},
    "fields": [],
    "public_token": null,
    "approved_at": null,
    "published_at": null,
    "closed_at": null,
    "created_at": "2026-05-22T10:00:00Z",
    "updated_at": "2026-05-22T10:00:00Z"
  },
  "error": null,
  "meta": {}
}
```

Example error:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "PERMISSION_DENIED",
    "message": "Permission denied",
    "details": {
      "action": "create",
      "resource_type": "form"
    }
  },
  "meta": {}
}
```

### `GET /forms`

فرم‌های قابل مشاهده برای کاربر فعلی را با pagination می‌دهد.

Response: `ApiListResponse<FormSummaryDto>`.

### `GET /forms/tags`

tagهای موجود فرم‌ها را با search اختیاری برمی‌گرداند.

Response: `ApiResponse<Vec<String>>`.

### `GET /forms/{id}`

جزئیات کامل فرم، fieldها و تنظیمات را برمی‌گرداند.

Response: `ApiResponse<FormDetailDto>`.

### `PATCH /forms/{id}`

متادیتا، settings، visibility یا scoring فرم را تغییر می‌دهد.

Request: `UpdateFormRequest`.

### `DELETE /forms/{id}`

فرم را soft-delete می‌کند.

Response: `ApiResponse<DeleteResultDto>`.

### `POST /forms/{id}/fields`

یک فیلد به فرم اضافه می‌کند.

Request: `CreateFormFieldRequest`.

### `PATCH /forms/{id}/fields/{field_id}`

فیلد موجود را به‌روزرسانی می‌کند.

Request: `UpdateFormFieldRequest`.

### `DELETE /forms/{id}/fields/{field_id}`

فیلد را soft-delete می‌کند.

Response: `ApiResponse<DeleteResultDto>`.

### `POST /forms/{id}/duplicate`

از فرم نسخه جدید می‌سازد.

Request: `DuplicateFormRequest`

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `title` | `string?` | عنوان فرم کپی‌شده. |
| `include_fields` | `bool` | آیا fieldها کپی شوند. |
| `include_visibility` | `bool` | آیا visibility کپی شود. |
| `include_activity_rules` | `bool` | آیا automation/activity ruleها کپی شوند. |

### `POST /forms/{id}/submit-for-approval`

فرم را وارد چرخه تایید می‌کند.

Request: `SubmitForApprovalRequest` با فیلد `note`.

### `POST /forms/{id}/approve`

فرم را تایید می‌کند و در صورت `publish_after_approval=true` می‌تواند منتشر کند.

Request: `ApproveFormRequest` با `comment` و `publish_after_approval`.

### `POST /forms/{id}/reject`

فرم pending را رد می‌کند.

Request: `RejectFormRequest` با `reason` اجباری.

### `POST /forms/{id}/publish`

فرم را منتشر یا schedule می‌کند.

Request: `PublishFormRequest`

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `publish_mode` | `PublishMode` | محدوده انتشار. |
| `visibility` | `FormVisibilityDto?` | visibility جدید هنگام انتشار. |
| `public_protection` | `PublicProtectionSettingsDto?` | protection مخصوص public link. |
| `scheduled_at` | `datetime?` | زمان انتشار زمان‌بندی‌شده. |

### `POST /forms/{id}/close`

فرم منتشرشده را می‌بندد. `CloseFormRequest.reason` دلیل اختیاری است.

### `POST /forms/{id}/archive`

فرم را آرشیو می‌کند. `ArchiveFormRequest.reason` دلیل اختیاری است.

### `PATCH /forms/{id}/visibility`

visibility فرم را تغییر می‌دهد.

Request: `UpdateFormVisibilityRequest` با فیلد `visibility`.

### `GET /forms/{id}/access-codes`

metadata رمز مشترک و کدهای هویتی را برمی‌گرداند؛ خود secret هیچ‌وقت برگردانده نمی‌شود.

Response: `ApiResponse<FormAccessCodesResponse>`.

### `PUT /forms/{id}/access-codes`

کدهای دسترسی را جایگزین می‌کند و می‌تواند رمز مشترک را rotate یا پاک کند.

Request: `SetFormAccessCodesRequest`.

### `PATCH /forms/{id}/public-protection`

تنظیمات public protection را تغییر می‌دهد. خاموش‌کردن protection برای audit ثبت می‌شود.

Request: `UpdatePublicProtectionRequest`.

### `GET /forms/{id}/analytics`

تحلیل‌های فرم را برمی‌گرداند.

Response: `ApiResponse<FormAnalyticsDto>`.

## Fields API و مدل فیلدها

فیلدها resource مستقل route-level ندارند و زیر فرم مدیریت می‌شوند.

فیلدهای `CreateFormFieldRequest` و `UpdateFormFieldRequest`:

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `type` | `FieldType` | نوع input؛ در Rust با نام `field_type` ذخیره می‌شود و در JSON با `type` می‌آید. |
| `label` | `string` | عنوان قابل نمایش فیلد. |
| `description` | `string?` | توضیح کمکی زیر label. |
| `placeholder` | `string?` | متن placeholder برای inputهای متنی. |
| `required` | `bool` | آیا پاسخ اجباری است. |
| `order_index` | `integer` | ترتیب نمایش در فرم. |
| `config` | `FieldConfigDto` | optionها، range، default و تنظیمات type-specific. |
| `validation` | `FieldValidationDto` | قوانین اعتبارسنجی پاسخ. |
| `visibility_conditions` | `ConditionalLogicRuleDto[]` | قوانین نمایش/پرش شرطی. |
| `scoring_config` | `FieldScoringConfigDto` | تنظیمات امتیازدهی فیلد. |
| `permissions` | `FieldPermissionConfigDto` | نقش‌هایی که فیلد را می‌بینند/ویرایش/پاسخ می‌دهند. |

Example request:

```json
{
  "type": "single_choice",
  "label": "How satisfied are you?",
  "description": "Choose one option.",
  "placeholder": null,
  "required": true,
  "order_index": 1,
  "config": {
    "options": [
      { "id": "good", "label": "Good", "value": "good", "order_index": 1, "score": 5, "metadata": {} },
      { "id": "bad", "label": "Bad", "value": "bad", "order_index": 2, "score": 0, "metadata": {} }
    ],
    "metadata": {}
  },
  "validation": {},
  "visibility_conditions": [],
  "scoring_config": { "enabled": true, "max_score": 5, "weight": 1, "option_scores": { "good": 5, "bad": 0 }, "rules": [], "categories": [], "metadata": {} },
  "permissions": { "visible_to_roles": [], "editable_by_roles": [], "answerable_by_roles": ["parent"], "hidden_from_roles": [], "metadata": {} }
}
```

خطاهای مهم: `VALIDATION_ERROR`، `PERMISSION_DENIED` برای field type غیرمجاز، `NOT_FOUND` برای فرم/فیلد حذف‌شده.

## Submissions API

### `POST /forms/{id}/submissions`

ارسال پاسخ توسط کاربر احراز هویت‌شده. فرم باید published و برای کاربر قابل پاسخ باشد.

Request: `CreateSubmissionRequest`

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `answers` | `AnswerInputDto[]` | حداقل یک پاسخ. |
| `anonymous` | `bool?` | درخواست ثبت ناشناس، فقط اگر فرم اجازه دهد. |
| `fingerprint_token` | `string?` | شناسه device/browser برای limit و ضدتکرار. |
| `respondent_name` | `string?` | نام نمایشی پاسخ‌دهنده مهمان/اختیاری. |

Example request:

```json
{
  "anonymous": false,
  "fingerprint_token": "fp_abc",
  "respondent_name": "Ali Ahmadi",
  "answers": [
    {
      "field_id": "55555555-5555-5555-5555-555555555555",
      "value": "good",
      "metadata": {}
    }
  ]
}
```

Response: `ApiResponse<SubmissionDetailDto>`.

خطاهای مهم: `FORM_NOT_PUBLISHED`, `FORM_CLOSED`, `PERMISSION_DENIED`, `VALIDATION_ERROR`, `CONFLICT`.

### `GET /forms/{id}/submissions`

لیست submissionهای فرم برای نقش دارای `view_results`.

Response: `ApiListResponse<SubmissionSummaryDto>`.

### `GET /submissions/{id}`

جزئیات یک submission و answerها.

Response: `ApiResponse<SubmissionDetailDto>`.

### `PATCH /submissions/{id}`

ویرایش answers، فقط اگر settings فرم اجازه دهد.

Request: `UpdateSubmissionRequest` با `answers`.

### `DELETE /submissions/{id}`

submission را soft-delete می‌کند.

Response: `ApiResponse<DeleteResultDto>`.

### `GET /submissions/{id}/score-breakdown`

جزئیات امتیازدهی submission را می‌دهد.

Response: `ApiResponse<ScoreBreakdownDto>`.

## Public Forms API

### `GET /public/forms/{public_token}`

فرم منتشرشده با public link را بدون Bearer JWT برمی‌گرداند.

Response: `ApiResponse<PublicFormDto>`.

خطاهای مهم: `NOT_FOUND`, `FORM_NOT_PUBLISHED`, `FORM_CLOSED`.

### `POST /public/forms/{public_token}/validate-access`

رمز فرم، کد هویتی، captcha، email/phone verification و rate limit را بررسی می‌کند و در صورت موفقیت `public_access_token` کوتاه‌عمر می‌دهد.

Request: `ValidatePublicFormAccessRequest`

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `respondent_mode` | `string?` | حالت پاسخ‌دهنده مثل `guest`, `identity_code`, `shared_password`. |
| `form_password` | `string?` | رمز مشترک فرم. |
| `identity_code` | `string?` | کد هویتی اختصاصی. |
| `fingerprint_token` | `string?` | fingerprint برای rate limit. |
| `captcha_token` | `string?` | token کپچا در صورت فعال بودن. |
| `email_verification_token` | `string?` | token تایید ایمیل. |
| `phone_verification_token` | `string?` | token تایید موبایل. |

Response: `ApiResponse<ValidatePublicFormAccessResponse>`.

خطاهای مهم: `PUBLIC_ACCESS_DENIED`, `RATE_LIMITED`, `NOT_FOUND`.

### `POST /public/forms/{public_token}/submissions`

ارسال پاسخ عمومی. اگر protection فعال باشد، `public_access_token` لازم است.

Request: `PublicSubmissionRequest`.

Response: `ApiResponse<PublicSubmissionResponse>` با `201`.

## Scoring API

### `GET /score-templates`

templateهای امتیازدهی global و سازمانی را می‌دهد.

Response: `ApiListResponse<ScoreTemplateDto>`.

### `POST /score-templates`

template امتیازدهی جدید می‌سازد.

Request: `CreateScoreTemplateRequest`

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `field_type` | `FieldType?` | محدود به نوع فیلد خاص یا عمومی. |
| `scoring_mode` | `ScoringMode` | حالت امتیازدهی. |
| `name` | `string` | نام template؛ طول ۱ تا ۱۶۰. |
| `config` | `object` | تنظیمات template. |
| `is_default` | `bool` | آیا default آن scope باشد. |

### `GET /score-templates/{id}`

یک template را برمی‌گرداند.

### `PATCH /score-templates/{id}`

template را ویرایش می‌کند.

Request: `UpdateScoreTemplateRequest`.

### `DELETE /score-templates/{id}`

template را حذف/غیرفعال می‌کند.

Response: `ApiResponse<DeleteResultDto>`.

## Activities API

### `GET /activities`

فعالیت‌های سازمان کاربر را لیست می‌کند.

Response: `ApiListResponse<ActivitySummaryDto>`.

### `GET /activities/{id}`

جزئیات activity را می‌دهد.

Response: `ApiResponse<ActivityDto>`.

### `PATCH /activities/{id}`

activity را به‌روزرسانی می‌کند.

Request: `UpdateActivityRequest`

| فیلد | نوع | توضیح |
| --- | --- | --- |
| `title` | `string?` | عنوان فعالیت. |
| `description` | `string?` | توضیح فعالیت. |
| `status` | `ActivityStatus?` | وضعیت جدید. |
| `assigned_to_user_id` | `uuid?` | کاربر مسئول. |
| `due_at` | `datetime?` | موعد انجام. |
| `metadata` | `object?` | داده‌ی تکمیلی. |

### `GET /forms/{id}/activity-rules`

automation ruleهای فرم را لیست می‌کند.

Response: `ApiListResponse<ActivityRuleDto>`.

### `POST /forms/{id}/activity-rules`

rule جدید می‌سازد.

Request: `CreateActivityRuleRequest`.

### `PATCH /activity-rules/{id}`

rule موجود را تغییر می‌دهد.

Request: `UpdateActivityRuleRequest`.

### `DELETE /activity-rules/{id}`

rule را soft-delete می‌کند.

## Analytics API

### `GET /dashboard/analytics`

آمار داشبورد سازمانی را می‌دهد: فرم‌ها، کاربران، submissionها، participation و نمودارهای توزیعی.

Response: `ApiResponse<DashboardAnalyticsDto>`.

### `GET /forms/{id}/analytics`

آمار یک فرم شامل submissionها، completion، score، field analytics و توزیع پاسخ‌دهندگان.

Response: `ApiResponse<FormAnalyticsDto>`.

## Audit API

### `GET /audit-logs`

لاگ‌های audit را با pagination برمی‌گرداند.

Response: `ApiListResponse<AuditLogDto>`.

خطاهای مهم: `PERMISSION_DENIED`, `FORBIDDEN`.

## Detailed Concept Reference به فارسی

این بخش فیلدهایی را توضیح می‌دهد که فقط با دیدن اسمشان معنی عملی و اثرشان در سیستم مشخص نمی‌شود. این توضیحات بخشی از قرارداد رفتاری API هستند و برای UI، permission، public link، workflow فرم و کنترل سوءاستفاده اهمیت دارند.

### هویت سازمان و `slug`

هر سازمان هم شناسه داخلی دارد، هم نام انسانی، هم یک شناسه خوانا و مناسب URL.

| فیلد | معنی | رفتار عملی |
| --- | --- | --- |
| `OrganizationDto.id` | شناسه UUID داخلی سازمان. | برای API call، relation دیتابیس، permission و تشخیص مالکیت استفاده شود. |
| `OrganizationDto.name` | نام انسانی سازمان. | برای نمایش در UI استفاده شود و ممکن است فاصله، حروف بزرگ/کوچک یا کاراکترهای نمایشی داشته باشد. |
| `OrganizationDto.slug` | نسخه normalized و URL-safe نام سازمان. | برای لینک‌های خوانا، invite/public URLهای احتمالی، ساخت/پیدا کردن سازمان از روی `organization_name` و flowهایی که UUID مناسب نیست استفاده می‌شود. |
| `OrganizationDto.parent_organization_id` | سازمان والد اختیاری. | برای ساختارهای سلسله‌مراتبی مثل هلدینگ، مدرسه مادر، شعبه، دپارتمان یا campus استفاده می‌شود. `null` یعنی سازمان سطح بالا است. |

`slug` فقط یک متن نمایشی نیست. مثلا `Demo School` می‌تواند به `demo-school` تبدیل شود. کلاینت نباید فرض کند می‌تواند slug را آزادانه تغییر دهد، مگر اینکه endpoint مخصوص آن وجود داشته باشد.

راهنمای استفاده:

| موقعیت | فیلد مناسب |
| --- | --- |
| فراخوانی APIهای سازمان | `id` |
| نمایش نام سازمان | `name` |
| لینک خوانا یا match کردن نام سازمان هنگام ثبت‌نام | `slug` فقط وقتی contract بک‌اند آن را خواسته باشد |
| مقایسه سازمان‌ها برای authorization | فقط `id`، نه `name` و نه `slug` |

### تنظیمات سازمان

`OrganizationSettingsDto` رفتار پیش‌فرض سازمان برای فرم‌ها و public access را مشخص می‌کند.

| فیلد | توضیح کامل |
| --- | --- |
| `default_timezone` | timezone پیش‌فرض سازمان، مثل `UTC` یا `Asia/Tehran`. وقتی timezone کاربر موجود نباشد، برای زمان‌بندی انتشار، start/end فرم و گروه‌بندی analytics استفاده می‌شود. |
| `public_forms_enabled` | سوییچ کلی فرم عمومی در سازمان. اگر `false` باشد، UI نباید امکان publish عمومی را نشان دهد، حتی اگر نقش کاربر permissionهای دیگر داشته باشد. |
| `default_public_protection_level` | سطح محافظت پیش‌فرض public form. اگر فرم هنگام publish تنظیم اختصاصی ندهد، این مقدار مبنا قرار می‌گیرد. |
| `require_audit_for_public_protection_disable` | اگر `true` باشد، ضعیف‌کردن یا خاموش‌کردن public protection عملیات حساس حساب می‌شود و باید audit شود. بهتر است UI برای این کار reason/comment بگیرد. |
| `metadata` | محل توسعه‌پذیر برای flagهای سازمانی. نباید secret یا داده حساس خام در آن ذخیره شود. |

### سطح‌های Public Protection

`PublicProtectionLevel` سیاست کلی امنیت public form را نشان می‌دهد. enforcement دقیق با `PublicProtectionSettingsDto` و strategyها انجام می‌شود.

| سطح | معنی | کاربرد معمول | رفتار پیشنهادی کلاینت |
| --- | --- | --- | --- |
| `none` | بدون محافظت جدی، فقط چک‌های پایه مثل موجود بودن و باز بودن فرم. | تست یا فرم عمومی کم‌ریسک. | قبل از publish هشدار نشان بده. ممکن است policy سازمان اجازه ندهد. |
| `basic` | محافظت سبک. | فرم‌های کم‌ریسک که دسترسی آسان مهم‌تر از سخت‌گیری است. | UI ساده نگه داشته شود. |
| `standard` | محافظت متعادل و پیش‌فرض. | اکثر surveyها و feedback formها. | default پیشنهادی؛ معمولا IP/token/fingerprint فعال است. |
| `strict` | محافظت سخت‌گیرانه‌تر. | فرم حساس، امتیازدار، عمومی پرریسک یا مستعد سوءاستفاده. | انتظار captcha/verification/rate-limit سخت‌تر داشته باش. |
| `custom` | تنظیمات کاملا اختصاصی. | policyهای خاص سازمان. | UI باید strategyها و limitهای دقیق را نشان دهد، نه preset فرضی. |

نکته مهم: `level` سیاست کلی را می‌گوید، اما `strategies` و عددهای limit مشخص می‌کنند سرور دقیقا چه چیزهایی را enforce می‌کند.

### تنظیمات Public Protection

| فیلد | توضیح کامل |
| --- | --- |
| `level` | سطح کلی policy. برای preset، هشدار و نمایش UI استفاده شود. |
| `strategies` | روش‌های فعال ضد سوءاستفاده. سرور می‌تواند چند strategy را هم‌زمان بررسی کند. |
| `ip_limit_per_minute` | سقف درخواست/ارسال عمومی از یک IP در دقیقه. `null` یعنی این limit در این لایه تنظیم نشده است. |
| `token_limit_per_day` | سقف استفاده روزانه از public access token. جلوی reuse طولانی یا share شدن token را می‌گیرد. |
| `access_limit_per_minute` | سقف تلاش‌های validate-access در دقیقه. برای جلوگیری از brute force رمز/کد/verification. |
| `cooldown_seconds` | حداقل فاصله بین تلاش‌های تکراری برای همان subject. |
| `max_submissions_per_ip` | سقف submission عمومی از یک IP در بازه tracking. |
| `max_submissions_per_fingerprint` | سقف submission از یک browser/device fingerprint. |
| `captcha_enabled` | اگر فعال باشد، validate/submission باید `captcha_token` داشته باشد. |
| `email_verification_enabled` | اگر فعال باشد، `email_verification_token` لازم است. |
| `phone_verification_enabled` | اگر فعال باشد، `phone_verification_token` لازم است. |
| `disabled_limits` | strategyهایی که با وجود سطح انتخاب‌شده عمدا غیرفعال شده‌اند. |
| `metadata` | تنظیمات توسعه‌ای یا provider-specific. secret خام نباید اینجا ذخیره شود. |

### Strategyهای Rate Limit

| Strategy | چه چیزی را دنبال می‌کند | جلوی چه چیزی را می‌گیرد |
| --- | --- | --- |
| `ip` | IP درخواست‌دهنده. | حجم زیاد از یک آدرس شبکه. |
| `user` | شناسه کاربر احراز هویت‌شده. | تکرار بیش از حد توسط یک account. |
| `token` | public access token یا token مشابه. | share/reuse شدن token معتبر. |
| `fingerprint` | fingerprint مرورگر/دستگاه. | تکرار از یک دستگاه حتی با تغییر IP. |
| `captcha` | نتیجه challenge کپچا. | bot و script. |
| `combined` | ترکیب چند سیگنال. | وقتی یک سیگنال به‌تنهایی قابل اعتماد نیست. |

### Visibility فرم

`FormVisibilityDto` مشخص می‌کند چه کسی فرم را می‌بیند و چه کسی می‌تواند پاسخ دهد. visibility جدا از status فرم است؛ یعنی حتی اگر کاربر در visibility مجاز باشد، فرم draft/closed/archived/unpublished یا خارج از زمان‌بندی هنوز قابل پاسخ نیست.

| فیلد | توضیح کامل |
| --- | --- |
| `mode` | مدل کلی visibility مثل private، organization، role-based، subordinates یا public-link. |
| `can_see` | inclusion rule برای دیدن فرم. |
| `can_answer` | inclusion rule برای پاسخ دادن. دیدن فرم لزوما یعنی اجازه پاسخ نیست. |
| `cannot_see` | exclusion rule برای دیدن. همیشه بر `can_see` اولویت دارد. |
| `cannot_answer` | exclusion rule برای پاسخ. همیشه بر `can_answer` اولویت دارد. |
| `guest_can_answer` | اجازه پاسخ توسط مهمان، معمولا در public flow. |
| `anonymous_allowed` | اجازه ذخیره/نمایش پاسخ به صورت ناشناس، طبق قوانین سرور. |
| `metadata` | داده توسعه‌ای برای ruleهای خاص کلاینت/سازمان. |

ترتیب ذهنی بررسی:

1. وضعیت فرم بررسی شود: draft/pending عموما answerable نیست.
2. boundary سازمان و مالکیت بررسی شود.
3. inclusionها مثل `can_see` و `can_answer` اعمال شوند.
4. exclusionها مثل `cannot_see` و `cannot_answer` آخر اعمال شوند و برنده‌اند.
5. برای public form، public protection و rate limit هم اعمال شود.

### تفاوت Publish Mode و Visibility Mode

`PublishMode` می‌گوید فرم با چه مدل انتشاری live شده است. `VisibilityMode` می‌گوید چه کسانی آن را می‌بینند یا جواب می‌دهند. این دو معمولا مرتبط‌اند ولی یکی نیستند.

| مفهوم | مثال | توضیح |
| --- | --- | --- |
| `publish_mode = private` | فرم داخلی/draft | فرم عمومی یا سازمانی منتشر نشده است. |
| `publish_mode = organization` | survey کل سازمان | داخل سازمان منتشر شده است. |
| `publish_mode = subordinates` | مدیر برای زیرمجموعه‌ها | انتشار محدود به hierarchy. |
| `publish_mode = role_based` | فقط والدین | انتشار برای roleهای انتخاب‌شده. |
| `publish_mode = public_link` | لینک عمومی ناشناس | انتشار با public token و احتمالا public protection. |

### Workflow وضعیت فرم

| Status | معنی | قدم‌های معمول بعدی |
| --- | --- | --- |
| `draft` | نسخه قابل ویرایش؛ معمولا answerable نیست. | ویرایش، duplicate، submit for approval یا publish مستقیم اگر مجاز باشد. |
| `pending_review` | منتظر تایید. | approve یا reject. |
| `rejected` | تایید رد شده. | ویرایش و ارسال مجدد برای تایید. |
| `approved` | تایید شده ولی ممکن است هنوز منتشر نشده باشد. | publish یا schedule. |
| `scheduled` | انتشار برای آینده زمان‌بندی شده. | انتظار، تغییر زمان‌بندی یا لغو طبق permission. |
| `published` | live و در صورت اجازه visibility/settings قابل پاسخ. | دریافت submission، close یا archive. |
| `closed` | submission جدید نمی‌پذیرد. | مشاهده نتایج یا archive. |
| `archived` | از workflow فعال خارج شده. | معمولا read-only. |

### Access Codeها

| نوع | هدف | آیا secret برمی‌گردد؟ |
| --- | --- | --- |
| Shared form password | یک رمز مشترک برای عبور از public gate. | فقط metadata برمی‌گردد؛ رمز خام هرگز برنمی‌گردد. |
| Identity code | کد برچسب‌دار برای شخص/گروه/دسته پاسخ‌دهنده. | label و metadata برمی‌گردد؛ کد خام برنمی‌گردد. |

`FormAccessCodeInputDto.code` در عمل write-only است: کلاینت آن را هنگام تنظیم می‌فرستد، سرور ذخیره امن/هش‌شده انجام می‌دهد، و بعدا فقط `FormAccessCodeDto` را برمی‌گرداند.

### فیلدهای `metadata`

بسیاری از DTOها `metadata` دارند. این فیلد برای توسعه آینده و اطلاعات custom است.

| قانون | دلیل |
| --- | --- |
| keyهای ناشناخته را حذف نکنید. | ممکن است بک‌اند یا کلاینت دیگر اضافه کرده باشد. |
| secret ذخیره نکنید. | metadata ممکن است به کلاینت یا audit log برگردد. |
| keyهای اختصاصی را namespace کنید. | مثل `mobile_app`, `web_admin`, `integration_x` تا collision پیش نیاید. |
| برای authorization به metadata تکیه نکنید. | permission باید با فیلدهای explicit و چک سرور انجام شود. |

## DTO Field Catalog

### Auth DTOs

| DTO | فیلدها |
| --- | --- |
| `RegisterResponse` | `user`: کاربر ساخته‌شده؛ `organization`: سازمان مرتبط یا `null`. |
| `LoginResponse` | `access_token`: JWT کوتاه‌عمر؛ `refresh_token`: token چرخشی؛ `token_type`: معمولا `Bearer`؛ `expires_in`: ثانیه تا انقضا؛ `user`: کاربر واردشده. |
| `RefreshTokenResponse` | مثل login ولی بدون `user`. |
| `LogoutResponse` | `logged_out`: اگر revoke انجام شده باشد `true`. |
| `MeResponse` | `user`: کاربر فعلی؛ `effective_permissions`: خروجی RBAC/ABAC موثر. |

### User DTOs

| DTO | فیلد | توضیح |
| --- | --- | --- |
| `UserSummaryDto` | `id` | شناسه کاربر. |
| `UserSummaryDto` | `organization_id` | سازمان کاربر یا `null` برای scopeهای خاص. |
| `UserSummaryDto` | `phone` | شماره اصلی ورود. |
| `UserSummaryDto` | `email` | ایمیل اختیاری. |
| `UserSummaryDto` | `display_name` | نام نمایشی. |
| `UserSummaryDto` | `gender` | جنسیت/برچسب اختیاری. |
| `UserSummaryDto` | `primary_role` | نقش اصلی. |
| `UserSummaryDto` | `status` | وضعیت حساب: `active`, `inactive`, `suspended`. |
| `UserProfileDto` | `phone` | شماره نمایشی پروفایل. |
| `UserProfileDto` | `avatar_url` | آدرس تصویر. |
| `UserProfileDto` | `locale` | زبان/locale مثل `fa-IR`. |
| `UserProfileDto` | `timezone` | timezone مثل `Asia/Tehran`. |
| `UserProfileDto` | `metadata` | داده آزاد کلاینت. |
| `UserDetailDto` | `profile` | پروفایل کامل. |
| `UserDetailDto` | `created_at`, `updated_at` | زمان ساخت و آخرین تغییر. |
| `UserRelationshipDto` | `parent_user_id`, `child_user_id` | رابطه سلسله‌مراتبی کاربرها. |
| `UserRelationshipDto` | `relationship_type` | نوع رابطه مثل manager/student/parent. |
| `SubordinateUserDto` | `user` | خلاصه کاربر زیرمجموعه. |
| `SubordinateUserDto` | `relationship_type` | نوع رابطه. |
| `SubordinateUserDto` | `depth` | عمق رابطه؛ فعلا مستقیم معمولا `1`. |

### Organization and Permission DTOs

| DTO | فیلد | توضیح |
| --- | --- | --- |
| `OrganizationSettingsDto` | `default_timezone` | timezone پیش‌فرض سازمان. |
| `OrganizationSettingsDto` | `public_forms_enabled` | آیا فرم عمومی مجاز است. |
| `OrganizationSettingsDto` | `default_public_protection_level` | سطح پیش‌فرض محافظت عمومی. |
| `OrganizationSettingsDto` | `require_audit_for_public_protection_disable` | آیا غیرفعال‌سازی protection باید audit شود. |
| `OrganizationDto` | `id`, `parent_organization_id` | شناسه سازمان و والد اختیاری. |
| `OrganizationDto` | `name`, `slug` | نام انسانی و slug یکتا. |
| `OrganizationRoleDto` | `name` | نقش سیستمی. |
| `OrganizationRoleDto` | `display_name` | نام نمایشی نقش. |
| `OrganizationRoleDto` | `is_system` | آیا نقش built-in است. |
| `OrganizationRoleDto` | `default_permissions` | actionهای پیش‌فرض. |
| `RoleRuleDto` | `can_create_forms`, `can_publish_forms` | قابلیت ساخت/انتشار فرم. |
| `RoleRuleDto` | `requires_approval_to_publish`, `two_step_approval_required` | نیازمندی‌های approval. |
| `RoleRuleDto` | `can_change_scoring` | اجازه تغییر scoring. |
| `RoleRuleDto` | `approver_roles` | نقش‌های تاییدکننده. |
| `RoleRuleDto` | `allowed_field_types`, `denied_field_types` | field typeهای مجاز/غیرمجاز. |
| `PermissionDto` | `action`, `resource_type`, `key` | permission machine-readable. |
| `RolePermissionDto` | `role`, `permission`, `allowed` | اتصال نقش به permission. |
| `FieldTypePermissionDto` | `role`, `field_type`, `allowed`, `reason` | کنترل field type برای نقش. |
| `ApprovalRuleDto` | `approval_required`, `two_step_required`, `approver_roles` | منطق تایید publish. |
| `PublishingRuleDto` | `can_publish_directly`, `allowed_publish_modes`, `can_disable_public_protection` | قوانین انتشار. |
| `EffectivePermissionsDto` | `actions`, `resources`, `field_types` | دسترسی‌های نهایی کاربر. |
| `EffectivePermissionsDto` | `can_manage_permissions`, `can_manage_scoring`, `can_manage_public_protection` | feature flagهای permission. |
| `EffectivePermissionsDto` | `abac_context` | context تصمیم‌گیری attribute-based. |

### Form DTOs

| DTO | فیلد | توضیح |
| --- | --- | --- |
| `AudienceRuleDto` | `audience_type` | نوع مخاطب: user/role/group/class/department/organization/public. |
| `AudienceRuleDto` | `id` | شناسه مخاطب، وقتی type شناسه‌پذیر است. |
| `AudienceRuleDto` | `role` | نقش هدف برای ruleهای role-based. |
| `AudienceRuleDto` | `label` | نام نمایشی rule. |
| `FormSettingsDto` | `allow_anonymous_answers` | اجازه پاسخ ناشناس. |
| `FormSettingsDto` | `one_submission_per_user` | جلوگیری از ارسال چندباره توسط یک کاربر. |
| `FormSettingsDto` | `answers_editable_after_submission` | اجازه ویرایش بعد از ارسال. |
| `FormSettingsDto` | `start_at`, `end_at` | بازه فعال بودن فرم. |
| `FormSettingsDto` | `max_submissions` | سقف تعداد submission. |
| `FormSettingsDto` | `submission_cooldown_seconds` | فاصله حداقل بین ارسال‌ها. |
| `FormSettingsDto` | `submission_mode` | سیاست ارسال: single/multiple/editable/anonymous. |
| `FormSettingsDto` | `answer_visibility` | اینکه چه کسی پاسخ‌ها را می‌بیند. |
| `FormSettingsDto` | `guests_can_answer` | اجازه مهمان برای پاسخ. |
| `FormVisibilityDto` | `mode` | حالت کلی visibility. |
| `FormVisibilityDto` | `can_see`, `can_answer` | مخاطبان مجاز به دیدن/پاسخ. |
| `FormVisibilityDto` | `cannot_see`, `cannot_answer` | استثناها؛ بر inclusion اولویت دارند. |
| `FormVisibilityDto` | `guest_can_answer`, `anonymous_allowed` | مجوز مهمان/ناشناس. |
| `PublicProtectionSettingsDto` | `level` | سطح محافظت. |
| `PublicProtectionSettingsDto` | `strategies` | strategyهای rate/protection فعال. |
| `PublicProtectionSettingsDto` | `ip_limit_per_minute`, `token_limit_per_day`, `access_limit_per_minute` | سقف‌های rate limit. |
| `PublicProtectionSettingsDto` | `cooldown_seconds` | فاصله مجاز درخواست‌ها. |
| `PublicProtectionSettingsDto` | `max_submissions_per_ip`, `max_submissions_per_fingerprint` | سقف submission عمومی. |
| `PublicProtectionSettingsDto` | `captcha_enabled`, `email_verification_enabled`, `phone_verification_enabled` | protectionهای اضافه. |
| `FormAccessCodeDto` | `code_type`, `label`, `enabled` | نوع کد، برچسب، وضعیت؛ مقدار secret برنمی‌گردد. |
| `FormSummaryDto` | `submissions_count` | تعداد submissionهای فرم. |
| `FormSummaryDto` | `public_token` | token public link، اگر وجود داشته باشد. |
| `FormDetailDto` | `fields` | فیلدهای فرم. |
| `FormDetailDto` | `approved_at`, `published_at`, `closed_at` | زمان‌های workflow. |

### Field DTOs

| DTO | فیلد | توضیح |
| --- | --- | --- |
| `FieldOptionDto` | `id` | کلید پایدار option. |
| `FieldOptionDto` | `label` | متن نمایش option. |
| `FieldOptionDto` | `value` | مقدار ذخیره‌شده هنگام پاسخ. |
| `FieldOptionDto` | `order_index` | ترتیب option. |
| `FieldOptionDto` | `score` | امتیاز اختیاری option. |
| `FieldConfigDto` | `options` | گزینه‌های choice/dropdown/rating. |
| `FieldConfigDto` | `rows`, `columns` | سطر/ستون matrix. |
| `FieldConfigDto` | `min`, `max`, `step` | محدوده عددی/slider. |
| `FieldConfigDto` | `default_value` | مقدار پیش‌فرض. |
| `FieldConfigDto` | `accept_mime_types`, `max_file_size_mb` | محدودیت فایل. |
| `FieldConfigDto` | `page_title`, `static_text` | محتوای page break/section/description. |
| `FieldValidationDto` | `min_length`, `max_length`, `regex` | اعتبارسنجی متن. |
| `FieldValidationDto` | `min_number`, `max_number` | اعتبارسنجی عدد. |
| `FieldValidationDto` | `min_items`, `max_items` | تعداد انتخاب‌ها/فایل‌ها. |
| `FieldValidationDto` | `required_message` | پیام اختصاصی required. |
| `FieldVisibilityConditionDto` | `source_field_id`, `operator`, `value` | شرط وابسته به پاسخ فیلد دیگر. |
| `ConditionalLogicRuleDto` | `mode`, `action` | ترکیب شرط‌ها و کاری که انجام می‌شود. |
| `ConditionalLogicRuleDto` | `target_field_ids`, `target_page_index` | هدف پنهان/نمایش/پرش. |
| `FieldScoringConfigDto` | `enabled`, `max_score`, `weight` | فعال‌سازی و وزن امتیاز. |
| `FieldScoringConfigDto` | `option_scores`, `rules`, `categories` | امتیاز گزینه‌ها، ruleها و دسته‌بندی‌ها. |
| `FieldPermissionConfigDto` | `visible_to_roles`, `editable_by_roles`, `answerable_by_roles`, `hidden_from_roles` | دسترسی‌های نقش‌محور فیلد. |
| `FormFieldDto` | `id`, `form_id`, `type` | شناسه‌ها و نوع فیلد. |
| `FormFieldDto` | `created_at`, `updated_at` | زمان ساخت/تغییر. |

### Submission and Public DTOs

| DTO | فیلد | توضیح |
| --- | --- | --- |
| `AnswerInputDto` | `field_id`, `value`, `metadata` | پاسخ ارسالی برای یک فیلد. |
| `AnswerDto` | `id`, `submission_id`, `created_at` | پاسخ ذخیره‌شده. |
| `SubmissionScoreDto` | `total_score`, `max_score`, `percentage_score`, `category_label` | خلاصه امتیاز. |
| `SubmissionSummaryDto` | `respondent_user_id`, `access_code_id`, `respondent_mode`, `respondent_label` | هویت پاسخ‌دهنده. |
| `SubmissionSummaryDto` | `anonymous`, `valid`, `submitted_at` | وضعیت submission. |
| `SubmissionDetailDto` | `guest_token_id`, `answers`, `updated_at` | جزئیات کامل. |
| `ScoreBreakdownDto` | `submission_id`, `result` | خروجی محاسبه scoring. |
| `PublicFormDto` | `access_policy`, `start_at`, `end_at` | سیاست دسترسی و بازه عمومی. |
| `PublicFormAccessPolicyDto` | `respondent_modes`, `requires_form_password`, `identity_codes_enabled`, `public_access_validation_required` | نیازمندی‌های دسترسی عمومی. |
| `PublicFormAccessDto` | `public_token`, `fingerprint_token`, `ip_hint`, `metadata` | context دسترسی عمومی. |
| `ValidatePublicFormAccessResponse` | `allowed`, `reason`, `access_token`, `respondent_mode`, `identity_label`, `rate_limit` | نتیجه validate-access. |
| `PublicSubmissionResponse` | `submission`, `message` | submission ساخته‌شده و پیام نهایی. |

### Scoring, Activity, Analytics, Audit, Rate Limit DTOs

| DTO | فیلد | توضیح |
| --- | --- | --- |
| `ScoreRuleDto` | `rule_type`, `min`, `max`, `value`, `score`, `weight`, `formula` | rule محاسبه امتیاز. |
| `ScoreCategoryDto` | `min_percentage`, `max_percentage`, `color`, `description` | دسته‌بندی نتیجه امتیاز. |
| `ScoreTemplateDto` | `organization_id`, `field_type`, `scoring_mode`, `config`, `is_default` | template امتیازدهی. |
| `FieldScoreBreakdownDto` | `field_id`, `label`, `score`, `max_score`, `weighted_score`, `rule_id`, `details` | سهم هر فیلد در امتیاز. |
| `ScoreResultDto` | `total_score`, `max_score`, `percentage_score`, `category`, `field_breakdowns`, `metadata` | نتیجه کامل scoring. |
| `ActivityRuleDto` | `trigger_type`, `condition`, `action_type`, `action_config`, `enabled` | automation rule. |
| `ActivityDto` | `organization_id`, `form_id`, `submission_id`, `assigned_to_user_id`, `title`, `description`, `status`, `due_at`, `metadata` | فعالیت پیگیری. |
| `AnalyticsBucketDto` | `key`, `label`, `count`, `percentage` | bucket آماری. |
| `AnalyticsTimeseriesPointDto` | `date`, `count` | نقطه نمودار زمانی. |
| `SubmissionCountAnalyticsDto` | `total`, `valid`, `anonymous`, `by_day`, `today`, `this_week`, `this_month` | آمار submission. |
| `CompletionRateAnalyticsDto` | `started`, `completed`, `completion_rate` | نرخ تکمیل. |
| `FieldAnalyticsDto` | `field_id`, `label`, `response_count`, `summary` | خلاصه پاسخ‌های یک فیلد. |
| `ScoreAnalyticsDto` | `average_score`, `max_score`, `average_percentage`, `category_distribution` | آمار score. |
| `FormAnalyticsDto` | `submissions`, `completion`, `score`, `fields`, `respondent_modes`, `gender_distribution`, `user_role_distribution`, `access_code_distribution` | تحلیل کامل فرم. |
| `DashboardAnalyticsDto` | `total_forms`, `published_forms`, `total_users`, `total_submissions`, `valid_submissions`, `participation_rate`, `top_forms` | آمار داشبورد. |
| `AuditLogDto` | `actor_user_id`, `action`, `resource_type`, `resource_id`, `ip_address`, `user_agent`, `details`, `created_at` | رویداد audit. |
| `RateLimitInfoDto` | `strategy`, `limit`, `remaining`, `reset_at` | وضعیت یک strategy. |
| `PublicRateLimitStatusDto` | `allowed`, `limits`, `retry_after_seconds` | جمع‌بندی rate limit عمومی. |

## Enum Catalog

| Enum | مقادیر |
| --- | --- |
| `UserRole` | `guest`, `parent`, `student`, `teacher`, `manager`, `admin`, `ceo`, `super_admin` |
| `PermissionAction` | `create`, `read`, `update`, `delete`, `publish`, `approve`, `reject`, `answer`, `view_results`, `export`, `manage_permissions`, `manage_scoring`, `manage_public_protection` |
| `ResourceType` | `form`, `form_field`, `submission`, `activity`, `user`, `organization`, `permission`, `score_template`, `audit_log` |
| `FormStatus` | `draft`, `pending_review`, `rejected`, `approved`, `scheduled`, `published`, `closed`, `archived` |
| `ApprovalStatus` | `not_required`, `required`, `pending`, `approved`, `rejected`, `cancelled` |
| `PublishMode` | `private`, `organization`, `subordinates`, `role_based`, `public_link` |
| `VisibilityMode` | `private`, `selected_users`, `selected_roles`, `subordinates`, `organization`, `public_link` |
| `SubmissionMode` | `single_submission`, `multiple_submissions`, `editable_submission`, `anonymous_submission` |
| `FieldType` | `short_text`, `long_text`, `email`, `phone`, `number`, `decimal`, `date`, `time`, `date_time`, `single_choice`, `multiple_choice`, `dropdown`, `rating_stars`, `numeric_rating`, `slider`, `likert_scale`, `matrix_single_choice`, `matrix_multiple_choice`, `yes_no`, `boolean_switch`, `nps`, `emoji_reaction`, `file_upload`, `image_upload`, `signature`, `location`, `ranking`, `section_title`, `description_block`, `divider`, `consent_checkbox`, `terms_acceptance`, `hidden`, `calculated`, `conditional_logic`, `score_display`, `quiz_question`, `page_break` |
| `AnswerVisibility` | `visible_to_creator`, `visible_to_admin`, `visible_to_manager`, `anonymous`, `private` |
| `ScoringMode` | `none`, `quiz`, `satisfaction`, `risk_assessment`, `weighted`, `custom` |
| `ScoreRuleType` | `fixed`, `option_based`, `range_based`, `formula`, `weighted`, `negative_score` |
| `ActivityTriggerType` | `submission_created`, `score_above`, `score_below`, `answer_equals`, `answer_contains`, `nps_low`, `nps_high`, `submission_count_reached`, `form_closed` |
| `ActivityActionType` | `create_activity`, `notify_user`, `notify_manager`, `send_email`, `send_webhook`, `mark_submission`, `assign_follow_up` |
| `ActivityStatus` | `open`, `in_progress`, `completed`, `cancelled` |
| `PublicProtectionLevel` | `none`, `basic`, `standard`, `strict`, `custom` |
| `RateLimitStrategy` | `ip`, `user`, `token`, `fingerprint`, `captcha`, `combined` |
| `AuditAction` | `created`, `updated`, `deleted`, `published`, `submitted_for_approval`, `approved`, `rejected`, `closed`, `archived`, `permission_changed`, `public_protection_disabled`, `login`, `logout`, `submission_created` |
