# Offline server install

> 🇮🇷 نسخه فارسی: [`OFFLINE-INSTALL.fa.md`](OFFLINE-INSTALL.fa.md)

Use this flow when the server cannot reach GitHub directly. You build the
installer on GitHub Actions, download it to your laptop, then `scp` it to the
server and run a single script.

## 1. Build the installer on GitHub

1. Go to **Actions → Build Installer**.
2. Click **Run workflow**.
3. Optionally type a `version` label (e.g. `v0.1.0`); leave empty for an
   auto timestamp.
4. Wait ~8–12 minutes. The job summary links to an artifact named
   `feedbackflow-installer-<version>.tar.gz`. Download it (GitHub wraps it
   in a `.zip`; extract once on your laptop).

## 2. Copy to the server

```bash
# from your laptop
scp feedbackflow-installer-<version>.tar.gz youruser@yourserver:~/
```

## 3. Server prerequisites (run once on a fresh VPS)

This assumes Ubuntu 22.04 with sudo.

### 3.1 Base packages and firewall

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl ca-certificates ufw nginx
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### 3.2 PostgreSQL

You said PostgreSQL is already installed on the server. Verify it's running:

```bash
sudo systemctl status postgresql
sudo -u postgres psql -c "select version();"
```

Pick a strong password and create the role and database the app will use:

```bash
DB_PASS="$(openssl rand -base64 32)"
echo "FeedbackFlow DB password: $DB_PASS"   # save this somewhere safe

sudo -u postgres psql <<SQL
CREATE USER feedbackflow WITH PASSWORD '$DB_PASS';
CREATE DATABASE feedbackflow OWNER feedbackflow;
GRANT ALL PRIVILEGES ON DATABASE feedbackflow TO feedbackflow;
SQL
```

If your `pg_hba.conf` requires it, ensure local TCP auth uses `md5` or
`scram-sha-256` and reload:

```bash
sudo sed -i 's/^local\s*all\s*all\s*peer/local   all             all                                     scram-sha-256/' /etc/postgresql/*/main/pg_hba.conf || true
sudo systemctl reload postgresql
```

Test the exact URL the app will use:

```bash
PGPASSWORD="$DB_PASS" psql -h 127.0.0.1 -U feedbackflow -d feedbackflow \
    -c "select current_user, current_database();"
```

If that prints `feedbackflow | feedbackflow`, the database is ready.

> **Note**: PostgreSQL 14 ships with Ubuntu 22.04. The app is tested on
> versions 14, 15, and 16. The schema uses `gen_random_uuid()` from the
> built-in `pgcrypto`; modern Postgres has it enabled by default.

## 4. Run the installer

```bash
mkdir -p ~/feedbackflow-installer
tar -xzf ~/feedbackflow-installer-<version>.tar.gz -C ~/feedbackflow-installer
cd ~/feedbackflow-installer
sudo ./install.sh
```

The first run does the following and then stops:

- Creates a system user `feedbackflow`.
- Creates `/opt/feedbackflow/{releases,current}`.
- Copies the binary and `web/` bundle into `/opt/feedbackflow/releases/<ts>/`.
- Symlinks `/opt/feedbackflow/current` to that release.
- Copies `feedbackflow.service` to `/etc/systemd/system/` and enables it.
- Creates `/opt/feedbackflow/.env` from the template **with placeholders** so
  it refuses to start until you edit it.

Edit the env file:

```bash
sudo nano /opt/feedbackflow/.env
```

Fill in the three required values:

```ini
DATABASE_URL=postgres://feedbackflow:DB_PASS_FROM_STEP_3@127.0.0.1:5432/feedbackflow
JWT_ACCESS_SECRET=<paste output of: openssl rand -base64 48>
CORS_ALLOWED_ORIGINS=https://your-domain.example
```

Run again:

```bash
sudo ./install.sh
```

Verify:

```bash
sudo systemctl status feedbackflow
curl http://127.0.0.1:8080/healthz   # expect: ok
sudo journalctl -u feedbackflow -n 40 --no-pager
```

## 5. nginx + TLS

Once your domain points to this server's IP:

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

## 6. Routine upgrades

Every time you push to `main` and the **Build Installer** workflow finishes,
download the new artifact, scp it, then on the server:

```bash
mkdir -p ~/feedbackflow-installer-new
tar -xzf ~/feedbackflow-installer-<new-version>.tar.gz -C ~/feedbackflow-installer-new
cd ~/feedbackflow-installer-new
sudo ./install.sh
```

The install script keeps the last 5 releases under
`/opt/feedbackflow/releases/`. To roll back manually:

```bash
ls /opt/feedbackflow/releases/
sudo ln -sfn /opt/feedbackflow/releases/<older-timestamp> /opt/feedbackflow/current
sudo systemctl restart feedbackflow
```

## 7. Backups

Daily pg_dump with 14-day retention:

```bash
sudo install -d -o postgres -g postgres -m 750 /var/backups/feedbackflow
sudo tee /etc/cron.d/feedbackflow-backup >/dev/null <<'CRON'
0 3 * * * postgres pg_dump -F c feedbackflow > /var/backups/feedbackflow/feedbackflow-$(date +\%Y\%m\%d).dump
0 4 * * * root find /var/backups/feedbackflow -name 'feedbackflow-*.dump' -mtime +14 -delete
CRON
```

Restore (drops and recreates the schema):

```bash
sudo systemctl stop feedbackflow
sudo -u postgres pg_restore --clean --if-exists -d feedbackflow \
    /var/backups/feedbackflow/feedbackflow-YYYYMMDD.dump
sudo systemctl start feedbackflow
```

## 8. Troubleshooting

| Symptom | Look at |
|--------|---------|
| Service won't start | `journalctl -u feedbackflow -n 80` |
| `connection refused` from app | Confirm DB is on `127.0.0.1:5432` and the password in `.env` matches |
| `password authentication failed` | Re-run the `CREATE USER` block, or use `\password feedbackflow` in `psql` |
| 502 from nginx | `curl http://127.0.0.1:8080/healthz` directly; check nginx error log |
| Web bundle 404s on assets | Confirm `web/` exists inside `/opt/feedbackflow/current/` |
| App keeps restarting on migration | Check the server log; the failing SQL line is logged before exit |
