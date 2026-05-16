import '../../data/dto/dto.dart';

class ApiException implements Exception {
  ApiException({
    required this.error,
    this.statusCode,
    this.responseData,
  });

  final ApiError error;
  final int? statusCode;
  final Object? responseData;

  bool get isExpiredToken => error.code == ErrorCode.tokenExpired;

  bool get isPermissionDenied =>
      error.code == ErrorCode.forbidden || error.code == ErrorCode.permissionDenied;

  bool get isValidationError => error.code == ErrorCode.validationError;
  bool get isRateLimited => error.code == ErrorCode.rateLimited;

  bool get isPublicFormClosed =>
      error.code == ErrorCode.formClosed || error.code == ErrorCode.formNotPublished;

  @override
  String toString() => 'ApiException(${error.code.toJson()}, ${error.message})';
}
