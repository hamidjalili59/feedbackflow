import 'package:flutter/material.dart';

import '../../data/api/api_exceptions.dart';
import '../../data/dto/dto.dart';
import '../../l10n/app_localizations.dart';

class FriendlyApiErrorMessage {
  const FriendlyApiErrorMessage._();

  static String from(Object error, {BuildContext? context}) =>
      describe(error, context: context).message;

  static ErrorCode? errorCodeOf(Object error) =>
      ApiFailure.tryRead(error)?.code;

  static UserFacingError describe(Object error, {BuildContext? context}) {
    final l10n = context?.l10n;
    final failure = ApiFailure.tryRead(error);
    if (failure == null) {
      return UserFacingError(
        title: l10n?.t('somethingWentWrong') ?? 'Something went wrong',
        message:
            l10n?.t('genericErrorMessage') ??
            'Please try again. If this keeps happening, contact support.',
        icon: Icons.error_outline_rounded,
        canRetry: true,
      );
    }

    switch (failure.code) {
      case ErrorCode.validationError:
        return UserFacingError(
          title: l10n?.t('fieldRequired') ?? 'Please check the form',
          message:
              l10n?.t('validationErrorMessage') ??
              'Some fields need your attention.',
          icon: Icons.rule_rounded,
          canRetry: false,
        );
      case ErrorCode.unauthorized:
      case ErrorCode.invalidToken:
      case ErrorCode.tokenExpired:
        return UserFacingError(
          title: l10n?.t('sessionExpired') ?? 'Session expired',
          message:
              l10n?.t('sessionExpiredMessage') ??
              'Please sign in again to continue.',
          icon: Icons.lock_clock_rounded,
          canRetry: false,
          shouldSignIn: true,
        );
      case ErrorCode.forbidden:
      case ErrorCode.permissionDenied:
        return UserFacingError(
          title: l10n?.t('permissionTitle') ?? 'You do not have access',
          message:
              l10n?.t('permissionMessage') ??
              'You do not have permission to view or change this resource.',
          icon: Icons.no_accounts_rounded,
          canRetry: false,
          shouldGoBack: true,
        );
      case ErrorCode.rateLimited:
        return UserFacingError(
          title: l10n?.t('rateLimited') ?? 'Too many requests',
          message:
              l10n?.t('rateLimitedMessage') ??
              'Please wait a moment and try again.',
          icon: Icons.hourglass_top_rounded,
          canRetry: true,
        );
      case ErrorCode.formClosed:
        return UserFacingError(
          title: l10n?.t('formClosed') ?? 'Form closed',
          message:
              l10n?.t('formClosedMessage') ??
              'This form is no longer accepting submissions.',
          icon: Icons.lock_outline_rounded,
          canRetry: false,
          shouldGoBack: true,
        );
      case ErrorCode.formNotPublished:
        return UserFacingError(
          title: l10n?.t('formUnavailable') ?? 'Form unavailable',
          message:
              l10n?.t('formUnavailableMessage') ??
              'This form is not published yet.',
          icon: Icons.visibility_off_rounded,
          canRetry: false,
          shouldGoBack: true,
        );
      case ErrorCode.publicAccessDenied:
      case ErrorCode.publicProtectionRequired:
        return UserFacingError(
          title: l10n?.t('protectedPublicForm') ?? 'Access validation required',
          message:
              l10n?.t('validatePublicFirst') ??
              'Validate public access before submitting this protected form.',
          icon: Icons.verified_user_outlined,
          canRetry: false,
        );
      case ErrorCode.notFound:
        return UserFacingError(
          title: l10n?.t('notFound') ?? 'Not found',
          message:
              l10n?.t('notFoundMessage') ??
              'The requested resource could not be found.',
          icon: Icons.search_off_rounded,
          canRetry: false,
          shouldGoBack: true,
        );
      case ErrorCode.conflict:
      case ErrorCode.approvalRequired:
        return UserFacingError(
          title: l10n?.t('actionBlocked') ?? 'Action blocked',
          message:
              l10n?.t('actionBlockedMessage') ??
              'This action is not allowed in the current state.',
          icon: Icons.block_rounded,
          canRetry: false,
        );
      case ErrorCode.serviceUnavailable:
        if (failure.kind == ApiFailureKind.timeout) {
          return UserFacingError(
            title: l10n?.t('requestTimedOut') ?? 'Request timed out',
            message:
                l10n?.t('requestTimedOutMessage') ??
                'The server took too long to respond. Please try again.',
            icon: Icons.timer_off_rounded,
            canRetry: true,
          );
        }
        if (failure.kind == ApiFailureKind.network) {
          return UserFacingError(
            title: l10n?.t('connectionProblem') ?? 'Connection problem',
            message:
                l10n?.t('connectionProblemMessage') ??
                'Could not reach the server. Check your connection and try again.',
            icon: Icons.wifi_off_rounded,
            canRetry: true,
          );
        }
        return UserFacingError(
          title: l10n?.t('serviceUnavailable') ?? 'Service unavailable',
          message:
              l10n?.t('serviceUnavailableMessage') ??
              'The server is unavailable right now. Please try again.',
          icon: Icons.cloud_off_rounded,
          canRetry: true,
        );
      case ErrorCode.internalServerError:
      case ErrorCode.unknown:
        return UserFacingError(
          title: l10n?.t('serverError') ?? 'Server error',
          message:
              l10n?.t('serverErrorMessage') ??
              'The server could not complete the request.',
          icon: Icons.cloud_off_rounded,
          canRetry: true,
        );
    }
  }
}

class UserFacingError {
  const UserFacingError({
    required this.title,
    required this.message,
    required this.icon,
    required this.canRetry,
    this.shouldSignIn = false,
    this.shouldGoBack = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final bool canRetry;
  final bool shouldSignIn;
  final bool shouldGoBack;
}
