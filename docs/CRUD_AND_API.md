# Lock In — CRUD & API Integration

Documentation for the two enhancements added to the Lock In quiz app:

1. **Complete CRUD** over the app's main data entity, persisted in a database.
2. **External API integration** with HTTP GET and POST requests.

---

## 1. Getting started

### Run the app

```bash
flutter pub get
flutter run
```

### Create the first admin

Admin access is controlled by a `role` field on the user document. The first
admin has to be promoted once, by hand:

1. Launch the app and choose **"No, I'm new here"**.
2. Enter a name and age, then set a password (e.g. `Ana Cruz` / `teacher123`).
3. Open the [Firebase console](https://console.firebase.google.com) →
   **Firestore Database** → `users` → find that document.
4. Add a field: `role` (string) = `admin`.
5. Back in the app, choose **"Yes, I have an account"** and log in with that
   name and password. There is no separate admin entrance — the gate reads the
   role after sign-in and routes admins to the dashboard automatically.

After that, admins can promote other accounts from **Admin Panel → Accounts**
without touching the console again.

### Enable Google sign-in

The "Connect with Google" step needs OAuth clients that this project does not
have yet — `android/app/google-services.json` currently has an empty
`oauth_client` array. Until these steps are done the button reports
*"Google sign-in is not set up for this app yet"* rather than crashing.

1. Firebase console → **Authentication → Sign-in method** → enable **Google**.
2. Get the app's debug SHA-1:
   ```bash
   cd android
   ./gradlew signingReport        # Windows: .\gradlew signingReport
   ```
   Copy the `SHA1` value from the `debug` variant.
3. Firebase console → **Project settings → Your apps → Android** →
   **Add fingerprint** → paste the SHA-1.
4. Download the refreshed `google-services.json` and replace
   `android/app/google-services.json`. It should now contain a non-empty
   `oauth_client` array.
5. `flutter clean && flutter run`.

For a release build, repeat step 2 with your release keystore and add that
SHA-1 too.

### Deploy the security rules

```bash
firebase deploy --only firestore:rules
```

The rules in [`firestore.rules`](../firestore.rules) enforce the same role check
the UI performs, so the admin screens cannot be bypassed by talking to Firestore
directly.

---

## 2. Startup flow

The app now opens by asking whether the person already has an account.

```
main.dart
  └─ AppGate                      lib/app_gate.dart
       ├─ nobody signed in     ──► WelcomePage
       │                            ├─ "Yes, I have an account" ──► LoginPage
       │                            └─ "No, I'm new here"       ──► PlayerOnboardingPage
       │                                                              (name → age)
       │                                                           └─► RegisterScreen
       │                                                              (password)
       │                                                           └─► ConnectGooglePage
       │                                                              (optional Gmail)
       ├─ account disabled     ──► "Account unavailable" screen (signed out)
       ├─ role == 'admin'      ──► AdminDashboardPage
       ├─ profile incomplete   ──► PlayerOnboardingPage
       └─ otherwise            ──► HomeMenu
```

`AppGate` is the single decision point. Every sign-in and sign-out routes back
through it, which is why there is **one** login screen for everybody: after a
successful sign-in `LoginPage` hands control to the gate, the gate reads the
account's `role`, and an admin lands in the admin panel while a student lands
in the game menu. A deactivated account cannot get past it either way.

### Connecting a Google account (optional)

After the password step, `ConnectGooglePage` asks whether the player wants to
attach a Gmail address **now or later**. It is genuinely optional — the account
already works with name + password, and "Maybe later" is offered again from the
profile screen (Home → Profile → *Connect Google account*).

Connecting is a **link**, not a second account:
`user.linkWithCredential(GoogleAuthProvider.credential(idToken: ...))` keeps the
same uid, so scores, level, and leaderboard place all survive. The player simply
gains a second way to sign in.

There is no code to type in. Google verifies the person during its own account
chooser, which is stronger than a numeric code the app would have to generate
and check itself. (Firebase has no built-in email OTP — its email flows send a
clickable link, and true OTP exists only for SMS.)

Implemented in `lib/services/google_link_service.dart`, written against
**google_sign_in v7** (`GoogleSignIn.instance`, `initialize()`, `authenticate()`
— all different from v6). Every outcome is mapped to a `GoogleLinkOutcome` with
a message that is already safe to show a child: cancelled, unsupported platform,
not configured, already linked, taken by another account, or failed.

`supportsAuthenticate()` gates the button, so it is hidden rather than offered
and then failing on Windows, Linux, and the web, where v7 has no interactive
chooser.

**Setup required before it will work** — see *Enable Google sign-in* below.

---

## 3. CRUD implementation

### Main data entity

**Quiz questions** (`quiz_questions` collection in Cloud Firestore).

This is the entity the system is built around: an admin writes the questions,
and students are asked them inside the existing English and Science lessons.
Accounts (`users`) are managed with a second, complete CRUD surface.

### Storage

**Cloud Firestore.** The app already used Firestore for profiles, game logs, and
leaderboards, so questions were added as a new top-level collection rather than
introducing a second storage system.

```
quiz_questions/{autoId}
  subject       : "english" | "science"
  topic         : "Nouns"
  instruction   : "Choose the noun in the sentence."
  prompt        : "The bright sun warmed the park."
  correctAnswer : "sun"
  choices       : ["bright", "warmed", "the"]   ← wrong answers only
  minLevel      : 1                             ← level gate
  source        : "manual" | "openTrivia"
  published     : true                          ← visible to students
  createdBy     : "<uid>"
  createdAt     : <timestamp>
  updatedAt     : <timestamp>
```

`choices` deliberately holds only the **wrong** answers. The game engine mixes
`correctAnswer` back in and shuffles at play time
(`SubjectQuizQuestion.shuffled`), which is the same contract the 78,000 bundled
questions already use — so admin questions and bundled questions are
interchangeable.

### Where each operation lives

| Operation | Entry point | Implementation |
|---|---|---|
| **Create** | `QuestionEditorPage` → "Create question" | `QuestionRepository.create` |
| **Create** (bulk) | `TriviaImportPage` → "Save to question bank" | `FirestoreRestApi.createQuestions` (HTTP POST) |
| **Read** | `QuestionListPage` (live list, search, subject filter) | `QuestionRepository.watchQuestions` |
| **Read** (in game) | English / Science lessons | `CustomQuestionSync` → `SubjectQuestionBank` |
| **Update** | `QuestionEditorPage` on an existing question | `QuestionRepository.update` |
| **Update** (quick) | Eye icon — publish / hide | `QuestionRepository.setPublished` |
| **Delete** | Trash icon → confirmation dialog | `QuestionRepository.delete` |

Accounts follow the same pattern:

| Operation | Entry point | Implementation |
|---|---|---|
| **Create** | `AccountEditorPage` → "Create account" | `UserAdminRepository.createAccount` |
| **Read** | `AccountListPage` (live list, search, role filter) | `UserAdminRepository.watchAccounts` |
| **Update** | `AccountEditorPage`, role toggle | `UserAdminRepository.updateAccount`, `.setRole` |
| **Delete** | Deactivate icon → confirmation | `UserAdminRepository.setDisabled` |

### Key files

```
lib/models/quiz_question_record.dart      entity + validation
lib/models/app_user_record.dart           account entity + validation
lib/services/question_repository.dart     question CRUD (Firestore SDK)
lib/services/user_admin_repository.dart   account CRUD (Firestore SDK + Auth)
lib/services/custom_question_sync.dart    pushes saved questions into the games
lib/screens/admin/                        all six admin screens
lib/utils/admin_theme.dart                shared admin UI kit
firestore.rules                           server-side role enforcement
```

### How a saved question reaches students

This is what makes the Create operation visible rather than theoretical.

1. `CustomQuestionSync` reads the **on-device cache first** and applies it to
   the bank — no network needed (see *Offline support* below).
2. It then attaches a live Firestore listener on
   `quiz_questions where published == true`.
3. On every change it groups the questions by subject and calls
   `SubjectQuestionBank.setCustomQuestions(...)`.
4. `SubjectQuestionBank._poolFor(subject)` concatenates the bundled `const`
   questions with the admin pool, so `randomQuestion(...)` draws from both.
5. Because lessons filter by **topic**, a question saved under an existing topic
   (e.g. `Nouns`) appears inside the *Nouns and Pronouns* lesson immediately —
   no app restart.

The `_LeveledQuestion` class was made public as `LeveledQuizQuestion` with a
`typedef` alias, so all ~78,000 bundled `const _LeveledQuestion(...)` literals
kept compiling unchanged.

### Offline support

Admin-created questions work with no internet, in both directions: students can
be asked them offline, and an admin can write them offline.

**Students play them offline.** Three separate things make this hold:

| Layer | What it does |
|---|---|
| `Settings(persistenceEnabled: true)` in `main.dart` | Firestore serves reads from its own cache when the network is gone. Set explicitly because persistence is **off by default on the web**. |
| `LocalQuestionCache` (`shared_preferences`) | A plain JSON copy of every published question, rewritten after each sync. Survives Firestore evicting its cache or the browser clearing site data. |
| `CustomQuestionSync.loadFromCache()` | Runs **before** Firestore is contacted, so the questions are in the bank on the first frame even if the network never answers. |

**Admins write them offline.** The subtle part is that a Firestore write Future
only completes once the *server* acknowledges it — offline that never happens,
so a plain `await` would leave the save button spinning forever. Every write in
`QuestionRepository` goes through `_settle`, which gives the acknowledgement a
4-second deadline and otherwise reports `WriteSyncState.queuedOffline`:

```dart
final doc = _collection.doc();          // id generated on the client
final syncState = await _settle(doc.set({...}));
return QuestionWriteResult(id: doc.id, syncState: syncState);
```

The question is durable either way — Firestore queues it and delivers it on
reconnect — so the UI says *"Saved on this device. It will sync when you are
back online."* instead of failing or lying.

**What the person sees**

- An `OfflineBanner` on every admin screen while the device is offline.
- The Import screen shows a *blocking* variant, because pulling from
  opentdb.com genuinely needs a connection — that is a raw HTTP call with no
  local queue. Writing questions by hand still works.
- The dashboard shows *"Playing from the copy on this device — N teacher
  questions saved offline · synced 2 h ago"*.

**Guards worth knowing about**

- An *empty* Firestore cache snapshot never overwrites the on-device copy, so a
  cold start with a stale Firestore cache cannot wipe good questions.
- A non-empty local snapshot **is** mirrored, so a question written offline
  reaches the on-device copy too.
- `markSynced` is only stamped for server-confirmed data, so the dashboard
  never claims to be current while offline.
- Invalid records are dropped on both save and load — a corrupt cache can never
  put an unanswerable question on screen, and an unparseable payload is ignored
  rather than crashing startup.

Covered by [`test/offline_question_cache_test.dart`](../test/offline_question_cache_test.dart).

### Data validation

Validation lives on the model, not in the widgets, so the editor form, the bulk
importer, and the repository all enforce the identical rules. Each returns a
`field -> message` map that the form paints under the offending input.

**Questions** (`QuizQuestionRecord.validate`):

| Rule | Message |
|---|---|
| Topic required, ≤ 60 chars | "Pick or type a topic." |
| Instruction required | "Tell the student what to do…" |
| Question 5–600 chars | "The question is too short to be clear." |
| Correct answer required | "Mark which answer is correct." |
| 2–5 wrong choices | "Add at least 2 wrong answers…" |
| No duplicate wrong choices (case-insensitive) | "…\"bright\" is repeated." |
| Correct answer not repeated as a wrong one | "The correct answer is also listed as a wrong answer." |
| Level 1–20 | "Level must be between 1 and 20." |

**Accounts** (`AppUserRecord.validate`): both names required, letters only, ≤ 40
chars; age required and between 4 and 100; password ≥ 6 characters and
confirmed on create.

Validation is covered by unit tests in
[`test/crud_validation_test.dart`](../test/crud_validation_test.dart).

### Notes on Delete

Questions are **hard deleted** — the document is removed and students stop
seeing it immediately.

Accounts are **soft deleted**: `disabled: true` is written, and both `AppGate`
and `LoginPage` refuse entry with an explanation. This is deliberate. A Firebase
client SDK can only delete *its own* auth credential — removing someone else's
requires a server holding the Admin SDK. Disabling is the honest client-side
equivalent, it is reversible, and it keeps the student's game logs and
leaderboard history intact.

Two guards protect the panel from being locked out: an admin cannot deactivate
or demote themselves, and the last remaining active admin cannot be deactivated
or demoted.

### User-friendly interface

- Live preview in the question editor showing exactly what the student will see,
  shuffled the way the game shuffles.
- Topic autocomplete drawn from the topics already in use, so new questions land
  in a lesson instead of an orphan topic.
- Search and filter chips on both list screens.
- Confirmation dialogs on every destructive action, naming what will be deleted.
- Explicit loading, empty, error, and "no matches" states (`AdminStateView`).
- The admin area reuses the app's existing visual language (thick borders, hard
  offset shadows) so it does not feel bolted on.

