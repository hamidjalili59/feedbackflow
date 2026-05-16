create table form_access_codes (
  id uuid primary key default gen_random_uuid(),
  form_id uuid not null references forms(id) on delete cascade,
  code_type text not null check (code_type in ('shared_password','identity_code')),
  label text,
  secret_hash text not null,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  check (
    (code_type = 'shared_password' and label is null)
    or (code_type = 'identity_code' and label is not null)
  )
);

create unique index idx_form_access_codes_one_shared
  on form_access_codes(form_id)
  where code_type='shared_password' and deleted_at is null;

create unique index idx_form_access_codes_identity_label
  on form_access_codes(form_id, lower(label))
  where code_type='identity_code' and deleted_at is null;

create index idx_form_access_codes_form_enabled
  on form_access_codes(form_id, code_type)
  where enabled=true and deleted_at is null;

alter table form_submissions
  add column access_code_id uuid references form_access_codes(id),
  add column respondent_mode text not null default 'authenticated'
    check (respondent_mode in ('anonymous','guest','authenticated','identity_code')),
  add column respondent_label text;

create index idx_form_submissions_access_code
  on form_submissions(form_id, access_code_id)
  where access_code_id is not null and deleted_at is null;
