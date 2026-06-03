# راهنمای کلاس/گروه و عضویت کاربران در FeedbackFlow

## نتیجه بررسی

در دیتابیس پروژه از قبل دو جدول زیر وجود داشت:

- `groups`: برای نگهداری گروه، کلاس و دپارتمان
- `group_members`: برای عضویت کاربران در گروه‌ها

همچنین فرم‌ها از قبل می‌توانستند به `group/class/department` تخصیص داده شوند، اما مسیر کامل برای **ساخت کلاس/گروه** و **افزودن کاربر به آن** در API و رابط کاربری وجود نداشت. در این نسخه این قابلیت اضافه شد.

## مسیر استفاده در برنامه

در داشبورد نقش‌های مدیریتی، یک کارت جدید با عنوان **مدیریت کلاس‌ها و گروه‌ها** اضافه شده است. از آنجا می‌توانید:

1. نام کلاس/گروه را وارد کنید.
2. نوع را انتخاب کنید: `class`، `group` یا `department`.
3. در صورت نیاز یک کد اختیاری وارد کنید.
4. روی «ساخت کلاس/گروه» بزنید.
5. از دکمه «اعضا» کنار هر کلاس/گروه، کاربر را جستجو و اضافه کنید.

## APIهای اضافه‌شده

همه مسیرها زیر `/api/v1` هستند و نیاز به Bearer JWT دارند. نقش‌های مجاز: `manager`، `admin`، `ceo`، `super_admin`.

### ساخت کلاس یا گروه

```http
POST /api/v1/audience-groups
Content-Type: application/json

{
  "name": "کلاس ۱۰۱",
  "group_type": "class",
  "metadata": { "code": "101" },
  "member_user_ids": []
}
```

### گرفتن لیست کلاس‌ها/گروه‌ها

```http
GET /api/v1/audience-groups?page=1&page_size=50&group_type=class
```

### دریافت جزئیات یک کلاس/گروه

```http
GET /api/v1/audience-groups/{id}
```

### ویرایش کلاس/گروه

```http
PATCH /api/v1/audience-groups/{id}
Content-Type: application/json

{
  "name": "کلاس ۱۰۱ - ویرایش‌شده",
  "group_type": "class",
  "metadata": { "code": "101-A" }
}
```

### حذف کلاس/گروه

```http
DELETE /api/v1/audience-groups/{id}
```

### گرفتن اعضای کلاس/گروه

```http
GET /api/v1/audience-groups/{id}/members
```

### افزودن یک کاربر به کلاس/گروه

```http
POST /api/v1/audience-groups/{id}/members
Content-Type: application/json

{
  "user_id": "USER_UUID",
  "role_in_group": "student"
}
```

### جایگزینی کامل اعضا

```http
PUT /api/v1/audience-groups/{id}/members
Content-Type: application/json

{
  "members": [
    { "user_id": "USER_UUID_1", "role_in_group": "student" },
    { "user_id": "USER_UUID_2", "role_in_group": "teacher" }
  ]
}
```

### حذف یک کاربر از کلاس/گروه

```http
DELETE /api/v1/audience-groups/{id}/members/{user_id}
```

## نکته امنیتی و منطقی

عضویت فقط برای کاربران همان سازمان مجاز است. همچنین پس از حذف نرم یک گروه، تخصیص فرم به آن گروه دیگر نباید از طریق عضویت‌های قدیمی فعال بماند؛ شرط‌های بررسی مخاطب به‌روزرسانی شدند تا فقط گروه‌های حذف‌نشده در نظر گرفته شوند.
