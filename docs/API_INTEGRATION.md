# Lock In — API Integration & Testing

**Project:** Lock In — an elementary quiz and brain-training app
(Flutter / Dart, Cloud Firestore)

---

## Quick answers

**APIs integrated.** Three: the **Open Trivia Database** (`opentdb.com`) for
importing ready-made quiz questions, the **Free Dictionary API**
(`dictionaryapi.dev`) for in-game word definitions, and the **Cloud Firestore
REST API** (`firestore.googleapis.com`) as the project's own backend reached
over plain HTTPS.

**Methods implemented.** **GET**, **POST**, **PATCH**, and **DELETE** — the full
lifecycle of a question document, plus two read-only third-party endpoints.

**Authentication.** Every call to the project's own backend carries the
signed-in user's Firebase ID token as a `Bearer` credential, so the same
security rules that guard the SDK guard these calls. The two third-party APIs
are free and key-less by design, so the project can be cloned and run by anyone.

**Where to see it working.** Admin Panel → **API Console** runs every request in
order and shows the real URL, request body, status code, and response for each.
Admin Panel → **Import from Open Trivia DB** does the same as a side effect of
real work.

---

## 1. Endpoints and methods

| Method | Endpoint | Purpose | Implemented in |
|:---|---|---|---|
| `GET` | `opentdb.com/api_category.php` | List trivia categories | `OpenTriviaApi.fetchCategories` |
| `GET` | `opentdb.com/api.php?amount={n}&category={id}&difficulty={d}&type=multiple&encode=url3986` | Fetch a batch of questions | `OpenTriviaApi.fetchQuestions` |
| `GET` | `api.dictionaryapi.dev/api/v2/entries/en/{word}` | Look up one word | `DictionaryApi.lookup` |
| `POST` | `firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents/quiz_questions` | **Create** a question | `FirestoreRestApi.createQuestion` |
| `POST` | `.../documents:runQuery` | **Search** questions (Firestore models search as POST, because the query travels in the body) | `FirestoreRestApi.runQuestionQuery` |
| `PATCH` | `.../documents/quiz_questions/{id}?updateMask.fieldPaths=...` | **Update** a question | `FirestoreRestApi.updateQuestion` |
| `PATCH` | `.../documents/quiz_questions/{id}?updateMask.fieldPaths=published&updateMask.fieldPaths=updatedAt` | Publish / hide, single-field | `FirestoreRestApi.setPublished` |
| `DELETE` | `.../documents/quiz_questions/{id}` | **Delete** a question | `FirestoreRestApi.deleteQuestion` |

### Why these APIs

**Open Trivia Database** returns multiple-choice questions in exactly the shape
this app already stores — a question, one `correct_answer`, and a list of
`incorrect_answers`. That maps one-to-one onto `QuizQuestionRecord`, so the API
feeds straight into the system's main data entity rather than sitting off to one
side: a teacher can stock a subject in seconds instead of typing every question
by hand.

**Free Dictionary API** serves the students rather than the admin. A child stuck
on a single unfamiliar word can unblock themselves without abandoning the
question.

**Cloud Firestore REST API** is the project's own backend reached over plain
HTTPS instead of through the Firestore SDK. This is where the write half of the
integration lives, carrying real, useful traffic rather than throwaway requests.

---

## 2. Files

```
lib/services/api/api_exception.dart        one error type for the whole API layer
lib/services/api/open_trivia_api.dart      GET    — categories + questions
lib/services/api/dictionary_api.dart       GET    — word lookup
lib/services/api/firestore_rest_api.dart   POST · PATCH · DELETE — the backend
lib/screens/admin/trivia_import_page.dart  admin UI for the import workflow
lib/screens/admin/api_console_page.dart    admin UI for the whole HTTP surface
lib/widgets/word_lookup_sheet.dart         student UI for the dictionary
lib/widgets/tappable_word_text.dart        makes words in a question tappable
tool/api_smoke_test.dart                   command-line live test, writes a transcript
test/api_client_test.dart                  15 tests — the two third-party APIs
test/firestore_rest_api_test.dart          21 tests — the REST backend
```

