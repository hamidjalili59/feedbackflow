# FeedbackFlow

Monorepo containing the FeedbackFlow backend (Rust + Axum + PostgreSQL) and
the Flutter client. The two ship together as a single release bundle.

## Layout

```
.
├── server/          Rust backend (Axum, SQLx, Argon2, JWT, OpenAPI)
├── client/          Flutter client (Material 3, RTL, multi-locale)
├── deploy/          systemd unit, install/fetch scripts, server docs
└── .github/         GitHub Actions release pipeline
```

## How a release happens

Every push to `main` triggers `.github/workflows/release.yml`:

1. `build-flutter-web` — analyzes and builds `client/` to `web/`.
2. `build-server` — builds `server/` as a static `x86_64-unknown-linux-musl`
   binary (no glibc dependency on the target).
3. `package` — combines binary + web bundle + `deploy/install.sh` +
   `deploy/feedbackflow.service` + `.env.example` into a single
   `feedbackflow-<sha>.tar.gz` artifact.

Tag a commit with `vX.Y.Z` to additionally publish a GitHub Release.

## How to deploy on a server

You never build anything on the server. You pull the artifact and run the
installer. Two flows:

- **Server has internet access to GitHub** →
  [`deploy/README.md`](deploy/README.md) (uses `gh` CLI on the server).
- **Server is offline / firewalled / behind a slow link** →
  [`deploy/OFFLINE-INSTALL.md`](deploy/OFFLINE-INSTALL.md) (manual download
  on your laptop, then `scp` to the server).

## Local development

Server:

```bash
cd server
cp .env.example .env   # then fill in real values
cargo run
```

Client:

```bash
cd client
bash scripts/download_vazirmatn_fonts.sh   # one-time
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome
```
