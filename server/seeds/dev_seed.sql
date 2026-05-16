-- Development seed data. Default password for all seeded users: Password123!
insert into organizations (id, name, slug, settings) values
('00000000-0000-0000-0000-000000000001', 'Acme School', 'acme-school', '{"default_timezone":"Europe/Berlin","public_forms_enabled":true,"default_public_protection_level":"standard","require_audit_for_public_protection_disable":true,"metadata":{}}')
on conflict (id) do nothing;

insert into roles (id, organization_id, name, display_name, default_permissions, is_system) values
('10000000-0000-0000-0000-000000000001', null, 'guest', 'Guest', '["read","answer"]', true),
('10000000-0000-0000-0000-000000000002', null, 'parent', 'Parent', '["read","answer"]', true),
('10000000-0000-0000-0000-000000000003', null, 'teacher', 'Teacher', '["create","read","update","delete","publish","answer","view_results"]', true),
('10000000-0000-0000-0000-000000000004', null, 'manager', 'Manager', '["create","read","update","delete","publish","approve","reject","answer","view_results","export","manage_public_protection"]', true),
('10000000-0000-0000-0000-000000000005', null, 'admin', 'Admin', '["create","read","update","delete","publish","approve","reject","answer","view_results","export","manage_permissions","manage_scoring","manage_public_protection"]', true),
('10000000-0000-0000-0000-000000000006', null, 'ceo', 'CEO', '["create","read","update","delete","publish","approve","reject","answer","view_results","export","manage_permissions","manage_scoring","manage_public_protection"]', true),
('10000000-0000-0000-0000-000000000007', null, 'super_admin', 'Super Admin', '["create","read","update","delete","publish","approve","reject","answer","view_results","export","manage_permissions","manage_scoring","manage_public_protection"]', true)
on conflict (organization_id, name) do nothing;

insert into permissions (action, resource_type, key, description)
select a, r, a || ':' || r, 'System permission ' || a || ' on ' || r
from unnest(array['create','read','update','delete','publish','approve','reject','answer','view_results','export','manage_permissions','manage_scoring','manage_public_protection']) a
cross join unnest(array['form','form_field','submission','activity','user','organization','permission','score_template','audit_log']) r
on conflict (key) do nothing;

insert into organization_role_rules (organization_id, role, rules) values
('00000000-0000-0000-0000-000000000001', 'teacher', '{"role":"teacher","can_create_forms":true,"can_publish_forms":false,"requires_approval_to_publish":true,"two_step_approval_required":true,"can_change_scoring":false,"approver_roles":["manager","admin","ceo","super_admin"],"allowed_field_types":["short_text","long_text","email","phone","number","date","time","single_choice","multiple_choice","dropdown","rating_stars","numeric_rating","slider","likert_scale","yes_no","boolean_switch","nps","emoji_reaction","section_title","description_block","divider","consent_checkbox","terms_acceptance","page_break"],"denied_field_types":["calculated","conditional_logic","score_display"],"metadata":{}}'),
('00000000-0000-0000-0000-000000000001', 'manager', '{"role":"manager","can_create_forms":true,"can_publish_forms":true,"requires_approval_to_publish":false,"two_step_approval_required":false,"can_change_scoring":true,"approver_roles":["admin","ceo","super_admin"],"allowed_field_types":["short_text","long_text","email","phone","number","decimal","date","time","date_time","single_choice","multiple_choice","dropdown","rating_stars","numeric_rating","slider","likert_scale","matrix_single_choice","matrix_multiple_choice","yes_no","boolean_switch","nps","emoji_reaction","file_upload","image_upload","signature","location","ranking","section_title","description_block","divider","consent_checkbox","terms_acceptance","hidden","calculated","conditional_logic","score_display","quiz_question","page_break"],"denied_field_types":[],"metadata":{}}'),
('00000000-0000-0000-0000-000000000001', 'admin', '{"role":"admin","can_create_forms":true,"can_publish_forms":true,"requires_approval_to_publish":false,"two_step_approval_required":false,"can_change_scoring":true,"approver_roles":["ceo","super_admin"],"allowed_field_types":["short_text","long_text","email","phone","number","decimal","date","time","date_time","single_choice","multiple_choice","dropdown","rating_stars","numeric_rating","slider","likert_scale","matrix_single_choice","matrix_multiple_choice","yes_no","boolean_switch","nps","emoji_reaction","file_upload","image_upload","signature","location","ranking","section_title","description_block","divider","consent_checkbox","terms_acceptance","hidden","calculated","conditional_logic","score_display","quiz_question","page_break"],"denied_field_types":[],"metadata":{}}')
on conflict (organization_id, role) do update set rules=excluded.rules, updated_at=now();

insert into users (id, organization_id, phone, email, password_hash, display_name, primary_role, profile, status) values
('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '+491000000001', 'admin@feedbackflow.local', '$argon2id$v=19$m=65536,t=3,p=2$Ito2I3a2pV9/JVKo0+sB9Q$hfcC799IK6BHorLigpPOl95zMMBPZnryuCEt2fr3SJ8', 'Alice Admin', 'admin', '{"locale":"en","timezone":"Europe/Berlin","metadata":{}}', 'active'),
('20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '+491000000002', 'manager@feedbackflow.local', '$argon2id$v=19$m=65536,t=3,p=2$Ito2I3a2pV9/JVKo0+sB9Q$hfcC799IK6BHorLigpPOl95zMMBPZnryuCEt2fr3SJ8', 'Mina Manager', 'manager', '{"locale":"en","timezone":"Europe/Berlin","metadata":{}}', 'active'),
('20000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '+491000000003', 'teacher@feedbackflow.local', '$argon2id$v=19$m=65536,t=3,p=2$Ito2I3a2pV9/JVKo0+sB9Q$hfcC799IK6BHorLigpPOl95zMMBPZnryuCEt2fr3SJ8', 'Tom Teacher', 'teacher', '{"locale":"en","timezone":"Europe/Berlin","metadata":{}}', 'active'),
('20000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', '+491000000004', 'parent@feedbackflow.local', '$argon2id$v=19$m=65536,t=3,p=2$Ito2I3a2pV9/JVKo0+sB9Q$hfcC799IK6BHorLigpPOl95zMMBPZnryuCEt2fr3SJ8', 'Pat Parent', 'parent', '{"locale":"en","timezone":"Europe/Berlin","metadata":{}}', 'active')
on conflict (id) do nothing;

insert into user_relationships (organization_id, parent_user_id, child_user_id, relationship_type) values
('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000003', 'manager_subordinate'),
('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000004', '20000000-0000-0000-0000-000000000003', 'parent_child')
on conflict do nothing;

insert into score_templates (organization_id, field_type, scoring_mode, name, config, is_default) values
(null, 'single_choice', 'quiz', 'Default quiz choice', '{"correct_option_score":1,"incorrect_option_score":0}', true),
(null, 'nps', 'satisfaction', 'Default NPS scoring', '{"promoter_min":9,"passive_min":7,"detractor_max":6}', true),
(null, 'numeric_rating', 'risk_assessment', 'Default risk rating', '{"low":{"min":0,"max":33},"medium":{"min":34,"max":66},"high":{"min":67,"max":100}}', true)
on conflict do nothing;
