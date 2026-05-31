# i18n and Chinese font updates

This update completes the newly added client strings for Persian, English, and Chinese in `lib/l10n/app_localizations.dart`.

## What changed

- Dashboard labels, metric dialogs, survey calendar, activity cards, user-management feedback, and assignment labels now read from localization keys instead of Persian literals.
- Login and guest-login text is localized in all supported languages.
- Step-form navigation and choice-field helper text are localized.
- Form templates now initialize their title, description, sample fields, and option labels according to the active app language when creating a new form.
- When the app locale is Chinese (`zh`), the app theme switches away from the Persian Abar font and asks the platform for common CJK fonts first:
  - `Noto Sans SC`
  - `Noto Sans CJK SC`
  - `Microsoft YaHei`
  - `PingFang SC`
  - `Heiti SC`
  - `SimHei`

No large Chinese font file is bundled in the repository; this avoids increasing the Flutter web bundle size. If a specific branded Chinese font is required later, add it to `assets/fonts`, register it in `pubspec.yaml`, and update `AppTheme.chineseFontFamily`.

## Files touched

- `lib/app.dart`
- `lib/app/providers.dart`
- `lib/l10n/app_localizations.dart`
- `lib/presentation/theme/app_theme.dart`
- `lib/presentation/models/form_builder_models.dart`
- `lib/presentation/widgets/field_renderer.dart`
- `lib/presentation/widgets/step_form_view.dart`
- `lib/features/auth/presentation/login_screen.dart`
- `lib/features/dashboard/presentation/dashboard_screen.dart`
- `lib/features/forms/presentation/form_detail_screen.dart`
