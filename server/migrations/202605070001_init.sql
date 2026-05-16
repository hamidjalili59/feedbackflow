create extension if not exists pgcrypto;
create extension if not exists citext;

create table organizations (
  id uuid primary key default gen_random_uuid(),
  parent_organization_id uuid references organizations(id),
  name text not null,
  slug text not null unique,
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table users (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations(id),
  email citext not null unique,
  password_hash text not null,
  display_name text not null,
  primary_role text not null check (primary_role in ('guest','parent','teacher','manager','admin','ceo','super_admin')),
  profile jsonb not null default '{}'::jsonb,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index idx_users_org_role on users(organization_id, primary_role) where deleted_at is null;

create table refresh_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  token_hash text not null,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  replaced_by_token_id uuid references refresh_tokens(id),
  created_at timestamptz not null default now()
);
create index idx_refresh_tokens_user on refresh_tokens(user_id);

create table roles (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations(id),
  name text not null check (name in ('guest','parent','teacher','manager','admin','ceo','super_admin')),
  display_name text not null,
  default_permissions jsonb not null default '[]'::jsonb,
  is_system boolean not null default true,
  created_at timestamptz not null default now(),
  unique (organization_id, name)
);

create table permissions (
  id uuid primary key default gen_random_uuid(),
  action text not null,
  resource_type text not null,
  key text not null unique,
  description text,
  created_at timestamptz not null default now()
);

create table role_permissions (
  role_id uuid not null references roles(id) on delete cascade,
  permission_id uuid not null references permissions(id) on delete cascade,
  allowed boolean not null default true,
  primary key(role_id, permission_id)
);

create table organization_role_rules (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  role text not null check (role in ('guest','parent','teacher','manager','admin','ceo','super_admin')),
  rules jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, role)
);

create table user_relationships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  parent_user_id uuid not null references users(id) on delete cascade,
  child_user_id uuid not null references users(id) on delete cascade,
  relationship_type text not null,
  created_at timestamptz not null default now(),
  unique(parent_user_id, child_user_id, relationship_type)
);
create index idx_user_relationships_parent on user_relationships(parent_user_id);
create index idx_user_relationships_child on user_relationships(child_user_id);

