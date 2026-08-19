# Lock In — System Architecture & Flowcharts

Diagrams are written in Mermaid, which GitHub renders inline. To export one as
an image for a slide deck, paste the fenced block into https://mermaid.live.

---

## 1. System architecture (layered)

```mermaid
flowchart TB
    subgraph client["Flutter client — lib/"]
        direction TB

        subgraph ui["Presentation — screens/ + widgets/"]
            gate["AppGate<br/><i>single entry decision point</i>"]
            auth["Auth screens<br/>welcome · login · register · onboarding"]
            student["Student screens<br/>home menu · 28 lesson games · exam · leaderboard"]
            admin["Admin screens<br/>dashboard · questions · accounts · import · API console"]
            shared["Shared widgets<br/>timer · hearts · dialogs · offline banner · overlays"]
        end

        subgraph domain["Domain — models/ + data/"]
            models["QuizQuestionRecord<br/>AppUserRecord<br/><i>validation lives here</i>"]
            bank["SubjectQuestionBank<br/><i>5,793 bundled + teacher questions</i>"]
        end

        subgraph svc["Services — services/"]
            repos["QuestionRepository<br/>UserAdminRepository<br/><i>CRUD via Firestore SDK</i>"]
            apis["services/api/<br/>OpenTriviaApi · DictionaryApi<br/>FirestoreRestApi"]
            sync["CustomQuestionSync<br/>LocalQuestionCache"]
            support["SoundService · TTS · Connectivity<br/>FaceProctor · GameLogger · Leaderboard"]
        end
    end

    subgraph external["External services"]
        fbauth["Firebase Authentication"]
        fs["Cloud Firestore<br/><i>+ security rules</i>"]
        otdb["Open Trivia DB<br/>opentdb.com"]
        dict["Free Dictionary API<br/>dictionaryapi.dev"]
        rest["Firestore REST API<br/>firestore.googleapis.com"]
    end

    ui --> domain
    ui --> svc
    domain --> svc
    repos --> fs
    sync --> fs
    support --> fs
    gate --> fbauth
    auth --> fbauth
    apis --> otdb
    apis --> dict
    apis --> rest
    rest -.->|"same rules,<br/>same data"| fs

    classDef layer fill:#EDE7FB,stroke:#2B1B4D,stroke-width:2px
    classDef ext fill:#FFF0E0,stroke:#8A4B00,stroke-width:2px
    class ui,domain,svc layer
    class fbauth,fs,otdb,dict,rest ext
```

**Why it is shaped this way.** Validation lives on the models, so the editor
form, the bulk importer, and the repository all enforce identical rules — a bad
question cannot be persisted regardless of which screen calls in. The API layer
is isolated behind one exception type (`ApiException`), so the UI has a single
error shape to render. And the REST client writes to the same collection the SDK
repository does, carrying the caller's ID token, so REST-created and
SDK-created questions are indistinguishable to the rest of the app.

---

## 2. Application flowchart — start-up and routing

`AppGate` (`lib/app_gate.dart`) is the single decision point. Every sign-in and
sign-out routes back through it, which is why there is one login screen for
everybody: the gate reads the account's role after authentication and sends an
admin to the panel and a student to the games.

