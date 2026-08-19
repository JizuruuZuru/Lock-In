import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/subject_question_bank.dart';
import '../../models/quiz_question_record.dart';
import '../../services/api/api_exception.dart';
import '../../services/api/dictionary_api.dart';
import '../../services/api/firestore_rest_api.dart';
import '../../services/api/open_trivia_api.dart';
import '../../utils/admin_theme.dart';
import '../../widgets/offline_banner.dart';

/// Live API test bench for the admin panel.
///
/// The import screen proves GET and POST as a side effect of doing real work.
/// This screen exists to exercise the whole HTTP surface deliberately and in
/// one place — **GET, POST, PATCH, and DELETE** — printing the exact request
/// and response for each, so the integration can be demonstrated and captured
/// without hunting through six different screens.
///
/// The write half runs a full lifecycle against a single throwaway document:
/// create it (POST), edit it (PATCH), search for it (POST runQuery), then
/// remove it (DELETE). Nothing is left behind in the question bank.
class ApiConsolePage extends StatefulWidget {
  const ApiConsolePage({super.key});

  @override
  State<ApiConsolePage> createState() => _ApiConsolePageState();
}

/// One completed step, in the order it ran.
class _StepResult {
  final String label;
  final String method;
  final String url;
  final String requestBody;
  final String responseBody;
  final int statusCode;
  final Duration elapsed;
  final String? error;

  const _StepResult({
    required this.label,
    required this.method,
    required this.url,
    this.requestBody = '',
    this.responseBody = '',
    this.statusCode = 0,
    this.elapsed = Duration.zero,
    this.error,
  });

  bool get failed => error != null;
}

class _ApiConsolePageState extends State<ApiConsolePage> {
  final OpenTriviaApi _trivia = OpenTriviaApi();
  final DictionaryApi _dictionary = DictionaryApi();
  final FirestoreRestApi _rest = FirestoreRestApi();

  final List<_StepResult> _results = <_StepResult>[];

  bool _running = false;
  String _currentStep = '';

  @override
  void dispose() {
    _trivia.dispose();
    _dictionary.dispose();
    _rest.dispose();
    super.dispose();
  }

  /// The document the write lifecycle operates on. Tagged clearly and left
  /// unpublished, so even if a run aborts half way through no student can be
  /// served it.
  QuizQuestionRecord _probeRecord() {
    return const QuizQuestionRecord(
      subject: SubjectQuizType.science,
      topic: 'API Console',
      instruction: 'Temporary record created by the API console.',
      prompt: 'API console probe - which planet is largest in our solar system?',
      correctAnswer: 'Jupiter',
      choices: ['Mars', 'Venus', 'Earth'],
      minLevel: 1,
      source: QuestionSource.openTrivia,
      published: false,
    );
  }

  /// Runs one step, timing it and turning any failure into a recorded row
  /// rather than an exception — a failed step must not abort the run, because
  /// seeing *which* verb failed is the whole point of the screen.
  Future<T?> _step<T>(
    String label,
    String method,
    Future<T> Function() body, {
    required _StepResult Function(T value) onSuccess,
    String url = '',
  }) async {
    setState(() => _currentStep = label);
    final watch = Stopwatch()..start();

    try {
      final value = await body();
      watch.stop();
      final built = onSuccess(value);
      if (!mounted) return value;
      setState(() {
        _results.add(
          _StepResult(
            label: built.label,
            method: built.method,
            url: built.url,
            requestBody: built.requestBody,
            responseBody: built.responseBody,
            statusCode: built.statusCode,
            elapsed: watch.elapsed,
          ),
        );
      });
      return value;
    } catch (error) {
      watch.stop();
      final failure = ApiException.from(error);
      if (!mounted) return null;
      setState(() {
        _results.add(
          _StepResult(
            label: label,
            method: method,
            url: url,
            statusCode: failure.statusCode ?? 0,
            elapsed: watch.elapsed,
            error: failure.message,
            responseBody: failure.detail ?? '',
          ),
        );
      });
      return null;
    }
  }

