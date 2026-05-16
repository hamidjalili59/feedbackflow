#!/usr/bin/env python3
"""Static source-vs-OpenAPI checks for the FeedbackFlow Flutter client.

This script does not require Dart or Flutter. It verifies the generated source still
matches the attached OpenAPI contract at a structural level.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OPENAPI = ROOT / 'tool' / 'openapi.json'
API_CLIENT = ROOT / 'lib' / 'data' / 'api' / 'feedback_flow_api_client.dart'
MODELS = ROOT / 'lib' / 'data' / 'dto' / 'models.dart'
ENUMS = ROOT / 'lib' / 'data' / 'dto' / 'enums.dart'


def fail(message: str) -> None:
    print(f'[FAIL] {message}')
    sys.exit(1)


def main() -> None:
    spec = json.loads(OPENAPI.read_text())
    api = API_CLIENT.read_text()
    models = MODELS.read_text()
    enums = ENUMS.read_text()

    operations: list[str] = []
    paths: list[str] = []
    for path, item in spec['paths'].items():
        paths.append(path)
        for method, op in item.items():
            if method.lower() in {'get', 'post', 'patch', 'put', 'delete'}:
                operations.append(op['operationId'])
                signature = re.search(r'Future<[^\n]+?>\s+' + re.escape(op['operationId']) + r'\s*\((?P<params>[^)]*)\)', api)
                if not signature:
                    fail(f'missing API client method for operationId {op["operationId"]}')
                ref = (
                    op.get('requestBody', {})
                    .get('content', {})
                    .get('application/json', {})
                    .get('schema', {})
                    .get('$ref')
                )
                if ref:
                    request_name = ref.split('/')[-1]
                    if f'required {request_name} request' not in signature.group('params'):
                        fail(f'{op["operationId"]} does not use {request_name} as request body type')

    for path in paths:
        if path not in api:
            fail(f'missing API path in client: {path}')

    extra_paths = sorted(set(re.findall(r"'(/api/v1/[^']+)'", api)) - set(paths))
    if extra_paths:
        fail('extra API paths in client: ' + ', '.join(extra_paths))

    for name, schema in spec['components']['schemas'].items():
        if 'enum' in schema:
            match = re.search(r'enum ' + re.escape(name) + r' \{(.*?)\n\}', enums, re.S)
            if not match:
                fail(f'missing Dart enum {name}')
            wires = re.findall(r"\n\s*\w+\('([^']+)'\)", match.group(1))
            dart_wires = sorted(wire for wire in wires if wire != '__unknown__')
            spec_wires = sorted(schema['enum'])
            if dart_wires != spec_wires:
                fail(f'enum wire mismatch for {name}: {dart_wires} != {spec_wires}')
        else:
            if name.startswith('ApiResponse_') or name.startswith('ApiListResponse_'):
                continue
            if name in {'ApiErrorDto'}:
                continue
            if name == 'ApiErrorResponse':
                continue
            if f'class {name} ' not in models:
                fail(f'missing Dart DTO class {name}')

    for dart_file in (ROOT / 'lib').rglob('*.dart'):
        text = dart_file.read_text()
        if 'DraftFormField changeType(FieldType nextType) {\n  DraftFormField changeType' in text:
            fail(f'duplicate DraftFormField.changeType declaration in {dart_file}')
        if 'SliverList.separated' in text:
            fail(f'SliverList.separated usage left in {dart_file}')

    print('[OK] OpenAPI/client structural checks passed.')
    print(f'[OK] {len(operations)} operationIds and {len(paths)} endpoint paths checked.')


if __name__ == '__main__':
    main()
