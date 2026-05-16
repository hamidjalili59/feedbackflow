import json
import os
import re
import shutil
import textwrap
import zipfile
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

ROOT = Path('/mnt/data/feedbackflow_flutter_client')
OPENAPI = Path('/mnt/data/openapi.json')

DART_KEYWORDS = {
    'abstract','as','assert','async','await','base','break','case','catch','class','const','continue','covariant','default','deferred','do','dynamic','else','enum','export','extends','extension','external','factory','false','final','finally','for','Function','get','hide','if','implements','import','in','interface','is','late','library','mixin','new','null','of','on','operator','part','required','rethrow','return','sealed','set','show','static','super','switch','sync','this','throw','true','try','typedef','var','void','when','while','with','yield'
}
# Some built-in identifiers are technically legal, but awkward in freezed named params.
SPECIAL_FIELD_NAMES = {
    'required': 'isRequired',
    'operator': 'operatorValue',
}

PARAM_DEFAULTS = {
    'page': '1',
    'page_size': '20',
    'search': 'null',
    'sort_by': 'null',
    'sort_order': 'null',
    'filters': 'null',
}


def load() -> Dict[str, Any]:
    return json.loads(OPENAPI.read_text())


def ensure_clean() -> None:
    if ROOT.exists():
        shutil.rmtree(ROOT)
    (ROOT / 'lib').mkdir(parents=True)


def write(path: str, content: str) -> None:
    p = ROOT / path
    p.parent.mkdir(parents=True, exist_ok=True)
    content = content.rstrip() + '\n'
    p.write_text(content)


def snake_to_camel(name: str, upper: bool = False) -> str:
    parts = re.split(r'[_\-\s]+', name)
    if not parts:
        return name
    out = ''
    for i, part in enumerate(parts):
        if not part:
            continue
        lower = part.lower()
        if i == 0 and not upper:
            out += lower
        else:
            # Preserve common all-caps acronyms as normal camel case where Dart style prefers lower acronyms.
            out += lower[:1].upper() + lower[1:]
    if not out:
        out = name
    return out


def lower_first(s: str) -> str:
    return s[:1].lower() + s[1:] if s else s


def dart_field_name(json_name: str) -> str:
    if json_name in SPECIAL_FIELD_NAMES:
        return SPECIAL_FIELD_NAMES[json_name]
    name = snake_to_camel(json_name)
    if name in DART_KEYWORDS:
        name = name + 'Value'
    return name


def enum_member_name(wire: str) -> str:
    # SCREAMING_SNAKE or snake_case both become lower camel.
    clean = wire.lower()
    name = snake_to_camel(clean)
    if not name:
        name = 'value'
    if re.match(r'^\d', name):
        name = 'value' + name
    if name in DART_KEYWORDS:
        name = name + 'Value'
    return name


def file_name_for_class(name: str) -> str:
    # Not used for model files, but useful for repos/mappers.
    s = re.sub(r'(?<!^)(?=[A-Z])', '_', name).lower()
    return s


def collect_enums(schemas: Dict[str, Any]) -> Dict[str, List[str]]:
    return {name: schema['enum'] for name, schema in schemas.items() if schema.get('type') == 'string' and 'enum' in schema}


def is_nullable_schema(schema: Dict[str, Any]) -> bool:
    t = schema.get('type')
    if isinstance(t, list) and 'null' in t:
        return True
    if 'oneOf' in schema:
        return any(s.get('type') == 'null' for s in schema['oneOf'])
    if 'anyOf' in schema:
        return any(s.get('type') == 'null' for s in schema['anyOf'])
    return False


def non_null_schema(schema: Dict[str, Any]) -> Dict[str, Any]:
    if 'oneOf' in schema:
        choices = [s for s in schema['oneOf'] if s.get('type') != 'null']
        if len(choices) == 1:
            return choices[0]
    if 'anyOf' in schema:
        choices = [s for s in schema['anyOf'] if s.get('type') != 'null']
        if len(choices) == 1:
            return choices[0]
    t = schema.get('type')
    if isinstance(t, list):
        non = [x for x in t if x != 'null']
        if len(non) == 1:
            cp = dict(schema)
            cp['type'] = non[0]
            return cp
    return schema


def schema_ref_name(schema: Dict[str, Any]) -> Optional[str]:
    if '$ref' in schema:
        return schema['$ref'].split('/')[-1]
    nn = non_null_schema(schema)
    if '$ref' in nn:
        return nn['$ref'].split('/')[-1]
    return None


class TypeInfo:
    def __init__(self, dart_type: str, nullable: bool, kind: str, enum_name: Optional[str] = None, list_item: Optional['TypeInfo'] = None):
        self.dart_type = dart_type
        self.nullable = nullable
        self.kind = kind  # primitive, datetime, enum, model, list, map, dynamic
        self.enum_name = enum_name
        self.list_item = list_item

    @property
    def type_string(self) -> str:
        return self.dart_type + ('?' if self.nullable and not self.dart_type.endswith('?') else '')


def type_from_schema(schema: Dict[str, Any], enums: Dict[str, List[str]], required: bool = False) -> TypeInfo:
    nullable = is_nullable_schema(schema) or not required
    s = non_null_schema(schema)
    ref = schema_ref_name(s)
    if ref:
        if ref in enums:
            return TypeInfo(ref, nullable, 'enum', enum_name=ref)
        return TypeInfo(ref, nullable, 'model')
    t = s.get('type')
    if t == 'string':
        if s.get('format') == 'date-time':
            return TypeInfo('DateTime', nullable, 'datetime')
        return TypeInfo('String', nullable, 'primitive')
    if t == 'integer':
        return TypeInfo('int', nullable, 'primitive')
    if t == 'number':
        return TypeInfo('double', nullable, 'primitive')
    if t == 'boolean':
        return TypeInfo('bool', nullable, 'primitive')
    if t == 'array':
        item = type_from_schema(s.get('items', {}), enums, required=True)
        return TypeInfo(f'List<{item.dart_type}>', nullable, 'list', list_item=item)
    if t == 'object':
        if 'additionalProperties' in s:
            add = s['additionalProperties']
            if add == True or add == {}:
                return TypeInfo('Map<String, Object?>', nullable, 'map')
            add_type = type_from_schema(add, enums, required=True)
            return TypeInfo(f'Map<String, {add_type.dart_type}>', nullable, 'map')
        return TypeInfo('Map<String, Object?>', nullable, 'map')
    # Empty schema: arbitrary JSON value.
    return TypeInfo('Object?', False, 'dynamic')


def converter_annotation(ti: TypeInfo) -> Optional[str]:
    if ti.kind == 'enum' and ti.enum_name:
        return f"@{'Nullable' if ti.nullable else ''}{ti.enum_name}JsonConverter()"
    if ti.kind == 'list' and ti.list_item and ti.list_item.kind == 'enum' and ti.list_item.enum_name:
        return f"@{'Nullable' if ti.nullable else ''}{ti.list_item.enum_name}ListJsonConverter()"
    return None


def default_for_required(schema: Dict[str, Any], ti: TypeInfo) -> Optional[str]:
    # Do not inject defaults for required fields; the backend contract should be honored.
    return None


