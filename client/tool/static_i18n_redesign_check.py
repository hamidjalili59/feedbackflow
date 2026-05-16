from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
errors=[]
required = {
    'lib/l10n/app_localizations.dart': ['Locale(\'fa\')', 'Locale(\'en\')', 'Locale(\'zh\')', 'TextDirection.rtl'],
    'lib/app.dart': ['localizationsDelegates', 'supportedLocales', 'localeControllerProvider'],
    'lib/app/providers.dart': ['class LocaleController extends _$LocaleController', "Locale build() => const Locale('fa')"],
    'lib/presentation/widgets/app_chrome.dart': ['class LanguageButton', 'localeControllerProvider', 'Icons.language_rounded'],
    'lib/presentation/widgets/feedback_field_kit.dart': ['FeedbackSheetFrame', 'FeedbackFieldCard', 'FeedbackOptionChip', 'compact'],
    'pubspec.yaml': ['flutter_localizations:'],
}
for rel,tokens in required.items():
    p=root/rel
    if not p.exists():
        errors.append(f'missing {rel}')
        continue
    text=p.read_text(encoding='utf-8')
    for token in tokens:
        if token not in text:
            errors.append(f'{rel} missing {token}')
if errors:
    print('[FAIL] i18n/redesign checks failed:')
    for error in errors: print(' -',error)
    sys.exit(1)
print('[OK] i18n, RTL, language switcher and feedback-kit redesign checks passed')
