alter table users drop constraint if exists users_primary_role_check;
alter table users
  add constraint users_primary_role_check
  check (primary_role in ('guest','parent','student','teacher','manager','admin','ceo','super_admin'));

alter table roles drop constraint if exists roles_name_check;
alter table roles
  add constraint roles_name_check
  check (name in ('guest','parent','student','teacher','manager','admin','ceo','super_admin'));

alter table organization_role_rules drop constraint if exists organization_role_rules_role_check;
alter table organization_role_rules
  add constraint organization_role_rules_role_check
  check (role in ('guest','parent','student','teacher','manager','admin','ceo','super_admin'));

alter table forms add column if not exists category text;
alter table forms add column if not exists tags text[] not null default '{}'::text[];

create index if not exists idx_forms_org_category_active
  on forms(organization_id, lower(category))
  where deleted_at is null and category is not null;

create index if not exists idx_forms_tags_gin_active
  on forms using gin(tags)
  where deleted_at is null;

insert into roles (id, organization_id, name, display_name, default_permissions, is_system)
values (
  '10000000-0000-0000-0000-000000000008',
  null,
  'student',
  'Student',
  '["read","answer"]'::jsonb,
  true
)
on conflict do nothing;