---

## 4. API integration

### APIs used

| # | API | Purpose | Key required |
|---|---|---|---|
| 1 | **Open Trivia Database** — `opentdb.com` | Import ready-made multiple-choice questions into the question bank | No |
| 2 | **Free Dictionary API** — `dictionaryapi.dev` | In-game word definitions and pronunciation for students | No |
| 3 | **Cloud Firestore REST API** — `firestore.googleapis.com` | The project's own backend, written to over HTTP POST | Uses the signed-in user's ID token |

### Why these APIs

**Open Trivia Database** returns multiple-choice questions in exactly the shape
this app stores — a question, one `correct_answer`, and a list of
`incorrect_answers`. That maps one-to-one onto `QuizQuestionRecord`, so the API
feeds directly into the CRUD entity: a teacher can stock a subject in seconds
instead of typing every question by hand.

**Free Dictionary API** serves the students rather than the admin. Tapping any
underlined word in a question opens its definition, phonetic spelling, and
example sentence, so a student blocked only by vocabulary can unblock
themselves without leaving the quiz.

**Cloud Firestore REST API** is how the imported questions are written back.
Firestore models document creation and structured queries as HTTP POST, which is
what carries the POST half of the integration on real, useful traffic rather
than a throwaway request.

### Endpoints and methods

