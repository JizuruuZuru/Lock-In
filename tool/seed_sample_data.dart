/// Seeds the demo data a live presentation needs: a few student accounts and a
/// spread of quiz questions across both subjects.
///
/// ```bash
/// # fill the project with sample data
/// dart run tool/seed_sample_data.dart --email ana.cruz@lockinplayers.app --password teacher123
///
/// # remove everything this script created, and nothing else
/// dart run tool/seed_sample_data.dart --email ... --password ... --clean
/// ```
///
/// Flags:
///   --email / --password   an **existing admin** account. The security rules
///                          only let an admin write questions or other people's
///                          user documents, so the seeder borrows that
///                          permission rather than working around it.
///   --clean                delete the seeded questions instead of writing them
///   --questions-only       skip the student accounts
///   --project / --api-key  override the values read from the repo config
///
/// Every question it writes carries `seedTag: "sample-data"`, which is how
/// `--clean` finds exactly its own rows and leaves real content untouched.
///
/// Bootstrapping the very first admin still has to happen by hand — the rules
/// deliberately refuse to let an account promote itself. Register in the app,
/// then set `role: "admin"` on that user document in the Firebase console once.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'lock_in_rest.dart';

const String seedTag = 'sample-data';

/// Demo students. Passwords are intentionally simple and public — these are
/// throwaway accounts for a classroom demo, not real credentials.
const List<(String, String, int)> _students = [
  ('Miguel', 'Santos', 9),
  ('Sofia', 'Reyes', 10),
  ('Andres', 'Bautista', 8),
  ('Isabel', 'Cruz', 11),
];

const String _studentPassword = 'student123';

/// A spread wide enough that the leaderboard, the subject filter, the level
/// gate, and the published/hidden toggle all have something to show.
final List<Map<String, dynamic>> _questions = [
  {
    'subject': 'english',
    'topic': 'Nouns',
    'instruction': 'Choose the noun in the sentence.',
    'prompt': 'The bright sun warmed the park.',
    'correctAnswer': 'sun',
    'choices': ['bright', 'warmed', 'the'],
    'minLevel': 1,
    'published': true,
  },
  {
    'subject': 'english',
    'topic': 'Verbs',
    'instruction': 'Choose the verb in the sentence.',
    'prompt': 'The children raced across the field.',
    'correctAnswer': 'raced',
    'choices': ['children', 'across', 'field'],
    'minLevel': 1,
    'published': true,
  },
  {
    'subject': 'english',
    'topic': 'Synonyms',
    'instruction': 'Choose the word that means the same as "happy".',
    'prompt': 'Which word means the same as happy?',
    'correctAnswer': 'glad',
    'choices': ['angry', 'tired', 'hungry'],
    'minLevel': 2,
    'published': true,
  },
  {
    'subject': 'english',
    'topic': 'Punctuation',
    'instruction': 'Choose the punctuation mark that ends a question.',
    'prompt': 'Which mark belongs at the end of "Where are you going"?',
    'correctAnswer': '?',
    'choices': ['.', '!', ','],
    'minLevel': 2,
    'published': true,
  },
  {
    'subject': 'english',
    'topic': 'Comprehension',
    'instruction': 'Read the sentence, then answer the question.',
    'prompt': 'Ana packed an umbrella because dark clouds filled the sky. '
        'Why did Ana pack an umbrella?',
    'correctAnswer': 'She thought it would rain',
    'choices': [
      'She was going swimming',
      'She wanted to stay warm',
      'She lost her bag',
    ],
    'minLevel': 4,
    'published': true,
  },
  {
    'subject': 'science',
    'topic': 'Solar System',
    'instruction': 'Choose the correct answer.',
    'prompt': 'Which planet is the largest in our solar system?',
    'correctAnswer': 'Jupiter',
    'choices': ['Mars', 'Venus', 'Earth'],
    'minLevel': 1,
    'published': true,
  },
  {
    'subject': 'science',
    'topic': 'Plants',
    'instruction': 'Choose the correct answer.',
    'prompt': 'Which part of a plant takes in water from the soil?',
    'correctAnswer': 'Roots',
    'choices': ['Leaves', 'Flower', 'Stem'],
    'minLevel': 1,
    'published': true,
  },
  {
    'subject': 'science',
    'topic': 'States of Matter',
    'instruction': 'Choose the correct answer.',
    'prompt': 'What happens to water when it is heated to boiling point?',
    'correctAnswer': 'It turns into a gas',
    'choices': ['It turns into a solid', 'It disappears', 'It gets heavier'],
    'minLevel': 3,
    'published': true,
  },
  {
    'subject': 'science',
    'topic': 'Animals',
    'instruction': 'Choose the correct answer.',
    'prompt': 'Which animal group has feathers and lays eggs?',
    'correctAnswer': 'Birds',
    'choices': ['Mammals', 'Fish', 'Reptiles'],
    'minLevel': 2,
    'published': true,
  },
  {
    'subject': 'science',
    'topic': 'Forces',
    'instruction': 'Choose the correct answer.',
    'prompt': 'What force pulls a dropped ball toward the ground?',
    'correctAnswer': 'Gravity',
    'choices': ['Friction', 'Magnetism', 'Wind'],
    'minLevel': 3,
    // Left unpublished on purpose, so the demo has a hidden row to show the
    // publish toggle against.
    'published': false,
  },
];