create table groups (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  parent_group_id uuid references groups(id),
  group_type text not null check (group_type in ('group','class','department')),
  name text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table group_members (
  group_id uuid not null references groups(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  role_in_group text,
  created_at timestamptz not null default now(),
  primary key(group_id, user_id)
);

create table forms (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  creator_id uuid not null references users(id),
  title text not null,
  description text,
  status text not null default 'draft' check (status in ('draft','pending_review','rejected','approved','scheduled','published','closed','archived')),
  visibility_mode text not null default 'private' check (visibility_mode in ('private','selected_users','selected_roles','subordinates','organization','public_link')),
  publish_mode text not null default 'private' check (publish_mode in ('private','organization','subordinates','role_based','public_link')),
  settings jsonb not null default '{}'::jsonb,
  visibility jsonb not null default '{}'::jsonb,
  public_protection jsonb not null default '{}'::jsonb,
  scoring_mode text not null default 'none' check (scoring_mode in ('none','quiz','satisfaction','risk_assessment','weighted','custom')),
  scoring_config jsonb not null default '{}'::jsonb,
  scheduled_at timestamptz,
  approved_at timestamptz,
  published_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index idx_forms_org_status on forms(organization_id, status) where deleted_at is null;
create index idx_forms_creator on forms(creator_id) where deleted_at is null;
create index idx_forms_visibility_gin on forms using gin(visibility);

create table form_fields (
  id uuid primary key default gen_random_uuid(),
  form_id uuid not null references forms(id) on delete cascade,
  field_type text not null,
  label text not null,
  description text,
  placeholder text,
  required boolean not null default false,
  order_index integer not null default 0,
  config jsonb not null default '{}'::jsonb,
  validation jsonb not null default '{}'::jsonb,
  visibility_conditions jsonb not null default '[]'::jsonb,
  scoring_config jsonb not null default '{}'::jsonb,
  permissions jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index idx_form_fields_form_order on form_fields(form_id, order_index) where deleted_at is null;
create index idx_form_fields_config_gin on form_fields using gin(config);

create table form_visibility_rules (
  id uuid primary key default gen_random_uuid(),
  form_id uuid not null references forms(id) on delete cascade,
  rule_type text not null check (rule_type in ('can_see','can_answer','cannot_see','cannot_answer')),
  audience_type text not null,
  audience_id uuid,
  role text,
  config jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index idx_form_visibility_rules_form on form_visibility_rules(form_id);

create table form_publish_rules (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  role text not null,
  rules jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(organization_id, role)
);

create table form_approval_requests (
  id uuid primary key default gen_random_uuid(),
  form_id uuid not null references forms(id) on delete cascade,
  requester_id uuid not null references users(id),
  reviewer_id uuid references users(id),
  status text not null check (status in ('not_required','pending','approved','rejected','cancelled')),
  note text,
  reviewer_comment text,
  requested_at timestamptz not null default now(),
  reviewed_at timestamptz
);
create index idx_form_approval_form_status on form_approval_requests(form_id, status);

create table public_form_tokens (
  id uuid primary key default gen_random_uuid(),
  form_id uuid not null references forms(id) on delete cascade,
  token text not null unique,
  enabled boolean not null default true,
  expires_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);
create index idx_public_form_tokens_form on public_form_tokens(form_id) where enabled=true and revoked_at is null;

create table form_submissions (
  id uuid primary key default gen_random_uuid(),
  form_id uuid not null references forms(id) on delete cascade,
  respondent_user_id uuid references users(id),
  guest_token_id uuid references public_form_tokens(id),
  anonymous boolean not null default false,
  fingerprint_token text,
  valid boolean not null default true,
  total_score double precision not null default 0,
  max_score double precision not null default 0,
  percentage_score double precision not null default 0,
  score_category text,
  submitted_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index idx_form_submissions_form on form_submissions(form_id, submitted_at desc) where deleted_at is null;
create unique index idx_single_user_submission on form_submissions(form_id, respondent_user_id) where respondent_user_id is not null and deleted_at is null;
create index idx_public_submissions_fingerprint on form_submissions(form_id, fingerprint_token) where fingerprint_token is not null and deleted_at is null;

create table form_answers (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references form_submissions(id) on delete cascade,
  field_id uuid not null references form_fields(id),
  value jsonb not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index idx_form_answers_submission on form_answers(submission_id);
create index idx_form_answers_value_gin on form_answers using gin(value);

create table score_templates (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations(id) on delete cascade,
  field_type text,
  scoring_mode text not null,
  name text not null,
  config jsonb not null default '{}'::jsonb,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table score_breakdowns (
  submission_id uuid primary key references form_submissions(id) on delete cascade,
  result jsonb not null,
  created_at timestamptz not null default now()
);

create table activity_rules (
  id uuid primary key default gen_random_uuid(),
  form_id uuid not null references forms(id) on delete cascade,
  trigger_type text not null,
  condition jsonb not null default '{}'::jsonb,
  action_type text not null,
  action_config jsonb not null default '{}'::jsonb,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index idx_activity_rules_form_enabled on activity_rules(form_id, enabled) where deleted_at is null;

create table activities (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  form_id uuid references forms(id) on delete set null,
  submission_id uuid references form_submissions(id) on delete set null,
  assigned_to_user_id uuid references users(id),
  title text not null,
  description text,
  status text not null default 'open' check (status in ('open','in_progress','completed','cancelled')),
  due_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index idx_activities_org_status on activities(organization_id, status) where deleted_at is null;

create table rate_limit_events (
  id uuid primary key default gen_random_uuid(),
  form_id uuid references forms(id) on delete cascade,
  public_token_id uuid references public_form_tokens(id),
  strategy text not null,
  key_hash text not null,
  allowed boolean not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index idx_rate_limit_events_form_time on rate_limit_events(form_id, created_at desc);

create table audit_logs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations(id) on delete set null,
  actor_user_id uuid references users(id) on delete set null,
  action text not null,
  resource_type text not null,
  resource_id uuid,
  ip_address text,
  user_agent text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index idx_audit_logs_org_time on audit_logs(organization_id, created_at desc);
create index idx_audit_logs_actor_time on audit_logs(actor_user_id, created_at desc);
