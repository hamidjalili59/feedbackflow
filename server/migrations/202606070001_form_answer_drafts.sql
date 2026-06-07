create table if not exists form_answer_drafts (
  id uuid primary key default gen_random_uuid(),
  form_id uuid not null references forms(id) on delete cascade,
  respondent_user_id uuid not null references users(id) on delete cascade,
  child_user_id uuid references users(id) on delete cascade,
  answers jsonb not null default '{}'::jsonb,
  current_step integer not null default 0 check (current_step >= 0),
  total_steps integer not null default 0 check (total_steps >= 0),
  updated_at timestamptz not null default now(),
  unique nulls not distinct (form_id, respondent_user_id, child_user_id)
);
create index if not exists idx_form_answer_drafts_user_updated
  on form_answer_drafts(respondent_user_id, updated_at desc);
