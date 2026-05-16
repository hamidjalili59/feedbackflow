# FeedbackFlow Server

Production-oriented Rust backend for a multi-role feedback, survey, and form platform designed for Flutter/Dart clients through a stable REST API and OpenAPI contract.

## Architecture

FeedbackFlow Server uses a layered architecture:

1. **HTTP/API layer**: Axum routers under `/api/v1`, Swagger UI at `/docs`, OpenAPI JSON at `/openapi.json`.
2. **DTO contract layer**: API DTOs live under `src/api_types`. Database models are not exposed directly.
3. **Security layer**: Argon2 password hashing, JWT access tokens, refresh-token rotation, RBAC/ABAC authorization, public-form throttling, audit logs.
4. **Domain services**: Forms, fields, submissions, scoring, activities, public forms, organizations, permissions, and users.
5. **Persistence layer**: PostgreSQL via SQLx. UUID primary keys, JSONB flexible configs, soft deletes, indexes, constraints, and migrations.
6. **Extension layer**: CAPTCHA, email/phone verification, file storage, notifications, webhooks, and Redis-backed rate limiting can be added behind service interfaces.

## Project structure

```text
src/
  main.rs
  config.rs
  app_state.rs
  error.rs
  response.rs
  api_types/
  auth/
  users/
  organizations/
  permissions/
  forms/
  fields/
  submissions/
  scoring/
  activities/
  public_forms/
  audit/
  rate_limit/
  db/
  middleware/
  openapi/
migrations/
seeds/
tests/
docs/
```

## Technology choices

- Rust stable
- Axum + Tokio
- SQLx + PostgreSQL
- UUID primary keys
- JSONB for field config, validation, visibility, scoring, permissions, activities, and organization settings
- Utoipa + Swagger UI for OpenAPI
- Argon2 for password hashing
- JWT access tokens with refresh token rotation
- Tower HTTP layers for CORS, tracing, timeout, and compression

## Setup

```bash
cp .env.example .env
docker compose up -d postgres redis
cargo run
```

Apply seed data after migrations:

```bash
psql postgres://feedbackflow:feedbackflow@localhost:5432/feedbackflow -f seeds/dev_seed.sql
```

Default seeded users all use password `Password123!`:

- `admin@feedbackflow.local`
- `manager@feedbackflow.local`
- `teacher@feedbackflow.local`
- `parent@feedbackflow.local`

## API envelope

Every success response uses:

```json
{
  "success": true,
  "data": {},
  "error": null,
  "meta": {}
}
```

Every error response uses:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "PERMISSION_DENIED",
    "message": "Human readable message",
    "details": {}
  },
  "meta": {}
}
```

List responses include pagination:

```json
{
  "success": true,
  "data": [],
  "error": null,
  "meta": {
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total_items": 100,
      "total_pages": 5,
      "has_next": true,
      "has_previous": false
    }
  }
}
```

## Major endpoints

### Auth

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/logout`
- `GET /api/v1/auth/me`

### Users and organizations

- `GET /api/v1/users/me`
- `GET /api/v1/users/{id}`
- `GET /api/v1/users/{id}/subordinates`
- `GET /api/v1/organizations/{id}`
- `GET /api/v1/organizations/{id}/roles`
- `PATCH /api/v1/organizations/{id}/role-rules`

### Permissions

- `GET /api/v1/permissions/effective`
- `GET /api/v1/permissions/field-types`
- `PATCH /api/v1/permissions/field-types`
- `PATCH /api/v1/permissions/publishing-rules`

### Forms and fields

