# User management and student/parent login fixes

## What changed

- Management users can now create and manage `parent` users from the dashboard user-management panel.
- The create-user form refreshes the user list immediately after a successful create; a full page refresh is no longer required.
- Phone numbers entered in the user-management UI are normalized before being sent to the server. For example `09123456789` becomes `+989123456789`.
- The server also normalizes phone numbers and can still find legacy users that were previously stored as `09...` or `98...`.
- Login errors are now clearer on the login screen. Invalid phone/password is shown as a credential problem instead of a generic session-expired message.

## Migration

A migration was added:

```text
server/migrations/202605300002_normalize_local_mobile_phone_numbers.sql
```

It updates existing local Iranian mobile numbers where safe:

- `09123456789` -> `+989123456789`
- `989123456789` -> `+989123456789`

If a normalized duplicate already exists, the legacy value is left unchanged to avoid violating uniqueness. The server login lookup still checks legacy candidates for compatibility.

## Expected workflow

1. A manager/admin/CEO/super-admin creates a parent, student, or teacher.
2. The user list refreshes automatically.
3. The created user can sign in with the same phone number and password without needing a page refresh or manual database cleanup.
