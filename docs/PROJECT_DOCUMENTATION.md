# Lock In — Project Documentation

**Midterm Progress Submission**

| | |
|---|---|
| **Project title** | Lock In — a proctored quiz and brain-training app for elementary learners |
| **Repository** | `benchmark` (Flutter) — https://github.com/JizuruuZuru/Lock-In |
| **Platform** | Flutter 3.44 / Dart 3.12 — Android, iOS, Web, Windows, macOS, Linux |
| **Backend** | Firebase Authentication + Cloud Firestore (project `benchmark-14acf`) |
| **Document date** | 19 August 2026 |

---

## 1. Project description

Lock In is a cross-platform learning app that turns elementary English, Math,
and Science practice into short, timed games, and gives the teacher a back
office to steer what is being asked.

It has two audiences and two faces:

**For students** — 28 lesson games across three subjects, each drawing from a
question bank of 5,809 hand-written English and Science questions plus
procedurally generated Math problems. Every game runs on the same loop: a
countdown timer, a hearts system, levels that unlock harder material, and
immediate feedback with sound and animation. On top of the lessons sits an
**Exam mode** — a mixed-subject test with three difficulties that can be
proctored: the front camera watches that a face is present and looking at the
screen, and leaving the app is detected, warned about, and logged.

**For teachers** — an admin panel behind a role check that manages the two data
entities the system is built on. Teachers write, edit, publish, hide, and delete
quiz questions; those questions flow straight into the student games without an
app restart. They also manage the accounts themselves: create students, correct
names and ages, promote another admin, or deactivate an account. Questions can
be bulk-imported from an external trivia API instead of typed by hand, and an
API console lets the whole HTTP surface be exercised and inspected in the app.

The app is built to keep working on a bad school connection. Firestore
persistence is switched on for every platform, teacher-written questions are
mirrored into an on-device cache, and admin writes made offline are queued and
reported honestly rather than left spinning.

---

## 2. Project objectives

### General objective

To build a working, database-backed learning application that gives elementary
students structured subject practice and gives their teacher direct control over
the questions they are asked — without either side needing a reliable internet
connection.

### Specific objectives

1. **Deliver subject practice as short games.** Cover elementary English, Math,
   and Science as separate topic-level lessons rather than one undifferentiated
   quiz, so a teacher can point a student at a specific weakness.
2. **Give the content to the teacher.** Make the question bank editable from
   inside the app through complete Create, Read, Update, and Delete operations,
   so the app's content is not frozen at build time.
3. **Persist everything to a real database.** Store accounts, questions,
   scores, game history, and exam attempts in Cloud Firestore, so progress
   survives reinstalls and is visible across devices.
4. **Enforce access on the server, not just in the UI.** Use Firebase Auth plus
   Firestore security rules so the admin screens cannot be bypassed by talking
   to the database directly.
5. **Integrate external APIs usefully.** Consume third-party HTTP APIs where
   they do real work — bulk question import and in-game word definitions —
   rather than as a bolt-on demonstration.
6. **Exercise the full HTTP surface.** Read and write the project's own backend
   over plain HTTPS with GET, POST, PATCH, and DELETE, with authentication,
   loading states, and error handling on every call.
7. **Discourage cheating during exams.** Detect and log leaving the app and the
   student's face leaving the camera, with escalating warnings.
8. **Survive a poor connection.** Keep the app playable and the admin panel
   writable while offline, and tell the user plainly which state they are in.
9. **Make failure legible.** Turn every network, validation, and permission
   failure into a message a child or teacher can act on, never a raw exception.

---

## 3. Scope

### In scope — built and working

| Area | What it covers |
|---|---|
| **Subjects** | English (13 lessons), Math (9 lessons), Science (6 lessons) |
| **Question bank** | 5,809 bundled English and Science questions; Math generated at run time; unlimited teacher-authored questions |
| **Exam mode** | 3 difficulties × 4 subject selections, mixed-subject question draw, hearts, timer, levels |
| **Proctoring** | Front-camera face presence and orientation checks, app-leave detection, warning overlays, per-attempt logging |
| **Accounts** | Name-and-password registration, anonymous play, optional Google account linking, onboarding, soft-delete |
| **Roles** | Student and Admin, enforced in the UI *and* in Firestore security rules |
| **Admin panel** | Dashboard with live stats, question CRUD, account CRUD, trivia importer, API console |
| **CRUD entity** | `quiz_questions` — full create, read, update, delete, plus search and subject filter |
| **Second CRUD surface** | `users` — full create, read, update, soft-delete, plus search and role filter |
| **External APIs** | Open Trivia Database (GET), Free Dictionary API (GET), Cloud Firestore REST API (GET-equivalent read via runQuery POST, plus POST, PATCH, DELETE) |
| **Offline** | Firestore persistence, `shared_preferences` question mirror, queued writes, offline banners |
| **Accessibility aids** | Text-to-speech, tap-a-word dictionary lookup, brightness overlay, responsive layouts |

### Out of scope — deliberately not built

