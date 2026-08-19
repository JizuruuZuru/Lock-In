/// Live API smoke test — proof, on the record, that every HTTP verb works.
///
/// Runs every request the app makes against the real services and prints the
/// exact URL, request body, status code, and response for each one, then writes
/// the whole transcript to a file that can be attached as submission evidence.
///
/// ```bash
/// dart run tool/api_smoke_test.dart --email ana.cruz@lockinplayers.app --password teacher123
/// ```
///
/// Flags:
///   --email / --password   an **admin** account; the security rules only let
///                          an admin write to `quiz_questions`. Prompted for
///                          when omitted.
///   --out `<path>`         where to write the transcript
///                          (default `docs/evidence/api-test-log.txt`)
///   --public-only          skip everything that needs a sign-in, so the two
///                          key-less GET endpoints can still be demonstrated
///   --project / --api-key  override the values read from the repo config
///
/// The write half operates on one throwaway document: create it (POST), edit it
/// (PATCH), search for it (POST runQuery), then delete it (DELETE). Nothing is
/// left behind in the question bank, and the probe is written unpublished so it
/// can never reach a student even if the run aborts halfway.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'lock_in_rest.dart';

Future<void> main(List<String> args) async {
  final options = parseArgs(args);
  final publicOnly = options['public-only'] == 'true';
  final outPath = options['out'] ?? 'docs/evidence/api-test-log.txt';

  final ProjectConfig config;
  try {
    config = ProjectConfig.discover(
      projectId: options['project'],
      apiKey: options['api-key'],
    );
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exitCode = 2;
    return;
  }

  final client = http.Client();
  final logs = <CallLog>[];
  final started = DateTime.now();

  stdout
    ..writeln('Lock In - live API smoke test')
    ..writeln('Project : ${config.projectId}')
    ..writeln('Started : $started')
    ..writeln('=' * 72);

  try {
    // ------------------------------------------------------------------ GET
    logs.add(await _call(
      client,
      label: 'GET trivia questions from Open Trivia DB',
      method: 'GET',
      uri: Uri.https('opentdb.com', '/api.php', {
        'amount': '2',
        'difficulty': 'easy',
        'type': 'multiple',
        'encode': 'url3986',
      }),
    ));

    logs.add(await _call(
      client,
      label: 'GET a word from the Free Dictionary API',
      method: 'GET',
      uri: Uri.https('api.dictionaryapi.dev', '/api/v2/entries/en/planet'),
    ));

    logs.add(await _call(
      client,
      label: 'GET a word that does not exist (expected 404)',
      method: 'GET',
      uri: Uri.https('api.dictionaryapi.dev', '/api/v2/entries/en/zzzqqxx'),
      expectFailure: true,
    ));

    if (publicOnly) {
      stdout.writeln('\n--public-only: skipping the authenticated half.');
    } else {
      // --------------------------------------------------------------- AUTH
      final email = options['email'] ?? promptFor('Admin login email');
      final password = options['password'] ?? promptFor('Password', secret: true);

      stdout.writeln('\nSigning in as $email ...');
      final token = await signIn(
        client: client,
        config: config,
        email: email,
        password: password,
      );
      stdout.writeln('Got an ID token (${token.length} chars). '
          'Every call below carries it as a bearer credential.\n');

      final authHeaders = <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // --------------------------------------------------------------- POST
      final probeFields = restFields(<String, dynamic>{
        'subject': 'science',
        'topic': 'API Smoke Test',
        'instruction': 'Temporary record written by tool/api_smoke_test.dart.',
        'prompt': 'Smoke test - which planet is largest in our solar system?',
        'correctAnswer': 'Jupiter',
        'choices': ['Mars', 'Venus', 'Earth'],
        'minLevel': 1,
        'source': 'openTrivia',
        'published': false,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });

      final createLog = await _call(
        client,
        label: 'POST create a question document',
        method: 'POST',
        uri: Uri.https(firestoreHost, '${config.documentsPath}/quiz_questions'),
        headers: authHeaders,
        body: jsonEncode({'fields': probeFields}),
      );
      logs.add(createLog);

      final probeId = _documentIdFrom(createLog.responseBody);
      if (probeId == null) {
        stdout.writeln('No document id came back, so the PATCH and DELETE steps '
            'have nothing to act on. Stopping here.');
      } else {
        stdout.writeln('Probe document id: $probeId\n');

        // ------------------------------------------------------------ PATCH
        final patchFields = restFields(<String, dynamic>{
          'prompt': 'Smoke test - edited at ${DateTime.now().toIso8601String()}',
          'minLevel': 3,
          'updatedAt': DateTime.now(),
        });

        logs.add(await _call(
          client,
          label: 'PATCH update the question (partial, with an update mask)',
          method: 'PATCH',
          uri: Uri.https(
            firestoreHost,
            '${config.documentsPath}/quiz_questions/$probeId',
            {'updateMask.fieldPaths': patchFields.keys.toList(growable: false)},
          ),
          headers: authHeaders,
          body: jsonEncode({'fields': patchFields}),
        ));

        // ------------------------------------------------- POST (search read)
        logs.add(await _call(
          client,
          label: 'POST runQuery - search questions by subject',
          method: 'POST',
          uri: Uri.https(firestoreHost, '${config.documentsPath}:runQuery'),
          headers: authHeaders,
          body: jsonEncode({
            'structuredQuery': {
              'from': [
                {'collectionId': 'quiz_questions'}
              ],
              'where': {
                'fieldFilter': {
                  'field': {'fieldPath': 'subject'},
                  'op': 'EQUAL',
                  'value': {'stringValue': 'science'},
                }
              },
              'limit': 3,
            }
          }),
        ));

        // ----------------------------------------------------------- DELETE
        logs.add(await _call(
          client,
          label: 'DELETE the question (probe cleaned up)',
          method: 'DELETE',
          uri: Uri.https(
            firestoreHost,
            '${config.documentsPath}/quiz_questions/$probeId',
          ),
          headers: authHeaders,
        ));

        logs.add(await _call(
          client,
          label: 'DELETE the same document again (expected 404)',
          method: 'DELETE',
          uri: Uri.https(
            firestoreHost,
            '${config.documentsPath}/quiz_questions/$probeId',
          ),
          headers: authHeaders,
          expectFailure: true,
        ));
      }

      // ------------------------------------------- unauthenticated (expected)
      logs.add(await _call(
        client,
        label: 'POST with no credential (expected 401/403)',
        method: 'POST',
        uri: Uri.https(firestoreHost, '${config.documentsPath}/quiz_questions'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': restFields(<String, dynamic>{'topic': 'nope'})}),
        expectFailure: true,
      ));
    }
  } catch (error) {
    stderr.writeln('\nRun stopped: $error');
    exitCode = 1;
  } finally {
    client.close();
  }

  _writeTranscript(outPath, config, started, logs);

  final passed = logs.where((log) => log.ok).length;
  final failed = logs.length - passed;

  stdout
    ..writeln('=' * 72)
    ..writeln('${logs.length} calls - $passed succeeded, $failed returned an error')
    ..writeln('(Steps labelled "expected" are supposed to fail; they prove the '
        'error paths work.)')
    ..writeln('Transcript written to $outPath');
}

/// Performs one request, prints it, and records it.
Future<CallLog> _call(
  http.Client client, {
  required String label,
  required String method,
  required Uri uri,
  Map<String, String> headers = const {'Accept': 'application/json'},
  String? body,
  bool expectFailure = false,
}) async {
  stdout
    ..writeln()
    ..writeln('[$method] $label')
    ..writeln('  URL      : $uri');

  final sentHeaders = <String, String>{
    ...headers,
    if (body != null) 'Content-Type': 'application/json',
  };

  final watch = Stopwatch()..start();
  try {
    final response = await switch (method) {
      'GET' => client.get(uri, headers: sentHeaders),
      'POST' => client.post(uri, headers: sentHeaders, body: body),
      'PATCH' => client.patch(uri, headers: sentHeaders, body: body),
      'DELETE' => client.delete(uri, headers: sentHeaders),
      _ => throw ArgumentError('Unsupported method $method'),
    }
        .timeout(const Duration(seconds: 25));
    watch.stop();

    final pretty = prettyJson(response.body);
    final ok = response.statusCode >= 200 && response.statusCode < 300;

    stdout.writeln('  Status   : ${response.statusCode} '
        '${ok ? "OK" : (expectFailure ? "(expected failure)" : "FAILED")} '
        '- ${watch.elapsedMilliseconds} ms');
    if (body != null) {
      stdout.writeln('  Request  :\n${_indent(clip(prettyJson(body)))}');
    }
    stdout.writeln('  Response :\n${_indent(clip(pretty))}');

    return CallLog(
      label: label,
      method: method,
      url: uri.toString(),
      requestBody: body == null ? '' : prettyJson(body),
      responseBody: pretty,
      statusCode: response.statusCode,
      elapsed: watch.elapsed,
    );
  } catch (error) {
    watch.stop();
    stdout.writeln('  Status   : no response - $error');
    return CallLog(
      label: label,
      method: method,
      url: uri.toString(),
      requestBody: body == null ? '' : prettyJson(body),
      elapsed: watch.elapsed,
      error: error.toString(),
    );
  }
}

String _indent(String text) =>
    text.split('\n').map((line) => '    $line').join('\n');

/// Firestore returns the document path as `name`; the id is its last segment.
String? _documentIdFrom(String responseBody) {
  try {
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      final name = decoded['name']?.toString() ?? '';
      if (name.isNotEmpty) return name.split('/').last;
    }
  } catch (_) {
    // Fall through — a body we cannot read simply has no id in it.
  }
  return null;
}

void _writeTranscript(
  String outPath,
  ProjectConfig config,
  DateTime started,
  List<CallLog> logs,
) {
  final file = File(outPath);
  file.parent.createSync(recursive: true);

  final buffer = StringBuffer()
    ..writeln('Lock In - live API test log')
    ..writeln('Project  : ${config.projectId}')
    ..writeln('Started  : $started')
    ..writeln('Finished : ${DateTime.now()}')
    ..writeln('Calls    : ${logs.length}')
    ..writeln('=' * 72);

  for (final log in logs) {
    buffer
      ..writeln()
      ..writeln('[${log.method}] ${log.label}')
      ..writeln('URL      : ${log.url}')
      ..writeln('Status   : ${log.error ?? log.statusCode}')
      ..writeln('Duration : ${log.elapsed.inMilliseconds} ms');
    if (log.requestBody.isNotEmpty) {
      buffer
        ..writeln('Request  :')
        ..writeln(log.requestBody);
    }
    if (log.responseBody.isNotEmpty) {
      buffer
        ..writeln('Response :')
        ..writeln(log.responseBody);
    }
    buffer.writeln('-' * 72);
  }

  file.writeAsStringSync(buffer.toString());
}