def generate_enums(enums: Dict[str, List[str]]) -> str:
    chunks = ["// GENERATED FROM openapi.json. Do not edit by hand.", "import 'package:json_annotation/json_annotation.dart';", ""]
    for enum_name in sorted(enums.keys()):
        values = enums[enum_name]
        chunks.append(f'enum {enum_name} {{')
        used = set()
        for wire in values:
            member = enum_member_name(wire)
            base = member
            i = 2
            while member in used or member == 'unknown':
                member = f'{base}{i}'
                i += 1
            used.add(member)
            chunks.append(f"  {member}('{wire}'),")
        unknown_wire = '__unknown__'
        chunks.append(f"  unknown('{unknown_wire}');")
        chunks.append('')
        chunks.append(f'  const {enum_name}(this.wireValue);')
        chunks.append('  final String wireValue;')
        chunks.append('')
        chunks.append(f'  static {enum_name} fromJson(Object? value) {{')
        chunks.append('    final wire = value is String ? value : null;')
        chunks.append(f'    return {enum_name}Wire.fromJson(wire);')
        chunks.append('  }')
        chunks.append('')
        chunks.append('  String toJson() => wireValue;')
        chunks.append('')
        chunks.append('  @override')
        chunks.append('  String toString() => wireValue;')
        chunks.append('}')
        chunks.append('')
        chunks.append(f'class {enum_name}Wire {{')
        chunks.append(f'  static const unknown = {enum_name}.unknown;')
        chunks.append(f'  static const Map<String, {enum_name}> _byWire = <String, {enum_name}>{{')
        for wire in values:
            member = enum_member_name(wire)
            # Repeat conflict resolution deterministically.
            # Simple because no conflicting wires in current contract.
            if member == 'unknown':
                member = 'unknown2'
            chunks.append(f"    '{wire}': {enum_name}.{member},")
        chunks.append('  };')
        chunks.append('')
        chunks.append(f'  static {enum_name} fromJson(Object? value) =>')
        chunks.append(f'      value is String ? (_byWire[value] ?? {enum_name}.unknown) : {enum_name}.unknown;')
        chunks.append('')
        chunks.append(f'  static String toJson({enum_name} value) => value.wireValue;')
        chunks.append('}')
        chunks.append('')
        chunks.append(f'class {enum_name}JsonConverter implements JsonConverter<{enum_name}, Object?> {{')
        chunks.append(f'  const {enum_name}JsonConverter();')
        chunks.append('')
        chunks.append('  @override')
        chunks.append(f'  {enum_name} fromJson(Object? json) => {enum_name}.fromJson(json);')
        chunks.append('')
        chunks.append('  @override')
        chunks.append(f'  Object? toJson({enum_name} object) => object.toJson();')
        chunks.append('}')
        chunks.append('')
        chunks.append(f'class Nullable{enum_name}JsonConverter implements JsonConverter<{enum_name}?, Object?> {{')
        chunks.append(f'  const Nullable{enum_name}JsonConverter();')
        chunks.append('')
        chunks.append('  @override')
        chunks.append(f'  {enum_name}? fromJson(Object? json) => json == null ? null : {enum_name}.fromJson(json);')
        chunks.append('')
        chunks.append('  @override')
        chunks.append(f'  Object? toJson({enum_name}? object) => object?.toJson();')
        chunks.append('}')
        chunks.append('')
        chunks.append(f'class {enum_name}ListJsonConverter implements JsonConverter<List<{enum_name}>, Object?> {{')
        chunks.append(f'  const {enum_name}ListJsonConverter();')
        chunks.append('')
        chunks.append('  @override')
        chunks.append(f'  List<{enum_name}> fromJson(Object? json) {{')
        chunks.append('    if (json is! Iterable) return const [];')
        chunks.append(f'    return json.map({enum_name}.fromJson).toList(growable: false);')
        chunks.append('  }')
        chunks.append('')
        chunks.append('  @override')
        chunks.append(f'  Object? toJson(List<{enum_name}> object) => object.map((e) => e.toJson()).toList(growable: false);')
        chunks.append('}')
        chunks.append('')
        chunks.append(f'class Nullable{enum_name}ListJsonConverter implements JsonConverter<List<{enum_name}>?, Object?> {{')
        chunks.append(f'  const Nullable{enum_name}ListJsonConverter();')
        chunks.append('')
        chunks.append('  @override')
        chunks.append(f'  List<{enum_name}>? fromJson(Object? json) {{')
        chunks.append('    if (json == null) return null;')
        chunks.append('    if (json is! Iterable) return const [];')
        chunks.append(f'    return json.map({enum_name}.fromJson).toList(growable: false);')
        chunks.append('  }')
        chunks.append('')
        chunks.append('  @override')
        chunks.append(f'  Object? toJson(List<{enum_name}>? object) => object?.map((e) => e.toJson()).toList(growable: false);')
        chunks.append('}')
        chunks.append('')
    return '\n'.join(chunks)


def generate_models(schemas: Dict[str, Any], enums: Dict[str, List[str]]) -> str:
    exclude_prefixes = ('ApiResponse_', 'ApiListResponse_')
    exclude = set(enums.keys()) | {'ApiErrorDto', 'ApiErrorResponse'}
    chunks = [
        "// GENERATED FROM openapi.json. Do not edit by hand.",
        "import 'package:freezed_annotation/freezed_annotation.dart';",
        "",
        "import 'enums.dart';",
        "",
        "part 'models.freezed.dart';",
        "part 'models.g.dart';",
        "",
    ]
    for name in sorted(schemas.keys()):
        schema = schemas[name]
        if name in exclude or any(name.startswith(p) for p in exclude_prefixes):
            continue
        if schema.get('type') != 'object':
            # Non-object schemas are enum or envelope specializations.
            continue
        required = set(schema.get('required', []))
        props = schema.get('properties', {})
        chunks.append('@freezed')
        chunks.append(f'class {name} with _${name} {{')
        chunks.append('  @JsonSerializable(includeIfNull: false, explicitToJson: true)')
        chunks.append(f'  const factory {name}({{')
        for json_name, prop_schema in props.items():
            is_req = json_name in required
            ti = type_from_schema(prop_schema, enums, required=is_req)
            field_name = dart_field_name(json_name)
            annotations = []
            conv = converter_annotation(ti)
            if conv:
                annotations.append(conv)
            annotations.append(f"@JsonKey(name: '{json_name}')")
            annot = ' '.join(annotations)
            required_kw = 'required ' if is_req else ''
            chunks.append(f'    {annot} {required_kw}{ti.type_string} {field_name},')
        chunks.append(f'  }}) = _{name};')
        chunks.append('')
        chunks.append(f'  factory {name}.fromJson(Map<String, dynamic> json) => _${name}FromJson(json);')
        chunks.append('}')
        chunks.append('')
    return '\n'.join(chunks)


def generate_api_response() -> str:
    return r"""
// Hand-written shared envelopes matching the generated OpenAPI envelope shapes.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'models.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

@freezed
class ApiError with _$ApiError {
  const factory ApiError({
    @ErrorCodeJsonConverter() @JsonKey(name: 'code') required ErrorCode code,
    @JsonKey(name: 'message') required String message,
    @JsonKey(name: 'details') Object? details,
  }) = _ApiError;

  factory ApiError.fromJson(Map<String, dynamic> json) => _$ApiErrorFromJson(json);
}

typedef ApiErrorDto = ApiError;

@Freezed(genericArgumentFactories: true)
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    @JsonKey(name: 'success') required bool success,
    @JsonKey(name: 'data') T? data,
    @JsonKey(name: 'error') ApiError? error,
    @Default(<String, Object?>{}) @JsonKey(name: 'meta') Map<String, Object?> meta,
  }) = _ApiResponse<T>;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);
}

@Freezed(genericArgumentFactories: true)
class ListResponse<T> with _$ListResponse<T> {
  const factory ListResponse({
    @JsonKey(name: 'success') required bool success,
    @JsonKey(name: 'data') List<T>? data,
    @JsonKey(name: 'error') ApiError? error,
    @JsonKey(name: 'meta') ListMetaDto? meta,
  }) = _ListResponse<T>;

  factory ListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) {
    final dataRaw = json['data'];
    final data = dataRaw is Iterable ? dataRaw.map(fromJsonT).toList(growable: false) : null;
    final errorRaw = json['error'];
    final error = errorRaw is Map ? ApiError.fromJson(Map<String, dynamic>.from(errorRaw)) : null;
    final metaRaw = json['meta'];
    ListMetaDto? meta;
    if (metaRaw is Map && metaRaw['pagination'] != null) {
      meta = ListMetaDto.fromJson(Map<String, dynamic>.from(metaRaw));
    }
    return ListResponse<T>(
      success: json['success'] == true,
      data: data,
      error: error,
      meta: meta,
    );
  }
}

typedef ApiListResponse<T> = ListResponse<T>;

@freezed
class ApiErrorResponse with _$ApiErrorResponse {
  const factory ApiErrorResponse({
    @JsonKey(name: 'success') required bool success,
    @JsonKey(name: 'data') Object? data,
    @JsonKey(name: 'error') required ApiError error,
    @Default(<String, Object?>{}) @JsonKey(name: 'meta') Map<String, Object?> meta,
  }) = _ApiErrorResponse;

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) => _$ApiErrorResponseFromJson(json);
}
""".strip()


