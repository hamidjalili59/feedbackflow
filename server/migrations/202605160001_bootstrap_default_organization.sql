-- Bootstrap a default organization and assign the super admin to it.
--
-- This migration is idempotent: if the organization already exists it does
-- nothing. If the super admin already has an organization_id it is left
-- unchanged.

-- 1. Create the default organization if it does not exist.
insert into organizations (id, name, slug, settings)
values (
  '00000000-0000-0000-0000-000000000001',
  'سازمان پیش‌فرض',
  'default',
  '{"locale":"fa","timezone":"Asia/Tehran","metadata":{"source":"bootstrap_migration"}}'::jsonb
)
on conflict (slug) do nothing;

-- 2. Assign all users that have no organization to the default one.
update users
set organization_id = '00000000-0000-0000-0000-000000000001',
    updated_at = now()
where organization_id is null
  and deleted_at is null;

-- 3. Ensure the default roles exist for this organization.
insert into roles (id, organization_id, name, display_name, default_permissions, is_system)
values
  ('00000001-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'super_admin', 'مدیر ارشد', '["*"]'::jsonb, true),
  ('00000001-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'admin', 'مدیر', '["forms.*","users.*","submissions.*","activities.*","audit.read"]'::jsonb, true),
  ('00000001-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'ceo', 'مدیرعامل', '["forms.*","users.*","submissions.*","activities.*","audit.read"]'::jsonb, true),
  ('00000001-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'manager', 'مدیر بخش', '["forms.*","submissions.*","activities.*"]'::jsonb, true),
  ('00000001-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 'teacher', 'معلم', '["forms.create","forms.own.*","submissions.own.*"]'::jsonb, true),
  ('00000001-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', 'parent', 'والد', '["forms.answer","submissions.own.read"]'::jsonb, true),
  ('00000001-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000001', 'student', 'دانش‌آموز', '["forms.answer","submissions.own.read"]'::jsonb, true)
on conflict (organization_id, name) do nothing;

-- 4. Audit log
insert into audit_logs (organization_id, actor_user_id, action, resource_type, resource_id, details)
select
  '00000000-0000-0000-0000-000000000001',
  id,
  'organization_created',
  'organization',
  '00000000-0000-0000-0000-000000000001',
  '{"source":"migration","name":"default_organization_bootstrap"}'::jsonb
from users
where primary_role = 'super_admin' and deleted_at is null
limit 1;