- `POST /api/v1/forms`
- `GET /api/v1/forms`
- `GET /api/v1/forms/{id}`
- `PATCH /api/v1/forms/{id}`
- `DELETE /api/v1/forms/{id}`
- `POST /api/v1/forms/{id}/fields`
- `PATCH /api/v1/forms/{id}/fields/{field_id}`
- `DELETE /api/v1/forms/{id}/fields/{field_id}`
- `POST /api/v1/forms/{id}/duplicate`
- `POST /api/v1/forms/{id}/submit-for-approval`
- `POST /api/v1/forms/{id}/approve`
- `POST /api/v1/forms/{id}/reject`
- `POST /api/v1/forms/{id}/publish`
- `POST /api/v1/forms/{id}/close`
- `POST /api/v1/forms/{id}/archive`
- `PATCH /api/v1/forms/{id}/visibility`
- `PATCH /api/v1/forms/{id}/public-protection`
- `GET /api/v1/forms/{id}/analytics`

### Public forms

- `GET /api/v1/public/forms/{public_token}`
- `POST /api/v1/public/forms/{public_token}/validate-access`
- `POST /api/v1/public/forms/{public_token}/submissions`

### Submissions

- `POST /api/v1/forms/{id}/submissions`
- `GET /api/v1/forms/{id}/submissions`
- `GET /api/v1/submissions/{id}`
- `PATCH /api/v1/submissions/{id}`
- `DELETE /api/v1/submissions/{id}`
- `GET /api/v1/submissions/{id}/score-breakdown`

### Activities and audit

- `GET /api/v1/activities`
- `POST /api/v1/forms/{id}/activity-rules`
- `PATCH /api/v1/activity-rules/{id}`
- `DELETE /api/v1/activity-rules/{id}`
- `GET /api/v1/audit-logs`

## Permission model

The permission engine combines:

- **RBAC defaults** by role.
- **ABAC checks** for organization boundary, ownership, form status, publish mode, visibility, and reviewer role.
- **Organization role rules** in `organization_role_rules.rules` JSONB.
- **Field type permissions** per role.
- **Publishing and approval rules** per role.

Important server-side rules implemented:

- Teachers require approval by default and cannot publish directly.
- Admin/CEO/Super Admin can manage permission rules.
- Organization boundary checks are enforced for non-global roles.
- Visibility exclusions override inclusions.
- Forms must be published before they can be answered.
- Private forms cannot be answered by guests.
- Public-link forms require `guest_can_answer` or `guests_can_answer` to accept guest submissions.
- Public forms use rate limits unless a permitted publisher disables them.
- Disabling public protection creates an audit log.
- Field type and scoring config changes are validated against effective permissions.

## OpenAPI

The service exposes:

- `GET /openapi.json`
- `GET /docs`

The OpenAPI contract is code-first using `utoipa` and DTOs under `src/api_types` derive `Serialize`, `Deserialize`, and `ToSchema`. Operation IDs are unique and client-friendly, for example `login`, `createForm`, `publishForm`, `getPublicForm`, and `submitPublicForm`.

## Example curl flow

Login:

```bash
curl -s http://localhost:8080/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"teacher@feedbackflow.local","password":"Password123!"}'
```

Create a form:

```bash
TOKEN="paste-access-token"
curl -s http://localhost:8080/api/v1/forms \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "title":"Parent Satisfaction Survey",
    "description":"Monthly pulse survey",
    "settings":{
      "allow_anonymous_answers":true,
      "one_submission_per_user":true,
      "answers_editable_after_submission":false,
      "start_at":null,
      "end_at":null,
      "max_submissions":null,
      "submission_cooldown_seconds":30,
      "submission_mode":"single_submission",
      "answer_visibility":"visible_to_creator",
      "guests_can_answer":false,
      "metadata":{}
    },
    "visibility":{
      "mode":"organization",
      "can_see":[],
      "can_answer":[],
      "cannot_see":[],
      "cannot_answer":[],
      "guest_can_answer":false,
      "anonymous_allowed":true,
      "metadata":{}
    },
    "scoring_mode":"satisfaction",
    "scoring_config":{}
  }'
```

Add a field:

