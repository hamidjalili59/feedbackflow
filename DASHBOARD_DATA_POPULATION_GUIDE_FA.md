# راهنمای پر شدن داده‌های داشبورد

این سند توضیح می‌دهد هر قسمت داشبورد از کدام داده واقعی دیتابیس ساخته می‌شود و راه منطقی پر کردن آن چیست. داشبورد از مسیر `GET /api/v1/dashboards/me` تغذیه می‌شود و نقش کاربر (`parent`, `student`, `teacher`, `manager`, `admin`, `ceo`, `super_admin`) تعیین می‌کند چه بخش‌هایی نمایش داده شود.

## اصول مشترک

داده‌های اصلی داشبورد از این جدول‌ها می‌آیند:

- `users`: کاربر، نقش، نام، پروفایل و عکس.
- `user_relationships`: رابطه والد و دانش‌آموز.
- `groups` و `group_members`: کلاس، شعبه، دپارتمان و عضویت دانش‌آموز/معلم.
- `forms` و `form_fields`: فرم‌ها، وضعیت انتشار، دسته‌بندی، زمان‌بندی و سؤال‌ها.
- `form_assignments`: هدف‌گذاری فرم برای کاربر، نقش، کلاس، گروه، سگمنت یا کل سازمان.
- `audience_segments` و `audience_segment_members`: سگمنت‌های reusable برای هدف‌گذاری.
- `form_submissions` و `form_answers`: پاسخ‌ها، امتیاز کل، درصد امتیاز و جواب فیلدها.
- `metric_definitions` و `metric_mappings`: تعریف شاخص‌های داشبورد و اتصال آن‌ها به پاسخ‌ها یا امتیاز فرم‌ها.
- `activities`: فعالیت‌های عملیاتی و هشدارهای کاربر.

## والد

نمای والد باید از لیست دانش‌آموزان شروع شود. این لیست از `user_relationships` با `relationship_type = parent_child` ساخته می‌شود.

برای پر کردن:

1. دانش‌آموز و والد را در `users` بسازید.
2. در مدیریت کاربران، Family relationships را باز کنید و والد را به دانش‌آموز وصل کنید.
3. برای هر دانش‌آموز، اگر کلاس لازم است، او را در `group_members` عضو گروهی از نوع `class` کنید.
4. برای نمایش عکس، `users.profile.avatar_url` را تنظیم کنید. اگر عکس وجود نداشته باشد UI حروف اول نام و نام خانوادگی را نشان می‌دهد.

بخش‌های والد:

- کارت دانش‌آموز: `users.display_name`, `users.profile.avatar_url`, `users.profile.metadata.grade_label`, آخرین کلاس از `group_members`.
- نظرسنجی‌های جدید و آخرین نظرسنجی‌ها: `forms` منتشر/زمان‌بندی/بسته‌شده، فیلتر شده با `visibility` و `form_assignments`. اگر `child_id` انتخاب شده باشد assignmentهای خود دانش‌آموز هم لحاظ می‌شود.
- وضعیت نظرسنجی‌ها: از وضعیت همان لیست survey ساخته می‌شود؛ پاسخ موجود در `form_submissions` یعنی completed.
- تقویم نظرسنجی‌ها: از `forms.published_at`, `forms.scheduled_at`, `forms.closed_at` و همان دسترسی کاربر/دانش‌آموز انتخاب‌شده می‌آید.
- فعالیت‌های اخیر: از `activities` که به کاربر assign شده یا عمومی سازمان است.

## دانش‌آموز

دانش‌آموز داشبورد خودش را می‌بیند.

برای پر کردن:

1. کاربر با نقش `student` بسازید.
2. او را به کلاس/گروه مربوط وصل کنید.
3. فرم را منتشر کنید و از `form_assignments` به دانش‌آموز، نقش student، کلاس یا سگمنت مربوط assign کنید.
4. دانش‌آموز فرم را پاسخ دهد تا `form_submissions` و `form_answers` ساخته شود.

بخش‌ها:

- پروفایل دانش‌آموز: از `users`.
- نظرسنجی‌های قابل پاسخ: از `forms` + `form_assignments` + `visibility`.
- نمودار مشارکت: از تعداد `form_submissions` در بازه انتخابی.
- شاخص‌ها: از `metric_definitions` و `metric_mappings`.

## معلم

معلم بیشتر نمای عملیاتی از فرم‌ها و پاسخ‌های مرتبط با خودش دارد.

برای پر کردن:

1. کاربر با نقش `teacher` بسازید.
2. معلم فرم ایجاد کند یا فرم‌ها به نقش/گروه مربوط assign شوند.
3. فرم منتشر شود.
4. مخاطبان فرم پاسخ دهند تا `form_submissions` ایجاد شود.
5. اگر رتبه‌بندی معلم‌ها لازم است، فرم‌های معلمان باید scoring داشته باشند تا `percentage_score` در `form_submissions` پر شود.