---

## 3. Request implementation

### GET — with JSON parsing and a second failure channel

```dart
final uri = Uri.https(host, '/api.php', <String, String>{
  'amount': amount.clamp(1, 50).toString(),
  if (categoryId != null && categoryId > 0) 'category': categoryId.toString(),
  if (difficulty != null && difficulty.isNotEmpty) 'difficulty': difficulty,
  'type': 'multiple',
  'encode': 'url3986',
});

final response = await _client
    .get(uri, headers: const {'Accept': 'application/json'})
    .timeout(timeout);

if (response.statusCode != 200) {
  throw ApiException.fromStatus(response.statusCode, body: response.body);
}

final json = jsonDecode(response.body) as Map<String, dynamic>;
_throwForResponseCode(json['response_code']);   // 200 OK can still mean failure

final questions = (json['results'] as List)
    .whereType<Map<String, dynamic>>()
    .map(TriviaQuestion.fromJson)
    .where((q) => q.incorrectAnswers.length >= 2)   // drop unplayable rows
    .toList();
```

Open Trivia DB **always answers HTTP 200** and reports real failures in a
`response_code` field, so that field is checked separately from the status code.
Because the request asks for `encode=url3986`, every text field arrives
percent-encoded and is decoded with `Uri.decodeComponent` during parsing.

### POST — authenticated, with typed value envelopes

```dart
final uri = Uri.https(host, '$_documentsPath/quiz_questions');
final body = jsonEncode({'fields': QuizQuestionRestCodec.toFields(clean, uid)});

final response = await _send('POST', uri, body: body);
```

Firestore's REST API does not accept plain JSON — every value is wrapped in a
typed envelope (`stringValue`, `integerValue`, `arrayValue`, …), so encoding and
decoding live in `QuizQuestionRestCodec`.

### PATCH — partial update with an explicit update mask

```dart
final fields = QuizQuestionRestCodec.toUpdateFields(clean);
final uri = Uri.https(
  host,
  '$_documentsPath/quiz_questions/${record.id}',
  {'updateMask.fieldPaths': fields.keys.toList()},   // repeated query key
);

final response = await _send('PATCH', uri, body: jsonEncode({'fields': fields}));
```

The `updateMask` names exactly which fields may change; everything not on the
mask is left untouched. That is how `createdAt` and `createdBy` survive an edit
— `toUpdateFields` removes them from both the mask and the body, so an update
can never rewrite who first authored a question or when. `setPublished` uses the
same mechanism with a two-field mask, so toggling visibility does not rewrite
the question text.

### DELETE — no body either way

```dart
final uri = Uri.https(host, '$_documentsPath/quiz_questions/$id');
final response = await _send('DELETE', uri);
```

Firestore answers a successful delete with `200` and an empty JSON object, so
there is nothing to parse — the status code *is* the result. An empty body is
reported as `{}` rather than blank so the console never shows a mystery gap.

### One send path for all three verbs

```dart
Future<http.Response> _send(String method, Uri uri, {String? body}) async {
  final token = await _idToken();
  final headers = <String, String>{
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
    if (body != null) 'Content-Type': 'application/json',
  };

  final Future<http.Response> call = switch (method) {
    'POST'   => _client.post(uri, headers: headers, body: body),
    'PATCH'  => _client.patch(uri, headers: headers, body: body),
    'DELETE' => _client.delete(uri, headers: headers),
    _ => throw ApiException("Unsupported HTTP method $method."),
  };

  final response = await call.timeout(timeout);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw ApiException.fromStatus(response.statusCode,
        body: _describeError(response.body));
  }
  return response;
}
```

Authentication, timeouts, and status handling are written once, so POST, PATCH,
and DELETE cannot drift apart.

