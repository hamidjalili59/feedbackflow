# راهنمای نصب آفلاین (سرور بدون دسترسی به GitHub)

این روش وقتی کاربرد داره که سرورت نمی‌تونه مستقیم با GitHub حرف بزنه. workflow رو روی GitHub اجرا می‌کنی، installer رو روی لپ‌تاپ خودت دانلود می‌کنی، با `scp` می‌فرستی روی سرور، و یه اسکریپت می‌زنی. تموم.

> این راهنما برای Ubuntu 22.04 نوشته شده. روی Ubuntu 24.04 و Debian 12 هم بدون تغییر کار می‌کنه.
>
> نسخه انگلیسی: [`OFFLINE-INSTALL.md`](OFFLINE-INSTALL.md)

## ۱. ساخت installer روی GitHub

۱. به تب **Actions** پروژه برو
۲. از لیست workflowهای سمت چپ روی **Build Installer** کلیک کن
۳. روی دکمه **Run workflow** بزن
۴. (اختیاری) فیلد `version` رو پر کن (مثل `v0.1.0`). خالی بذاری، خودش timestamp می‌ذاره.
۵. حدود ۸ تا ۱۲ دقیقه صبر کن

وقتی job سبز شد، توی صفحه run scroll بزن پایین تا قسمت **Artifacts** رو ببینی. یه آیتم به اسم `feedbackflow-installer-<version>` هست. روش کلیک کن — یه فایل `.zip` دانلود می‌شه.

> **چرا zip؟** GitHub همه artifactها رو در یه zip می‌پیچه. وقتی روی لپ‌تاپ extract کنی، فایل اصلی `.tar.gz` بیرون میاد.

## ۲. انتقال به سرور

روی لپ‌تاپ:

```powershell
# Windows (PowerShell)
scp .\feedbackflow-installer-<version>.tar.gz youruser@yourserver:~/
```

```bash
# Linux / macOS
scp ./feedbackflow-installer-<version>.tar.gz youruser@yourserver:~/
```

## ۳. آماده‌سازی سرور (فقط یک بار)

از این به بعد همه دستورها روی سرور اجرا می‌شن. با ssh وصل شو.

### ۳.۱ پکیج‌های پایه و فایروال

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl ca-certificates ufw nginx

sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

پورت ۸۰۸۰ بسته می‌مونه. nginx جلو میاد و TLS رو هندل می‌کنه.

### ۳.۲ تنظیم PostgreSQL

گفتی Postgres از قبل نصب شده. اول مطمئن بشو سالم بالاست:

```bash
sudo systemctl status postgresql
sudo -u postgres psql -c "select version();"
```

اگه نسخه رو دیدی، مرحله بعد. در غیر این صورت با `sudo systemctl enable --now postgresql` بالاش بیار.

#### ساخت کاربر و دیتابیس

اول یه پسورد قوی بساز و **یه جای امن کپی کن** (با Ctrl+Insert از terminal کپی می‌شه؛ این خط فقط یه بار بهت پسورد رو نشون می‌ده):

```bash
DB_PASS="$(openssl rand -base64 32)"
echo "FeedbackFlow DB password: $DB_PASS"
```

ساخت role و database:

```bash
sudo -u postgres psql <<SQL
CREATE USER feedbackflow WITH PASSWORD '$DB_PASS';
CREATE DATABASE feedbackflow OWNER feedbackflow;
GRANT ALL PRIVILEGES ON DATABASE feedbackflow TO feedbackflow;
SQL
```

#### تست اتصال

دقیقاً با همون URLی که اپ استفاده می‌کنه تست کن:

```bash
PGPASSWORD="$DB_PASS" psql -h 127.0.0.1 -U feedbackflow -d feedbackflow \
    -c "select current_user, current_database();"
```

اگه `feedbackflow | feedbackflow` رو دیدی، DB آماده‌ست.

#### اگه با ارور `password authentication failed` مواجه شدی

