-- Promote or create the requested phone-based Super Admin account.
--
-- IMPORTANT:
-- Do not edit previous migration files after they have been applied.
-- SQLx verifies migration checksums, so this migration intentionally applies the
-- new phone-based bootstrap requirement as a new versioned migration.
--
-- Login phone: +989361360584
-- Optional contact email: hamidjalili9010@gmail.com
-- Password: Alijahany59, stored as Argon2id hash only.

alter table users add column if not exists phone text;

with existing_phone_user as (
  select id
  from users
  where phone = '+989361360584'
    and deleted_at is null
  limit 1
),
existing_email_user as (
  select id
  from users
  where lower(email::text) = 'hamidjalili9010@gmail.com'
    and deleted_at is null
  limit 1
),
target_user as (
  select id from existing_phone_user
  union all
  select id from existing_email_user
  where not exists (select 1 from existing_phone_user)
  limit 1
),
inserted_user as (
  insert into users (
    id,
    organization_id,
    phone,
    email,
    password_hash,
    display_name,
    primary_role,
    profile,
    status,
    deleted_at
  )
  select
    'ffffffff-ffff-ffff-ffff-fffffffffff1',
    null,
    '+989361360584',
    'hamidjalili9010@gmail.com',
    '$argon2id$v=19$m=65536,t=3,p=2$iR3PlIXUyYlZ56liXtKJQw$tTnUkFBWyyPjMTe/brdQSX+CDVoaDSvwu10CTZZFT4M',
    'Hamid Jalili',
    'super_admin',
    '{"locale":"fa","timezone":"Europe/Tehran","metadata":{"source":"bootstrap_phone_super_admin_migration"}}'::jsonb,
    'active',
    null
  where not exists (select 1 from target_user)
  on conflict (id) do update set
    phone = excluded.phone,
    email = excluded.email,
    password_hash = excluded.password_hash,
    primary_role = 'super_admin',
    status = 'active',
    deleted_at = null,
    updated_at = now(),
    profile = users.profile || '{"metadata":{"source":"bootstrap_phone_super_admin_migration","promoted_to":"super_admin"}}'::jsonb
  returning id
),
selected_user as (
  select id from target_user
  union all
  select id from inserted_user
  limit 1
),
updated_user as (
  update users
  set
    phone = '+989361360584',
    email = case
      when email is null
        and not exists (
          select 1
          from users other_user
          where lower(other_user.email::text) = 'hamidjalili9010@gmail.com'
            and other_user.deleted_at is null
            and other_user.id <> users.id
        )
      then 'hamidjalili9010@gmail.com'
      else email
    end,
    password_hash = '$argon2id$v=19$m=65536,t=3,p=2$iR3PlIXUyYlZ56liXtKJQw$tTnUkFBWyyPjMTe/brdQSX+CDVoaDSvwu10CTZZFT4M',
    primary_role = 'super_admin',
    status = 'active',
    deleted_at = null,
    updated_at = now(),
    profile = users.profile || '{"metadata":{"source":"bootstrap_phone_super_admin_migration","promoted_to":"super_admin","login_phone":"+989361360584"}}'::jsonb
  where id = (select id from selected_user)
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
  '{"source":"migration","change":"phone_super_admin_bootstrap","login_phone":"+989361360584","email":"hamidjalili9010@gmail.com","role":"super_admin"}'::jsonb
from updated_user;