| Method | Endpoint | Used by |
|---|---|---|
| `GET` | `https://opentdb.com/api_category.php` | `OpenTriviaApi.fetchCategories` |
| `GET` | `https://opentdb.com/api.php?amount={n}&category={id}&difficulty={d}&type=multiple&encode=url3986` | `OpenTriviaApi.fetchQuestions` |
| `GET` | `https://api.dictionaryapi.dev/api/v2/entries/en/{word}` | `DictionaryApi.lookup` |
| `POST` | `https://firestore.googleapis.com/v1/projects/{projectId}/databases/(default)/documents/quiz_questions` | `FirestoreRestApi.createQuestion` |
| `POST` | `https://firestore.googleapis.com/v1/projects/{projectId}/databases/(default)/documents:runQuery` | `FirestoreRestApi.runQuestionQuery` |

### Files

```
lib/services/api/api_exception.dart      one error type for the whole API layer
lib/services/api/open_trivia_api.dart    GET  — categories + questions
lib/services/api/dictionary_api.dart     GET  — word lookup
lib/services/api/firestore_rest_api.dart POST — create document, runQuery
lib/screens/admin/trivia_import_page.dart admin UI for the import workflow
lib/widgets/word_lookup_sheet.dart        student UI for the dictionary
lib/widgets/tappable_word_text.dart       makes question words tappable
```

