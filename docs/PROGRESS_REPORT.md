# Lock In — Midterm Progress Report

**Date:** 19 August 2026
**Repository:** https://github.com/JizuruuZuru/Lock-In (branch `main`)

---

## 1. Completion status

| Component | Status | Notes |
|---|:---:|---|
| **UI/UX Development** | ✅ **Complete** | 45 screens and 21 reusable widgets. Consistent visual language across student and admin areas; responsive layouts for phone, tablet, and desktop. |
| **Navigation & Structure** | ✅ **Complete** | `AppGate` is a single routing decision point covering all five destinations. Every screen reachable, back navigation correct, no dead ends. |
| **CRUD Features** | ✅ **Complete** | Full create / read / update / delete on `quiz_questions`, plus a second complete surface on `users`. Search and filter on both. |
| **API Integration** | ✅ **Complete** | Three APIs, four HTTP verbs, authenticated, error-handled, with 36 unit tests and a live smoke-test script. |
| **Documentation** | ✅ **Complete** | Seven documents covering objectives, scope, architecture, schema, API, evidence, and this report. |
| **Testing** | 🟡 **In progress** | 136 unit tests passing. Widget and integration tests not yet written. |
| **Teacher analytics** | ⬜ **Not started** | Attempt data is being written; the reporting screens are final-phase work. |

**Overall: the midterm scope is complete and demonstrable.** Everything the
submission asks for is implemented, running, and covered by evidence. Remaining
work is listed in §5 and belongs to the final project rather than this
milestone.

---

## 2. Current accomplishments

### 2.1 Scale of what exists

| Measure | Count |
|---|---|
| Dart source files in `lib/` | 120 |
| Lines of Dart in `lib/` | 106,117 |
| Screens | 45 |
| Reusable widgets | 21 |
| Services | 23 |
| Playable lesson games | 28 (English 13, Math 9, Science 6) |
| Exam configurations | 12 (3 difficulties × 4 subject selections) |
| Bundled questions | 5,793 (English 2,953 · Science 2,840) across 18 topic files |
| Firestore collections | 5 top-level + 3 subcollections |
| Automated tests | 136, all passing |

### 2.2 Student experience — complete

- **28 lesson games** across three subjects, each topic-scoped so a teacher can
  target a specific weakness rather than assigning "English".
- **A shared game loop** — countdown timer, hearts, level progression, correct
  and incorrect animations, sound feedback, and a game-over summary — so every
  lesson behaves the same way and a student learns the interface once.
- **Exam mode** with three difficulties and any combination of subjects, drawing
  a mixed question set and logging every individual answer.
- **Proctoring**: on-device face detection (presence and orientation) plus
  app-leave detection, with escalating warning overlays and per-violation
  logging. No camera image ever leaves the device.
- **Leaderboard** with per-game personal bests.
- **Accessibility aids**: text-to-speech for the spelling game, tap-any-word
  dictionary lookup inside questions, and a brightness overlay.

### 2.3 Teacher experience — complete

- **Admin dashboard** with live counts of questions, accounts, and
  API-sourced questions.
- **Question management** — create, read, update, delete, publish/hide, with
  search, subject filter, topic autocomplete drawn from topics already in use,
  and a live preview showing exactly what the student will see, shuffled the way
  the game shuffles.
- **Account management** — create real loginable accounts, edit names and ages,
  promote another admin, deactivate an account, with search and role filter.
- **Bulk import** from Open Trivia DB with duplicate detection, difficulty →
  level mapping, and a preview table with checkboxes.
- **API console** exercising the entire HTTP surface with full request and
  response inspection.

### 2.4 Data and access control — complete

- Two fully modelled entities with validation on the model, so the editor form,
  the bulk importer, and the repository all enforce identical rules.
- Security rules that mirror the UI's role check on the server, including two
  lockout guards: an admin cannot demote or deactivate themselves, and the last
  active admin cannot be demoted or deactivated.
- Soft delete for accounts, preserving game history and leaderboard place.
- Audit stamps (`createdBy`, `createdAt`, `updatedAt`) that an update cannot
  overwrite, enforced through the PATCH update mask.

### 2.5 Offline resilience — complete