def generate_dto_barrel() -> str:
    return """export 'api_response.dart';\nexport 'enums.dart';\nexport 'models.dart';\n"""


def response_dart_type(ref_name: str) -> Tuple[str, str, str]:
    # returns (kind, return_type, item_type_or_data_type)
    if ref_name.startswith('ApiListResponse_'):
        item = ref_name.removeprefix('ApiListResponse_')
        return ('list', f'ListResponse<{item}>', item)
    if ref_name.startswith('ApiResponse_'):
        data = ref_name.removeprefix('ApiResponse_')
        if data.startswith('Vec_'):
            item = data.removeprefix('Vec_')
            return ('api_list_data', f'ApiResponse<List<{item}>>', item)
        return ('api', f'ApiResponse<{data}>', data)
    if ref_name == 'ApiErrorResponse':
        return ('error', 'ApiErrorResponse', 'ApiErrorResponse')
    return ('api', f'ApiResponse<{ref_name}>', ref_name)


def success_response_ref(op: Dict[str, Any]) -> Optional[str]:
    responses = op.get('responses', {})
    for status in sorted(responses.keys()):
        try:
            code = int(status)
        except ValueError:
            continue
        if 200 <= code < 300:
            schema = responses[status].get('content', {}).get('application/json', {}).get('schema')
            if schema and '$ref' in schema:
                return schema['$ref'].split('/')[-1]
    return None


def body_ref(op: Dict[str, Any]) -> Optional[str]:
    schema = op.get('requestBody', {}).get('content', {}).get('application/json', {}).get('schema')
    if schema and '$ref' in schema:
        return schema['$ref'].split('/')[-1]
    return None


def param_type(param: Dict[str, Any], enums: Dict[str, List[str]]) -> TypeInfo:
    required = param.get('required', False)
    return type_from_schema(param.get('schema', {}), enums, required=required)


def query_value_expr(param_name: str, ti: TypeInfo) -> str:
    name = dart_field_name(param_name)
    if ti.kind == 'enum':
        return f'{name}?.toJson()'
    if ti.kind == 'list' and ti.list_item and ti.list_item.kind == 'enum':
        return f'{name}?.map((e) => e.toJson()).toList(growable: false)'
    return name


def generate_api_client(openapi: Dict[str, Any], enums: Dict[str, List[str]]) -> str:
    chunks = [
        "// GENERATED FROM openapi.json operationIds. Do not edit by hand.",
        "import 'package:dio/dio.dart';",
        "",
        "import '../dto/dto.dart';",
        "import 'api_exceptions.dart';",
        "",
        "class FeedbackFlowApiClient {",
        "  FeedbackFlowApiClient(this._dio);",
        "",
        "  final Dio _dio;",
        "",
        "  Map<String, dynamic> _jsonObject(Object? value) {",
        "    if (value is Map<String, dynamic>) return value;",
        "    if (value is Map) return Map<String, dynamic>.from(value);",
        "    throw const ApiContractException('Expected a JSON object from the API.');",
        "  }",
        "",
        "  Map<String, dynamic> _clean(Map<String, dynamic> value) {",
        "    return Map<String, dynamic>.from(value)..removeWhere((_, v) => v == null);",
        "  }",
        "",
        "  String _path(String template, Map<String, String> params) {",
        "    var path = template;",
        "    for (final entry in params.entries) {",
        "      path = path.replaceAll('{${entry.key}}', Uri.encodeComponent(entry.value));",
        "    }",
        "    return path;",
        "  }",
        "",
        "  ApiResponse<T> _parseApiResponse<T>(Object? json, T Function(Object?) fromJsonT) {",
        "    return ApiResponse<T>.fromJson(_jsonObject(json), fromJsonT);",
        "  }",
        "",
        "  ListResponse<T> _parseListResponse<T>(Object? json, T Function(Object?) fromJsonT) {",
        "    final map = _jsonObject(json);",
        "    final dataRaw = map['data'];",
        "    final data = dataRaw is Iterable ? dataRaw.map(fromJsonT).toList(growable: false) : null;",
        "    final errorRaw = map['error'];",
        "    final error = errorRaw is Map ? ApiError.fromJson(Map<String, dynamic>.from(errorRaw)) : null;",
        "    final metaRaw = map['meta'];",
        "    ListMetaDto? meta;",
        "    if (metaRaw is Map && metaRaw['pagination'] != null) {",
        "      meta = ListMetaDto.fromJson(Map<String, dynamic>.from(metaRaw));",
        "    }",
        "    return ListResponse<T>(success: map['success'] == true, data: data, error: error, meta: meta);",
        "  }",
        "",
        "  List<T> _parseDtoList<T>(Object? json, T Function(Object?) fromJsonT) {",
        "    if (json is! Iterable) return const [];",
        "    return json.map(fromJsonT).toList(growable: false);",
        "  }",
        "",
    ]
    for path, path_item in openapi['paths'].items():
        placeholders = set(re.findall(r'{([^}]+)}', path))
        for method, op in path_item.items():
            if method.lower() not in {'get','post','patch','delete','put'}:
                continue
            opid = op['operationId']
            resp_ref = success_response_ref(op)
            if not resp_ref:
                continue
            kind, ret_type, data_type = response_dart_type(resp_ref)
            b_ref = body_ref(op)
            params = op.get('parameters', [])
            sig_parts: List[str] = []
            query_entries: List[Tuple[str, str]] = []
            path_entries: List[Tuple[str, str]] = []
            for p in params:
                json_name = p['name']
                ti = param_type(p, enums)
                name = dart_field_name(json_name)
                # Required nullable parameters are made optional with defaults for ergonomic list calls,
                # while still preserving the JSON parameter names and operationId.
                default = PARAM_DEFAULTS.get(json_name)
                is_path_placeholder = json_name in placeholders
                if is_path_placeholder:
                    sig_parts.append(f'required {ti.type_string} {name}')
                    path_entries.append((json_name, name))
                else:
                    if default is not None:
                        sig_parts.append(f'{ti.type_string} {name} = {default}')
                    elif p.get('required', False):
                        sig_parts.append(f'required {ti.type_string} {name}')
                    else:
                        sig_parts.append(f'{ti.type_string} {name}')
                    query_entries.append((json_name, query_value_expr(json_name, ti)))
            if b_ref:
                sig_parts.append(f'required {b_ref} request')
            if sig_parts:
                sig = '{' + ', '.join(sig_parts) + '}'
            else:
                sig = ''
            chunks.append(f'  /// operationId: {opid}')
            chunks.append(f'  /// {method.upper()} {path}')
            if op.get('security'):
                chunks.append('  /// Requires Bearer JWT.')
            else:
                chunks.append('  /// Public endpoint; no Bearer JWT required by the contract.')
            chunks.append(f'  Future<{ret_type}> {opid}({sig}) async {{')
            path_expr = f"'{path}'"
            if path_entries:
                pairs = ', '.join([f"'{json}': {var}.toString()" for json, var in path_entries])
                path_expr = f"_path('{path}', <String, String>{{{pairs}}})"
            query_code = ''
            if query_entries:
                qmap = ', '.join([f"'{json}': {expr}" for json, expr in query_entries])
                query_code = f', queryParameters: _clean(<String, dynamic>{{{qmap}}})'
            data_code = ', data: request.toJson()' if b_ref else ''
            dio_method = method.lower()
            chunks.append(f"    final response = await _dio.{dio_method}<Map<String, dynamic>>({path_expr}{query_code}{data_code});")
            if kind == 'api':
                chunks.append(f"    return _parseApiResponse<{data_type}>(response.data, (json) => {data_type}.fromJson(_jsonObject(json)));" )
            elif kind == 'api_list_data':
                chunks.append(f"    return _parseApiResponse<List<{data_type}>>(response.data, (json) => _parseDtoList<{data_type}>(json, (item) => {data_type}.fromJson(_jsonObject(item))));")
            elif kind == 'list':
                chunks.append(f"    return _parseListResponse<{data_type}>(response.data, (json) => {data_type}.fromJson(_jsonObject(json)));" )
            else:
                chunks.append("    return ApiErrorResponse.fromJson(_jsonObject(response.data));")
            chunks.append('  }')
            chunks.append('')
    chunks.append('}')
    chunks.append('')
    return '\n'.join(chunks)


