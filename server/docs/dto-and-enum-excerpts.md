# DTO and enum excerpts

The complete DTO and enum contract lives under `src/api_types` and is exported through `GET /openapi.json`.

## Enum style

All enums except `ErrorCode` use snake_case JSON values.

```rust
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum UserRole {
    Guest,
    Parent,
    Teacher,
    Manager,
    Admin,
    Ceo,
    SuperAdmin,
}
```

```rust
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, ToSchema)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum ErrorCode {
    Unauthorized,
    Forbidden,
    PermissionDenied,
    ValidationError,
    NotFound,
    Conflict,
    RateLimited,
    FormClosed,
    FormNotPublished,
    ApprovalRequired,
    PublicProtectionRequired,
    PublicAccessDenied,
    InvalidToken,
    TokenExpired,
    InternalServerError,
    ServiceUnavailable,
}
```

## Envelope DTOs

```rust
pub struct ApiResponse<T> {
    pub success: bool,
    pub data: Option<T>,
    pub error: Option<ApiErrorDto>,
    pub meta: serde_json::Value,
}
```

```rust
pub struct ApiErrorResponse {
    pub success: bool,
    pub data: Option<serde_json::Value>,
    pub error: ApiErrorDto,
    pub meta: serde_json::Value,
}
```

## Register behavior

`RegisterRequest` supports either `organization_id` or `organization_name`, but not both.

- `organization_id`: join an existing organization. If not found, returns `VALIDATION_ERROR`.
- `organization_name`: create or join an organization by generated slug.
- both fields together: returns `VALIDATION_ERROR`.

`RegisterResponse.organization` returns the joined or created organization when registration is organization-scoped.

## Public form access

`validatePublicFormAccess` returns a short-lived `access_token` when allowed. `submitPublicForm` must include that value as `public_access_token` whenever the form's public protection requires validation.

## Major JSON examples

Login response envelope:

```json
{
  "success": true,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "uuid.secret",
    "token_type": "Bearer",
    "expires_in": 900,
    "user": {
      "id": "20000000-0000-0000-0000-000000000003",
      "organization_id": "00000000-0000-0000-0000-000000000001",
      "email": "teacher@feedbackflow.local",
      "display_name": "Tom Teacher",
      "primary_role": "teacher",
      "profile": { "locale": "en", "timezone": "Europe/Berlin", "metadata": {} },
      "status": "active",
      "created_at": "2026-05-07T12:00:00Z",
      "updated_at": "2026-05-07T12:00:00Z"
    }
  },
  "error": null,
  "meta": {}
}
```

Error envelope:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "PUBLIC_ACCESS_DENIED",
    "message": "public_access_token is required. Call validatePublicFormAccess before submitPublicForm.",
    "details": { "field": "public_access_token" }
  },
  "meta": {}
}
```

Public submission request:

```json
{
  "anonymous": true,
  "fingerprint_token": "browser-fingerprint-token",
  "public_access_token": "access-token-from-validate-access",
  "captcha_token": "optional-provider-token",
  "answers": [
    {
      "field_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "value": 9,
      "metadata": {}
    }
  ]
}
```
