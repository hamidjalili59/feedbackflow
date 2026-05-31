import '../../data/api/api_exceptions.dart';
import '../../data/dto/dto.dart';
import 'api_exception.dart';

class ApiFailureMessage {
  const ApiFailureMessage({required this.title, required this.message});

  final String title;
  final String message;
}

class ApiFailureMapper {
  const ApiFailureMapper();

  ApiFailureMessage map(Object error) {
    final failure = ApiFailure.tryRead(error);
    if (failure != null) {
      return _fromCode(failure.code, failure.message);
    }
    if (error is ApiException) {
      return _fromCode(error.error.code, error.error.message);
    }
    return const ApiFailureMessage(
      title: 'Something went wrong',
      message: 'Please try again.',
    );
  }

  ApiFailureMessage _fromCode(ErrorCode code, String message) {
    switch (code) {
      case ErrorCode.validationError:
        return ApiFailureMessage(title: 'Validation error', message: message);
      case ErrorCode.tokenExpired:
      case ErrorCode.invalidToken:
      case ErrorCode.unauthorized:
        return const ApiFailureMessage(
          title: 'Session expired',
          message: 'Please sign in again.',
        );
      case ErrorCode.forbidden:
      case ErrorCode.permissionDenied:
        return ApiFailureMessage(title: 'Permission denied', message: message);
      case ErrorCode.rateLimited:
        return ApiFailureMessage(title: 'Too many requests', message: message);
      case ErrorCode.formClosed:
      case ErrorCode.formNotPublished:
        return ApiFailureMessage(title: 'Form unavailable', message: message);
      case ErrorCode.publicAccessDenied:
      case ErrorCode.publicProtectionRequired:
        return ApiFailureMessage(
          title: 'Public access required',
          message: message,
        );
      case ErrorCode.notFound:
        return ApiFailureMessage(title: 'Not found', message: message);
      case ErrorCode.conflict:
      case ErrorCode.approvalRequired:
        return ApiFailureMessage(title: 'Action blocked', message: message);
      case ErrorCode.serviceUnavailable:
      case ErrorCode.internalServerError:
      case ErrorCode.unknown:
        return ApiFailureMessage(title: 'Server error', message: message);
    }
  }
}
