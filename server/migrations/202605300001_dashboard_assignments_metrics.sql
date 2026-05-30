-- Dashboard-ready data model for targeted survey assignments, reusable audience segments, and dynamic metrics.
-- These tables are additive and keep the older visibility JSON model working.

create table if not exists audience_segments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  name text not null,
  slug text not null,
  description text,
  segment_type text not null default 'static'
    check (segment_type in ('static','dynamic','event','camp','cohort','custom')),
  rules jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  enabled boolean not null default true,
  created_by_user_id uuid references users(id) on delete set null,
  updated_by_user_id uuid references users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create unique index if not exists idx_audience_segments_org_slug_active
  on audience_segments(organization_id, lower(slug))
  where deleted_at is null;

create index if not exists idx_audience_segments_org_type_active
  on audience_segments(organization_id, segment_type, enabled)
  where deleted_at is null;

create table if not exists audience_segment_members (
  segment_id uuid not null references audience_segments(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  role_snapshot text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key(segment_id, user_id)
);

create index if not exists idx_audience_segment_members_user
  on audience_segment_members(user_id, segment_id);

create table if not exists form_assignments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  form_id uuid not null references forms(id) on delete cascade,
  audience_type text not null
    check (audience_type in ('user','role','group','class','department','organization','segment')),
  audience_user_id uuid references users(id) on delete cascade,
  audience_role text check (audience_role is null or audience_role in ('guest','parent','student','teacher','manager','admin','ceo','super_admin')),
  audience_group_id uuid references groups(id) on delete cascade,
  audience_segment_id uuid references audience_segments(id) on delete cascade,
  label text,
  can_see boolean not null default true,
  can_answer boolean not null default true,
  assigned_by_user_id uuid references users(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists idx_form_assignments_form_active
  on form_assignments(form_id, audience_type)
  where deleted_at is null;

create index if not exists idx_form_assignments_org_active
  on form_assignments(organization_id, created_at desc)
  where deleted_at is null;

create index if not exists idx_form_assignments_user_active
  on form_assignments(audience_user_id, form_id)
  where audience_user_id is not null and deleted_at is null;

create index if not exists idx_form_assignments_role_active
  on form_assignments(organization_id, audience_role, form_id)
  where audience_role is not null and deleted_at is null;

create index if not exists idx_form_assignments_group_active
  on form_assignments(audience_group_id, form_id)
  where audience_group_id is not null and deleted_at is null;

create index if not exists idx_form_assignments_segment_active
  on form_assignments(audience_segment_id, form_id)
  where audience_segment_id is not null and deleted_at is null;

create table if not exists metric_definitions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  key text not null,
  title text not null,
  description text,
  metric_type text not null default 'score'
    check (metric_type in ('score','percentage','rating','count','label','custom')),
  aggregation_method text not null default 'avg'
    check (aggregation_method in ('avg','sum','count','min','max','latest')),
  scale_min double precision,
  scale_max double precision,
  positive_direction text not null default 'higher_is_better'
    check (positive_direction in ('higher_is_better','lower_is_better','neutral')),
  thresholds jsonb not null default '[]'::jsonb,
  display jsonb not null default '{}'::jsonb,
  enabled boolean not null default true,
  created_by_user_id uuid references users(id) on delete set null,
  updated_by_user_id uuid references users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create unique index if not exists idx_metric_definitions_org_key_active
  on metric_definitions(organization_id, lower(key))
  where deleted_at is null;

create index if not exists idx_metric_definitions_org_enabled_active
  on metric_definitions(organization_id, enabled, created_at desc)
  where deleted_at is null;

create table if not exists metric_mappings (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  metric_id uuid not null references metric_definitions(id) on delete cascade,
  form_id uuid references forms(id) on delete cascade,
  field_id uuid references form_fields(id) on delete cascade,
  source_type text not null default 'field_answer'
    check (source_type in ('field_answer','submission_score','submission_percentage','submission_count','custom')),
  transform jsonb not null default '{}'::jsonb,
  weight double precision not null default 1,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists idx_metric_mappings_metric_active
  on metric_mappings(metric_id, enabled)
  where deleted_at is null;

create index if not exists idx_metric_mappings_form_field_active
  on metric_mappings(form_id, field_id)
  where deleted_at is null;