روی نصب پیش‌فرض Postgres در Ubuntu، اتصال‌های local از peer auth استفاده می‌کنن (یعنی unix user باید با pg user یکی باشه). برای اینکه از پسورد استفاده کنه، فایل `pg_hba.conf` رو ویرایش کن:

```bash
sudo sed -i 's/^local\s*all\s*all\s*peer/local   all             all                                     scram-sha-256/' \
    /etc/postgresql/*/main/pg_hba.conf
sudo systemctl reload postgresql
```

و دوباره تست کن.

> **نکته‌ی نسخه**: این اپ روی Postgres 14, 15, 16 تست شده. اسکیمای migrations از تابع `gen_random_uuid()` استفاده می‌کنه که از Postgres 13 به بعد built-in هست. نگرانی نداره.

### ۳.۳ نصب gh CLI لازم نیست

چون installer رو از قبل دانلود کردی، روی سرور به gh یا اینترنت GitHub احتیاجی نیست.

## ۴. اجرای installer

```bash
mkdir -p ~/feedbackflow-installer
tar -xzf ~/feedbackflow-installer-<version>.tar.gz -C ~/feedbackflow-installer
cd ~/feedbackflow-installer
sudo ./install.sh
```

اولین اجرا این کارها رو می‌کنه و **عمدی متوقف می‌شه**:

- یه کاربر سیستمی به اسم `feedbackflow` می‌سازه
- پوشه‌های `/opt/feedbackflow/{releases,current}` می‌سازه
- باینری و پوشه `web/` رو می‌بره داخل `/opt/feedbackflow/releases/<timestamp>/`
- symlink `/opt/feedbackflow/current` رو به اون release اشاره می‌ده
- فایل `feedbackflow.service` رو در `/etc/systemd/system/` کپی می‌کنه و enable می‌کنه
- یه `.env` با مقادیر placeholder از روی template می‌سازه و **اجازه start نمی‌ده** تا تنظیمش کنی

### ویرایش `.env`

```bash
sudo nano /opt/feedbackflow/.env
```

سه خط رو حتماً تنظیم کن:

```ini
DATABASE_URL=postgres://feedbackflow:DB_PASS_FROM_STEP_3@127.0.0.1:5432/feedbackflow
JWT_ACCESS_SECRET=<خروجی openssl rand -base64 48>
CORS_ALLOWED_ORIGINS=https://your-domain.example
```

برای تولید secret JWT:

```bash
openssl rand -base64 48
```

> **مهم**: `DATABASE_URL` رو دقیقاً از روی پسوردی که توی مرحله ۳.۲ ساختی بنویس. اگه پسوردت کاراکترهای خاصی داره (مثل `+` یا `/` یا `@`)، اون‌ها رو URL-encode کن. ابزار سریع:
> ```bash
> python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1],safe=''))" "$DB_PASS"
> ```

### اجرای دوم

```bash
sudo ./install.sh
```

این بار سرویس بالا میاد، migrationها روی DB اجرا می‌شن، و اپ روی `127.0.0.1:8080` listen می‌کنه.

### تست

```bash
sudo systemctl status feedbackflow
curl http://127.0.0.1:8080/healthz   # باید ok برگردونه
sudo journalctl -u feedbackflow -n 40 --no-pager
```

## ۵. nginx + TLS

(وقتی دامنه‌ت روی IP سرور تنظیم شد):

```bash
sudo tee /etc/nginx/sites-available/feedbackflow >/dev/null <<'NGINX'
server {
    listen 80;
    server_name your-domain.example;
    client_max_body_size 20M;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
    }
}
NGINX

sudo ln -sf /etc/nginx/sites-available/feedbackflow /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.example
```

> **نکته ایران**: گاهی روی سرورهای میزبان داخل ایران، challenge HTTP لتس‌انکریپت روی پورت ۸۰ گیر می‌کنه. اگه مشکل خوردی، گزینه `--standalone` با `--preferred-challenges dns` یا DNS challenge با کلودفلر/آروان جایگزینه.