  Future<void> _runAll() async {
    if (_running) return;
    setState(() {
      _running = true;
      _results.clear();
    });

    // ----------------------------------------------------------------- GET
    await _step<TriviaFetchResult>(
      'GET trivia questions',
      'GET',
      () => _trivia.fetchQuestions(amount: 2, difficulty: 'easy'),
      url: 'https://${OpenTriviaApi.host}/api.php',
      onSuccess: (value) => _StepResult(
        label: 'GET trivia questions (${value.questions.length} returned)',
        method: 'GET',
        url: value.requestUrl,
        responseBody: value.rawJson,
        statusCode: 200,
      ),
    );

    await _step<DictionaryEntry>(
      'GET dictionary entry',
      'GET',
      () => _dictionary.lookup('planet'),
      url: 'https://${DictionaryApi.host}/api/v2/entries/en/planet',
      onSuccess: (value) => _StepResult(
        label: 'GET dictionary entry for "planet"',
        method: 'GET',
        url: 'https://${DictionaryApi.host}/api/v2/entries/en/planet',
        responseBody: value.rawJson,
        statusCode: 200,
      ),
    );

    // ---------------------------------------------------------------- POST
    final created = await _step<RestPublishResult>(
      'POST create question',
      'POST',
      () => _rest.createQuestionDetailed(_probeRecord()),
      url: '${_rest.documentsBaseUrl}/quiz_questions',
      onSuccess: (value) => _StepResult(
        label: 'POST create question (id ${value.createdIds.first})',
        method: 'POST',
        url: value.lastRequestUrl,
        requestBody: value.lastRequestBody,
        responseBody: value.lastResponseBody,
        statusCode: 200,
      ),
    );

    final createdIds = created?.createdIds ?? const <String>[];
    final probeId = createdIds.isEmpty ? null : createdIds.first;

    // --------------------------------------------------------------- PATCH
    if (probeId != null) {
      await _step<RestCallLog>(
        'PATCH update question',
        'PATCH',
        () => _rest.updateQuestion(
          _probeRecord().copyWith(
            id: probeId,
            prompt: 'API console probe - updated at '
                '${DateTime.now().toIso8601String()}',
            minLevel: 3,
          ),
        ),
        url: '${_rest.documentsBaseUrl}/quiz_questions/$probeId',
        onSuccess: (log) => _StepResult(
          label: 'PATCH update question',
          method: log.method,
          url: log.url,
          requestBody: log.requestBody,
          responseBody: log.responseBody,
          statusCode: log.statusCode,
        ),
      );

      await _step<RestCallLog>(
        'PATCH publish flag',
        'PATCH',
        () => _rest.setPublished(probeId, false),
        url: '${_rest.documentsBaseUrl}/quiz_questions/$probeId',
        onSuccess: (log) => _StepResult(
          label: 'PATCH publish flag (single-field update mask)',
          method: log.method,
          url: log.url,
          requestBody: log.requestBody,
          responseBody: log.responseBody,
          statusCode: log.statusCode,
        ),
      );
    }

    // -------------------------------------------------- POST (runQuery read)
    await _step<RestQueryResult>(
      'POST runQuery search',
      'POST',
      () => _rest.runQuestionQueryDetailed(
        subject: SubjectQuizType.science,
        limit: 5,
      ),
      url: '${_rest.documentsBaseUrl}:runQuery',
      onSuccess: (value) => _StepResult(
        label: 'POST runQuery search (${value.questions.length} matched)',
        method: value.log.method,
        url: value.log.url,
        requestBody: value.log.requestBody,
        responseBody: value.log.responseBody,
        statusCode: value.log.statusCode,
      ),
    );

    // -------------------------------------------------------------- DELETE
    if (probeId != null) {
      await _step<RestCallLog>(
        'DELETE question',
        'DELETE',
        () => _rest.deleteQuestion(probeId),
        url: '${_rest.documentsBaseUrl}/quiz_questions/$probeId',
        onSuccess: (log) => _StepResult(
          label: 'DELETE question (probe cleaned up)',
          method: log.method,
          url: log.url,
          responseBody: log.responseBody,
          statusCode: log.statusCode,
        ),
      );
    }

    // -------------------------------------- DELETE against a missing document
    // Proves the failure path is handled too, not only the happy one.
    await _step<RestCallLog>(
      'DELETE missing document (expected failure)',
      'DELETE',
      () => _rest.deleteQuestion('this-document-does-not-exist'),
      url: '${_rest.documentsBaseUrl}/quiz_questions/this-document-does-not-exist',
      onSuccess: (log) => _StepResult(
        label: 'DELETE missing document',
        method: log.method,
        url: log.url,
        responseBody: log.responseBody,
        statusCode: log.statusCode,
      ),
    );

    if (!mounted) return;
    setState(() {
      _running = false;
      _currentStep = '';
    });
  }