---

## 4. JSON samples

### `GET https://opentdb.com/api.php?amount=1&category=17&difficulty=easy&type=multiple&encode=url3986`

```json
{
  "response_code": 0,
  "results": [
    {
      "type": "multiple",
      "difficulty": "easy",
      "category": "Science%3A%20Nature",
      "question": "What%20is%20the%20largest%20planet%20in%20our%20solar%20system%3F",
      "correct_answer": "Jupiter",
      "incorrect_answers": ["Mars", "Venus", "Earth"]
    }
  ]
}
```

### `GET https://api.dictionaryapi.dev/api/v2/entries/en/planet`

```json
[
  {
    "word": "planet",
    "phonetic": "/ˈplænət/",
    "phonetics": [
      { "text": "/ˈplænɪt/",
        "audio": "https://api.dictionaryapi.dev/media/pronunciations/en/planet-us.mp3" }
    ],
    "meanings": [
      {
        "partOfSpeech": "noun",
        "definitions": [
          {
            "definition": "A body which orbits the Sun.",
            "example": "Jupiter is the largest planet in the solar system."
          }
        ],
        "synonyms": []
      }
    ]
  }
]
```

### `POST .../documents/quiz_questions`

**Request:**

```json
{
  "fields": {
    "subject":       { "stringValue": "science" },
    "topic":         { "stringValue": "Solar System" },
    "instruction":   { "stringValue": "Choose the correct answer." },
    "prompt":        { "stringValue": "Which planet is the largest in our solar system?" },
    "correctAnswer": { "stringValue": "Jupiter" },
    "choices":       { "arrayValue": { "values": [
                         { "stringValue": "Mars" },
                         { "stringValue": "Venus" },
                         { "stringValue": "Earth" }
                       ] } },
    "minLevel":      { "integerValue": "1" },
    "source":        { "stringValue": "openTrivia" },
    "published":     { "booleanValue": false },
    "createdBy":     { "stringValue": "kPq2xN8vTZbW1mA0" },
    "createdAt":     { "timestampValue": "2026-08-19T04:12:55.401Z" },
    "updatedAt":     { "timestampValue": "2026-08-19T04:12:55.401Z" }
  }
}
```

**Response — `200`:**

```json
{
  "name": "projects/benchmark-14acf/databases/(default)/documents/quiz_questions/8fQ2xNbW1mA0kPqZ",
  "fields": { "…": "…" },
  "createTime": "2026-08-19T04:12:55.401Z",
  "updateTime": "2026-08-19T04:12:55.401Z"
}
```

The new document id is the last path segment of `name`.

### `PATCH .../documents/quiz_questions/8fQ2xNbW1mA0kPqZ?updateMask.fieldPaths=prompt&updateMask.fieldPaths=minLevel&updateMask.fieldPaths=updatedAt`

**Request:**

```json
{
  "fields": {
    "prompt":    { "stringValue": "Which planet is the largest — updated?" },
    "minLevel":  { "integerValue": "3" },
    "updatedAt": { "timestampValue": "2026-08-19T04:13:07.882Z" }
  }
}
```

**Response — `200`:** the full document after the edit. Note `createTime` is
unchanged and `updateTime` has moved:

```json
{
  "name": "projects/benchmark-14acf/databases/(default)/documents/quiz_questions/8fQ2xNbW1mA0kPqZ",
  "fields": {
    "prompt":   { "stringValue": "Which planet is the largest — updated?" },
    "minLevel": { "integerValue": "3" },
    "topic":    { "stringValue": "Solar System" },
    "…": "…"
  },
  "createTime": "2026-08-19T04:12:55.401Z",
  "updateTime": "2026-08-19T04:13:07.882Z"
}
```

### `DELETE .../documents/quiz_questions/8fQ2xNbW1mA0kPqZ`

**Response — `200`:**

```json
{}
```

**Deleting it again — `404`:**