def generate_api_exceptions() -> str:
    return r"""
import '../dto/dto.dart';

class ApiFailure implements Exception {
  const ApiFailure({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
  });

  final ErrorCode code;
  final String message;
  final Object? details;
  final int? statusCode;

  factory ApiFailure.fromError(ApiError? error, {int? statusCode}) {
    if (error == null) {
      return const ApiFailure(
        code: ErrorCode.internalServerError,
        message: 'The server returned success=false without an error object.',
      );
    }
    return ApiFailure(
      code: error.code,
      message: error.message,
      details: error.details,
      statusCode: statusCode,
    );
  }

  bool get isAuthFailure => code == ErrorCode.unauthorized || code == ErrorCode.invalidToken || code == ErrorCode.tokenExpired;
  bool get isPermissionFailure => code == ErrorCode.forbidden || code == ErrorCode.permissionDenied;
  bool get isValidationFailure => code == ErrorCode.validationError;
  bool get isRateLimited => code == ErrorCode.rateLimited;
  bool get isPublicFormClosed => code == ErrorCode.formClosed;

  @override
  String toString() => 'ApiFailure(code: ${code.toJson()}, message: $message)';
}

class ApiContractException implements Exception {
  const ApiContractException(this.message);
  final String message;

  @override
  String toString() => 'ApiContractException: $message';
}

class EnvelopeGuard {
  const EnvelopeGuard._();

  static T data<T>(ApiResponse<T> response) {
    if (!response.success) {
      throw ApiFailure.fromError(response.error);
    }
    final data = response.data;
    if (data == null) {
      throw const ApiContractException('The server returned success=true with null data.');
    }
    return data;
  }

  static List<T> dataList<T>(ApiResponse<List<T>> response) {
    if (!response.success) {
      throw ApiFailure.fromError(response.error);
    }
    final data = response.data;
    if (data == null) {
      throw const ApiContractException('The server returned success=true with null list data.');
    }
    return data;
  }

  static ListResponse<T> list<T>(ListResponse<T> response) {
    if (!response.success) {
      throw ApiFailure.fromError(response.error);
    }
    if (response.data == null) {
      throw const ApiContractException('The server returned success=true with null list data.');
    }
    if (response.meta?.pagination == null) {
      throw const ApiContractException('The server returned a list without pagination meta.');
    }
    return response;
  }
}
""".strip()


def generate_token_store() -> str:
    return r"""
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokenStore {
  AuthTokenStore(this._storage);

  static const _accessTokenKey = 'feedbackflow.access_token';
  static const _refreshTokenKey = 'feedbackflow.refresh_token';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
""".strip()


def generate_dio_factory() -> str:
    return r"""
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../security/token_store.dart';

class ApiDioFactory {
  const ApiDioFactory._();

  static Dio create({
    required String baseUrl,
    required AuthTokenStore tokenStore,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        validateStatus: (status) => status != null && status < 600,
        headers: const {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(_BearerTokenInterceptor(tokenStore));
    return dio;
  }

  static AuthTokenStore defaultTokenStore() => AuthTokenStore(const FlutterSecureStorage());
}

class _BearerTokenInterceptor extends Interceptor {
  _BearerTokenInterceptor(this._tokenStore);

  final AuthTokenStore _tokenStore;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final path = options.path;
    final isPublicAuth = path.contains('/api/v1/auth/login') ||
        path.contains('/api/v1/auth/register') ||
        path.contains('/api/v1/auth/refresh') ||
        path.contains('/api/v1/public/');
    if (!isPublicAuth) {
      final token = await _tokenStore.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
""".strip()


def repo_return(kind: str, ret_type: str, data_type: str) -> str:
    if kind == 'api':
        return data_type
    if kind == 'api_list_data':
        return f'List<{data_type}>'
    if kind == 'list':
        return f'ListResponse<{data_type}>'
    return ret_type


def repo_guard(kind: str, opid: str) -> str:
    if kind == 'api':
        return f'EnvelopeGuard.data(await _api.{opid}('
    if kind == 'api_list_data':
        return f'EnvelopeGuard.dataList(await _api.{opid}('
    if kind == 'list':
        return f'EnvelopeGuard.list(await _api.{opid}('
    return f'await _api.{opid}('


def generate_repositories(openapi: Dict[str, Any], enums: Dict[str, List[str]]) -> Dict[str, str]:
    by_tag: Dict[str, List[Tuple[str, str, Dict[str, Any]]]] = {}
    for path, path_item in openapi['paths'].items():
        for method, op in path_item.items():
            if method.lower() not in {'get','post','patch','delete','put'}:
                continue
            tag = op.get('tags', ['Api'])[0]
            by_tag.setdefault(tag, []).append((path, method.lower(), op))
    files: Dict[str, str] = {}
    for tag in sorted(by_tag.keys()):
        class_base = re.sub(r'[^A-Za-z0-9]', '', tag)
        repo_name = f'{class_base}Repository'
        impl_name = f'Dio{class_base}Repository'
        chunks = [
            f"import '../api/feedback_flow_api_client.dart';",
            f"import '../api/api_exceptions.dart';",
            f"import '../dto/dto.dart';",
            "",
            f'abstract class {repo_name} {{',
        ]
        method_defs = []
        impl_defs = []
        for path, method, op in by_tag[tag]:
            opid = op['operationId']
            resp_ref = success_response_ref(op)
            if not resp_ref:
                continue
            kind, api_ret, data_type = response_dart_type(resp_ref)
            ret = repo_return(kind, api_ret, data_type)
            b_ref = body_ref(op)
            params = op.get('parameters', [])
            sig_parts = []
            call_parts = []
            for p in params:
                ti = param_type(p, enums)
                name = dart_field_name(p['name'])
                default = PARAM_DEFAULTS.get(p['name'])
                if default is not None:
                    sig_parts.append(f'{ti.type_string} {name} = {default}')
                elif p.get('required', False):
                    sig_parts.append(f'required {ti.type_string} {name}')
                else:
                    sig_parts.append(f'{ti.type_string} {name}')
                call_parts.append(f'{name}: {name}')
            if b_ref:
                sig_parts.append(f'required {b_ref} request')
                call_parts.append('request: request')
            sig = '{' + ', '.join(sig_parts) + '}' if sig_parts else ''
            method_defs.append(f'  Future<{ret}> {opid}({sig});')
            call = ', '.join(call_parts)
            open_call = repo_guard(kind, opid)
            impl_defs.append(f'  @override')
            impl_defs.append(f'  Future<{ret}> {opid}({sig}) async {{')
            if call:
                impl_defs.append(f'    return {open_call}{call}));')
            else:
                impl_defs.append(f'    return {open_call}));')
            impl_defs.append('  }')
            impl_defs.append('')
        chunks.extend(method_defs)
        chunks.append('}')
        chunks.append('')
        chunks.append(f'class {impl_name} implements {repo_name} {{')
        chunks.append(f'  {impl_name}(this._api);')
        chunks.append('')
        chunks.append('  final FeedbackFlowApiClient _api;')
        chunks.append('')
        chunks.extend(impl_defs)
        chunks.append('}')
        files[f'{file_name_for_class(tag)}_repository.dart'] = '\n'.join(chunks)
    return files


