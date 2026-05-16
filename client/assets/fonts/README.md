# Fonts

Vazirmatn is the primary app font and is required for both Persian and Latin
text on all platforms.

The TTF files are not committed to the repository. Run one of the helper
scripts to download them:

```powershell
# Windows / PowerShell
pwsh scripts/download_vazirmatn_fonts.ps1
```

```bash
# macOS / Linux / WSL
scripts/download_vazirmatn_fonts.sh
```

The scripts pull the official release archive from
[rastikerdar/vazirmatn](https://github.com/rastikerdar/vazirmatn) and write the
weights referenced from `pubspec.yaml`:

- `Vazirmatn-Regular.ttf`   (400)
- `Vazirmatn-Medium.ttf`    (500)
- `Vazirmatn-SemiBold.ttf`  (600)
- `Vazirmatn-Bold.ttf`      (700)
- `Vazirmatn-ExtraBold.ttf` (800)
- `Vazirmatn-Black.ttf`     (900)

After running the script, run `flutter pub get` so the Flutter tool picks up
the newly registered assets.