Three independent layers, so no single failure removes the questions:
Firestore persistence enabled on every platform, a `shared_preferences` JSON
mirror of every published question, and a cache-first load that puts questions
in the bank on the first frame. Admin writes made offline are queued and
reported as *"Saved on this device. It will sync when you are back online."*
rather than hanging or lying.

---

## 3. Work completed in this submission cycle

Five items were added or fixed for the midterm submission:

### 3.1 PATCH and DELETE over HTTP — new

`FirestoreRestApi` previously implemented only POST. Update and delete went
through the Firestore SDK, so the HTTP surface was incomplete. Added:

- `updateQuestion` — HTTP **PATCH** with an explicit `updateMask`, which is what
  keeps `createdAt` and `createdBy` from being rewritten by an edit.
- `setPublished` — HTTP **PATCH** with a two-field mask, so toggling visibility
  does not rewrite the question text.
- `deleteQuestion` — HTTP **DELETE**, with an empty-id guard so a malformed call
  cannot address the collection path instead of a document.
- A single `_send` path shared by POST, PATCH, and DELETE, so authentication,
  timeouts, and status handling cannot drift apart between verbs.

### 3.2 Dead code revived — `runQuestionQuery`

The structured-search method existed and its comment claimed the admin question
browser used it, but nothing called it. It is now driven by the API console, and
returns the exchange alongside the rows so the console can display it. The
misleading comment was corrected.

### 3.3 API Console screen — new

`lib/screens/admin/api_console_page.dart`. Runs every endpoint the app uses in
order — GET, POST, PATCH, runQuery, DELETE — against one throwaway document that
it deletes at the end, and shows each exchange as an expandable card with method
badge, URL, status, duration, and copyable request and response bodies. Includes
two deliberate failure cases so the error paths are visible too.

This turns "API responses properly displayed" and "error responses properly
handled" from something spread across several screens into a single capturable
view.

### 3.4 Command-line tooling — new

- `tool/api_smoke_test.dart` — signs in through the Firebase Auth REST API and
  runs the full lifecycle against the live backend, printing every exchange and
  writing a transcript to `docs/evidence/api-test-log.txt`. A `--public-only`
  mode demonstrates the two key-less GET endpoints with no sign-in.
- `tool/seed_sample_data.dart` — creates four demo students and ten questions
  spread across both subjects and several levels, one deliberately unpublished
  so the publish toggle has something to act on. Every row it writes carries
  `seedTag: "sample-data"`, so `--clean` removes exactly its own and nothing
  else.
- `tool/lock_in_rest.dart` — shared plumbing. Reads the project id from
  `firebase.json` and the API key from `firebase_options.dart` at run time, so
  there is one source of truth rather than duplicated config.

### 3.5 Defect found and fixed — `data_clear_events`

Mapping the schema surfaced a real bug. The profile screen's **"Clear data"**
button writes to `users/{uid}/data_clear_events`, but `firestore.rules` had no
match block for that subcollection. Firestore rules do not cascade to
subcollections, so the write was denied, the un-caught rejection threw, and
everything after it — the profile update and the confirmation message — never
ran. The button silently did nothing.

Fixed by adding a rules block matching the existing `game_logs` /
`leave_attempts` pattern. Requires `firebase deploy --only firestore:rules` to
take effect.

### 3.6 Documentation corrected

The previous `docs/CRUD_AND_API.md` claimed the app bundles "78,000 questions".
The actual count is **5,793**, verified by counting the question literals across
all 18 topic files. The figure is corrected throughout, and every count in these
documents was measured rather than estimated.

---

## 4. Completed features

### Authentication and accounts
- [x] Welcome screen routing new and returning players
- [x] Name-and-password registration (no email required from the child)
- [x] Login with the same name-based credential
- [x] Anonymous / guest play
- [x] Two-step onboarding (name → age) that resumes where it stopped
- [x] Optional Google account linking, keeping the same uid and all progress
- [x] Terms acceptance
- [x] Role-based routing to student or admin on a single sign-in path
- [x] Disabled-account gate with an explanation

