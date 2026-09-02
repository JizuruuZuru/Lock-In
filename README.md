# Lock In

A proctored quiz and brain-training app for elementary learners, built in
Flutter on Firebase.

Students get 28 short, timed lesson games across English, Math, and Science,
plus a mixed-subject Exam mode that can watch for a face and detect leaving the
app. Teachers get an admin panel that owns the question bank and the accounts —
write, edit, publish, hide, and delete questions, and see them reach students
without an app restart.

| | |
|---|---|
| **Framework** | Flutter 3.44 · Dart 3.12 |
| **Backend** | Firebase Authentication + Cloud Firestore |
| **Platforms** | Android · iOS · Web · Windows · macOS · Linux |
| **Tests** | 241, all passing |

---

## Quick start

```bash
flutter pub get
flutter run                 # or: flutter run -d chrome / -d windows
```

The app is playable straight away — 5,793 questions are bundled into the binary,
so a student can practise with no account and no connection.

### Deploy the security rules

The rules enforce the same role check the UI performs, so the admin screens
cannot be bypassed by talking to Firestore directly. Deploy them once:

```bash
firebase deploy --only firestore:rules
```

### Create the first admin

Admin access is a `role` field on the user document. The rules deliberately
refuse to let an account grant itself that role — otherwise any student could —
so exactly one step is manual:

1. Launch the app and choose **"No, I'm new here"**.
2. Enter a name and age, then set a password (e.g. `Ana Cruz` / `teacher123`).
3. Open the [Firebase console](https://console.firebase.google.com) →
   **Firestore Database** → `users` → find that document.
4. Add a field: `role` (string) = `admin`.
5. Back in the app, choose **"Yes, I have an account"** and sign in with that
   name and password.

There is no separate admin entrance. `AppGate` reads the role after sign-in and
routes admins to the dashboard automatically. After this, admins promote other
accounts from **Admin Panel → Accounts** without touching the console again.

### Seed sample data

```bash
dart run tool/seed_sample_data.dart --email ana.cruz@lockinplayers.app --password teacher123
```

Creates four demo students (password `student123`) and ten questions spread
across both subjects and several levels, one deliberately unpublished. Every row
carries `seedTag: "sample-data"`, so `--clean` removes exactly its own and
nothing else.

---

## How sign-in works

The app never asks a child for an email address. A name and password are turned
into a synthetic credential — `Ana Cruz` becomes
`ana.cruz@lockinplayers.app` — so Firebase's email/password provider can be used
with something a young student can actually remember. See
[`lib/utils/name_credential.dart`](lib/utils/name_credential.dart).

Players can optionally **link** a Google account afterwards. It is a link, not a
second account: `linkWithCredential` keeps the same uid, so scores, level, and
leaderboard place all survive — the player simply gains a second way to sign in.

### Enabling Google sign-in

Not configured in this repository. `android/app/google-services.json` has an
empty `oauth_client` array, so the button reports *"Google sign-in is not set up
for this app yet"* rather than failing obscurely. To enable it:

1. Firebase console → **Authentication → Sign-in method** → enable **Google**.
2. Get the debug SHA-1:
   ```bash
   cd android
   ./gradlew signingReport        # Windows: .\gradlew signingReport
   ```
3. Firebase console → **Project settings → Your apps → Android** →
   **Add fingerprint** → paste the SHA-1.
4. Download the refreshed `google-services.json` and replace
   `android/app/google-services.json`.
5. `flutter clean && flutter run`.

Repeat step 2 with your release keystore for a release build.

---

## Testing

```bash
flutter analyze                                     # static analysis
flutter test                                        # 241 unit tests
flutter test test/firestore_rest_api_test.dart      # the REST layer alone
```

Live API checks — real traffic against the real services:

```bash
# the two key-less GET endpoints, no sign-in needed
dart run tool/api_smoke_test.dart --public-only

# the full lifecycle: GET -> POST -> PATCH -> runQuery -> DELETE
dart run tool/api_smoke_test.dart --email <admin> --password <password>
```

The full run operates on one throwaway document that it deletes at the end, and
writes a transcript to `docs/evidence/api-test-log.txt`.

---

## Project structure

```
lib/
├── main.dart                   entry point, Firebase init, offline persistence
├── app_gate.dart               the single routing decision point
├── data/                       5,793 bundled questions + the question bank
├── models/                     the two entities, with validation on the model
├── screens/                    45 screens — admin, auth, games, exam, home
├── services/                   23 services
│   ├── api/                    the whole HTTP surface
│   ├── question_repository.dart      CRUD — quiz_questions
│   └── user_admin_repository.dart    CRUD — users
├── utils/                      theme, layout, Firebase options
└── widgets/                    21 reusable widgets
test/                           15 files, 241 tests
tool/                           CLI scripts — API smoke test, sample-data seeder
docs/                           project documentation
firestore.rules                 server-side role enforcement
```

---

## APIs

| API | Method | Purpose | Key |
|---|:--:|---|:--:|
| [Open Trivia Database](https://opentdb.com) | GET | Bulk-import ready-made questions | none |
| [Free Dictionary API](https://dictionaryapi.dev) | GET | In-game word definitions | none |
| Cloud Firestore REST | POST · PATCH · DELETE | The project's own backend over HTTPS | Firebase ID token |

Admin Panel → **API Console** runs every one of them and shows the real request
and response for each. Details in [docs/API_INTEGRATION.md](docs/API_INTEGRATION.md).

---

## Offline behaviour

The app is built for a school connection that comes and goes:

- Firestore persistence is enabled explicitly on every platform (it is off by
  default on the web).
- Published questions are mirrored to a plain JSON copy in
  `shared_preferences`, which survives Firestore evicting its own cache.
- That cache is loaded **before** the network is contacted, so questions are in
  the bank on the first frame.
- Admin writes made offline are queued by Firestore and reported as *"Saved on
  this device. It will sync when you are back online"* — not left spinning, and
  not falsely reported as saved to the server.
- The typeface is **bundled, not downloaded**. `google_fonts` fetches from
  fonts.gstatic.com on first launch and quietly falls back to Roboto when that
  fails, so a first launch on a dead connection looked different from every
  launch after it. The OFL-licensed Noto Sans faces now ship in
  [`assets/fonts/`](assets/fonts) — subsetted to Latin, IPA, punctuation, and
  symbols, which is 0.85 MB rather than 3.2 MB and drops no glyph the app can
  render. Licence: [`assets/fonts/OFL.txt`](assets/fonts/OFL.txt).

---

## Documentation

| Document | Covers |
|---|---|
| [PROJECT_DOCUMENTATION.md](docs/PROJECT_DOCUMENTATION.md) | Description, objectives, scope, limitations, stack |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | System flowchart, navigation map, data flows, offline strategy |
| [DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md) | ERD, every collection and field, security rules |
| [API_INTEGRATION.md](docs/API_INTEGRATION.md) | All three APIs, every verb, JSON samples, error handling |
| [PROGRESS_REPORT.md](docs/PROGRESS_REPORT.md) | Accomplishments, completed and remaining features |
| [EVIDENCE_GUIDE.md](docs/EVIDENCE_GUIDE.md) | How to capture every required screenshot and log |
| [SUBMISSION_CHECKLIST.md](docs/SUBMISSION_CHECKLIST.md) | Each requirement mapped to its evidence |

---

## Known limitations

- **Face proctoring is mobile-only** — it needs a front camera and ML Kit. On
  desktop and web the exam runs unproctored; the app-leave detector still works.
- **Account deletion is a soft delete** — a client SDK cannot remove another
  person's auth credential. `disabled: true` blocks sign-in and is reversible.
- **The first admin is promoted by hand**, by design (see above).
- **Queries filter on one equality field**, with sorting done client-side, so
  the project needs no composite indexes and deploys to a clean Firebase
  project. A classroom-scale trade-off.

Full list: [PROJECT_DOCUMENTATION.md §4](docs/PROJECT_DOCUMENTATION.md#4-limitations).
