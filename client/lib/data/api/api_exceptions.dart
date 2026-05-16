import 'package:dio/dio.dart';

import '../dto/dto.dart';

class ApiFailure implements Exception {
  const ApiFailure({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
    this.kind = ApiFailureKind.api,
  });

  final ErrorCode code;
  final String message;
  final Object? details;
  final int? statusCode;
  final ApiFailureKind kind;

  factory ApiFailure.fromError(ApiError? error, {int? statusCode}) {
    if (error == null) {
      return ApiFailure(
        code: _codeFromStatus(statusCode),
        message: _messageFromStatus(statusCode),
        statusCode: statusCode,
      );
    }
    return ApiFailure(
      code: error.code,
      message: error.message,
      details: error.details,
      statusCode: statusCode,
    );
  }

  factory ApiFailure.fromEnvelope(Map<String, dynamic> json, {int? statusCode}) {
    final errorRaw = json['error'];
    if (errorRaw is Map) {
      return ApiFailure.fromError(
        ApiError.fromJson(Map<String, dynamic>.from(errorRaw)),
        statusCode: statusCode,
      );
    }

    return ApiFailure(
      code: _codeFromStatus(statusCode),
      message: _messageFromStatus(statusCode),
      details: json,
      statusCode: statusCode,
    );
  }

  factory ApiFailure.network({String? message}) {
    return const ApiFailure(
      code: ErrorCode.serviceUnavailable,
      message: '',
      kind: ApiFailureKind.network,
    );
  }

  factory ApiFailure.timeout() {
    return const ApiFailure(
      code: ErrorCode.serviceUnavailable,
      message: '',
      kind: ApiFailureKind.timeout,
    );
  }

  factory ApiFailure.cancelled() {
    return const ApiFailure(
      code: ErrorCode.serviceUnavailable,
      message: '',
      kind: ApiFailureKind.cancelled,
    );
  }

  factory ApiFailure.unexpected(Object error, {int? statusCode}) {
    return ApiFailure(
      code: _codeFromStatus(statusCode),
      message: error.toString().isEmpty ? _messageFromStatus(statusCode) : error.toString(),
      details: error,
      statusCode: statusCode,
      kind: ApiFailureKind.unexpected,
    );
  }

  static ApiFailure? tryRead(Object? error) {
    if (error is ApiFailure) return error;
    if (error is DioException) {
      final inner = error.error;
      if (inner is ApiFailure) return inner;
      final data = error.response?.data;
      if (data is Map) {
        return ApiFailure.fromEnvelope(
          Map<String, dynamic>.from(data),
          statusCode: error.response?.statusCode,
        );
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiFailure.timeout();
        case DioExceptionType.connectionError:
          return ApiFailure.network(message: error.message);
        case DioExceptionType.cancel:
          return ApiFailure.cancelled();
        case DioExceptionType.badCertificate:
        case DioExceptionType.badResponse:
        case DioExceptionType.unknown:
          return ApiFailure.unexpected(
            error.message ?? error,
            statusCode: error.response?.statusCode,
          );
      }
    }
    return null;
  }

  bool get isAuthFailure => code == ErrorCode.unauthorized || code == ErrorCode.invalidToken || code == ErrorCode.tokenExpired;
  bool get isPermissionFailure => code == ErrorCode.forbidden || code == ErrorCode.permissionDenied;
  bool get isValidationFailure => code == ErrorCode.validationError;
  bool get isRateLimited => code == ErrorCode.rateLimited;
  bool get isPublicFormClosed => code == ErrorCode.formClosed;
  bool get isFormUnavailable => code == ErrorCode.formClosed || code == ErrorCode.formNotPublished;
  bool get isRetryable => kind == ApiFailureKind.network || kind == ApiFailureKind.timeout || code == ErrorCode.serviceUnavailable || code == ErrorCode.internalServerError || code == ErrorCode.rateLimited;

  @override
  String toString() => 'ApiFailure(code: ${code.toJson()}, message: $message, statusCode: $statusCode)';
}

enum ApiFailureKind { api, network, timeout, cancelled, unexpected }

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

ErrorCode _codeFromStatus(int? statusCode) {
  switch (statusCode) {
    case 400:
      return ErrorCode.validationError;
    case 401:
      return ErrorCode.unauthorized;
    case 403:
      return ErrorCode.permissionDenied;
    case 404:
      return ErrorCode.notFound;
    case 409:
      return ErrorCode.conflict;
    case 429:
      return ErrorCode.rateLimited;
    case 503:
      return ErrorCode.serviceUnavailable;
    default:
      return ErrorCode.internalServerError;
  }
}

String _messageFromStatus(int? statusCode) {
  switch (statusCode) {
    case 400:
      return 'The request was not valid.';
    case 401:
      return 'Your session has expired. Please sign in again.';
    case 403:
      return 'You do not have permission to access this resource.';
    case 404:
      return 'The requested resource was not found.';
    case 409:
      return 'This action conflicts with the current state.';
    case 429:
      return 'Too many requests. Please try again later.';
    case 503:
      return 'The service is temporarily unavailable.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
