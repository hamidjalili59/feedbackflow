alter table users add column if not exists gender text;

alter table users drop constraint if exists users_gender_check;
alter table users
  add constraint users_gender_check
  check (gender is null or gender in ('female','male','other','prefer_not_to_say'));

create index if not exists idx_users_org_gender_active
  on users(organization_id, gender)
  where deleted_at is null;

create index if not exists idx_form_submissions_form_mode
  on form_submissions(form_id, respondent_mode)
  where deleted_at is null;

create index if not exists idx_form_submissions_submitted_at
  on form_submissions(submitted_at)
  where deleted_at is null;