```json
{
  "error": {
    "code": 404,
    "message": "Document does not exist.",
    "status": "NOT_FOUND"
  }
}
```

### `POST .../documents:runQuery`

**Request:**

```json
{
  "structuredQuery": {
    "from": [{ "collectionId": "quiz_questions" }],
    "where": {
      "fieldFilter": {
        "field": { "fieldPath": "subject" },
        "op": "EQUAL",
        "value": { "stringValue": "science" }
      }
    },
    "limit": 3
  }
}
```

**Response — `200`:** an array, one element per match. Rows carrying only a
`readTime` are Firestore's markers for "no match" and are filtered out.

```json
[
  {
    "document": {
      "name": "projects/benchmark-14acf/databases/(default)/documents/quiz_questions/8fQ2xNbW1mA0kPqZ",
      "fields": { "…": "…" }
    },
    "readTime": "2026-08-19T04:13:10.004Z"
  }
]
```

---

## 5. Displaying the data in the UI

| Screen | What it shows |
|---|---|
| **API Console** (`ApiConsolePage`) | Every request in order as an expandable card: colour-coded method badge, URL, status, duration, and the full request and response bodies, each copyable. A "Copy the whole log" action puts the entire transcript on the clipboard. |
| **Trivia importer** (`TriviaImportPage`) | Questions that came back as a preview table with checkboxes — question text, correct answer in green, wrong answers in grey, difficulty, and the level it would unlock at. Duplicates already in the bank are greyed out and cannot be ticked. |
| **JSON inspector** | The `{ }` button in the import screen's app bar opens the real GET response and the last POST request/response, copyable. |
| **Word lookup** (`WordLookupSheet`) | Definition, phonetic spelling, part of speech, example sentence, and synonyms, with a "hear it" button. Long words in every question are underlined and tappable. |
| **Dashboard** | A "From API" stat card counts how many stored questions came from Open Trivia DB. |

---

## 6. Loading states and error handling

Every request goes through `ApiException`, which turns low-level failures into a
message a child can act on.

| Situation | What the user sees |
|---|---|
| Request in flight | Spinner + "Asking Open Trivia DB for 10 questions…" / "Running: PATCH update question" |
| No internet (`SocketException`) | "No internet connection. Check your Wi-Fi and try again." |
| HTTP 400 | "The request was not accepted by the server." |
| HTTP 401 / 403 | "You are not allowed to do that. Try signing in again." |
| HTTP 404 | "We could not find what you asked for." |
| HTTP 429 | "Too many requests too quickly. Wait a few seconds and retry." |
| HTTP 5xx | "The server is having trouble right now. Try again later." |
| Malformed JSON (`FormatException`) | "The server sent data we could not read." |
| `response_code: 1` | "Open Trivia DB does not have that many questions for this category." |
| `response_code: 5` | "Open Trivia DB allows one request every 5 seconds." |
| Dictionary 404 | "No dictionary entry found for \"zzzz\"." |
| Not signed in | "You must be signed in to save to the server." — checked **before** any request is made |

Also handled:

- **Timeouts** — 15 s for Open Trivia DB, 12 s for the dictionary, 20 s for Firestore.
- **Retry** — every failure state renders a **Try again** button that re-runs the request.
- **Partial success** — bulk publish collects per-row failures instead of aborting, then reports honestly: *"Saved 8, but 2 failed. First error: …"*.
- **Server error messages are unwrapped** — Firestore reports failures as `{"error": {"message": "…"}}`; `_describeError` pulls that message out for the debug panel while the user still sees the friendly line.
- **Malformed rows are filtered out** before reaching the preview, so a question with fewer than two wrong answers can never be imported.
- **Validation before the network** — an invalid question is rejected without a request being made at all.
- **Guard rails on ids** — an empty document id is refused rather than sent, which would otherwise address the *collection* path instead of a document.
- **Caching** — dictionary lookups are cached in memory, so re-tapping a word during a quiz makes no second request.
- **Offline** — the import and console screens show a blocking offline banner, because they genuinely cannot work without a connection.
- **A failed step does not abort the console run** — seeing *which* verb failed is the point, so each step is recorded and the run continues.

