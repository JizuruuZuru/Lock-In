import 'dart:io';

import 'package:http/http.dart' as http;

/// A network/API failure that already carries a message safe to show a child.
///
/// Every API service in `lib/services/api/` funnels its failures through this
/// type so the UI only ever has one error shape to render.
class ApiException implements Exception {
  /// Short, kid-friendly explanation shown in the UI.
  final String message;

  /// HTTP status when the failure came back from the server, else null.
  final int? statusCode;

  /// Raw detail kept for the debug panel — never shown as the primary message.
  final String? detail;

  const ApiException(this.message, {this.statusCode, this.detail});

  /// Turns a low-level exception into a message a user can act on.
  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    // On the web `dart:io` is a stub that is never thrown from: the browser
    // client reports every transport failure as a ClientException instead, so
    // it is checked first or a web user would only ever see the generic
    // fallback message below.
    if (error is http.ClientException) {
      return const ApiException(
        'No internet connection. Check your Wi-Fi and try again.',
      );
    }
    if (error is SocketException) {
      return const ApiException(
        'No internet connection. Check your Wi-Fi and try again.',
      );
    }
    if (error is HttpException) {
      return ApiException(
        'The server could not be reached. Try again in a moment.',
        detail: error.message,
      );
    }
    if (error is FormatException) {
      return ApiException(
        'The server sent data we could not read.',
        detail: error.message,
      );
    }
    return ApiException(
      'Something went wrong while contacting the server.',
      detail: error.toString(),
    );
  }

  /// Maps an HTTP status code to a readable message.
  factory ApiException.fromStatus(int statusCode, {String? body}) {
    final message = switch (statusCode) {
      400 => 'The request was not accepted by the server.',
      401 || 403 => 'You are not allowed to do that. Try signing in again.',
      404 => 'We could not find what you asked for.',
      429 => 'Too many requests too quickly. Wait a few seconds and retry.',
      >= 500 => 'The server is having trouble right now. Try again later.',
      _ => 'Request failed (HTTP $statusCode).',
    };
    return ApiException(message, statusCode: statusCode, detail: body);
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
