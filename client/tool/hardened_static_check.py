#!/usr/bin/env python3
"""Extra compile-sanity checks that do not require the Flutter SDK."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f'[FAIL] {message}')
    sys.exit(1)


def text(path: str) -> str:
    return (ROOT / path).read_text()


def assert_absent(pattern: str, source: str, label: str) -> None:
    if re.search(pattern, source):
        fail(label)


def main() -> None:
    if (ROOT / 'lib/app/app.dart').exists():
        fail('stale lib/app/app.dart remains; the canonical app bootstrap must be lib/app.dart')

    main_dart = text('lib/main.dart')
    if "import 'app/app.dart';" in main_dart or 'import "app/app.dart";' in main_dart:
        fail('lib/main.dart still imports the old app/app.dart path')
    if "import 'app.dart';" not in main_dart:
        fail('lib/main.dart must import root lib/app.dart')

    app_dart = text('lib/app.dart')
    for name in [
        'AuthRepository', 'FormsRepository', 'FieldsRepository', 'PublicFormsRepository',
        'ActivitiesRepository', 'AnalyticsRepository', 'AuditRepository', 'OrganizationsRepository',
        'PermissionsRepository', 'ScoringRepository', 'SubmissionsRepository', 'UsersRepository',
    ]:
        # Allow generic type annotations such as RepositoryProvider<AuthRepository>, but not constructor calls.
        assert_absent(r'(?<![A-Za-z0-9_])' + re.escape(name) + r'\s*\(', app_dart, f'lib/app.dart instantiates abstract {name}')

    dependencies = text('lib/app/dependencies.dart')
    required_impls = [
        'DioAuthRepository(apiClient)', 'DioFormsRepository(apiClient)', 'DioFieldsRepository(apiClient)',
        'DioPublicFormsRepository(apiClient)', 'DioActivitiesRepository(apiClient)',
        'DioAnalyticsRepository(apiClient)', 'DioAuditRepository(apiClient)',
        'DioOrganizationsRepository(apiClient)', 'DioPermissionsRepository(apiClient)',
        'DioScoringRepository(apiClient)', 'DioSubmissionsRepository(apiClient)', 'DioUsersRepository(apiClient)',
    ]
    for needle in required_impls:
        if needle not in dependencies:
            fail(f'AppDependencies is missing concrete repository wiring: {needle}')

    if 'TokenStorage' in ''.join(p.read_text() for p in (ROOT / 'lib').rglob('*.dart')):
        fail('legacy TokenStorage reference remains; use AuthTokenStore')

    router = text('lib/app/router.dart')
    for needle in [
        'FormsBloc(formsRepository:',
        'FormDetailBloc(formsRepository:',
        'PublicFormBloc(publicFormsRepository:',
        'CreateFormBloc(',
    ]:
        if needle not in router:
            fail(f'router missing expected Bloc construction: {needle}')

    # Freezed 3 class declarations.
    for rel in [
        'lib/data/dto/models.dart',
        'lib/data/dto/api_response.dart',
        'lib/domain/entities/entities.dart',
    ]:
        source = text(rel)
        bad = re.search(r'@(?:F|f)reezed(?:\([^\n]*\))?\nclass\s+\w+', source)
        if bad:
            fail(f'{rel} uses Freezed 2 class style near: {bad.group(0)}')
    for rel in ['lib/presentation/bloc/auth/auth_bloc.dart', 'lib/presentation/bloc/forms/forms_bloc.dart', 'lib/presentation/bloc/form_detail/form_detail_bloc.dart', 'lib/presentation/bloc/public_form/public_form_bloc.dart']:
        source = text(rel)
        bad = re.search(r'@freezed\nclass\s+\w+', source)
        if bad:
            fail(f'{rel} uses non-sealed Freezed union declaration')

    all_dart = '\n'.join(p.read_text() for p in (ROOT / 'lib').rglob('*.dart'))
    forbidden_literals = [
        'whenOrNull(', '.when(', 'maybeWhen(', 'mapOrNull(', 'maybeMap(',
        'CardTheme(', 'CardThemeData(', 'surfaceVariant', '.withOpacity(', 'SliverList.separated',
        'DraftFormField changeType(FieldType nextType) {\n  DraftFormField changeType',
        'void _onFieldMoved(CreateFormFieldMoved event, Emitter<CreateFormState> emit) {\n  void _onFieldMoved',
    ]
    for literal in forbidden_literals:
        if literal in all_dart:
            fail(f'forbidden or stale pattern remains: {literal}')

    pubspec = text('pubspec.yaml')
    for needle in [
        "sdk: '>=3.10.0 <4.0.0'", 'dio: ^5.9.2', 'flutter_bloc: ^9.1.1', 'bloc: ^9.2.0',
        'drift: ^2.33.0', 'drift_flutter: ^0.3.0', 'freezed_annotation: ^3.1.0',
        'json_annotation: ^4.11.0', 'go_router: ^17.2.3', 'flutter_secure_storage: ^10.1.0',
        'build_runner: ^2.15.0', 'freezed: ^3.2.5', 'json_serializable: ^6.13.2',
        'drift_dev: ^2.33.0', 'flutter_lints: ^6.0.0',
    ]:
        if needle not in pubspec:
            fail(f'pubspec missing expected latest dependency line: {needle}')

    analysis_options = text('analysis_options.yaml')
    if 'invalid_annotation_target: ignore' not in analysis_options:
        fail('analysis_options.yaml must ignore invalid_annotation_target for Freezed + json_serializable')

    # Basic delimiter sanity: not a parser, but catches accidental duplicate blocks and truncation.
    pairs = {'(': ')', '[': ']', '{': '}'}
    for path in (ROOT / 'lib').rglob('*.dart'):
        s = path.read_text()
        for opening, closing in pairs.items():
            if s.count(opening) != s.count(closing):
                fail(f'obvious delimiter imbalance in {path.relative_to(ROOT)} for {opening}{closing}')

    print('[OK] Hardened static checks passed.')
    print('[OK] Checked stale app bootstrap, DI wiring, Bloc constructors, Freezed 3 declarations, deprecated UI APIs, duplicate methods, and dependency versions.')


if __name__ == '__main__':
    main()