### Features added through the integration

- **Bulk question import.** Choose a category, difficulty, and amount; preview
  what came back; tick the ones worth keeping; publish them into the bank.
- **Duplicate detection.** Before showing the preview, the existing question
  keys are read from Firestore and any question already in the bank is greyed
  out and un-tickable, so the same import cannot be run twice by accident.
- **Difficulty → level mapping.** `easy` unlocks at level 1, `medium` at 4,
  `hard` at 7, so imported questions respect the game's existing progression.
- **JSON inspector.** The exact GET response and the last POST request/response
  are viewable and copyable from the app itself.
- **In-game dictionary.** Long words in a question are underlined and tappable;
  tapping opens definitions, phonetics, an example, synonyms, and a
  text-to-speech "hear it" button.

### Request implementation

`OpenTriviaApi.fetchQuestions` — HTTP GET, JSON parsing, and the two failure
modes this API has:

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

`FirestoreRestApi.createQuestion` — HTTP POST with the typed value envelopes
Firestore's REST API requires, authenticated with the caller's ID token:

```dart
final uri = Uri.https(host, '$_documentsPath/quiz_questions');
final body = jsonEncode({'fields': QuizQuestionRestCodec.toFields(clean, uid)});

final response = await _client.post(
  uri,
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await user.getIdToken()}',
  },
  body: body,
);
```

### JSON response samples

**`GET https://opentdb.com/api.php?amount=2&category=17&difficulty=easy&type=multiple&encode=url3986`**

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

Text arrives percent-encoded because the request asks for `encode=url3986`;
`TriviaQuestion._decode` runs `Uri.decodeComponent` on every field, turning
`"What%20is%20the%20largest%20planet..."` into
`"What is the largest planet in our solar system?"`.

