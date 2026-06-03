-- The application already enforces one_submission_per_user per form setting.
-- A global unique index made repeat submissions fail even when that setting was false.
drop index if exists idx_single_user_submission;
