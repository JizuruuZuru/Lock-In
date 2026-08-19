/// Shared REST plumbing for the command-line tools in `tool/`.
///
/// These scripts run under plain `dart run`, not `flutter run`, so they cannot
/// import anything from `lib/` that touches `dart:ui` — which rules out
/// `firebase_options.dart` and the Firebase plugins. Instead the project id and
/// API key are read straight out of the repo's own config files at start-up, so
/// there is still exactly one source of truth for them.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const String firestoreHost = 'firestore.googleapis.com';
const String identityHost = 'identitytoolkit.googleapis.com';

/// Project settings discovered from the repo rather than hard-coded.
class ProjectConfig {
  final String projectId;
  final String apiKey;

  const ProjectConfig({required this.projectId, required this.apiKey});

  String get documentsPath =>
      '/v1/projects/$projectId/databases/(default)/documents';

  String get documentsBaseUrl => 'https://$firestoreHost$documentsPath';

  /// Reads `firebase.json` for the project id and `lib/utils/firebase_options.dart`
  /// for a web API key. Either can be overridden from the command line.
  static ProjectConfig discover({String? projectId, String? apiKey}) {
    var resolvedProject = projectId;
    var resolvedKey = apiKey;

    if (resolvedProject == null) {
      final file = File('firebase.json');
      if (file.existsSync()) {
        final match =
            RegExp(r'"projectId"\s*:\s*"([^"]+)"').firstMatch(file.readAsStringSync());
        resolvedProject = match?.group(1);
      }
    }

    if (resolvedKey == null) {
      final file = File('lib/utils/firebase_options.dart');
      if (file.existsSync()) {
        final match =
            RegExp(r"apiKey:\s*'([^']+)'").firstMatch(file.readAsStringSync());
        resolvedKey = match?.group(1);
      }
    }

    if (resolvedProject == null || resolvedKey == null) {
      throw StateError(
        'Could not work out the Firebase project id or API key.\n'
        'Run this from the repository root, or pass --project and --api-key.',
      );
    }

    return ProjectConfig(projectId: resolvedProject, apiKey: resolvedKey);
  }
}

/// The login email the app builds from a player's name, mirroring
/// `lib/utils/name_credential.dart` so a seeded account can actually sign in.
String buildLoginEmail({required String firstName, required String lastName}) {
  String normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
      .replaceAll(RegExp(r'\.+'), '.')
      .replaceAll(RegExp(r'^\.|\.$'), '');

  final first = normalize(firstName);
  final last = normalize(lastName);
  final loginId = first.isEmpty && last.isEmpty
      ? 'player'
      : first.isEmpty
          ? last
          : last.isEmpty
              ? first
              : '$first.$last';
  return '$loginId@lockinplayers.app';
}

String buildLoginId({required String firstName, required String lastName}) {
  return buildLoginEmail(firstName: firstName, lastName: lastName).split('@').first;
}

/// One HTTP exchange, recorded so the caller can print it verbatim.
class CallLog {
  final String label;
  final String method;
  final String url;
  final String requestBody;
  final String responseBody;
  final int statusCode;
  final Duration elapsed;
  final String? error;

  const CallLog({
    required this.label,
    required this.method,
    required this.url,
    this.requestBody = '',
    this.responseBody = '',
    this.statusCode = 0,
    this.elapsed = Duration.zero,
    this.error,
  });

  bool get ok => error == null && statusCode >= 200 && statusCode < 300;
}

/// Pretty-prints JSON, falling back to the raw text when it will not parse —
/// a body that cannot be decoded is exactly the one worth seeing verbatim.
String prettyJson(String body) {
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
  } catch (_) {
    return body;
  }
}

/// Truncates a long body so a log stays readable. Full bodies are still written
/// to the log file; this is only for the terminal.
String clip(String text, {int maxLines = 24}) {
  final lines = text.split('\n');
  if (lines.length <= maxLines) return text;
  return '${lines.take(maxLines).join('\n')}\n  ... (${lines.length - maxLines} more lines)';
}

/// Signs in with the app's own name-based credential and returns an ID token.
///
/// Uses the Firebase Auth REST API directly, which is the same credential check
/// the app performs — so a token from here carries exactly the permissions the
/// security rules grant that person, admin included.
Future<String> signIn({
  required http.Client client,
  required ProjectConfig config,
  required String email,
  required String password,
}) async {
  final uri = Uri.https(identityHost, '/v1/accounts:signInWithPassword', {
    'key': config.apiKey,
  });

  final response = await client.post(
    uri,
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
      'returnSecureToken': true,
    }),
  );

  final json = jsonDecode(response.body);
  if (response.statusCode != 200) {
    final message = json is Map && json['error'] is Map
        ? json['error']['message']
        : response.body;
    throw StateError('Sign-in failed for $email: $message');
  }
  return (json as Map<String, dynamic>)['idToken'].toString();
}

/// Creates an auth credential and returns its uid. Signs the caller back out of
/// nothing — the REST API is stateless, so no session is left behind.
Future<String> signUp({
  required http.Client client,
  required ProjectConfig config,
  required String email,
  required String password,
}) async {
  final uri = Uri.https(identityHost, '/v1/accounts:signUp', {'key': config.apiKey});

  final response = await client.post(
    uri,
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
      'returnSecureToken': true,
    }),
  );

  final json = jsonDecode(response.body);
  if (response.statusCode != 200) {
    final message = json is Map && json['error'] is Map
        ? json['error']['message']
        : response.body;
    throw StateError('Could not create $email: $message');
  }
  return (json as Map<String, dynamic>)['localId'].toString();
}

/// Wraps a plain Dart value in the typed envelope Firestore's REST API needs.
Map<String, dynamic> restValue(dynamic value) {
  if (value == null) return {'nullValue': null};
  if (value is bool) return {'booleanValue': value};
  if (value is int) return {'integerValue': value.toString()};
  if (value is double) return {'doubleValue': value};
  if (value is DateTime) {
    return {'timestampValue': value.toUtc().toIso8601String()};
  }
  if (value is List) {
    return {
      'arrayValue': {'values': value.map(restValue).toList(growable: false)}
    };
  }
  if (value is Map) {
    return {
      'mapValue': {
        'fields': value.map((key, item) => MapEntry(key.toString(), restValue(item)))
      }
    };
  }
  return {'stringValue': value.toString()};
}

Map<String, dynamic> restFields(Map<String, dynamic> data) {
  return data.map((key, value) => MapEntry(key, restValue(value)));
}

/// Parses `--flag value` and `--flag=value` into a map. Deliberately small —
/// these are internal tools, not a public CLI.
Map<String, String> parseArgs(List<String> args) {
  final parsed = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) continue;

    final name = arg.substring(2);
    if (name.contains('=')) {
      final index = name.indexOf('=');
      parsed[name.substring(0, index)] = name.substring(index + 1);
    } else if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
      parsed[name] = args[i + 1];
      i++;
    } else {
      parsed[name] = 'true';
    }
  }
  return parsed;
}

/// Prompts on the terminal when a required value was not passed as a flag.
String promptFor(String label, {bool secret = false}) {
  stdout.write('$label: ');
  if (secret) stdin.echoMode = false;
  final value = stdin.readLineSync() ?? '';
  if (secret) {
    stdin.echoMode = true;
    stdout.writeln();
  }
  return value.trim();
}
