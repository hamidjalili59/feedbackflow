-- Bootstrap the initial Super Admin account.
-- This migration is intentionally idempotent:
-- - If the user does not exist, it creates the account.
-- - If the user already exists, it promotes the account to super_admin,
--   reactivates it, clears deleted_at, and sets the bootstrap password hash.
--
-- Login email: hamidjalili9010@gmail.com
-- Password is stored as Argon2id hash, never as plaintext.

with upserted_super_admin as (
  insert into users (
    id,
    organization_id,
    email,
    password_hash,
    display_name,
    primary_role,
    profile,
    status,
    deleted_at
  ) values (
    'ffffffff-ffff-ffff-ffff-fffffffffff1',
    null,
    'hamidjalili9010@gmail.com',
    '$argon2id$v=19$m=65536,t=3,p=2$iR3PlIXUyYlZ56liXtKJQw$tTnUkFBWyyPjMTe/brdQSX+CDVoaDSvwu10CTZZFT4M',
    'Hamid Jalili',
    'super_admin',
    '{"locale":"fa","timezone":"Europe/Berlin","metadata":{"source":"bootstrap_migration"}}'::jsonb,
    'active',
    null
  )
  on conflict (email) do update set
    password_hash = excluded.password_hash,
    primary_role = 'super_admin',
    status = 'active',
    deleted_at = null,
    updated_at = now(),
    profile = users.profile || '{"metadata":{"source":"bootstrap_migration","promoted_to":"super_admin"}}'::jsonb
  returning id, organization_id
)
insert into audit_logs (
  organization_id,
  actor_user_id,
  action,
  resource_type,
  resource_id,
  details
)
select
  organization_id,
  id,
  'permission_changed',
  'user',
  id,
  '{"source":"migration","email":"hamidjalili9010@gmail.com","role":"super_admin"}'::jsonb
from upserted_super_admin;
