# Lock In — Evidence Capture Guide

Everything Section F asks for, as a shot-by-shot list: where to be, what to tap,
and what must be visible in the frame for the shot to count.

Save screenshots into `docs/evidence/` using the file names given below. That
folder is where `tool/api_smoke_test.dart` writes its transcript too, so all the
evidence ends up in one place.

```bash
mkdir -p docs/evidence
```

---

## Before you start

**1. Deploy the security rules.** The `data_clear_events` fix is not live until
you do.

```bash
firebase deploy --only firestore:rules
```

**2. Make sure you have an admin account.** If this is a fresh project, register
in the app, then open the Firebase console → Firestore → `users` → your document
and add `role` = `admin` (string). This one step is manual by design — the rules
refuse to let an account promote itself.

**3. Seed the demo data**, so every list has something in it:

```bash
dart run tool/seed_sample_data.dart --email <your.admin>@lockinplayers.app --password <password>
```

That writes four students and ten questions, one deliberately unpublished so the
publish toggle has something to act on.

**4. Run the app.**

```bash
flutter run                # or: flutter run -d chrome / -d windows
```

Use a **phone or emulator** for the exam-proctoring shots — face detection is
mobile-only.

**Taking the shot:** Android emulator `Ctrl+S`; physical Android
`Power + Volume Down`; Windows `Win + Shift + S`; Chrome — use the OS snipping
tool, not DevTools, so the frame looks like the real app.

---

## A. Screenshots of implemented features

| # | File name | Screen | Path to get there | Must be visible |
|:--:|---|---|---|---|
| 1 | `01-welcome.png` | Welcome | Launch signed out | Both choices — "Yes, I have an account" and "No, I'm new here" |
| 2 | `02-onboarding-name.png` | Onboarding | Welcome → "No, I'm new here" | The name field with the animated helper |
| 3 | `03-register.png` | Register | Onboarding → age → next | The password field and its validation hint |
| 4 | `04-home-menu.png` | Home menu | Sign in as a student | The subject cards and the Exam section |
| 5 | `05-lesson-list.png` | English lessons | Home → English | Several of the 13 lessons with their subtitles |
| 6 | `06-game-in-play.png` | Any lesson game | Home → English → Nouns and Pronouns | Timer, hearts, level, the question, and the answer buttons |
| 7 | `07-correct-feedback.png` | Same game | Answer correctly | The correct-answer animation |
| 8 | `08-game-over.png` | Same game | Lose all hearts, or finish | The score summary popup |
| 9 | `09-exam-setup.png` | Exam mode | Home → Exam → All Subjects | The difficulty choices |
| 10 | `10-exam-proctored.png` | Exam mode | Start an exam **on a phone** | The exam question with the proctoring indicator active |
| 11 | `11-leave-warning.png` | Exam mode | Press Home, then return | The leave-warning overlay |
| 12 | `12-leaderboard.png` | Leaderboard | Home → Leaderboard | Several ranked entries with scores |
| 13 | `13-word-lookup.png` | Any lesson | Tap an underlined word in a question | The dictionary sheet over the question — definition, phonetic, example |
| 14 | `14-offline-banner.png` | Any admin screen | Turn Wi-Fi off | The offline strip with its message |

---

## B. CRUD screenshots

Sign in as an **admin** for all of these.

| # | File name | Operation | Path | Must be visible |
|:--:|---|---|---|---|
| 15 | `15-admin-dashboard.png` | — | Sign in as admin | The three stat cards (Questions, Accounts, From API) and the four action tiles |
| 16 | `16-create-form.png` | **CREATE** | Dashboard → Manage Questions → **+** | The filled-in form **with the live student preview visible** |
| 17 | `17-create-success.png` | **CREATE** | Tap "Create question" | The "Question created and published" confirmation |
| 18 | `18-read-list.png` | **READ** | Manage Questions | Several questions with subject, topic, level, and answer chips |
| 19 | `19-read-in-game.png` | **READ** | Play the lesson matching a question you created | **Your question being asked to a student** — this is the shot that proves the loop closes |
| 20 | `20-update-form.png` | **UPDATE** | Tap a question → change the answer | The editor with the changed value, before saving |
| 21 | `21-update-success.png` | **UPDATE** | Save | The "Question updated" confirmation |
| 22 | `22-delete-confirm.png` | **DELETE** | Trash icon on a row | The confirmation dialog **naming the question** |
| 23 | `23-delete-after.png` | **DELETE** | Confirm | The list with the row gone |
| 24 | `24-search-filter.png` | **SEARCH** | Type in the search box + tap a subject chip | The search text, the active chip, and the narrowed result set |
| 25 | `25-accounts-list.png` | **READ** | Dashboard → Manage Accounts | Several accounts with roles and status |
| 26 | `26-account-create.png` | **CREATE** | Manage Accounts → **+** | The new-account form filled in |
| 27 | `27-account-deactivate.png` | **DELETE** | Deactivate icon | The confirmation dialog explaining what deactivation does |
| 28 | `28-validation-errors.png` | **VALIDATION** | Submit the question form with an empty prompt and one wrong answer | The red messages painted under the offending fields |