```mermaid
flowchart TD
    start(["App launch<br/>main.dart"]) --> init["Firebase.initializeApp<br/>+ Firestore persistence ON"]
    init --> gate{"AppGate<br/>anybody signed in?"}

    gate -->|"no"| welcome["WelcomePage<br/><i>Do you already have an account?</i>"]
    welcome -->|"Yes, I have one"| login["LoginPage"]
    welcome -->|"No, I'm new"| onboard["PlayerOnboardingPage<br/>name → age"]
    onboard --> register["RegisterScreen<br/>set a password"]
    register --> google["ConnectGooglePage<br/><i>optional, skippable</i>"]
    google --> gate
    login --> gate

    gate -->|"yes"| sync["Start CustomQuestionSync<br/><i>cache first, then live listener</i>"]
    sync --> profile["Read users/{uid}"]

    profile --> offline{"Firestore<br/>reachable?"}
    offline -->|"no — offline"| home
    offline -->|"yes"| disabled{"disabled == true?"}

    disabled -->|"yes"| blocked["Sign out<br/>'Account unavailable'"]
    blocked --> welcome
    disabled -->|"no"| role{"role == 'admin'?"}

    role -->|"yes"| dash["AdminDashboardPage"]
    role -->|"no"| complete{"profile complete?"}
    complete -->|"no"| onboard
    complete -->|"yes"| home["HomeMenu"]

    home --> pick{"What now?"}
    pick -->|"Lessons"| subject["Pick subject →<br/>pick lesson → play"]
    pick -->|"Exam"| exam["Pick subjects →<br/>pick difficulty → proctored exam"]
    pick -->|"Leaderboard"| board["LeaderboardScreen"]
    pick -->|"Profile"| prof["Profile · history · Connect Google"]

    dash --> adminpick{"Admin action"}
    adminpick -->|"Manage Questions"| qcrud["Question list → editor<br/><i>create · read · update · delete</i>"]
    adminpick -->|"Manage Accounts"| acrud["Account list → editor<br/><i>create · read · update · disable</i>"]
    adminpick -->|"Import"| import["Trivia importer<br/><i>GET → preview → POST</i>"]
    adminpick -->|"API Console"| console["API console<br/><i>GET · POST · PATCH · DELETE</i>"]

    classDef entry fill:#D6F5D6,stroke:#2F5233,stroke-width:2px
    classDef adminNode fill:#EDE7FB,stroke:#6A3FC4,stroke-width:2px
    classDef danger fill:#FFE0E0,stroke:#8B0000,stroke-width:2px
    class start,welcome entry
    class dash,qcrud,acrud,import,console,adminpick adminNode
    class blocked danger
```

---

## 3. Navigation map

The app navigates imperatively with `Navigator.push` rather than named routes —
there is no route table to reproduce. This is the reachable screen graph.

```mermaid
flowchart LR
    AppGate --> WelcomePage
    AppGate --> HomeMenu
    AppGate --> AdminDashboardPage
    AppGate --> PlayerOnboardingPage
    AppGate --> AccountDisabled["'Account unavailable'"]

    WelcomePage --> LoginPage
    WelcomePage --> PlayerOnboardingPage
    PlayerOnboardingPage --> RegisterScreen
    RegisterScreen --> ConnectGooglePage

    HomeMenu --> EnglishLessons["English — 13 lessons"]
    HomeMenu --> MathLessons["Math — 9 lessons"]
    HomeMenu --> ScienceLessons["Science — 6 lessons"]
    HomeMenu --> ExamGame["Exam mode"]
    HomeMenu --> LeaderboardScreen
    HomeMenu --> ConnectGooglePage
    HomeMenu --> AdminDashboardPage

    AdminDashboardPage --> QuestionListPage
    AdminDashboardPage --> AccountListPage
    AdminDashboardPage --> TriviaImportPage
    AdminDashboardPage --> ApiConsolePage
    QuestionListPage --> QuestionEditorPage
    AccountListPage --> AccountEditorPage

    EnglishLessons --> WordLookupSheet["Word lookup sheet<br/><i>tap any word</i>"]
    ExamGame --> GameSecurityOverlay["Security overlay<br/><i>face + leave detection</i>"]
```