```bash
FORM_ID="paste-form-id"
curl -s http://localhost:8080/api/v1/forms/$FORM_ID/fields \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "type":"nps",
    "label":"How likely are you to recommend us?",
    "description":null,
    "placeholder":null,
    "required":true,
    "order_index":0,
    "config":{"min":0,"max":10,"step":1,"options":[],"rows":[],"columns":[],"metadata":{}},
    "validation":{},
    "visibility_conditions":[],
    "scoring_config":{"enabled":true,"max_score":10,"weight":1,"option_scores":{},"rules":[],"categories":[],"metadata":{}},
    "permissions":{}
  }'
```

Teacher submits for approval:

```bash
curl -s -X POST http://localhost:8080/api/v1/forms/$FORM_ID/submit-for-approval \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"note":"Ready for review"}'
```

Manager approves:

```bash
MANAGER_TOKEN="paste-manager-token"
curl -s -X POST http://localhost:8080/api/v1/forms/$FORM_ID/approve \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"comment":"Approved","publish_after_approval":false}'
```

Publish:

```bash
curl -s -X POST http://localhost:8080/api/v1/forms/$FORM_ID/publish \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"publish_mode":"organization","visibility":null,"public_protection":null,"scheduled_at":null}'
```

Submit as authenticated user:

```bash
FIELD_ID="paste-field-id"
curl -s -X POST http://localhost:8080/api/v1/forms/$FORM_ID/submissions \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"anonymous":false,"fingerprint_token":"device-abc","answers":[{"field_id":"'"$FIELD_ID"'","value":9,"metadata":{}}]}'
```

## Flutter client connection

The backend can also serve the compiled Flutter web app. Build the client first:

```bash
cd ../feedbackflow_flutter_client
flutter build web --release
```

By default the server serves `../feedbackflow_flutter_client/build/web`. Override it when needed:

```bash
FLUTTER_WEB_DIST_DIR=/app/public cargo run
```

Server routes under `/api`, `/docs`, `/openapi.json`, and `/healthz` stay reserved for the backend. Other safe `GET`/`HEAD` paths fall back to Flutter's `index.html`, so direct visits such as `/public/{token}` open the public form route in the app.

Use the OpenAPI file as the source of truth:

```bash
curl http://localhost:8080/openapi.json -o openapi.json
```

Recommended Dart generators:

```bash
dart pub add dio json_annotation freezed_annotation
dart pub add --dev build_runner json_serializable freezed openapi_generator_cli
```

A typical generated client flow:

```dart
final api = FeedbackFlowApi(basePathOverride: 'http://localhost:8080/api/v1');
final login = await api.getAuthApi().login(
  loginRequest: LoginRequest(email: 'teacher@feedbackflow.local', password: 'Password123!'),
);
final token = login.data!.data!.accessToken;
api.setBearerAuth('bearer_auth', token);
final form = await api.getFormsApi().createForm(createFormRequest: request);
```

For dynamic form rendering, Flutter should use:

- `FormDetailDto.fields`
- `FormFieldDto.type`
- `FormFieldDto.config`
- `FormFieldDto.validation`
- `FormFieldDto.visibility_conditions`
- `FormFieldDto.permissions`
- `FormSettingsDto`
- `FormVisibilityDto`

## Tests

Run unit tests:

```bash
cargo test
```

Run ignored integration smoke tests after bringing up PostgreSQL:

```bash
docker compose up -d postgres
DATABASE_URL=postgres://feedbackflow:feedbackflow@localhost:5432/feedbackflow cargo test --test integration_ignored -- --ignored
```

## Notes for production hardening

This starter is structured for production but should be reviewed before live use:

- Move rate limiting to Redis or a dedicated gateway for multi-instance deployments.
- Add invitation/bootstrap flows for privileged users.
- Add CAPTCHA/email/phone provider implementations.
- Add object storage for actual file upload bytes; this backend stores metadata only.
- Add row-level database policies if required by compliance.
- Add CI that runs migrations, tests, OpenAPI linting, and security scans.
