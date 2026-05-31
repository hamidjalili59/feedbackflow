-- Production defaults for dashboard cards.
-- These metrics are intentionally based on submission-level columns so every
-- organization has useful dashboard values before custom field mappings are set.

with inserted as (
  insert into metric_definitions (
    organization_id,
    key,
    title,
    description,
    metric_type,
    aggregation_method,
    scale_min,
    scale_max,
    positive_direction,
    thresholds,
    display,
    enabled
  )
  select
    o.id,
    m.key,
    m.title,
    m.description,
    m.metric_type,
    m.aggregation_method,
    m.scale_min,
    m.scale_max,
    m.positive_direction,
    m.thresholds,
    m.display,
    true
  from organizations o
  cross join (
    values
      (
        'participation',
        'مشارکت',
        'تعداد پاسخ‌های ثبت‌شده در بازه انتخاب‌شده',
        'count',
        'sum',
        0::double precision,
        null::double precision,
        'higher_is_better',
        '[]'::jsonb,
        '{"unit":"","icon":"groups"}'::jsonb,
        'submission_count'
      ),
      (
        'satisfaction',
        'رضایت کلی',
        'میانگین درصد امتیاز پاسخ‌ها در بازه انتخاب‌شده',
        'percentage',
        'avg',
        0::double precision,
        100::double precision,
        'higher_is_better',
        '[{"min":80,"label":"عالی","status":"success"},{"min":50,"max":79.999,"label":"معمولی","status":"warning"},{"max":49.999,"label":"نیازمند توجه","status":"danger"}]'::jsonb,
        '{"unit":"%","icon":"sentiment_satisfied"}'::jsonb,
        'submission_percentage'
      ),
      (
        'response_quality',
        'کیفیت پاسخ‌ها',
        'میانگین درصد امتیاز پاسخ‌ها برای تحلیل کیفیت فرم‌ها',
        'score',
        'avg',
        0::double precision,
        100::double precision,
        'higher_is_better',
        '[{"min":80,"label":"خوب","status":"success"},{"min":50,"max":79.999,"label":"معمولی","status":"warning"},{"max":49.999,"label":"ضعیف","status":"danger"}]'::jsonb,
        '{"unit":"%","icon":"fact_check"}'::jsonb,
        'submission_percentage'
      )
  ) as m(key, title, description, metric_type, aggregation_method, scale_min, scale_max, positive_direction, thresholds, display, source_type)
  where o.deleted_at is null
    and not exists (
      select 1
      from metric_definitions existing
      where existing.organization_id = o.id
        and lower(existing.key) = lower(m.key)
        and existing.deleted_at is null
    )
  returning id, organization_id, key
)
insert into metric_mappings (
  organization_id,
  metric_id,
  source_type,
  weight,
  enabled
)
select
  i.organization_id,
  i.id,
  case
    when i.key = 'participation' then 'submission_count'
    else 'submission_percentage'
  end,
  1,
  true
from inserted i
where not exists (
  select 1
  from metric_mappings mm
  where mm.metric_id = i.id
    and mm.deleted_at is null
);