## ۶. آپدیت‌های بعدی

هر بار **Build Installer** روی GitHub موفق شد:

۱. artifact جدید رو روی لپ‌تاپ دانلود کن
۲. extract → `.tar.gz` بیار بیرون
۳. scp روی سرور
۴. روی سرور:

```bash
mkdir -p ~/feedbackflow-installer-new
tar -xzf ~/feedbackflow-installer-<new-version>.tar.gz -C ~/feedbackflow-installer-new
cd ~/feedbackflow-installer-new
sudo ./install.sh
```

اسکریپت ۵ release آخر رو نگه می‌داره. برای rollback دستی:

```bash
ls /opt/feedbackflow/releases/
sudo ln -sfn /opt/feedbackflow/releases/<older-timestamp> /opt/feedbackflow/current
sudo systemctl restart feedbackflow
```

## ۷. پشتیبان‌گیری دیتابیس

cron روزانه با نگهداری ۱۴ روزه:

```bash
sudo install -d -o postgres -g postgres -m 750 /var/backups/feedbackflow
sudo tee /etc/cron.d/feedbackflow-backup >/dev/null <<'CRON'
0 3 * * * postgres pg_dump -F c feedbackflow > /var/backups/feedbackflow/feedbackflow-$(date +\%Y\%m\%d).dump
0 4 * * * root find /var/backups/feedbackflow -name 'feedbackflow-*.dump' -mtime +14 -delete
CRON
```

### Restore (مهم: schema رو drop می‌کنه)

```bash
sudo systemctl stop feedbackflow
sudo -u postgres pg_restore --clean --if-exists -d feedbackflow \
    /var/backups/feedbackflow/feedbackflow-YYYYMMDD.dump
sudo systemctl start feedbackflow
```

## ۸. عیب‌یابی

| علامت | اولین جای بررسی |
|------|------------------|
| سرویس بالا نمیاد | `journalctl -u feedbackflow -n 80` |
| `connection refused` | پورت ۵۴۳۲ روی `127.0.0.1` گوش می‌ده؟ پسورد در `.env` با چیزی که در `psql` ساختی یکیه؟ |
| `password authentication failed` | بلوک `CREATE USER` رو دوباره اجرا کن، یا توی psql بزن `\password feedbackflow` |
| ۵۰۲ از nginx | اول `curl http://127.0.0.1:8080/healthz` مستقیم. بعد `tail -f /var/log/nginx/error.log` |
| asset های وب 404 می‌شن | پوشه `web/` داخل `/opt/feedbackflow/current/` هست؟ |
| سرویس مدام crash می‌کنه روی migration | لاگ سرور خطای دقیق SQL رو قبل از exit چاپ می‌کنه. اون migration رو نگاه کن. |
| `gen_random_uuid does not exist` | روی Postgres قدیمی‌ای؟ اجرا کن `sudo -u postgres psql -d feedbackflow -c "create extension if not exists pgcrypto;"` |

## ۹. چک‌لیست امنیتی نهایی

- [ ] `.env` با مجوز `0600` و owner `feedbackflow` (install.sh انجام می‌ده)
- [ ] `JWT_ACCESS_SECRET` تازه (نه placeholder)
- [ ] پسورد DB قوی و فقط در `/opt/feedbackflow/.env` ذخیره
- [ ] فایروال فقط 22/80/443
- [ ] Postgres روی `localhost` فقط (پیش‌فرض Ubuntu همینه)
- [ ] TLS با Let's Encrypt فعال و `certbot renew --dry-run` پاس می‌ده
- [ ] cron backup روزانه فعال
- [ ] `journalctl -u feedbackflow` تمیز و بدون error در شرایط عادی

اگه هر کدوم این موارد چک نشد، قبل از پابلیک کردن دامنه برگرد بهش رسیدگی کن.
