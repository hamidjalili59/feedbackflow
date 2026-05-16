# Generated OpenAPI structure

`GET /openapi.json` returns the OpenAPI 3.1 contract used by Flutter/Dart clients. The contract is the single source of truth for DTOs, enums, authentication, endpoint paths, operation IDs, and response envelopes.

Top-level shape:

```json
{
  "openapi": "3.1.0",
  "info": {
    "title": "FeedbackFlow Server API",
    "version": "0.1.0"
  },
  "paths": {
    "/api/v1/auth/login": {
      "post": {
        "operationId": "login",
        "tags": ["Auth"],
        "requestBody": {
          "content": {
            "application/json": {
              "schema": { "$ref": "#/components/schemas/LoginRequest" }
            }
          }
        },
        "responses": {
          "200": {
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/ApiResponse_LoginResponse" }
              }
            }
          },
          "401": {
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/ApiErrorResponse" }
              }
            }
          }
        }
      }
    }
  },
  "components": {
    "securitySchemes": {
      "bearer_auth": { "type": "http", "scheme": "bearer" }
    },
    "schemas": {
      "ApiErrorResponse": {},
      "PaginationMeta": {},
      "RegisterRequest": {},
      "RegisterResponse": {},
      "LoginRequest": {},
      "LoginResponse": {},
      "CreateFormRequest": {},
      "FormDetailDto": {},
      "FormFieldDto": {},
      "PublicSubmissionRequest": {},
      "ScoreTemplateDto": {},
      "ActivityDto": {}
    }
  }
}
```

## Envelope rules

Single-resource success responses use:

```json
{
  "success": true,
  "data": {},
  "error": null,
  "meta": {}
}
```

List responses use:

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

Error responses always include `data: null`:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human readable message",
    "details": {}
  },
  "meta": {}
}
```

All enums use snake_case JSON values except `ErrorCode`, which uses SCREAMING_SNAKE_CASE.

## Recently stabilized endpoints

The following endpoints are part of the stable Flutter contract:

- `PATCH /api/v1/users/me` with operationId `updateMyProfile`
- `GET /api/v1/permissions/publishing-rules` with operationId `getPublishingRules`
- `GET /api/v1/score-templates` with operationId `listScoreTemplates`
- `POST /api/v1/score-templates` with operationId `createScoreTemplate`
- `GET /api/v1/score-templates/{id}` with operationId `getScoreTemplate`
- `PATCH /api/v1/score-templates/{id}` with operationId `updateScoreTemplate`
- `DELETE /api/v1/score-templates/{id}` with operationId `deleteScoreTemplate`
- `GET /api/v1/activities/{id}` with operationId `getActivity`
- `PATCH /api/v1/activities/{id}` with operationId `updateActivity`
- `GET /api/v1/forms/{id}/activity-rules` with operationId `listActivityRules`
