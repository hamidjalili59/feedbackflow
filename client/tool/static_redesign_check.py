from pathlib import Path
root = Path(__file__).resolve().parents[1]
checks = {
    'lib/presentation/widgets/app_chrome.dart': ['class AppBackButton', 'class ThemeModeButton', 'class GradientScaffold', 'class PageHeaderCard'],
    'lib/presentation/widgets/feedback_field_kit.dart': ['class FeedbackFieldCard', 'class FeedbackOptionChip', 'class FeedbackRatingButton'],
    'lib/presentation/theme/app_theme.dart': ['static ThemeData light()', 'static ThemeData dark()', 'pageGradient'],
    'lib/app/providers.dart': ['class ThemeController extends _$ThemeController'],
    'lib/app.dart': ['themeMode: ref.watch(themeControllerProvider)', 'darkTheme: AppTheme.dark()'],
    'lib/features/forms/presentation/form_detail_screen.dart': ['AppBackButton', 'ThemeModeButton'],
    'lib/features/forms/presentation/create_form_screen.dart': ['AppBackButton', 'ThemeModeButton'],
    'lib/features/public_forms/presentation/public_form_screen.dart': ['AppBackButton', 'FeedbackFieldCard'],
}
missing = []
for rel, needles in checks.items():
    path = root / rel
    text = path.read_text(encoding='utf-8') if path.exists() else ''
    for needle in needles:
        if needle not in text:
            missing.append(f'{rel} missing {needle!r}')
if missing:
    print('[FAIL] redesign check failed')
    for item in missing:
        print(' -', item)
    raise SystemExit(1)
print('[OK] Redesign/navigation/dark-mode checks passed')