| Route class | File |
|---|---|
| `AppGate` | [lib/app_gate.dart](../lib/app_gate.dart) |
| `WelcomePage` / `LoginPage` / `RegisterScreen` / `ConnectGooglePage` | [lib/screens/auth/](../lib/screens/auth/) |
| `PlayerOnboardingPage` | [lib/screens/onboarding/player_onboarding_page.dart](../lib/screens/onboarding/player_onboarding_page.dart) |
| `HomeMenu` | [lib/screens/home/home_menu.dart](../lib/screens/home/home_menu.dart) |
| Lesson games | [lib/screens/english/](../lib/screens/english/), [lib/screens/math/](../lib/screens/math/), [lib/screens/science/](../lib/screens/science/) |
| `ExamGame` | [lib/screens/exams/exam_game.dart](../lib/screens/exams/exam_game.dart) |
| `LeaderboardScreen` | [lib/screens/profile/leaderboard_screen.dart](../lib/screens/profile/leaderboard_screen.dart) |
| Admin screens | [lib/screens/admin/](../lib/screens/admin/) |

---

## 4. Data flow — a teacher's question reaching a student

This is the path that makes the Create operation visible rather than
theoretical.

```mermaid
sequenceDiagram
    autonumber
    actor T as Teacher (admin)
    participant E as QuestionEditorPage
    participant M as QuizQuestionRecord
    participant R as QuestionRepository
    participant FS as Cloud Firestore
    participant S as CustomQuestionSync
    participant C as LocalQuestionCache
    participant B as SubjectQuestionBank
    actor ST as Student

    T->>E: fills the form, taps "Create question"
    E->>M: validate()
    alt validation fails
        M-->>E: {field: message}
        E-->>T: errors painted under the inputs
    else valid
        M-->>R: sanitized record
        R->>FS: doc().set(...)  — id generated client-side
        alt server acknowledges within 4 s
            FS-->>R: synced
            R-->>T: "Question created and published"
        else no connection
            R-->>T: "Saved on this device. It will sync when you are back online."
        end
        FS-->>S: snapshot (published == true)
        S->>C: mirror to shared_preferences
        S->>B: setCustomQuestions(bySubject)
        ST->>B: randomQuestion(topic: "Nouns")
        B-->>ST: the teacher's question, in the Nouns lesson
    end
```

**The key move** is step 12: `SubjectQuestionBank._poolFor(subject)`
concatenates the bundled `const` questions with the teacher pool, so
`randomQuestion(...)` draws from both. Because lessons filter by *topic*, a
question saved under an existing topic appears in that lesson immediately — no
app restart.

---

## 5. Data flow — API import (GET → preview → POST)

```mermaid
sequenceDiagram
    autonumber
    actor T as Teacher
    participant UI as TriviaImportPage
    participant OT as OpenTriviaApi
    participant OTDB as opentdb.com
    participant QR as QuestionRepository
    participant RA as FirestoreRestApi
    participant REST as firestore.googleapis.com

    T->>UI: picks category, difficulty, amount
    UI->>OT: fetchQuestions(amount, category, difficulty)
    OT->>OTDB: GET /api.php?...&encode=url3986
    OTDB-->>OT: 200 + {response_code, results[]}
    Note over OT: 200 can still mean failure —<br/>response_code is checked separately
    OT-->>UI: decoded questions + raw JSON

    UI->>QR: existingQuestionKeys()
    QR-->>UI: keys already in the bank
    Note over UI: duplicates greyed out<br/>and un-tickable

    T->>UI: ticks the keepers, taps "Save to question bank"
    loop one POST per question
        UI->>RA: createQuestionDetailed(record)
        RA->>RA: attach Bearer <Firebase ID token>
        RA->>REST: POST /documents/quiz_questions
        REST-->>RA: 200 + {name, fields, createTime}
    end
    RA-->>UI: RestPublishResult(created, failures)
    UI-->>T: "Saved 8, but 2 failed. First error: ..."
```

---

## 6. Offline strategy

Three independent layers, so no single failure takes the questions away.