---

## 7. Testing

### Unit tests — 36 tests over the HTTP layer, no network needed

```bash
flutter test test/api_client_test.dart test/firestore_rest_api_test.dart
```

Both suites run against canned responses via `package:http/testing.dart`'s
`MockClient`. `FirestoreRestApi` takes a `tokenProvider` and `uid` seam, so the
whole authenticated surface is exercised with no Firebase app initialised.

| Suite | Covers |
|---|---|
| `api_client_test.dart` (15) | Category parsing, url3986 decoding, amount clamping, every `response_code` branch, unplayable-row filtering, HTTP failure mapping, record conversion, difficulty→level mapping, dictionary parsing, the 404 path, empty-word rejection, lookup caching, status-code messages |
| `firestore_rest_api_test.dart` (21) | **POST**: path, bearer token, typed envelopes, pre-flight validation, partial-failure collection. **PATCH**: update mask contents, `createdAt`/`createdBy` protection, mask/body agreement, single-field publish toggle, empty-id refusal, 403 mapping. **DELETE**: path, empty-body handling, empty-id refusal, 404 mapping. **runQuery**: single filter, compositeFilter, read-time marker filtering, detailed result. **Auth**: no token means no request. **Codec**: document round-trip, update-field stripping |

### Live test — real traffic, written to a transcript

```bash
# both key-less GET endpoints, no sign-in needed
dart run tool/api_smoke_test.dart --public-only

# the full lifecycle, signed in as an admin
dart run tool/api_smoke_test.dart --email ana.cruz@lockinplayers.app --password teacher123
```

The script signs in through the Firebase Auth REST API, then runs
GET → POST → PATCH → runQuery → DELETE against a **single throwaway document**
that it deletes at the end, plus three deliberate failure cases (a missing word,
a second delete of the same document, and an unauthenticated POST). It prints
each exchange and writes the whole transcript to
`docs/evidence/api-test-log.txt`.

The probe document is written with `published: false`, so even if a run aborts
half way it can never reach a student.

Sample terminal output:

```
[GET] GET a word that does not exist (expected 404)
  URL      : https://api.dictionaryapi.dev/api/v2/entries/en/zzzqqxx
  Status   : 404 (expected failure) - 335 ms
  Response :
    {
      "title": "No Definitions Found",
      "message": "Sorry pal, we couldn't find definitions for the word you were looking for.",
      "resolution": "You can try the search again at later time or head to the web instead."
    }
```

---

## 8. Screenshot checklist

| Required shot | Where to get it |
|---|---|
| **API connection established** | Admin Panel → API Console, after "Run all requests" — the summary chip reads "N succeeded" |
| **GET tested** | The two GET cards expanded, showing the trivia and dictionary responses |
| **POST tested** | The POST card expanded, showing the typed-envelope request body and the `name`/`createTime` response |
| **PATCH tested** | The PATCH card expanded — the URL shows the `updateMask.fieldPaths` query parameters |
| **DELETE tested** | The DELETE card expanded, showing `{}` and HTTP 200 |
| **Responses properly displayed** | The importer's preview table, and the dictionary sheet open over a quiz question |
| **Error responses handled** | The "expected failure" cards in the console (red badge, plain-language message); or turn Wi-Fi off and tap "Fetch questions" in the importer |
| **Authentication** | The Firestore cards — the request only succeeds while signed in as an admin; sign in as a student to capture the 403 |
| **API testing logs** | `dart run tool/api_smoke_test.dart` terminal output, plus `docs/evidence/api-test-log.txt` |

Full step-by-step capture instructions: [EVIDENCE_GUIDE.md](EVIDENCE_GUIDE.md).