بخش‌ها:

- نمودار مشارکت: از `form_submissions` سازمان در بازه.
- کارت‌های عملیاتی: از summary پاسخ‌ها و فعالیت‌ها.
- شاخص‌ها: از metricها و mappingها.

## مدیر، ادمین، مدیرعامل و سوپرادمین

این نقش‌ها نمای مدیریتی کامل‌تر می‌بینند.

برای پر کردن:

1. فرم‌ها را بسازید و publish کنید.
2. assignments را برای نقش‌ها، کلاس‌ها، گروه‌ها یا سگمنت‌ها تنظیم کنید.
3. پاسخ ثبت کنید.
4. metricها و mappingها را بسازید یا از metricهای پیش‌فرض migration استفاده کنید.
5. برای رتبه‌بندی معلم‌ها، فرم‌هایی که creator آن‌ها معلم است باید پاسخ دارای `percentage_score` داشته باشند.

بخش‌ها:

- نمودار مشارکت سازمان: تعداد `form_submissions` در بازه.
- شاخص‌های داینامیک: `metric_definitions` فعال + `metric_mappings`.
- تقویم: فرم‌های قابل مشاهده در بازه.
- آخرین نظرسنجی‌ها: `forms` قابل مشاهده/assign شده.
- فعالیت‌ها: `activities`.
- برترین معلم‌ها: میانگین `form_submissions.percentage_score` برای فرم‌هایی که `forms.creator_id` آن معلم است، مرتب نزولی.
- ضعیف‌ترین معلم‌ها: همان query، مرتب صعودی.
- تنظیمات metric و segment: `metric_definitions`, `metric_mappings`, `audience_segments`.
- مدیریت کاربران، روابط خانوادگی، فرم‌های در انتظار تایید: از `users`, `user_relationships`, `forms.status = pending_review`.

## شاخص‌های پیش‌فرض

برای اینکه داشبورد سازمان تازه خالی نماند، migration `202605310001_default_dashboard_metrics.sql` سه شاخص پیش‌فرض می‌سازد:

- `participation`: تعداد پاسخ‌ها از `form_submissions`.
- `satisfaction`: میانگین `percentage_score`.
- `response_quality`: میانگین `percentage_score` با نمایش کیفیت.

این‌ها به `metric_mappings` از نوع `submission_count` یا `submission_percentage` وصل می‌شوند و بدون mapping فیلدی هم قابل محاسبه هستند.

برای شاخص‌های اختصاصی:

1. metric بسازید: `POST /api/v1/metrics`.
2. mappingهای آن را تنظیم کنید: `PUT /api/v1/metrics/{id}/mappings`.
3. اگر source `field_answer` است، `form_id` و `field_id` بدهید.
4. اگر source `submission_score`, `submission_percentage`, یا `submission_count` است، `form_id` اختیاری است؛ بدون `form_id` کل سازمان محاسبه می‌شود.

## فرم نمرات و رتبه‌بندی معلم‌ها

برای اینکه «برترین معلم‌ها» و «ضعیف‌ترین معلم‌ها» واقعی باشند:

1. هر معلم باید creator فرم خودش باشد، یا فرم‌های مربوط به معلم با `creator_id` همان معلم ساخته شوند.
2. scoring فرم را فعال کنید.
3. فیلدهای امتیازی مثل rating, numeric, likert یا nps داشته باشید.
4. کاربران فرم را پاسخ دهند.
5. هنگام ثبت پاسخ، server امتیاز را در `form_submissions.total_score`, `max_score`, `percentage_score` ذخیره می‌کند.
6. داشبورد مدیریتی میانگین `percentage_score` فرم‌های هر معلم را ranking می‌کند.

## فعالیت‌ها

فعالیت‌ها از جدول `activities` می‌آیند. راه پر کردن:

- دستی از API فعالیت‌ها: `GET/PATCH /api/v1/activities`.
- خودکار با activity rules فرم: `GET/PUT /api/v1/forms/{id}/activity-rules`.
- هنگام submission، engine قوانین را بررسی می‌کند و اگر شرط match شود، در `activities` رکورد می‌سازد.

## نکات QA

- اگر داشبورد metric ندارد، اول `metric_definitions` و `metric_mappings` را بررسی کنید.
- اگر والد دانش‌آموز نمی‌بیند، `user_relationships` را بررسی کنید.
- اگر فرم در داشبورد کاربر نیست، `forms.status`, `forms.visibility`, و `form_assignments` را بررسی کنید.
- اگر تقویم با دانش‌آموز انتخابی هماهنگ نیست، query باید `child_id` داشته باشد.
- اگر ranking معلم‌ها صفر است، پاسخ‌ها score ندارند یا فرم‌ها creator معلم ندارند.
