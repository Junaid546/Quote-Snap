import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

// ─── AppError Sealed Hierarchy ────────────────────────────────────────────────

sealed class AppError {
  const AppError();
}

class NetworkError extends AppError {
  final String message;
  final int? statusCode;
  const NetworkError({required this.message, this.statusCode});
}

class DatabaseError extends AppError {
  final String message;
  final Object? cause;
  const DatabaseError({required this.message, this.cause});
}

class AuthError extends AppError {
  final String message;
  final String? code;
  const AuthError({required this.message, this.code});
}

class ValidationError extends AppError {
  final Map<String, String> fieldErrors;
  const ValidationError(this.fieldErrors);
}

class UnknownError extends AppError {
  final String message;
  const UnknownError(this.message);
}

// ─── Extensions ────────────────────────────────────────────────────────────────

extension AppErrorX on AppError {
  String get userFriendlyMessage {
    switch (this) {
      case NetworkError e:
        if (e.statusCode == 401 || e.statusCode == 403) {
          return 'Authentication failed. Please sign in again.';
        }
        if (e.statusCode != null && e.statusCode! >= 500) {
          return 'Server is temporarily unavailable. Please try again later.';
        }
        return 'No internet connection. Please check your connection and try again.';

      case DatabaseError():
        return 'Something went wrong saving your data. Please try again.';

      case AuthError e:
        switch (e.code) {
          case 'user-not-found':
            return 'No account found with this email address.';
          case 'wrong-password':
            return 'Incorrect password. Please try again.';
          case 'email-already-in-use':
            return 'This email is already registered.';
          case 'network-request-failed':
            return 'Network error. Please check your connection.';
          case 'too-many-requests':
            return 'Too many failed attempts. Please wait a moment.';
          default:
            return e.message;
        }

      case ValidationError e:
        return e.fieldErrors.values.first;

      case UnknownError e:
        return e.message.isNotEmpty
            ? e.message
            : 'Something went wrong. Please try again.';
    }
  }

  bool get isRetryable {
    return switch (this) {
      NetworkError() => true,
      DatabaseError() => true,
      AuthError() => false,
      ValidationError() => false,
      UnknownError() => false,
    };
  }

  String get logMessage {
    switch (this) {
      case NetworkError e:
        return 'NetworkError(${e.statusCode}): ${e.message}';
      case DatabaseError e:
        return 'DatabaseError: ${e.message} | cause: ${e.cause}';
      case AuthError e:
        return 'AuthError(${e.code}): ${e.message}';
      case ValidationError e:
        return 'ValidationError: ${e.fieldErrors}';
      case UnknownError e:
        return 'UnknownError: ${e.message}';
    }
  }
}

// ─── Error Mapping Helpers ────────────────────────────────────────────────────

/// Maps any exception to an [AppError].
AppError mapError(Object error, [StackTrace? stack]) {
  if (error is AppError) return error;

  if (error is FirebaseAuthException) {
    return AuthError(message: error.message ?? error.code, code: error.code);
  }

  if (error is PlatformException) {
    return DatabaseError(
      message: error.message ?? 'Database error',
      cause: error,
    );
  }

  if (error is TimeoutException) {
    return const NetworkError(message: 'Request timed out');
  }

  if (error is Exception) {
    final msg = error.toString().replaceFirst('Exception: ', '');
    if (msg.toLowerCase().contains('network') ||
        msg.toLowerCase().contains('socket')) {
      return NetworkError(message: msg);
    }
    if (msg.toLowerCase().contains('database') ||
        msg.toLowerCase().contains('sql')) {
      return DatabaseError(message: msg, cause: error);
    }
    return UnknownError(msg);
  }

  return UnknownError(error.toString());
}
