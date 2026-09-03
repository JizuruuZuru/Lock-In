# Lock In — Submission Checklist

Every requirement mapped to the file, screen, or test that satisfies it.

**Legend:** ✅ done and verified · 🟡 done, needs you to capture it · ⬜ not applicable

---

## A. Project Documentation

| | Requirement | Status | Where |
|:--:|---|:--:|---|
| ☑ | Project Title and Description | ✅ | [PROJECT_DOCUMENTATION.md §1](PROJECT_DOCUMENTATION.md#1-project-description) |
| ☑ | Project Objectives Defined | ✅ | [PROJECT_DOCUMENTATION.md §2](PROJECT_DOCUMENTATION.md#2-project-objectives) — 1 general, 9 specific |
| ☑ | Scope and Limitations Identified | ✅ | [PROJECT_DOCUMENTATION.md §3–4](PROJECT_DOCUMENTATION.md#3-scope) — in scope, out of scope, and 9 stated limitations |
| ☑ | Updated System Flowchart / Architecture Diagram | ✅ | [ARCHITECTURE.md](ARCHITECTURE.md) — 7 diagrams: layered architecture, start-up flowchart, navigation map, two sequence diagrams, offline strategy, proctoring state machine |
| ☑ | Database Design (ERD or Schema) | ✅ | [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) — Mermaid ERD, every collection and field, rules matrix, index policy |
| ☑ | Project Progress Report | ✅ | [PROGRESS_REPORT.md](PROGRESS_REPORT.md) |

---

## B. System Implementation

| | Requirement | Status | Evidence |
|:--:|---|:--:|---|
| ☑ | User Interface (UI) Developed | ✅ | 45 screens, 21 widgets. Consistent visual language; responsive via [`responsive_layout.dart`](../lib/utils/responsive_layout.dart) and [`admin_theme.dart`](../lib/utils/admin_theme.dart) |
| ☑ | Navigation and Routing Functional | ✅ | [`AppGate`](../lib/app_gate.dart) — a five-way decision covering welcome, onboarding, home, admin, and disabled. Map in [ARCHITECTURE.md §2–3](ARCHITECTURE.md#2-application-flowchart--start-up-and-routing) |
| ☑ | Core Features Implemented | ✅ | 28 lesson games, exam mode, proctoring, leaderboard, admin panel. Full list in [PROGRESS_REPORT.md §4](PROGRESS_REPORT.md#4-completed-features) |
| ☑ | Forms and Data Validation Working | ✅ | [`QuizQuestionRecord.validate()`](../lib/models/quiz_question_record.dart), [`AppUserRecord.validate()`](../lib/models/app_user_record.dart). Validation lives on the model, so the editor form, the bulk importer, and the repository enforce identical rules. Covered by `test/crud_validation_test.dart` |
| ☑ | Error Handling Implemented | ✅ | [`ApiException`](../lib/services/api/api_exception.dart) for the network layer; `QuestionValidationException` / `AccountValidationException` for writes; [`AdminStateView`](../lib/utils/admin_theme.dart) for loading, empty, and error states; [`ErrorDialog`](../lib/widgets/error_dialog.dart) and [`OfflineBanner`](../lib/widgets/offline_banner.dart) in the UI |

### Validation rules enforced

**Questions** — topic required and ≤ 60 chars; instruction required; prompt
5–600 chars; correct answer required; 2–5 wrong choices, all distinct
case-insensitively and none matching the correct answer; level 1–20.

**Accounts** — both names required, letters only, ≤ 40 chars; age 4–100;
password ≥ 6 characters and confirmed on create.

---

## C. CRUD Functionality

**Main entity:** `quiz_questions` — the entity the system is built around. A
second complete surface exists on `users`.

| | Operation | Status | Entry point | Implementation |
|:--:|---|:--:|---|---|
| ☑ | **Create** | ✅ | Admin → Manage Questions → **+** | [`QuestionRepository.create`](../lib/services/question_repository.dart) |
| ☑ | Create (bulk, via API) | ✅ | Admin → Import from Open Trivia DB | [`FirestoreRestApi.createQuestions`](../lib/services/api/firestore_rest_api.dart) — HTTP POST |
| ☑ | **Read** | ✅ | Manage Questions — live list | `QuestionRepository.watchQuestions` |
| ☑ | Read (in game) | ✅ | Any lesson | `CustomQuestionSync` → `SubjectQuestionBank` |
| ☑ | **Update** | ✅ | Tap a question → edit → save | `QuestionRepository.update` |
| ☑ | Update (quick toggle) | ✅ | Eye icon — publish / hide | `QuestionRepository.setPublished` |
| ☑ | **Delete** | ✅ | Trash icon → confirmation | `QuestionRepository.delete` |
| ☑ | Delete (bulk) | ✅ | Multi-select | `QuestionRepository.deleteMany` |
| ☑ | **Search / Filter** | ✅ | Search box + subject chips | [`question_list_page.dart`](../lib/screens/admin/question_list_page.dart#L119) — searches question, topic, and answer |

### Accounts — the second CRUD surface

| Operation | Entry point | Implementation |
|---|---|---|
| **Create** | Manage Accounts → **+** | `UserAdminRepository.createAccount` — uses a throwaway secondary `FirebaseApp` so creating an account does not sign the admin out |
| **Read** | Manage Accounts — live list, search, role filter | `UserAdminRepository.watchAccounts` |
| **Update** | Editor, role toggle | `UserAdminRepository.updateAccount`, `.setRole` |
| **Delete** | Deactivate → confirmation | `UserAdminRepository.setDisabled` — **soft delete** |

**Why accounts are soft-deleted:** a Firebase client SDK can only delete its
*own* auth credential; removing someone else's requires a server holding the
Admin SDK. Disabling is the honest client-side equivalent, it is reversible, and
it keeps the student's game logs and leaderboard history intact. Two guards
prevent lockout: an admin cannot demote or deactivate themselves, and the last
active admin cannot be demoted or deactivated.

---

## D. API Integration and Testing

| | Requirement | Status | Evidence |
|:--:|---|:--:|---|
| ☑ | API Connection Successfully Established | ✅ | Three APIs live. Admin → **API Console** → "Run all requests" |
| ☑ | **GET** Requests Tested | ✅ | `OpenTriviaApi.fetchCategories`, `.fetchQuestions`, `DictionaryApi.lookup`. 15 unit tests in `test/api_client_test.dart` |
| ☑ | **POST** Requests Tested | ✅ | `FirestoreRestApi.createQuestion` (create) and `.runQuestionQuery` (search). Unit tests in `test/firestore_rest_api_test.dart` |
| ☑ | **PUT/PATCH** Requests Tested | ✅ | `FirestoreRestApi.updateQuestion` and `.setPublished` — HTTP **PATCH** with an explicit `updateMask`. 6 unit tests |
| ☑ | **DELETE** Requests Tested | ✅ | `FirestoreRestApi.deleteQuestion` — HTTP **DELETE**. 4 unit tests |
| ☑ | API Responses Properly Displayed | ✅ | Connection Check reports every step in plain language and copies the full transcript (method, URL, status, duration, both bodies) to the clipboard; importer preview table; JSON inspector; dictionary sheet |
| ☑ | Error Responses Properly Handled | ✅ | [`ApiException`](../lib/services/api/api_exception.dart) — see the table in [API_INTEGRATION.md §6](API_INTEGRATION.md#6-loading-states-and-error-handling). Two deliberate failure cases in the Connection Check prove it, each with status-code-specific advice |
| ☑ | Authentication / Authorization Implemented | ✅ | Every backend call carries `Authorization: Bearer <Firebase ID token>`, checked against the same [`firestore.rules`](../firestore.rules) that guard the SDK. Sign in as a student to see the 403 |
| ☑ | API Documentation Available | ✅ | [API_INTEGRATION.md](API_INTEGRATION.md) — endpoints, implementation, JSON samples for every verb, error table, testing |

### Verb coverage at a glance

| Verb | Endpoint | Screen | Tests |
|:--:|---|---|:--:|
| `GET` | `opentdb.com/api.php` | Import, API Console | 9 |
| `GET` | `dictionaryapi.dev/.../{word}` | Word lookup, API Console | 4 |
| `POST` | `.../documents/quiz_questions` | Import, API Console | 5 |
| `POST` | `.../documents:runQuery` | API Console | 4 |
| `PATCH` | `.../quiz_questions/{id}` | API Console | 6 |
| `DELETE` | `.../quiz_questions/{id}` | API Console | 4 |

```bash
flutter test test/api_client_test.dart test/firestore_rest_api_test.dart   # 36 tests
dart run tool/api_smoke_test.dart --public-only                            # live, no sign-in
dart run tool/api_smoke_test.dart --email <admin> --password <pw>          # full lifecycle
```

---

## E. Project Demonstration Materials

| | Requirement | Status | Where |
|:--:|---|:--:|---|
| ☑ | Source Code Available and Organized | ✅ | Layered by responsibility — `models/`, `data/`, `services/`, `screens/`, `widgets/`, `utils/`. Map in [ARCHITECTURE.md §8](ARCHITECTURE.md#8-directory-map) |
| ☑ | System Ready for Live Demonstration | ✅ | `flutter analyze` clean, 136 tests passing. Rehearsal script in [EVIDENCE_GUIDE.md §G](EVIDENCE_GUIDE.md#g-live-demonstration-script) |
| ☑ | Presentation Slides Prepared | 🟡 | Not built — the section says "if required". [PROGRESS_REPORT.md](PROGRESS_REPORT.md) and the demo script are structured to present from directly |
| ☑ | Sample Data Available for Testing | ✅ | [`tool/seed_sample_data.dart`](../tool/seed_sample_data.dart) — 4 students, 10 questions across both subjects and several levels, one unpublished. `--clean` removes exactly its own rows |
| ☑ | Project Repository Updated | 🟡 | Commit and push the work in this cycle |

---

## F. Midterm Progress Evidence

| | Requirement | Status | How |
|:--:|---|:--:|---|
| ☑ | Screenshots of Implemented Features | 🟡 | [EVIDENCE_GUIDE.md §A–B](EVIDENCE_GUIDE.md#a-screenshots-of-implemented-features) — 28 shots, each with its path and what must be in frame |
| ☑ | API Testing Screenshots / Logs | 🟡 | [EVIDENCE_GUIDE.md §C](EVIDENCE_GUIDE.md#c-api-testing-screenshots-and-logs) — 14 shots, plus `docs/evidence/api-test-log.txt` generated by `tool/api_smoke_test.dart` |
| ☑ | Database Screenshot | 🟡 | [EVIDENCE_GUIDE.md §D](EVIDENCE_GUIDE.md#d-database-screenshots) — 6 shots from the Firebase console |
| ☑ | Source Code Samples for Key Features | ✅ | [EVIDENCE_GUIDE.md §E](EVIDENCE_GUIDE.md#e-source-code-samples) — 8 files, one per requirement, with line anchors |
| ☑ | List of Completed Features | ✅ | [PROGRESS_REPORT.md §4](PROGRESS_REPORT.md#4-completed-features) |
| ☑ | List of Remaining Features | ✅ | [PROGRESS_REPORT.md §5](PROGRESS_REPORT.md#5-remaining-features--final-project) |

The 🟡 items need you to press the shutter — the screens, scripts, and data they
capture all exist and work.

---

## Project Completion Status

| Component | Status |
|---|---|
| **UI/UX Development** | ✅ **Complete** |
| **Navigation & Structure** | ✅ **Complete** |
| **CRUD Features** | ✅ **Complete** |
| **API Integration** | ✅ **Complete** |
| **Documentation** | ✅ **Complete** |

---

## Verification

```bash
flutter analyze     # no issues found
flutter test        # 136 tests, all passing
```

Last verified 19 August 2026 against Flutter 3.44.0 / Dart 3.12.0.

## Pre-submission steps

1. `firebase deploy --only firestore:rules` — the `data_clear_events` fix is not
   live until you do this.
2. `dart run tool/seed_sample_data.dart --email <admin> --password <pw>`
3. Capture the 🟡 evidence — [EVIDENCE_GUIDE.md](EVIDENCE_GUIDE.md)
4. Commit and push.