  void _copyLog() {
    final buffer = StringBuffer()
      ..writeln('Lock In - API console log')
      ..writeln('Captured ${DateTime.now()}')
      ..writeln('=' * 60);

    for (final result in _results) {
      final status =
          result.failed ? 'FAILED - ${result.error}' : '${result.statusCode}';
      buffer
        ..writeln()
        ..writeln('[${result.method}] ${result.label}')
        ..writeln('URL      : ${result.url}')
        ..writeln('Status   : $status')
        ..writeln('Duration : ${result.elapsed.inMilliseconds} ms');
      if (result.requestBody.isNotEmpty) {
        buffer
          ..writeln('Request  :')
          ..writeln(result.requestBody);
      }
      if (result.responseBody.isNotEmpty) {
        buffer
          ..writeln('Response :')
          ..writeln(result.responseBody);
      }
      buffer.writeln('-' * 60);
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Full API log copied to the clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passed = _results.where((result) => !result.failed).length;
    final failed = _results.where((result) => result.failed).length;

    return AdminScaffold(
      title: 'API Console',
      subtitle: 'GET - POST - PATCH - DELETE',
      actions: [
        if (_results.isNotEmpty)
          IconButton(
            tooltip: 'Copy the whole log',
            onPressed: _copyLog,
            icon: const Icon(Icons.copy_all_rounded),
          ),
      ],
      body: Column(
        children: [
          const OfflineBanner(
            blocking: true,
            message:
                'The API console makes live HTTP calls, so it needs a connection.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _intro(),
                const SizedBox(height: 14),
                _runBar(passed, failed),
                const SizedBox(height: 14),
                if (_results.isEmpty && !_running)
                  const AdminStateView(
                    icon: Icons.api_rounded,
                    title: 'Nothing run yet',
                    message:
                        'Tap "Run all requests" to call every endpoint in order '
                        'and see the real request and response for each one.',
                  )
                else
                  for (final result in _results) ...[
                    _resultCard(result),
                    const SizedBox(height: 10),
                  ],
                if (_running)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: AdminStateView.loading(
                      _currentStep.isEmpty ? 'Starting...' : 'Running: $_currentStep',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _intro() {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            icon: Icons.lan_rounded,
            title: 'Every request the app makes',
            caption: 'Runs the full lifecycle against a throwaway document, then '
                'deletes it. Nothing is left in the question bank.',
          ),
          const SizedBox(height: 12),
          _endpointRow('GET', 'opentdb.com/api.php', 'Fetch trivia questions'),
          _endpointRow(
            'GET',
            'api.dictionaryapi.dev/.../entries/en/{word}',
            'Look up a word',
          ),
          _endpointRow(
            'POST',
            'firestore.../documents/quiz_questions',
            'Create a question',
          ),
          _endpointRow(
            'PATCH',
            'firestore.../quiz_questions/{id}',
            'Update a question',
          ),
          _endpointRow(
            'POST',
            'firestore.../documents:runQuery',
            'Search questions',
          ),
          _endpointRow(
            'DELETE',
            'firestore.../quiz_questions/{id}',
            'Delete a question',
          ),
        ],
      ),
    );
  }

  Widget _endpointRow(String method, String url, String purpose) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 72, child: _methodBadge(method)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  url,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: AdminPalette.ink,
                  ),
                ),
                Text(
                  purpose,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AdminPalette.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _methodColor(String method) {
    return switch (method) {
      'GET' => const Color(0xFF1976D2),
      'POST' => AdminPalette.success,
      'PATCH' => const Color(0xFFEF6C00),
      'DELETE' => AdminPalette.danger,
      _ => AdminPalette.muted,
    };
  }

  Widget _methodBadge(String method) {
    final color = _methodColor(method);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.6),
      ),
      child: Text(
        method,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _runBar(int passed, int failed) {
    return AdminPanel(
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _running ? null : _runAll,
              icon: _running
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(_running ? 'Running...' : 'Run all requests'),
            ),
          ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AdminChip(
                  label: '$passed succeeded',
                  color: AdminPalette.success,
                  icon: Icons.check_circle_rounded,
                ),
                if (failed > 0) ...[
                  const SizedBox(width: 8),
                  AdminChip(
                    label: '$failed failed',
                    color: AdminPalette.danger,
                    icon: Icons.error_rounded,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultCard(_StepResult result) {
    final color = result.failed ? AdminPalette.danger : _methodColor(result.method);

    return AdminPanel(
      padding: EdgeInsets.zero,
      borderColor: color,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: SizedBox(width: 66, child: _methodBadge(result.method)),
          title: Text(
            result.label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            result.failed
                ? result.error!
                : 'HTTP ${result.statusCode} - ${result.elapsed.inMilliseconds} ms',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: result.failed ? AdminPalette.danger : AdminPalette.muted,
            ),
          ),
          trailing: Icon(
            result.failed ? Icons.error_rounded : Icons.check_circle_rounded,
            color: color,
          ),
          children: [
            _codeBlock('URL', result.url),
            if (result.requestBody.isNotEmpty)
              _codeBlock('Request body', result.requestBody),
            if (result.responseBody.isNotEmpty)
              _codeBlock('Response body', result.responseBody),
          ],
        ),
      ),
    );
  }

  Widget _codeBlock(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: AdminPalette.muted,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              IconButton(
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                tooltip: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label copied.')),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF11121A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                content,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  height: 1.45,
                  color: Color(0xFFD7E3FF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
