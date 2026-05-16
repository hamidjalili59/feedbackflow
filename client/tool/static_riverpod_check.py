from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
errors = []

for rel in [
    'lib/presentation/bloc',
    'lib/data/dto/dtos.dart',
    'lib/data/dto/envelope.dart',
]:
    if (root / rel).exists():
        errors.append(f'unexpected legacy path exists: {rel}')

text_files = [p for p in root.rglob('*') if p.is_file() and p.suffix in {'.dart', '.yaml'}]
for path in text_files:
    text = path.read_text(encoding='utf-8')
    rel = path.relative_to(root).as_posix()
    forbidden = ['package:flutter_bloc', 'package:bloc', 'BlocProvider', 'BlocBuilder', 'BlocConsumer', 'BlocListener']
    for token in forbidden:
        if token in text:
            errors.append(f'{rel} still references {token}')

pubspec = (root / 'pubspec.yaml').read_text(encoding='utf-8')
required_pubspec_tokens = [
    'flutter_riverpod:',
    'riverpod_annotation:',
    'riverpod_generator:',
    'build_runner:',
]
for token in required_pubspec_tokens:
    if token not in pubspec:
        errors.append(f'pubspec.yaml is missing {token}')
for token in ['flutter_bloc:', '\n  bloc:']:
    if token in pubspec:
        errors.append(f'pubspec.yaml still contains {token.strip()}')

providers = (root / 'lib/app/providers.dart').read_text(encoding='utf-8')
router = (root / 'lib/app/router.dart').read_text(encoding='utf-8')

for rel, text in [('lib/app/providers.dart', providers), ('lib/app/router.dart', router)]:
    if "package:riverpod_annotation/riverpod_annotation.dart" not in text:
        errors.append(f'{rel} does not import riverpod_annotation')
    if "part '" not in text or ".g.dart';" not in text:
        errors.append(f'{rel} is missing a generated part directive')
    if '@Riverpod' not in text and '@riverpod' not in text:
        errors.append(f'{rel} has no @Riverpod/@riverpod annotations')

for manual in ['Provider<', 'FutureProvider', 'StateProvider', 'NotifierProvider', 'AsyncNotifierProvider']:
    if manual in providers:
        errors.append(f'providers.dart still contains manual {manual} declaration')
    if manual in router and manual != 'Provider<':
        errors.append(f'router.dart still contains manual {manual} declaration')

for class_name in ['AuthController', 'FormsController', 'CreateFormController']:
    if f'class {class_name} extends _${class_name}' not in providers:
        errors.append(f'{class_name} does not extend generated _${class_name}')

for token in [
    'appDependenciesProvider',
    'authControllerProvider',
    'formsControllerProvider',
    'createFormControllerProvider',
    'publicFormProvider',
    'routerProvider',
]:
    found = any(token in p.read_text(encoding='utf-8') for p in root.rglob('*.dart') if p.is_file())
    if not found:
        errors.append(f'generated provider usage missing: {token}')

for required_part in ['lib/app/providers.g.dart', 'lib/app/router.g.dart']:
    if not (root / required_part).exists():
        errors.append(f'missing generated compatibility file: {required_part}')

if errors:
    print('[FAIL] Riverpod generator checks failed:')
    for error in errors:
        print(' -', error)
    sys.exit(1)
print('[OK] Riverpod generator checks passed')