**`GET https://api.dictionaryapi.dev/api/v2/entries/en/sun`**

```json
[
  {
    "word": "sun",
    "phonetic": "/sʌn/",
    "phonetics": [{ "text": "/sʌn/", "audio": "https://.../sun-us.mp3" }],
    "meanings": [
      {
        "partOfSpeech": "noun",
        "definitions": [
          {
            "definition": "The star at the centre of our solar system.",
            "example": "The sun rose over the hill."
          }
        ],
        "synonyms": ["daystar", "sol"]
      }
    ]
  }
]
```

**`POST .../documents/quiz_questions`** — request body:

```json
{
  "fields": {
    "subject":       { "stringValue": "science" },
    "topic":         { "stringValue": "Nature" },
    "prompt":        { "stringValue": "What is the largest planet in our solar system?" },
    "correctAnswer": { "stringValue": "Jupiter" },
    "choices":       { "arrayValue": { "values": [
                         { "stringValue": "Mars" },
                         { "stringValue": "Venus" },
                         { "stringValue": "Earth" }
                       ] } },
    "minLevel":      { "integerValue": "1" },
    "source":        { "stringValue": "openTrivia" },
    "published":     { "booleanValue": true }
  }
}
```

— and the response:

```json
{
  "name": "projects/benchmark-14acf/databases/(default)/documents/quiz_questions/8fQ2xN…",
  "fields": { "...": "..." },
  "createTime": "2026-08-13T04:12:55.401Z",
  "updateTime": "2026-08-13T04:12:55.401Z"
}
```

The document id is the last path segment of `name`.

### Loading states and error handling

Every request goes through `ApiException`, which converts low-level failures
into a message a child can act on:

| Situation | What the user sees |
|---|---|
| Request in flight | Spinner + "Asking Open Trivia DB for 10 questions…" |
| No internet (`SocketException`) | "No internet connection. Check your Wi-Fi and try again." |
| HTTP 429 | "Too many requests too quickly. Wait a few seconds and retry." |
| HTTP 5xx | "The server is having trouble right now. Try again later." |
| Malformed JSON (`FormatException`) | "The server sent data we could not read." |
| `response_code: 1` | "Open Trivia DB does not have that many questions for this category." |
| `response_code: 5` | "Open Trivia DB allows one request every 5 seconds." |
| Dictionary 404 | "No dictionary entry found for \"zzzz\"." |

Additional handling:

- A 15-second timeout on Open Trivia DB, 12 on the dictionary, 20 on Firestore.
- Every failure state renders a **Try again** button that re-runs the request.
- Bulk publish collects per-row failures instead of aborting, then reports
  honestly: *"Saved 8, but 2 failed. First error: …"*.
- Malformed API rows are filtered out before reaching the preview, so a question
  with fewer than two wrong answers can never be imported.
- Dictionary lookups are cached in memory, so re-tapping a word during a quiz
  makes no second request.

### Tests

[`test/api_client_test.dart`](../test/api_client_test.dart) covers the HTTP layer
against canned responses using `MockClient` — JSON parsing, url3986 decoding,
amount clamping, every `response_code` branch, the 404 path, caching, and the
status-code messages. No network access is needed to run them.

```bash
flutter test
```

---

## 5. Screenshot checklist

For the submission, capture:

**CRUD**
1. **Create** — Admin Panel → Questions → New question, form filled in with the
   student preview visible, then the "Question created and published" toast.
2. **Read** — the Questions list showing several questions with their subject,
   topic, level, and answer chips; plus a student playing a lesson and being
   asked one of those questions.
3. **Update** — the same question open in the editor with a changed answer, and
   the "Question updated" toast.
4. **Delete** — the "Delete this question?" confirmation dialog, and the list
   afterwards with the row gone.
5. **Accounts** — the Accounts list, an account being edited, and the
   "Deactivate…" confirmation.

**API**
6. **API request implementation** — the Import screen showing the endpoint list
   and the request builder, mid-request with the spinner visible.
7. **Retrieved data displayed** — the preview table of questions returned by
   Open Trivia DB, and the dictionary sheet open over a quiz question.
8. **JSON response sample** — the JSON inspector sheet (tap the `{ }` icon in
   the Import screen app bar).
9. **Error handling** — turn Wi-Fi off and tap "Fetch questions" to capture the
   failure state with its Try again button.