**For shot 19** — create a question with topic `Nouns`, publish it, then go
Home → English → *Nouns and Pronouns* and play until it appears. Questions are
drawn at random, so it may take a few rounds. This single screenshot is the
strongest CRUD evidence you can produce.

---

## C. API testing screenshots and logs

| # | File name | What | Path | Must be visible |
|:--:|---|---|---|---|
| 29 | `29-api-console-idle.png` | Endpoints | Dashboard → **API Console** | The endpoint list with all four method badges — GET, POST, PATCH, DELETE |
| 30 | `30-api-console-running.png` | Loading state | Tap "Run all requests", shoot immediately | The spinner and the "Running: …" caption naming the current step |
| 31 | `31-api-console-summary.png` | Connection established | Wait for the run to finish | The "N succeeded" chip and the full list of result cards |
| 32 | `32-api-get.png` | **GET tested** | Expand a GET card | The URL and the JSON response body |
| 33 | `33-api-post.png` | **POST tested** | Expand the POST card | The typed-envelope request body **and** the response with `name` and `createTime` |
| 34 | `34-api-patch.png` | **PATCH tested** | Expand the PATCH card | The URL showing `updateMask.fieldPaths=…` and the response with a moved `updateTime` |
| 35 | `35-api-delete.png` | **DELETE tested** | Expand the DELETE card | HTTP 200 and the `{}` response |
| 36 | `36-api-error.png` | **Error handled** | Expand an "expected failure" card | The red badge and the plain-language message |
| 37 | `37-api-import.png` | Responses displayed | Dashboard → Import from Open Trivia DB → Fetch | The preview table — correct answers green, duplicates greyed out |
| 38 | `38-api-json-inspector.png` | JSON sample | Import screen → `{ }` in the app bar | The raw GET response and the last POST request/response |
| 39 | `39-api-offline.png` | Error handled | Turn Wi-Fi off → tap "Fetch questions" | The failure state **and its Try again button** |
| 40 | `40-api-auth.png` | Authorization | Sign in as a **student**, reach the API console | The 403 — proving the rules apply to REST calls, not just the SDK |

### API testing logs (Section F: "API Testing Screenshots/Logs")

Run the live smoke test and screenshot the terminal:

```bash
# no sign-in needed — the two key-less GET endpoints
dart run tool/api_smoke_test.dart --public-only

# the full lifecycle: GET → POST → PATCH → runQuery → DELETE
dart run tool/api_smoke_test.dart --email <your.admin>@lockinplayers.app --password <password>
```

- `41-smoke-test-terminal.png` — the terminal output, ideally framed on the
  PATCH and DELETE steps
- `docs/evidence/api-test-log.txt` — written automatically; attach the file

Also capture the unit tests:

```bash
flutter test test/api_client_test.dart test/firestore_rest_api_test.dart
```

- `42-api-unit-tests.png` — the terminal showing **36 tests passing**, with the
  PATCH and DELETE test names readable

---

## D. Database screenshots