def generate_domain_entities() -> str:
    return r"""
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/dto/dto.dart';

part 'entities.freezed.dart';

@freezed
class FormEntity with _$FormEntity {
  const factory FormEntity({
    required String id,
    required String organizationId,
    required String creatorId,
    required String title,
    String? description,
    required FormStatus status,
    required VisibilityMode visibilityMode,
    required PublishMode publishMode,
    required ScoringMode scoringMode,
    required int submissionsCount,
    String? publicToken,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _FormEntity;
}

@freezed
class FormFieldEntity with _$FormFieldEntity {
  const factory FormFieldEntity({
    required String id,
    required String formId,
    required FieldType type,
    required String label,
    String? description,
    String? placeholder,
    required bool isRequired,
    required int orderIndex,
  }) = _FormFieldEntity;
}

@freezed
class SubmissionEntity with _$SubmissionEntity {
  const factory SubmissionEntity({
    required String id,
    required String formId,
    String? respondentUserId,
    required bool anonymous,
    required bool valid,
    required SubmissionScoreDto score,
    required DateTime submittedAt,
    DateTime? updatedAt,
  }) = _SubmissionEntity;
}

@freezed
class PermissionSetEntity with _$PermissionSetEntity {
  const factory PermissionSetEntity({
    required String userId,
    String? organizationId,
    required UserRole role,
    required List<PermissionAction> actions,
    required List<ResourceType> resources,
    required List<FieldType> fieldTypes,
    required bool canManagePermissions,
    required bool canManageScoring,
    required bool canManagePublicProtection,
  }) = _PermissionSetEntity;
}

@freezed
class ActivityEntity with _$ActivityEntity {
  const factory ActivityEntity({
    required String id,
    required String organizationId,
    String? formId,
    String? submissionId,
    String? assignedToUserId,
    required String title,
    String? description,
    required ActivityStatus status,
    DateTime? dueAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ActivityEntity;
}
""".strip()


def generate_mappers() -> Dict[str, str]:
    return {
        'form_dto_mapper.dart': r"""
import '../../domain/entities/entities.dart';
import '../dto/dto.dart';

class FormDtoMapper {
  const FormDtoMapper._();

  static FormEntity summaryToEntity(FormSummaryDto dto) => FormEntity(
        id: dto.id,
        organizationId: dto.organizationId,
        creatorId: dto.creatorId,
        title: dto.title,
        description: dto.description,
        status: dto.status,
        visibilityMode: dto.visibilityMode,
        publishMode: dto.publishMode,
        scoringMode: dto.scoringMode,
        submissionsCount: dto.submissionsCount,
        publicToken: dto.publicToken,
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
      );

  static FormEntity detailToEntity(FormDetailDto dto) => FormEntity(
        id: dto.id,
        organizationId: dto.organizationId,
        creatorId: dto.creatorId,
        title: dto.title,
        description: dto.description,
        status: dto.status,
        visibilityMode: dto.visibilityMode,
        publishMode: dto.publishMode,
        scoringMode: dto.scoringMode,
        submissionsCount: 0,
        publicToken: dto.publicToken,
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
      );
}
""".strip(),
        'field_dto_mapper.dart': r"""
import '../../domain/entities/entities.dart';
import '../dto/dto.dart';

class FieldDtoMapper {
  const FieldDtoMapper._();

  static FormFieldEntity toEntity(FormFieldDto dto) => FormFieldEntity(
        id: dto.id,
        formId: dto.formId,
        type: dto.type,
        label: dto.label,
        description: dto.description,
        placeholder: dto.placeholder,
        isRequired: dto.isRequired,
        orderIndex: dto.orderIndex,
      );
}
""".strip(),
        'submission_dto_mapper.dart': r"""
import '../../domain/entities/entities.dart';
import '../dto/dto.dart';

class SubmissionDtoMapper {
  const SubmissionDtoMapper._();

  static SubmissionEntity detailToEntity(SubmissionDetailDto dto) => SubmissionEntity(
        id: dto.id,
        formId: dto.formId,
        respondentUserId: dto.respondentUserId,
        anonymous: dto.anonymous,
        valid: dto.valid,
        score: dto.score,
        submittedAt: dto.submittedAt,
        updatedAt: dto.updatedAt,
      );

  static SubmissionEntity summaryToEntity(SubmissionSummaryDto dto) => SubmissionEntity(
        id: dto.id,
        formId: dto.formId,
        respondentUserId: dto.respondentUserId,
        anonymous: dto.anonymous,
        valid: dto.valid,
        score: dto.score,
        submittedAt: dto.submittedAt,
      );
}
""".strip(),
        'permission_dto_mapper.dart': r"""
import '../../domain/entities/entities.dart';
import '../dto/dto.dart';

class PermissionDtoMapper {
  const PermissionDtoMapper._();

  static PermissionSetEntity toEntity(EffectivePermissionsDto dto) => PermissionSetEntity(
        userId: dto.userId,
        organizationId: dto.organizationId,
        role: dto.role,
        actions: dto.actions,
        resources: dto.resources,
        fieldTypes: dto.fieldTypes,
        canManagePermissions: dto.canManagePermissions,
        canManageScoring: dto.canManageScoring,
        canManagePublicProtection: dto.canManagePublicProtection,
      );
}
""".strip(),
        'activity_dto_mapper.dart': r"""
import '../../domain/entities/entities.dart';
import '../dto/dto.dart';

class ActivityDtoMapper {
  const ActivityDtoMapper._();

  static ActivityEntity toEntity(ActivityDto dto) => ActivityEntity(
        id: dto.id,
        organizationId: dto.organizationId,
        formId: dto.formId,
        submissionId: dto.submissionId,
        assignedToUserId: dto.assignedToUserId,
        title: dto.title,
        description: dto.description,
        status: dto.status,
        dueAt: dto.dueAt,
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
      );
}
""".strip(),
    }


def generate_drift_db() -> str:
    return r"""
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class LocalForms extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get creatorId => text()();
  TextColumn get title => text()();
  TextColumn get status => text()();
  TextColumn get rawJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalFormFields extends Table {
  TextColumn get id => text()();
  TextColumn get formId => text()();
  TextColumn get fieldType => text()();
  TextColumn get label => text()();
  IntColumn get orderIndex => integer()();
  TextColumn get rawJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalSubmissions extends Table {
  TextColumn get id => text()();
  TextColumn get formId => text()();
  TextColumn get rawJson => text()();
  DateTimeColumn get submittedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalActivities extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get title => text()();
  TextColumn get status => text()();
  TextColumn get rawJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalPermissions extends Table {
  TextColumn get userId => text()();
  TextColumn get role => text()();
  TextColumn get rawJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

@DriftDatabase(tables: [LocalForms, LocalFormFields, LocalSubmissions, LocalActivities, LocalPermissions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'feedbackflow'));

  @override
  int get schemaVersion => 1;
}
""".strip()


def generate_error_presenter() -> str:
    return r"""
import '../../data/api/api_exceptions.dart';
import '../../data/dto/dto.dart';

class FriendlyApiErrorMessage {
  const FriendlyApiErrorMessage._();

  static String from(Object error) {
    if (error is! ApiFailure) return 'Something went wrong. Please try again.';
    switch (error.code) {
      case ErrorCode.validationError:
        return error.message;
      case ErrorCode.unauthorized:
      case ErrorCode.invalidToken:
      case ErrorCode.tokenExpired:
        return 'Your session has expired. Please sign in again.';
      case ErrorCode.forbidden:
      case ErrorCode.permissionDenied:
        return 'You do not have permission to perform this action.';
      case ErrorCode.rateLimited:
        return 'Too many requests. Please try again later.';
      case ErrorCode.formClosed:
        return 'This public form is closed.';
      case ErrorCode.formNotPublished:
        return 'This form is not published yet.';
      case ErrorCode.publicAccessDenied:
      case ErrorCode.publicProtectionRequired:
        return 'Public access validation is required before submitting this form.';
      case ErrorCode.notFound:
        return 'The requested resource was not found.';
      case ErrorCode.conflict:
      case ErrorCode.approvalRequired:
      case ErrorCode.internalServerError:
      case ErrorCode.serviceUnavailable:
      case ErrorCode.unknown:
        return error.message;
    }
  }
}
""".strip()