### Student features
- [x] Home menu with subject and exam sections
- [x] 13 English lesson games
- [x] 9 Math lesson games
- [x] 6 Science lesson games
- [x] Exam mode — 3 difficulties × 4 subject selections
- [x] Difficulty selection per game where applicable
- [x] Hearts, timer, levels, and level-up celebration
- [x] Correct / incorrect animation and sound feedback
- [x] Game-over summary with score
- [x] Leaderboard with per-game personal bests
- [x] Profile with history and a clear-data action
- [x] Tap-any-word dictionary lookup inside questions
- [x] Text-to-speech for spelling
- [x] Face-presence proctoring (mobile)
- [x] App-leave detection, warning, and logging
- [x] Offline play from the on-device question cache

### Admin features
- [x] Dashboard with live stats
- [x] Question **create** with validation and live student preview
- [x] Question **read** — live list with search and subject filter
- [x] Question **update**, including a quick publish/hide toggle
- [x] Question **delete** with a naming confirmation dialog
- [x] Bulk delete (multi-select)
- [x] Account **create** — real, loginable, without logging the admin out
- [x] Account **read** — live list with search and role filter
- [x] Account **update** — names, age, role
- [x] Account **soft delete** (deactivate) with confirmation
- [x] Lockout guards — cannot demote or deactivate yourself or the last admin
- [x] Bulk import from Open Trivia DB with duplicate detection
- [x] API console covering GET, POST, PATCH, DELETE
- [x] JSON inspector for raw request and response
- [x] Offline banner on every admin screen

### Platform and data
- [x] Firestore persistence on every platform
- [x] On-device question cache surviving Firestore cache eviction
- [x] Queued offline writes with honest status reporting
- [x] Server-side security rules mirroring the UI role check
- [x] Validation shared by every write path
- [x] One error type for the whole API layer
- [x] 136 automated tests

---

## 5. Remaining features — final project

### High priority
- [ ] **Teacher analytics** — per-student and per-topic performance drawn from
      `exam_attempts` and `game_logs`. The data is already being written; only
      the reporting screens are missing.
- [ ] **Class / section grouping** so a teacher sees their own students rather
      than every account.
- [ ] **Assignment flow** — set a lesson or exam for a class, with a due date.
- [ ] **Widget and integration tests** covering the CRUD screens and the exam
      flow end to end.

### Medium priority
- [ ] **Question import from CSV** for teachers who already keep banks in a
      spreadsheet.
- [ ] **Bulk edit** — retag or re-level several questions at once.
- [ ] **Question difficulty auto-tuning** from real answer statistics rather
      than the imported label.
- [ ] **Google sign-in fully configured** — enable the provider and register the
      SHA-1 fingerprints (see [README](../README.md)).
- [ ] **Hard account deletion** via a Cloud Function holding the Admin SDK,
      replacing the current soft delete.
- [ ] **Proctoring review screen** so a teacher can see violations in context
      rather than as a counter.

### Lower priority
- [ ] Localisation (Filipino / English toggle)
- [ ] Achievements and badges
- [ ] Parent-facing progress summary
- [ ] Composite indexes and server-side sorting, if the bank outgrows
      client-side sorting
- [ ] Dark mode

---

## 6. Verification

Everything claimed above was checked, not assumed:

```bash
flutter analyze                 # no issues
flutter test                    # 136 tests, all passing
dart run tool/api_smoke_test.dart --public-only   # live GET calls, 200 and 404
```

Last run: 19 August 2026. `flutter analyze` reports no issues across `lib/`,
`test/`, and `tool/`.

---

## 7. Risks and mitigations

| Risk | Mitigation |
|---|---|
| **Open Trivia DB rate-limits or goes down mid-demo** | The importer degrades to a clear "wait a few seconds" message with a retry button. Sample data is already seeded, so the demo does not depend on a live import. |
| **No connection at the venue** | The app is built for this — bundled questions need no network at all, and the on-device cache carries teacher questions. Only the import and API console screens genuinely require a connection, and both say so. |
| **Face proctoring unavailable on the demo device** | It is mobile-only by design and falls back to a stub. Run the exam demo on a phone; the leave detector works everywhere. |
| **Admin account locked out** | Two guards prevent it in-app. Recovery is a one-field edit in the Firebase console. |
| **Rules changes not deployed** | The `data_clear_events` fix needs `firebase deploy --only firestore:rules`. Listed as a pre-demo step in the [README](../README.md). |