| Not built | Why |
|---|---|
| **Teacher-facing analytics dashboards** | Attempt data is being written now (`exam_attempts`, `game_logs`); reporting on it is scheduled for the final phase. |
| **Class or section grouping** | Accounts are flat. Grouping students into classes needs a data model decision that is not needed for the midterm scope. |
| **Hard-deleting an account** | The Firebase client SDK can only delete *its own* credential. Removing someone else's requires a server holding the Admin SDK, which this project does not deploy. Accounts are soft-deleted (`disabled: true`) instead. |
| **Push notifications** | No reminder or assignment flow exists yet, so there is nothing to notify about. |
| **Multiplayer or live classroom mode** | Every session is single-player; real-time co-play is a different architecture. |
| **Server-side question generation with AI** | The bundled bank plus the trivia importer already cover the content need. |
| **Paid or key-holding APIs** | Both third-party APIs used are free and key-less, so the project can be cloned and run by anyone. |

---

## 4. Limitations

These are honest constraints of the current build, not oversights:

1. **The first admin must be promoted by hand.** The security rules deliberately
   refuse to let an account grant itself the admin role — otherwise any student
   could. So exactly one manual step is required: register in the app, then set
   `role: "admin"` on that user document in the Firebase console. Every later
   admin is promoted from inside the app.

2. **Account deletion is a soft delete.** As above — a client SDK cannot remove
   another person's auth credential. `disabled: true` blocks sign-in at the gate
   and is reversible, and it keeps the student's game history and leaderboard
   place intact.

3. **Google sign-in needs project configuration that is not committed.**
   `android/app/google-services.json` currently carries an empty `oauth_client`
   array, so the "Connect with Google" button reports *"Google sign-in is not
   set up for this app yet"* rather than failing obscurely. Enabling it needs
   the Google provider switched on and a SHA-1 fingerprint registered — see the
   [README](../README.md).

4. **Face proctoring is mobile-only.** It depends on `google_mlkit_face_detection`
   and a front camera. On Windows, Linux, and the web the app falls back to a
   stub implementation and the exam runs unproctored. The app-leave detector
   still works everywhere.

5. **Open Trivia DB rate-limits to one request every 5 seconds** per IP and its
   questions are general-knowledge, not curriculum-aligned. Imported questions
   therefore need a teacher's eye before publishing, which is why the importer
   previews them with checkboxes rather than saving everything it fetches.

6. **The Free Dictionary API defines words at adult reading level.** A
   definition is shown as-is; it is not simplified for a young reader.

7. **Firestore queries filter on one equality field only.** Sorting and
   multi-field filtering are done client-side, deliberately, so the project
   needs no composite indexes and can be deployed from a clean Firebase project.
   This is fine at classroom scale and would need revisiting at thousands of
   questions.

8. **Offline writes are queued, not confirmed.** A question written with no
   connection is durable on the device and syncs on reconnect, but it cannot be
   server-validated until then. The UI says so rather than implying success.

9. **No automated UI tests.** Coverage is at the unit level — 136 tests over
   models, validation, the question bank, the offline cache, and the whole HTTP
   layer. Widget and integration tests are listed as remaining work.

---

## 5. Technology stack

| Layer | Choice | Why |
|---|---|---|
| **UI** | Flutter 3.44, Material 3, `google_fonts` | One codebase across the six platforms the school might use |
| **State** | `StatefulWidget` + `provider` | The app is screen-local; a heavier state solution would add ceremony without benefit |
| **Auth** | `firebase_auth` 6.1 | Anonymous, email/password (behind a name-based credential), and Google linking in one SDK |
| **Database** | `cloud_firestore` 6.1 | Live listeners drive the admin lists; built-in offline persistence covers the connectivity requirement |
| **HTTP** | `http` 1.2 | Direct control over requests for the REST integration, and `MockClient` makes the whole layer testable |
| **Local cache** | `shared_preferences` 2.3 | A plain JSON mirror of published questions that survives Firestore evicting its own cache |
| **Proctoring** | `camera`, `google_mlkit_face_detection`, `permission_handler` | On-device face detection with no image ever leaving the phone |
| **Media** | `audioplayers`, `flutter_tts` | Sound feedback and spoken prompts for the spelling game |
| **Connectivity** | `connectivity_plus` 6.1 | Drives the offline banners |

---

## 6. Companion documents

| Document | Covers |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | System flowchart, navigation map, layered architecture, data-flow diagrams |
| [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) | ERD, every collection and field, security rules, indexes |
| [API_INTEGRATION.md](API_INTEGRATION.md) | All three APIs, every verb, request/response samples, error handling |
| [PROGRESS_REPORT.md](PROGRESS_REPORT.md) | Current accomplishments, completed and remaining feature lists, completion status |
| [EVIDENCE_GUIDE.md](EVIDENCE_GUIDE.md) | How to capture every required screenshot and log |
| [SUBMISSION_CHECKLIST.md](SUBMISSION_CHECKLIST.md) | Each requirement mapped to the file, screen, or test that satisfies it |
| [../README.md](../README.md) | Setup, run, and first-admin instructions |
