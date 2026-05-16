# راهنمای آپدیت (استقرار نسخه جدید)

هر بار که کد جدید push کردی و installer جدید ساختی، با این مراحل ساده نسخه جدید رو روی سرور بالا بیار.

## مراحل

### ۱. ساخت installer جدید (روی GitHub)

1. کد رو push کن به `main`
2. برو **Actions → Build Installer → Run workflow**
3. (اختیاری) ورژن بذار مثل `0.0.2`
4. صبر کن تا سبز بشه (~۱۰ دقیقه)
5. از قسمت **Artifacts** فایل `feedbackflow-installer-...` رو دانلود کن
6. zip رو extract کن → فایل `.tar.gz` بیرون میاد

### ۲. انتقال به سرور (روی لپ‌تاپ)

```bash
scp feedbackflow-installer-<version>.tar.gz feedbackflow@YOUR_SERVER_IP:~/
```

### ۳. نصب روی سرور

```bash
ssh feedbackflow@YOUR_SERVER_IP
```

```bash
mkdir -p ~/feedbackflow-update
tar -xzf ~/feedbackflow-installer-<version>.tar.gz -C ~/feedbackflow-update
cd ~/feedbackflow-update
sudo ./install.sh
```

تموم. سرویس restart می‌شه، migration های جدید خودکار اجرا می‌شن.

### ۴. تأیید

```bash
curl http://127.0.0.1:8080/healthz
# باید ok برگردونه

sudo journalctl -u feedbackflow -n 20 --no-pager
# باید "FeedbackFlow Server listening" ببینی بدون error
```

از مرورگر هم چک کن:
```
http://YOUR_SERVER_IP/healthz
```

## نکات مهم

- **نیازی به تغییر `.env` نیست** — فایل env از نسخه قبل دست‌نخورده می‌مونه
- **نیازی به دستکاری Postgres نیست** — migration ها خودکار اجرا می‌شن
- **نیازی به restart nginx نیست** — nginx به `127.0.0.1:8080` وصله و سرویس خودش restart می‌شه
- **اگه مشکل خورد**، rollback کن (بخش پایین)

## Rollback (برگشت به نسخه قبل)

اسکریپت ۵ نسخه آخر رو نگه می‌داره:

```bash
# ببین چه نسخه‌هایی داری
ls /opt/feedbackflow/releases/

# برگرد به نسخه قبلی
sudo ln -sfn /opt/feedbackflow/releases/<OLDER_TIMESTAMP> /opt/feedbackflow/current
sudo systemctl restart feedbackflow

# تأیید
curl http://127.0.0.1:8080/healthz
```

## خلاصه یک‌خطی

```bash
# روی لپ‌تاپ:
scp feedbackflow-installer-NEW.tar.gz feedbackflow@SERVER:~/

# روی سرور:
mkdir -p ~/feedbackflow-update && tar -xzf ~/feedbackflow-installer-NEW.tar.gz -C ~/feedbackflow-update && cd ~/feedbackflow-update && sudo ./install.sh && curl http://127.0.0.1:8080/healthz
```
