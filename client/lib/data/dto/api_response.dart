// Hand-written shared envelopes matching the generated OpenAPI envelope shapes.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'models.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

@freezed
abstract class ApiError with _$ApiError {
  const factory ApiError({
    @ErrorCodeJsonConverter() @JsonKey(name: 'code') required ErrorCode code,
    @JsonKey(name: 'message') required String message,
    @JsonKey(name: 'details') Object? details,
  }) = _ApiError;

  factory ApiError.fromJson(Map<String, dynamic> json) => _$ApiErrorFromJson(json);
}

typedef ApiErrorDto = ApiError;

@Freezed(genericArgumentFactories: true)
abstract class ApiResponse<T> with _$ApiResponse<T> {
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
abstract class ListResponse<T> with _$ListResponse<T> {
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
abstract class ApiErrorResponse with _$ApiErrorResponse {
  const factory ApiErrorResponse({
    @JsonKey(name: 'success') required bool success,
    @JsonKey(name: 'data') Object? data,
    @JsonKey(name: 'error') required ApiError error,
    @Default(<String, Object?>{}) @JsonKey(name: 'meta') Map<String, Object?> meta,
  }) = _ApiErrorResponse;

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) => _$ApiErrorResponseFromJson(json);
}
