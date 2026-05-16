# Server deploy guide (Ubuntu 22.04)

You never build anything on the server. GitHub Actions builds a release
bundle and you pull it on the server with `gh`.

## What lives on the server

```
/opt/feedbackflow/
  .env                       <- secrets (chmod 600, owner feedbackflow)
  current -> releases/<ts>   <- symlink to the active release
  releases/
    20260516-141200/
      feedbackflow-server    <- static musl binary
      web/                   <- Flutter web bundle
    20260518-091300/
      ...
```

systemd unit: `feedbackflow.service`. Logs live in `journalctl -u feedbackflow`.

---

## 1. First-time bootstrap

Run these once on a fresh VPS as a sudo-capable user.

### 1.1 Base packages

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl unzip nginx postgresql postgresql-contrib ufw fail2ban
```

### 1.2 Firewall

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

Port 8080 stays closed; only nginx is public-facing.

### 1.3 PostgreSQL

PostgreSQL 14 ships with Ubuntu 22.04 and listens on `localhost:5432` by
default - no extra hardening required for this single-host setup.

Start the cluster (already enabled by the package, this just confirms):

```bash
sudo systemctl enable --now postgresql
sudo systemctl status postgresql
```

Generate a strong DB password and keep it somewhere safe:

```bash
DB_PASS=$(openssl rand -base64 32)
echo "$DB_PASS"
```

Create the role and database:

```bash
sudo -u postgres psql <<SQL
CREATE USER feedbackflow WITH PASSWORD '$DB_PASS';
CREATE DATABASE feedbackflow OWNER feedbackflow;
GRANT ALL PRIVILEGES ON DATABASE feedbackflow TO feedbackflow;
SQL
```

Verify the user and DB exist:

```bash
sudo -u postgres psql -c "\du" | grep feedbackflow
sudo -u postgres psql -c "\l"  | grep feedbackflow
```

Test the connection string the app will use:

```bash
PGPASSWORD="$DB_PASS" psql -h localhost -U feedbackflow -d feedbackflow -c "select version();"
```

If that prints the PostgreSQL version, you're done with the database step.

### 1.4 GitHub CLI

The `gh` package is not in the default Ubuntu repos.

```bash
type -p curl >/dev/null || sudo apt install -y curl
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
sudo apt update
sudo apt install -y gh

gh auth login    # device-code flow; open the URL on your laptop
```

Tell scripts which repo to pull from:

```bash
echo 'export GH_REPO=YOUR_GH_USER/feedbackflow' \
  | sudo tee /etc/profile.d/feedbackflow.sh >/dev/null
source /etc/profile.d/feedbackflow.sh
```

### 1.5 Pull the deploy script

We want `fetch-release.sh` on the server (it lives in `deploy/`):

```bash
mkdir -p ~/feedbackflow-deploy && cd ~/feedbackflow-deploy
gh repo clone "$GH_REPO" repo
cp repo/deploy/fetch-release.sh .
chmod +x fetch-release.sh
```

### 1.6 First install

Find the latest successful release run:

```bash
gh run list --repo "$GH_REPO" --workflow release.yml --status success --limit 1
```

Run the installer with that run id:

```bash
sudo -E ./fetch-release.sh <RUN_ID>
```

The first run creates `/opt/feedbackflow/.env` from the template and stops
because the secrets still hold placeholders. Edit them:

```bash
sudo nano /opt/feedbackflow/.env
```

Set at minimum:

- `DATABASE_URL=postgres://feedbackflow:<DB_PASS>@localhost:5432/feedbackflow`
- `JWT_ACCESS_SECRET=<openssl rand -base64 48>`
- `CORS_ALLOWED_ORIGINS=https://your-domain.example`

Run again:

```bash
sudo -E ./fetch-release.sh <RUN_ID>
```

Verify:

```bash
sudo systemctl status feedbackflow
curl http://127.0.0.1:8080/healthz   # expect: ok
```

### 1.7 nginx + TLS

Once your domain points to this VPS:

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

---

## 2. Routine deploys

After every push to `main` GitHub Actions builds a new bundle. To roll it
out:

```bash
cd ~/feedbackflow-deploy
gh run list --repo "$GH_REPO" --workflow release.yml --status success --limit 1
sudo -E ./fetch-release.sh <NEW_RUN_ID>
```

Migrations run automatically on startup (`RUN_MIGRATIONS=true` in `.env`).

The script keeps the last 5 releases under `/opt/feedbackflow/releases/` so
you can roll back manually:

```bash
ls /opt/feedbackflow/releases/
sudo ln -sfn /opt/feedbackflow/releases/<older-timestamp> /opt/feedbackflow/current
sudo systemctl restart feedbackflow
```

---

## 3. Backups

Daily pg_dump with 14-day retention:

```bash
sudo install -d -o postgres -g postgres -m 750 /var/backups/feedbackflow
sudo tee /etc/cron.d/feedbackflow-backup >/dev/null <<'CRON'
0 3 * * * postgres pg_dump -F c feedbackflow > /var/backups/feedbackflow/feedbackflow-$(date +\%Y\%m\%d).dump
0 4 * * * root find /var/backups/feedbackflow -name 'feedbackflow-*.dump' -mtime +14 -delete
CRON
```

Restore (dangerous - this drops and recreates objects):

```bash
sudo systemctl stop feedbackflow
sudo -u postgres pg_restore --clean --if-exists -d feedbackflow \
    /var/backups/feedbackflow/feedbackflow-YYYYMMDD.dump
sudo systemctl start feedbackflow
```

---

## 4. Troubleshooting

| Symptom | First check |
|--------|-------------|
| `feedbackflow.service` won't start | `journalctl -u feedbackflow -n 80` |
| App returns 502 from nginx | `curl http://127.0.0.1:8080/healthz` directly |
| Can't connect to DB | `sudo -u postgres psql -c '\l'` and `cat /opt/feedbackflow/.env` |
| Wrong locale on web | Ensure CORS origin matches what the browser sends |
| `gh` rate-limited from server | Re-run with `gh auth refresh` |