def generate_blocs() -> Dict[str, str]:
    return {
        'auth/auth_bloc.dart': r"""
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/security/token_store.dart';
import '../../../data/api/api_exceptions.dart';
import '../../../data/dto/dto.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../common/friendly_api_error_message.dart';

part 'auth_bloc.freezed.dart';

@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.started() = AuthStarted;
  const factory AuthEvent.loginRequested({required String email, required String password}) = AuthLoginRequested;
  const factory AuthEvent.logoutRequested() = AuthLogoutRequested;
}

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated({required UserDetailDto user, required EffectivePermissionsDto permissions}) = AuthAuthenticated;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.failure({required String message, ErrorCode? code}) = AuthFailureState;
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository, required AuthTokenStore tokenStore})
      : _authRepository = authRepository,
        _tokenStore = tokenStore,
        super(const AuthState.initial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _authRepository;
  final AuthTokenStore _tokenStore;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    try {
      final me = await _authRepository.getMe();
      emit(AuthState.authenticated(user: me.user, permissions: me.effectivePermissions));
    } catch (error) {
      await _tokenStore.clear();
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    try {
      final response = await _authRepository.login(request: LoginRequest(email: event.email, password: event.password));
      await _tokenStore.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken);
      final me = await _authRepository.getMe();
      emit(AuthState.authenticated(user: me.user, permissions: me.effectivePermissions));
    } catch (error) {
      emit(AuthState.failure(
        message: FriendlyApiErrorMessage.from(error),
        code: error is ApiFailure ? error.code : null,
      ));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken != null) {
      try {
        await _authRepository.logout(request: LogoutRequest(refreshToken: refreshToken));
      } catch (_) {
        // Local logout still succeeds when the server has already revoked or expired the token.
      }
    }
    await _tokenStore.clear();
    emit(const AuthState.unauthenticated());
  }
}
""".strip(),
        'forms/forms_bloc.dart': r"""
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/api/api_exceptions.dart';
import '../../../data/dto/dto.dart';
import '../../../data/repositories/forms_repository.dart';
import '../../common/friendly_api_error_message.dart';

part 'forms_bloc.freezed.dart';

@freezed
class FormsEvent with _$FormsEvent {
  const factory FormsEvent.loadRequested({@Default(1) int page}) = FormsLoadRequested;
  const factory FormsEvent.createRequested({required CreateFormRequest request}) = FormsCreateRequested;
  const factory FormsEvent.refreshRequested() = FormsRefreshRequested;
}

@freezed
class FormsState with _$FormsState {
  const factory FormsState.initial() = FormsInitial;
  const factory FormsState.loading() = FormsLoading;
  const factory FormsState.loaded({required List<FormSummaryDto> forms, required PaginationMeta pagination}) = FormsLoaded;
  const factory FormsState.failure({required String message, ErrorCode? code}) = FormsFailure;
}

class FormsBloc extends Bloc<FormsEvent, FormsState> {
  FormsBloc(this._formsRepository) : super(const FormsState.initial()) {
    on<FormsLoadRequested>(_onLoadRequested);
    on<FormsCreateRequested>(_onCreateRequested);
    on<FormsRefreshRequested>(_onRefreshRequested);
  }

  final FormsRepository _formsRepository;

  Future<void> _onLoadRequested(FormsLoadRequested event, Emitter<FormsState> emit) async {
    emit(const FormsState.loading());
    try {
      final response = await _formsRepository.listForms(page: event.page);
      emit(FormsState.loaded(
        forms: response.data ?? const [],
        pagination: response.meta!.pagination,
      ));
    } catch (error) {
      emit(FormsState.failure(
        message: FriendlyApiErrorMessage.from(error),
        code: error is ApiFailure ? error.code : null,
      ));
    }
  }

  Future<void> _onCreateRequested(FormsCreateRequested event, Emitter<FormsState> emit) async {
    try {
      await _formsRepository.createForm(request: event.request);
      add(const FormsEvent.refreshRequested());
    } catch (error) {
      emit(FormsState.failure(
        message: FriendlyApiErrorMessage.from(error),
        code: error is ApiFailure ? error.code : null,
      ));
    }
  }

  Future<void> _onRefreshRequested(FormsRefreshRequested event, Emitter<FormsState> emit) async {
    add(const FormsEvent.loadRequested());
  }
}
""".strip(),
        'form_detail/form_detail_bloc.dart': r"""
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/api/api_exceptions.dart';
import '../../../data/dto/dto.dart';
import '../../../data/repositories/forms_repository.dart';
import '../../common/friendly_api_error_message.dart';

part 'form_detail_bloc.freezed.dart';

@freezed
class FormDetailEvent with _$FormDetailEvent {
  const factory FormDetailEvent.loadRequested({required String formId}) = FormDetailLoadRequested;
  const factory FormDetailEvent.publishRequested({required String formId, required PublishFormRequest request}) = FormDetailPublishRequested;
}

@freezed
class FormDetailState with _$FormDetailState {
  const factory FormDetailState.initial() = FormDetailInitial;
  const factory FormDetailState.loading() = FormDetailLoading;
  const factory FormDetailState.loaded(FormDetailDto form) = FormDetailLoaded;
  const factory FormDetailState.failure({required String message, ErrorCode? code}) = FormDetailFailure;
}

class FormDetailBloc extends Bloc<FormDetailEvent, FormDetailState> {
  FormDetailBloc(this._formsRepository) : super(const FormDetailState.initial()) {
    on<FormDetailLoadRequested>(_onLoadRequested);
    on<FormDetailPublishRequested>(_onPublishRequested);
  }

  final FormsRepository _formsRepository;

  Future<void> _onLoadRequested(FormDetailLoadRequested event, Emitter<FormDetailState> emit) async {
    emit(const FormDetailState.loading());
    try {
      emit(FormDetailState.loaded(await _formsRepository.getForm(id: event.formId)));
    } catch (error) {
      emit(FormDetailState.failure(
        message: FriendlyApiErrorMessage.from(error),
        code: error is ApiFailure ? error.code : null,
      ));
    }
  }

  Future<void> _onPublishRequested(FormDetailPublishRequested event, Emitter<FormDetailState> emit) async {
    try {
      final form = await _formsRepository.publishForm(id: event.formId, request: event.request);
      emit(FormDetailState.loaded(form));
    } catch (error) {
      emit(FormDetailState.failure(
        message: FriendlyApiErrorMessage.from(error),
        code: error is ApiFailure ? error.code : null,
      ));
    }
  }
}
""".strip(),
        'public_form/public_form_bloc.dart': r"""
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/api/api_exceptions.dart';
import '../../../data/dto/dto.dart';
import '../../../data/repositories/public_forms_repository.dart';
import '../../common/friendly_api_error_message.dart';

part 'public_form_bloc.freezed.dart';

@freezed
class PublicFormEvent with _$PublicFormEvent {
  const factory PublicFormEvent.loadRequested({required String publicToken}) = PublicFormLoadRequested;
  const factory PublicFormEvent.validateAccessRequested({required String publicToken, required ValidatePublicFormAccessRequest request}) = PublicFormValidateAccessRequested;
  const factory PublicFormEvent.submitRequested({required String publicToken, required PublicSubmissionRequest request}) = PublicFormSubmitRequested;
}

@freezed
class PublicFormState with _$PublicFormState {
  const factory PublicFormState.initial() = PublicFormInitial;
  const factory PublicFormState.loading() = PublicFormLoading;
  const factory PublicFormState.loaded({required PublicFormDto form, String? publicAccessToken}) = PublicFormLoaded;
  const factory PublicFormState.submitted(PublicSubmissionResponse response) = PublicFormSubmitted;
  const factory PublicFormState.failure({required String message, ErrorCode? code}) = PublicFormFailure;
}

class PublicFormBloc extends Bloc<PublicFormEvent, PublicFormState> {
  PublicFormBloc(this._repository) : super(const PublicFormState.initial()) {
    on<PublicFormLoadRequested>(_onLoadRequested);
    on<PublicFormValidateAccessRequested>(_onValidateAccessRequested);
    on<PublicFormSubmitRequested>(_onSubmitRequested);
  }

  final PublicFormsRepository _repository;
  PublicFormDto? _currentForm;

  Future<void> _onLoadRequested(PublicFormLoadRequested event, Emitter<PublicFormState> emit) async {
    emit(const PublicFormState.loading());
    try {
      _currentForm = await _repository.getPublicForm(publicToken: event.publicToken);
      emit(PublicFormState.loaded(form: _currentForm!));
    } catch (error) {
      emit(PublicFormState.failure(
        message: FriendlyApiErrorMessage.from(error),
        code: error is ApiFailure ? error.code : null,
      ));
    }
  }

  Future<void> _onValidateAccessRequested(PublicFormValidateAccessRequested event, Emitter<PublicFormState> emit) async {
    try {
      final result = await _repository.validatePublicFormAccess(publicToken: event.publicToken, request: event.request);
      final form = _currentForm;
      if (form != null) {
        emit(PublicFormState.loaded(form: form, publicAccessToken: result.accessToken));
      }
    } catch (error) {
      emit(PublicFormState.failure(
        message: FriendlyApiErrorMessage.from(error),
        code: error is ApiFailure ? error.code : null,
      ));
    }
  }

  Future<void> _onSubmitRequested(PublicFormSubmitRequested event, Emitter<PublicFormState> emit) async {
    try {
      emit(PublicFormState.submitted(await _repository.submitPublicForm(publicToken: event.publicToken, request: event.request)));
    } catch (error) {
      emit(PublicFormState.failure(
        message: FriendlyApiErrorMessage.from(error),
        code: error is ApiFailure ? error.code : null,
      ));
    }
  }
}
""".strip(),
    }