Future<void> main(List<String> args) async {
  final options = parseArgs(args);
  final clean = options['clean'] == 'true';
  final questionsOnly = options['questions-only'] == 'true';

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

  final email = options['email'] ?? promptFor('Admin login email');
  final password = options['password'] ?? promptFor('Password', secret: true);

  final client = http.Client();

  try {
    stdout.writeln('Signing in as $email ...');
    final token = await signIn(
      client: client,
      config: config,
      email: email,
      password: password,
    );
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    stdout.writeln('Signed in.\n');

    if (clean) {
      await _clean(client, config, headers);
    } else {
      if (!questionsOnly) {
        await _seedStudents(client, config, headers);
      }
      await _seedQuestions(client, config, headers);
    }
  } on StateError catch (error) {
    stderr.writeln('\n${error.message}');
    stderr.writeln(
      '\nIf no admin exists yet: register in the app, then open the Firebase '
      'console -> Firestore -> users -> your document, and add the field '
      'role = "admin". The rules refuse to let an account promote itself, '
      'which is why this one step is manual.',
    );
    exitCode = 1;
  } catch (error) {
    stderr.writeln('\nSeeding failed: $error');
    exitCode = 1;
  } finally {
    client.close();
  }
}

Future<void> _seedStudents(
  http.Client client,
  ProjectConfig config,
  Map<String, String> headers,
) async {
  stdout.writeln('Student accounts');
  stdout.writeln('-' * 60);

  for (final (firstName, lastName, age) in _students) {
    final loginEmail = buildLoginEmail(firstName: firstName, lastName: lastName);

    String uid;
    try {
      uid = await signUp(
        client: client,
        config: config,
        email: loginEmail,
        password: _studentPassword,
      );
    } on StateError catch (error) {
      // An existing account is a success for a seeder, not a failure — the
      // point is that the data is there afterwards.
      if (error.message.contains('EMAIL_EXISTS')) {
        stdout.writeln('  = $firstName $lastName already exists ($loginEmail)');
        continue;
      }
      rethrow;
    }

    final fullName = '$firstName $lastName';
    final response = await client.patch(
      Uri.https(firestoreHost, '${config.documentsPath}/users/$uid'),
      headers: headers,
      body: jsonEncode({
        'fields': restFields(<String, dynamic>{
          'uid': uid,
          'firstName': firstName,
          'lastName': lastName,
          'fullName': fullName,
          'username': fullName,
          'loginId': buildLoginId(firstName: firstName, lastName: lastName),
          'loginEmail': loginEmail,
          'email': loginEmail,
          'age': age,
          'role': 'student',
          'disabled': false,
          'isAnonymous': false,
          'authProvider': 'email',
          'profile_complete': true,
          'onboarding_step': 'done',
          'highscore': 0,
          'seedTag': seedTag,
          'createdAt': DateTime.now(),
          'accountCreatedAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        })
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      stdout.writeln('  + $fullName  ($loginEmail / $_studentPassword)');
    } else {
      stdout.writeln('  ! $fullName - profile write failed: '
          '${response.statusCode} ${_errorMessage(response.body)}');
    }
  }
  stdout.writeln();
}

Future<void> _seedQuestions(
  http.Client client,
  ProjectConfig config,
  Map<String, String> headers,
) async {
  stdout.writeln('Quiz questions');
  stdout.writeln('-' * 60);

  var created = 0;
  for (final question in _questions) {
    final response = await client.post(
      Uri.https(firestoreHost, '${config.documentsPath}/quiz_questions'),
      headers: headers,
      body: jsonEncode({
        'fields': restFields(<String, dynamic>{
          ...question,
          'source': 'manual',
          'seedTag': seedTag,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        })
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      created++;
      final flag = question['published'] == true ? 'published' : 'hidden';
      stdout.writeln('  + [${question['subject']}] ${question['topic']} '
          '- $flag');
    } else {
      stdout.writeln('  ! ${question['topic']} failed: '
          '${response.statusCode} ${_errorMessage(response.body)}');
    }
  }

  stdout
    ..writeln()
    ..writeln('Wrote $created of ${_questions.length} questions.')
    ..writeln('Run again with --clean to remove exactly these rows.');
}

Future<void> _clean(
  http.Client client,
  ProjectConfig config,
  Map<String, String> headers,
) async {
  stdout.writeln('Removing seeded questions (seedTag == "$seedTag")');
  stdout.writeln('-' * 60);

  final response = await client.post(
    Uri.https(firestoreHost, '${config.documentsPath}:runQuery'),
    headers: headers,
    body: jsonEncode({
      'structuredQuery': {
        'from': [
          {'collectionId': 'quiz_questions'}
        ],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'seedTag'},
            'op': 'EQUAL',
            'value': {'stringValue': seedTag},
          }
        },
        'limit': 500,
      }
    }),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    stderr.writeln('Search failed: ${response.statusCode} '
        '${_errorMessage(response.body)}');
    exitCode = 1;
    return;
  }

  final rows = jsonDecode(response.body);
  if (rows is! List) {
    stderr.writeln('Firestore returned an unexpected query result.');
    exitCode = 1;
    return;
  }

  final ids = rows
      .whereType<Map<String, dynamic>>()
      .map((row) => row['document'])
      .whereType<Map<String, dynamic>>()
      .map((document) => document['name'].toString().split('/').last)
      .toList(growable: false);

  if (ids.isEmpty) {
    stdout.writeln('  Nothing to remove.');
    return;
  }

  var deleted = 0;
  for (final id in ids) {
    final result = await client.delete(
      Uri.https(firestoreHost, '${config.documentsPath}/quiz_questions/$id'),
      headers: headers,
    );
    if (result.statusCode >= 200 && result.statusCode < 300) {
      deleted++;
      stdout.writeln('  - $id');
    } else {
      stdout.writeln('  ! $id failed: ${result.statusCode} '
          '${_errorMessage(result.body)}');
    }
  }

  stdout
    ..writeln()
    ..writeln('Deleted $deleted of ${ids.length} seeded questions.')
    ..writeln('Seeded student accounts are left alone — deactivate them from '
        'Admin Panel -> Accounts if you want them gone.');
}

String _errorMessage(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map && decoded['error'] is Map) {
      return decoded['error']['message'].toString();
    }
  } catch (_) {
    // Fall through to the raw body.
  }
  return body;
}