From the [Firebase console](https://console.firebase.google.com) →
**Firestore Database**:

| # | File name | What | Must be visible |
|:--:|---|---|---|
| 43 | `43-db-collections.png` | Collection list | `users`, `quiz_questions`, `leaderboard_entries`, `exam_attempts`, `exam_sessions` |
| 44 | `44-db-question-doc.png` | One `quiz_questions` document | All fields expanded — `subject`, `topic`, `prompt`, `correctAnswer`, `choices` array, `minLevel`, `source`, `published`, `createdBy`, `createdAt`, `updatedAt` |
| 45 | `45-db-user-doc.png` | One `users` document | `role`, `disabled`, `firstName`, `lastName`, `age`, `highscore` |
| 46 | `46-db-subcollections.png` | `users/{uid}` subcollections | `game_logs` and `leave_attempts` |
| 47 | `47-db-rules.png` | Firestore → **Rules** tab | The `quiz_questions` block showing `allow create, update, delete: if isAdmin()` |
| 48 | `48-db-auth-users.png` | **Authentication → Users** | The account list, showing the seeded students |

**Tip for shot 44:** run the API console *first*, then screenshot a question the
importer created — it will carry `source: "openTrivia"`, which visibly ties the
database back to the API integration.

---

## E. Source code samples

Section F asks for "source code samples for key features". These files are the
ones worth showing — each is self-contained and demonstrates one requirement:

| Feature | File | Why this one |
|---|---|---|
| **CRUD** | [lib/services/question_repository.dart](../lib/services/question_repository.dart) | All four operations in one file, with the offline `_settle` deadline |
| **Validation** | [lib/models/quiz_question_record.dart](../lib/models/quiz_question_record.dart#L180) | `validate()` returning `field → message`, shared by every write path |
| **API — GET** | [lib/services/api/open_trivia_api.dart](../lib/services/api/open_trivia_api.dart#L156) | Query building, timeout, and the second failure channel |
| **API — POST/PATCH/DELETE** | [lib/services/api/firestore_rest_api.dart](../lib/services/api/firestore_rest_api.dart) | The whole authenticated write surface, one `_send` path |
| **Error handling** | [lib/services/api/api_exception.dart](../lib/services/api/api_exception.dart) | Every low-level failure mapped to a message a child can act on |
| **Routing** | [lib/app_gate.dart](../lib/app_gate.dart) | The five-way decision that makes one login screen serve everybody |
| **Security** | [firestore.rules](../firestore.rules) | Server-side role enforcement, including the self-promotion guard |
| **Tests** | [test/firestore_rest_api_test.dart](../test/firestore_rest_api_test.dart) | PATCH mask protection and DELETE guards |

Screenshot these with syntax highlighting from your editor — `49-code-*.png`
onward — or print the files to PDF.

---

## F. Sample data

Section E asks for "sample data available for testing". Point at:

- **`tool/seed_sample_data.dart`** — the script itself is the evidence. It
  documents exactly what demo data exists and can recreate it on any machine.
- **`50-seed-terminal.png`** — the terminal output of a seed run, showing the
  accounts created with their login credentials and the questions written.
- The seeded student logins, for the demo:

  | Student | Login | Password |
  |---|---|---|
  | Miguel Santos | `miguel.santos@lockinplayers.app` | `student123` |
  | Sofia Reyes | `sofia.reyes@lockinplayers.app` | `student123` |
  | Andres Bautista | `andres.bautista@lockinplayers.app` | `student123` |
  | Isabel Cruz | `isabel.cruz@lockinplayers.app` | `student123` |

  In the app these are entered as a **name and password**, not an email — the
  address is synthesised internally so Firebase's email/password provider can be
  used with credentials a child can remember.

Clean up afterwards with:

```bash
dart run tool/seed_sample_data.dart --email <admin> --password <password> --clean
```

---

## G. Live demonstration script

A 5-minute run that hits every requirement in order:

| Time | Do this | Requirement shown |
|---|---|---|
| 0:00 | Launch signed out. Show Welcome → register a student → onboarding → home. | UI, navigation, forms, validation |
| 1:00 | Play one English lesson. Answer right and wrong. Tap a word for its definition. | Core features, error feedback, API (dictionary GET) |
| 2:00 | Start an exam on a phone. Press Home and come back — show the warning. | Proctoring, core features |
| 2:45 | Sign out, sign in as admin. Land on the dashboard. | Role-based routing, security |
| 3:00 | Create a question. Show the live preview. Save. Edit it. Delete it. | **Full CRUD** |
| 4:00 | Import from Open Trivia DB — fetch, preview, publish. | API GET + POST |
| 4:30 | Open the API Console. Run all requests. Expand PATCH and DELETE. | **All four HTTP verbs**, responses displayed, errors handled |
| 5:00 | Turn Wi-Fi off. Show the offline banner and a queued write. | Offline resilience, error handling |

**Rehearse the offline step** — it is the most impressive and the most likely to
misbehave on unfamiliar Wi-Fi.

---

## Evidence checklist

- [ ] `docs/evidence/` created
- [ ] Security rules deployed
- [ ] Sample data seeded
- [ ] Shots 1–14 — implemented features
- [ ] Shots 15–28 — CRUD, including shot 19 (your question in a live game)
- [ ] Shots 29–42 — API testing, including PATCH and DELETE
- [ ] `docs/evidence/api-test-log.txt` generated
- [ ] Shots 43–48 — database
- [ ] Code samples captured or printed
- [ ] Shot 50 — seed terminal output
- [ ] Demonstration rehearsed once end to end