def generate_app_files() -> Dict[str, str]:
    return {
        'main.dart': r"""
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/dependencies.dart';

void main() {
  const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');
  runApp(FeedbackFlowApp(dependencies: AppDependencies.create(baseUrl: baseUrl)));
}
""".strip(),
        'app/dependencies.dart': r"""
import '../core/api/dio_factory.dart';
import '../core/security/token_store.dart';
import '../data/api/feedback_flow_api_client.dart';
import '../data/local/app_database.dart';
import '../data/repositories/activities_repository.dart';
import '../data/repositories/analytics_repository.dart';
import '../data/repositories/audit_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/fields_repository.dart';
import '../data/repositories/forms_repository.dart';
import '../data/repositories/organizations_repository.dart';
import '../data/repositories/permissions_repository.dart';
import '../data/repositories/public_forms_repository.dart';
import '../data/repositories/scoring_repository.dart';
import '../data/repositories/submissions_repository.dart';
import '../data/repositories/users_repository.dart';

class AppDependencies {
  AppDependencies._({
    required this.tokenStore,
    required this.database,
    required this.apiClient,
    required this.authRepository,
    required this.formsRepository,
    required this.publicFormsRepository,
    required this.activitiesRepository,
    required this.analyticsRepository,
    required this.auditRepository,
    required this.fieldsRepository,
    required this.organizationsRepository,
    required this.permissionsRepository,
    required this.scoringRepository,
    required this.submissionsRepository,
    required this.usersRepository,
  });

  final AuthTokenStore tokenStore;
  final AppDatabase database;
  final FeedbackFlowApiClient apiClient;
  final AuthRepository authRepository;
  final FormsRepository formsRepository;
  final PublicFormsRepository publicFormsRepository;
  final ActivitiesRepository activitiesRepository;
  final AnalyticsRepository analyticsRepository;
  final AuditRepository auditRepository;
  final FieldsRepository fieldsRepository;
  final OrganizationsRepository organizationsRepository;
  final PermissionsRepository permissionsRepository;
  final ScoringRepository scoringRepository;
  final SubmissionsRepository submissionsRepository;
  final UsersRepository usersRepository;

  factory AppDependencies.create({required String baseUrl}) {
    final tokenStore = ApiDioFactory.defaultTokenStore();
    final dio = ApiDioFactory.create(baseUrl: baseUrl, tokenStore: tokenStore);
    final apiClient = FeedbackFlowApiClient(dio);
    return AppDependencies._(
      tokenStore: tokenStore,
      database: AppDatabase(),
      apiClient: apiClient,
      authRepository: DioAuthRepository(apiClient),
      formsRepository: DioFormsRepository(apiClient),
      publicFormsRepository: DioPublicFormsRepository(apiClient),
      activitiesRepository: DioActivitiesRepository(apiClient),
      analyticsRepository: DioAnalyticsRepository(apiClient),
      auditRepository: DioAuditRepository(apiClient),
      fieldsRepository: DioFieldsRepository(apiClient),
      organizationsRepository: DioOrganizationsRepository(apiClient),
      permissionsRepository: DioPermissionsRepository(apiClient),
      scoringRepository: DioScoringRepository(apiClient),
      submissionsRepository: DioSubmissionsRepository(apiClient),
      usersRepository: DioUsersRepository(apiClient),
    );
  }
}
""".strip(),
        'app/app.dart': r"""
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/forms_repository.dart';
import '../data/repositories/public_forms_repository.dart';
import '../presentation/bloc/auth/auth_bloc.dart';
import 'dependencies.dart';
import 'router.dart';

class FeedbackFlowApp extends StatelessWidget {
  const FeedbackFlowApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: dependencies.authRepository),
        RepositoryProvider<FormsRepository>.value(value: dependencies.formsRepository),
        RepositoryProvider<PublicFormsRepository>.value(value: dependencies.publicFormsRepository),
      ],
      child: BlocProvider(
        create: (_) => AuthBloc(authRepository: dependencies.authRepository, tokenStore: dependencies.tokenStore)..add(const AuthEvent.started()),
        child: MaterialApp.router(
          title: 'FeedbackFlow',
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
          routerConfig: createRouter(dependencies),
        ),
      ),
    );
  }
}
""".strip(),
        'app/router.dart': r"""
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../presentation/bloc/form_detail/form_detail_bloc.dart';
import '../presentation/bloc/forms/forms_bloc.dart';
import '../presentation/bloc/public_form/public_form_bloc.dart';
import '../presentation/screens/form_detail_screen.dart';
import '../presentation/screens/forms_list_screen.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/public_form_screen.dart';
import '../presentation/screens/splash_screen.dart';
import 'dependencies.dart';

GoRouter createRouter(AppDependencies dependencies) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/forms',
        builder: (context, state) => BlocProvider(
          create: (_) => FormsBloc(dependencies.formsRepository)..add(const FormsEvent.loadRequested()),
          child: const FormsListScreen(),
        ),
      ),
      GoRoute(
        path: '/forms/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BlocProvider(
            create: (_) => FormDetailBloc(dependencies.formsRepository)..add(FormDetailEvent.loadRequested(formId: id)),
            child: FormDetailScreen(formId: id),
          );
        },
      ),
      GoRoute(
        path: '/public/:token',
        builder: (context, state) {
          final token = state.pathParameters['token']!;
          return BlocProvider(
            create: (_) => PublicFormBloc(dependencies.publicFormsRepository)..add(PublicFormEvent.loadRequested(publicToken: token)),
            child: PublicFormScreen(publicToken: token),
          );
        },
      ),
    ],
  );
}
""".strip(),
    }


