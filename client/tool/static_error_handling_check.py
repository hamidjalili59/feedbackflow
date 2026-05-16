from pathlib import Path
root = Path(__file__).resolve().parents[1]
checks = [
    (root / 'lib/core/api/dio_factory.dart', '_ApiEnvelopeInterceptor'),
    (root / 'lib/core/api/dio_factory.dart', 'ApiFailure.fromEnvelope'),
    (root / 'lib/presentation/widgets/error_panel.dart', 'class ErrorPanel'),
    (root / 'lib/presentation/common/friendly_api_error_message.dart', 'UserFacingError'),
    (root / 'lib/features/forms/presentation/form_detail_screen.dart', 'ErrorPanel'),
]
missing = []
for path, needle in checks:
    text = path.read_text() if path.exists() else ''
    if needle not in text:
        missing.append(f'{path.relative_to(root)} missing {needle!r}')

for old in ['lib/presentation/screens', 'BlocBuilder', 'BlocProvider', 'BlocConsumer', 'BlocListener']:
    for path in (root / 'lib').rglob('*.dart'):
        if old in str(path.relative_to(root)) or old in path.read_text():
            missing.append(f'unexpected legacy token {old!r} in {path.relative_to(root)}')

if missing:
    print('[FAIL] error handling check failed')
    for item in missing:
        print(' -', item)
    raise SystemExit(1)
print('[OK] Centralized error handling and feature layout checks passed')