```mermaid
flowchart TD
    boot(["App start"]) --> cache["1. LocalQuestionCache.load()<br/><i>shared_preferences JSON</i>"]
    cache -->|"questions in the bank<br/>on the first frame"| bank[("SubjectQuestionBank")]
    cache --> listen["2. Firestore live listener<br/>quiz_questions where published == true"]

    listen --> online{"network?"}
    online -->|"yes"| server["Server snapshot"]
    online -->|"no"| fscache["3. Firestore local cache<br/><i>persistenceEnabled: true</i>"]

    server --> guard{"snapshot empty?"}
    fscache --> guard
    guard -->|"empty — could be a cold cache"| keep["Keep the on-device copy<br/><i>never overwrite good data with nothing</i>"]
    guard -->|"has rows"| apply["Apply to the bank<br/>+ rewrite the cache"]
    apply --> bank
    keep --> bank

    write(["Admin writes a question"]) --> settle["_settle(write, 4 s deadline)"]
    settle -->|"server acknowledged"| synced["WriteSyncState.synced<br/>'Question created'"]
    settle -->|"deadline passed"| queued["WriteSyncState.queuedOffline<br/>'Saved on this device'"]
    queued -.->|"delivered on reconnect"| server

    classDef ok fill:#D6F5D6,stroke:#2F5233
    classDef warn fill:#FFF0E0,stroke:#8A4B00
    class synced,apply ok
    class queued,keep warn
```

**Why the 4-second deadline exists.** A Firestore write Future only completes
once the *server* acknowledges it. Offline that never happens, so a plain
`await` would leave the save button spinning forever even though the question is
already stored locally and queued. `QuestionRepository._settle` gives the
acknowledgement a deadline and otherwise reports `queuedOffline` — the write is
durable either way.

---

## 7. Exam proctoring flow

```mermaid
stateDiagram-v2
    [*] --> Setup: student opens Exam mode
    Setup --> Running: subjects + difficulty chosen

    Running --> FaceCheck: front camera frame
    FaceCheck --> Running: face present and facing screen
    FaceCheck --> Violation: no face for 3 s / looking away

    Running --> LeaveDetected: app backgrounded or route popped
    LeaveDetected --> Violation

    Violation --> Logged: LeaveAttemptLogger.logAttempt()
    Logged --> Warned: warning overlay + sound
    Warned --> Running: student returns
    Warned --> AutoSubmit: repeat violation

    Running --> Finished: hearts exhausted or timer ends
    AutoSubmit --> Finished

    Finished --> Saved: exam_attempts + exam_sessions + game_logs + leaderboard_entries
    Saved --> [*]
```

Every violation increments `cheat_attempts_count` on the user document and adds
a row to `users/{uid}/leave_attempts`, so a teacher can see the pattern rather
than a single number. Face frames are processed on-device by ML Kit and are
never uploaded.

---

## 8. Directory map

```
lib/
├── main.dart                     app entry, Firebase init, offline persistence
├── app_gate.dart                 the routing decision point (see §2)
├── auth_gate.dart, onboarding_gate.dart
├── data/
│   ├── subject_question_bank.dart      bundled + teacher question pools
│   └── questions/                      5,793 questions across 18 topic files
│       ├── english/  (12 files)
│       └── science/  (6 files)
├── models/                       QuizQuestionRecord, AppUserRecord (validation)
├── screens/                      45 files
│   ├── admin/    6 screens       dashboard, questions, accounts, import, console
│   ├── auth/     4 screens       welcome, login, register, connect Google
│   ├── english/ 13 games
│   ├── math/     9 games
│   ├── science/  6 games
│   ├── exams/    exam_game.dart
│   ├── home/     home_menu.dart
│   ├── onboarding/, profile/, shared/
├── services/                     23 files
│   ├── api/                      the whole HTTP surface (4 files)
│   ├── question_repository.dart  CRUD — quiz_questions
│   ├── user_admin_repository.dart CRUD — users
│   ├── custom_question_sync.dart, local_question_cache.dart
│   └── proctoring, sound, TTS, connectivity, logging, leaderboard
├── utils/                        theme, constants, firebase options, layout
└── widgets/                      21 reusable widgets
test/                             9 files, 136 tests
tool/                             CLI scripts — API smoke test, sample-data seeder
firestore.rules                   server-side role enforcement
```