def generate_screens() -> Dict[str, str]:
    return {
        'presentation/screens/splash_screen.dart': r"""
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth/auth_bloc.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        state.whenOrNull(
          authenticated: (_, __) => context.go('/forms'),
          unauthenticated: () => context.go('/login'),
          failure: (_, __) => context.go('/login'),
        );
      },
      child: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
""".strip(),
        'presentation/screens/login_screen.dart': r"""
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        state.whenOrNull(authenticated: (_, __) => context.go('/forms'));
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Sign in')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final loading = state is AuthLoading;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
                      const SizedBox(height: 12),
                      TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                      const SizedBox(height: 24),
                      if (state is AuthFailureState) Text(state.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: loading
                            ? null
                            : () => context.read<AuthBloc>().add(AuthEvent.loginRequested(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                )),
                        child: loading ? const CircularProgressIndicator() : const Text('Sign in'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
""".strip(),
        'presentation/screens/forms_list_screen.dart': r"""
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/forms/forms_bloc.dart';

class FormsListScreen extends StatelessWidget {
  const FormsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forms')),
      body: BlocBuilder<FormsBloc, FormsState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            failure: (message, _) => Center(child: Text(message)),
            loaded: (forms, pagination) => RefreshIndicator(
              onRefresh: () async => context.read<FormsBloc>().add(const FormsEvent.refreshRequested()),
              child: ListView.separated(
                itemCount: forms.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final form = forms[index];
                  return ListTile(
                    title: Text(form.title),
                    subtitle: Text('${form.status.toJson()} · ${form.submissionsCount} submissions'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/forms/${form.id}'),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
""".strip(),
        'presentation/screens/form_detail_screen.dart': r"""
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/form_detail/form_detail_bloc.dart';

class FormDetailScreen extends StatelessWidget {
  const FormDetailScreen({super.key, required this.formId});

  final String formId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form details')),
      body: BlocBuilder<FormDetailBloc, FormDetailState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            failure: (message, _) => Center(child: Text(message)),
            loaded: (form) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(form.title, style: Theme.of(context).textTheme.headlineSmall),
                if (form.description != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(form.description!)),
                const SizedBox(height: 16),
                Text('Status: ${form.status.toJson()}'),
                Text('Visibility: ${form.visibilityMode.toJson()}'),
                Text('Publish mode: ${form.publishMode.toJson()}'),
                const Divider(),
                for (final field in form.fields)
                  ListTile(
                    title: Text(field.label),
                    subtitle: Text(field.type.toJson()),
                    trailing: field.isRequired ? const Text('Required') : null,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
""".strip(),
        'presentation/screens/public_form_screen.dart': r"""
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/dto/dto.dart';
import '../bloc/public_form/public_form_bloc.dart';

class PublicFormScreen extends StatelessWidget {
  const PublicFormScreen({super.key, required this.publicToken});

  final String publicToken;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Public form')),
      body: BlocBuilder<PublicFormBloc, PublicFormState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            failure: (message, _) => Center(child: Text(message)),
            submitted: (response) => Center(child: Text(response.message)),
            loaded: (form, accessToken) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(form.title, style: Theme.of(context).textTheme.headlineSmall),
                if (form.description != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(form.description!)),
                const SizedBox(height: 16),
                for (final field in form.fields)
                  ListTile(title: Text(field.label), subtitle: Text(field.type.toJson())),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    context.read<PublicFormBloc>().add(
                          PublicFormEvent.submitRequested(
                            publicToken: publicToken,
                            request: PublicSubmissionRequest(
                              anonymous: true,
                              publicAccessToken: accessToken,
                              answers: const <AnswerInputDto>[],
                            ),
                          ),
                        );
                  },
                  child: const Text('Submit empty draft'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
""".strip(),
    }


def generate_pubspec() -> str:
    return r"""
name: feedbackflow_flutter_client
description: Flutter client generated against the FeedbackFlow OpenAPI contract.
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  dio: ^5.7.0
  flutter_bloc: ^8.1.6
  bloc: ^8.1.4
  drift: ^2.21.0
  drift_flutter: ^0.2.1
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  go_router: ^14.6.2
  flutter_secure_storage: ^9.2.2
  collection: ^1.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  drift_dev: ^2.21.0
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - tool/openapi.json
""".strip()


def generate_analysis_options() -> str:
    return r"""
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - '**/*.freezed.dart'
    - '**/*.g.dart'

linter:
  rules:
    always_use_package_imports: false
""".strip()


def generate_readme(openapi: Dict[str, Any], enums: Dict[str, List[str]]) -> str:
    ops = []
    for path, path_item in openapi['paths'].items():
        for method, op in path_item.items():
            if method.lower() in {'get','post','patch','delete','put'}:
                ops.append(f"- `{op['operationId']}` → `{method.upper()} {path}`")
    required_enums = ', '.join(sorted(enums.keys()))
    return f"""
# FeedbackFlow Flutter Client

This Flutter client is generated from `tool/openapi.json`, copied from the attached `openapi.json` contract. The OpenAPI contract remains the single source of truth for DTO names, enum wire values, endpoint paths, operation IDs, response envelopes, and authentication requirements.

## Stack

- Flutter/Dart
- Dio
- Bloc / flutter_bloc
- Drift
- freezed
- json_serializable
- go_router
- flutter_secure_storage

## Generate code

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Run with a backend base URL:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

## Contract notes

Single-resource responses parse through `ApiResponse<T>`. List responses parse through `ListResponse<T>` / `ApiListResponse<T>`. Error envelopes parse through `ApiErrorResponse` and expose `ApiError` with `ErrorCode`.

The contract marks several list pagination/filter parameters as `in: path` even though the endpoint paths do not contain corresponding placeholders. The generated client preserves the endpoint paths exactly and sends non-placeholder parameters as query parameters.

All enum values below include an `unknown` fallback in Dart. Existing wire values are emitted exactly as defined by OpenAPI:

{required_enums}

## Generated operation coverage

{chr(10).join(ops)}
""".strip()


def generate_contract_report(openapi: Dict[str, Any], enums: Dict[str, List[str]]) -> str:
    lines = ['# OpenAPI client contract report', '', f"Title: {openapi['info']['title']}", f"Version: {openapi['info']['version']}", '', '## Enums', '']
    for name in sorted(enums.keys()):
        lines.append(f'### {name}')
        lines.append('')
        for wire in enums[name]:
            lines.append(f'- `{wire}` → `{name}.{enum_member_name(wire)}`')
        lines.append('- unknown fallback → `.unknown`')
        lines.append('')
    lines.append('## Operations')
    lines.append('')
    for path, path_item in openapi['paths'].items():
        for method, op in path_item.items():
            if method.lower() in {'get','post','patch','delete','put'}:
                ref = success_response_ref(op) or 'unknown'
                lines.append(f"- `{op['operationId']}`: `{method.upper()} {path}` → `{ref}`")
    return '\n'.join(lines)


def main() -> None:
    openapi = load()
    schemas = openapi['components']['schemas']
    enums = collect_enums(schemas)
    ensure_clean()

    # Contract copy and generator copy.
    (ROOT / 'tool').mkdir(parents=True, exist_ok=True)
    shutil.copy2(OPENAPI, ROOT / 'tool/openapi.json')
    shutil.copy2(Path(__file__), ROOT / 'tool/generate_from_openapi.py')

    write('pubspec.yaml', generate_pubspec())
    write('analysis_options.yaml', generate_analysis_options())
    write('README.md', generate_readme(openapi, enums))
    write('CONTRACT_REPORT.md', generate_contract_report(openapi, enums))

    write('lib/data/dto/enums.dart', generate_enums(enums))
    write('lib/data/dto/models.dart', generate_models(schemas, enums))
    write('lib/data/dto/api_response.dart', generate_api_response())
    write('lib/data/dto/dto.dart', generate_dto_barrel())

    write('lib/data/api/api_exceptions.dart', generate_api_exceptions())
    write('lib/data/api/feedback_flow_api_client.dart', generate_api_client(openapi, enums))
    write('lib/core/security/token_store.dart', generate_token_store())
    write('lib/core/api/dio_factory.dart', generate_dio_factory())

    for fn, content in generate_repositories(openapi, enums).items():
        write(f'lib/data/repositories/{fn}', content)

    write('lib/domain/entities/entities.dart', generate_domain_entities())
    for fn, content in generate_mappers().items():
        write(f'lib/data/mappers/{fn}', content)
    write('lib/data/local/app_database.dart', generate_drift_db())

    write('lib/presentation/common/friendly_api_error_message.dart', generate_error_presenter())
    for fn, content in generate_blocs().items():
        write(f'lib/presentation/bloc/{fn}', content)
    for fn, content in generate_app_files().items():
        write(f'lib/{fn}', content)
    for fn, content in generate_screens().items():
        write(f'lib/{fn}', content)

    # Validation artifacts.
    manifest = []
    for p in sorted(ROOT.rglob('*')):
        if p.is_file():
            manifest.append(str(p.relative_to(ROOT)))
    write('MANIFEST.txt', '\n'.join(manifest))

    # Zip archive.
    zip_path = Path('/mnt/data/feedbackflow_flutter_client.zip')
    if zip_path.exists():
        zip_path.unlink()
    with zipfile.ZipFile(zip_path, 'w', compression=zipfile.ZIP_DEFLATED) as z:
        for p in ROOT.rglob('*'):
            if p.is_file():
                z.write(p, p.relative_to(ROOT.parent))
    print(f'Generated {ROOT}')
    print(f'Generated {zip_path}')
    print(f'{len(manifest)} files')
    print(f'{len(enums)} enums, {len(schemas)} schemas, {sum(1 for _ in openapi["paths"])} paths')

if __name__ == '__main__':
    main()
