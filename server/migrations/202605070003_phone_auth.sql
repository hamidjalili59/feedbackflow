-- Move authentication from email/password to phone/password.
-- Email becomes optional profile/contact information.
-- This migration is idempotent enough for partially prepared databases and preserves existing users.

alter table users add column if not exists phone text;

with numbered_users as (
  select
    id,
    email,
    row_number() over (order by created_at, id) as rn
  from users
  where phone is null
)
update users u
set phone = case
  when lower(u.email::text) = 'hamidjalili9010@gmail.com' then '+989000000001'
  when lower(u.email::text) = 'admin@feedbackflow.local' then '+491000000001'
  when lower(u.email::text) = 'manager@feedbackflow.local' then '+491000000002'
  when lower(u.email::text) = 'teacher@feedbackflow.local' then '+491000000003'
  when lower(u.email::text) = 'parent@feedbackflow.local' then '+491000000004'
  else '+100000' || lpad(numbered_users.rn::text, 9, '0')
end
from numbered_users
where u.id = numbered_users.id
  and u.phone is null;

update users
set
  primary_role = 'super_admin',
  status = 'active',
  deleted_at = null,
  updated_at = now(),
  phone = '+989000000001'
where lower(email::text) = 'hamidjalili9010@gmail.com';

alter table users alter column phone set not null;

alter table users drop constraint if exists users_email_key;
alter table users alter column email drop not null;

create unique index if not exists idx_users_phone_unique_active
  on users(phone)
  where deleted_at is null;

create unique index if not exists idx_users_email_unique_active
  on users(lower(email::text))
  where email is not null and deleted_at is null;

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
  '{"source":"migration","change":"phone_auth_enabled","login_phone":"+989000000001","email":"hamidjalili9010@gmail.com"}'::jsonb
from users
where lower(email::text) = 'hamidjalili9010@gmail.com';
