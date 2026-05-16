# Branding assets

This folder is reserved for branding artwork (app icons, splash screens, login
logos, etc.).

To enable a logo on the native splash screen, drop the following files here
and uncomment the relevant lines in `pubspec.yaml > flutter_native_splash`:

- `splash_icon.png` — light theme splash icon (square, 1024×1024 recommended).
- `splash_icon_dark.png` — dark theme splash icon (same dimensions).

After adding the files run:

```bash
flutter pub run flutter_native_splash:create
```

This regenerates Android and iOS splash resources to match
`flutter_native_splash` config in `pubspec.yaml`.

Without an image the splash will simply show the configured background color
(`#F3F3F5` light / `#0B1020` dark), which is a perfectly valid starting point.
