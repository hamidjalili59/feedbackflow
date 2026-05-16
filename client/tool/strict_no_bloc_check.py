from pathlib import Path

root = Path(__file__).resolve().parents[1]
scan_paths = [root / 'lib', root / 'pubspec.yaml']
forbidden = [
    'package:flutter_bloc',
    'package:bloc',
    'BlocProvider',
    'BlocBuilder',
    'BlocConsumer',
    'BlocListener',
    'Cubit<',
    'extends Cubit',
    'extends Bloc',
    'Bloc<',
]
failures = []
for scan_path in scan_paths:
    files = [scan_path] if scan_path.is_file() else [p for p in scan_path.rglob('*') if p.is_file()]
    for path in files:
        text = path.read_text(encoding='utf-8', errors='ignore')
        for token in forbidden:
            if token in text:
                failures.append((path.relative_to(root).as_posix(), token))

if failures:
    print('[FAIL] Found Bloc-era tokens in source:')
    for path, token in failures:
        print(f'  - {path}: {token}')
    raise SystemExit(1)

pubspec = (root / 'pubspec.yaml').read_text(encoding='utf-8')
if '\n  bloc:' in pubspec or '\n  flutter_bloc:' in pubspec:
    print('[FAIL] pubspec.yaml still contains Bloc dependencies')
    raise SystemExit(1)

print('[OK] No Bloc-era source tokens found in lib/ or pubspec.yaml')
