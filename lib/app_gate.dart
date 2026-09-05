import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/app_user_record.dart';
import 'screens/admin/admin_dashboard_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/auth/welcome_page.dart';
import 'screens/home/home_menu.dart';
import 'screens/onboarding/player_onboarding_page.dart';
import 'services/custom_question_sync.dart';
import 'services/leaderboard_service.dart';
import 'services/player_proctoring_preference.dart';
import 'services/proctoring_settings.dart';
import 'utils/admin_theme.dart';
import 'widgets/animated_shape_background.dart';

/// Where the gate decided to send the player.
enum _GateRoute { welcome, onboarding, secureAccount, home, admin, disabled }

/// The app's single entry decision point.
///
/// On every cold start it answers, in order:
///  1. Is anybody signed in? If not, show [WelcomePage] — the "do you already
///     have an account?" screen.
///  2. Has this account been disabled by an admin? If so, sign out and explain.
///  3. Is this an admin? Send them straight to the admin dashboard.
///  4. Is the player profile finished? If not, resume onboarding.
///  5. Otherwise, play.
///
/// It also kicks off [CustomQuestionSync] so admin-authored questions are in
/// the pool before the first quiz screen is built.
class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  late Future<_GateResult> _bootFuture;

  @override
  void initState() {
    super.initState();
    _bootFuture = _boot();
  }

  void _reload() {
    setState(() {
      _bootFuture = _boot();
    });
  }

  Future<_GateResult> _boot() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) {
      return const _GateResult(route: _GateRoute.welcome);
    }

    // Teacher questions load in the background; a failure here must never
    // block the app, since the bundled question bank is fully playable alone.
    // Started only once somebody is signed in, because the security rules
    // require an authenticated reader for `quiz_questions`.
    unawaited(CustomQuestionSync.instance.start().catchError((Object _) {}));

    // Same treatment: the games need to know whether to open the camera, and a
    // failure here must not block entry - the on-device copy, or the
    // proctoring-on default, stands until Firestore answers.
    unawaited(ProctoringSettings.instance.start().catchError((Object _) {}));

    // The player's own half of the same decision. Awaited, unlike the two
    // above, because it is a local `shared_preferences` read rather than a
    // network one, and because a game screen reads it on its first frame - an
    // unresolved read would silently mean "camera on" for whoever opened a
    // game fastest. It never throws, so there is nothing to catch.
    await PlayerProctoringPreference.instance.loadFor(user.uid);

    Map<String, dynamic> data = <String, dynamic>{};
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      data = snapshot.data() ?? <String, dynamic>{};

      if (snapshot.exists) {
        // Deliberately not awaited. Persistence is on (see main.dart), so the
        // read above is served from the local cache when there is no network -
        // which means the `catch` below never fires offline. Awaiting this
        // write would then block forever, because a write future only
        // completes on server acknowledgement, and the gate would sit on
        // "Getting things ready..." with no timeout and no way out. Touching
        // `lastSeenAt` is bookkeeping; it must never gate entry to the app.
        unawaited(
          snapshot.reference.set(
            {'lastSeenAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true),
          ).catchError((Object _) {}),
        );
      }
    } catch (_) {
      // Offline. A returning player has a cached profile, so let them play
      // rather than trapping them behind a network error.
      return _GateResult(route: _GateRoute.home, user: user);
    }

    final record = AppUserRecord.fromMap(user.uid, data);

    if (record.disabled) {
      // Teacher questions are loaded into a process-wide pool, so on a shared
      // classroom device they would otherwise stay in play for whoever signs
      // in next. Torn down alongside the cached player name, which was already
      // being reset here.
      resetPlayerNameCache();
      await CustomQuestionSync.instance.stop();
      await ProctoringSettings.instance.stop();
      PlayerProctoringPreference.instance.reset();
      await auth.signOut();
      return _GateResult(route: _GateRoute.disabled, user: user, record: record);
    }

    if (record.isAdmin) {
      return _GateResult(route: _GateRoute.admin, user: user, record: record);
    }

    // An anonymous session with nothing filled in means the player never got
    // past the welcome screen — ask the account question again rather than
    // dropping them into a half-finished onboarding.
    final hasAnyProfile = record.firstName.trim().isNotEmpty ||
        record.fullName.trim().isNotEmpty;
    if (user.isAnonymous && !hasAnyProfile) {
      return const _GateResult(route: _GateRoute.welcome);
    }

    if (!_isProfileComplete(record, data)) {
      return _GateResult(
        route: _GateRoute.onboarding,
        user: user,
        record: record,
        rawData: data,
      );
    }

    // Still anonymous with a finished profile: they answered every question
    // and then backed out of setting a password. An anonymous session carries
    // no credential, so it cannot be signed into - close the app, clear its
    // data, or pick up another tablet and the name, age, and every score are
    // gone, with nothing the child or a teacher can do about it.
    //
    // The password screen used to be a pushed route that could simply be
    // dismissed. Checking here as well catches the accounts that already got
    // through that gap, on their very next launch.
    if (user.isAnonymous) {
      return _GateResult(
        route: _GateRoute.secureAccount,
        user: user,
        record: record,
        rawData: data,
      );
    }

    return _GateResult(route: _GateRoute.home, user: user, record: record);
  }

  bool _isProfileComplete(AppUserRecord record, Map<String, dynamic> data) {
    // Parenthesised deliberately. `&&` already binds tighter than `||`, so the
    // behaviour is unchanged - but the line break used to sit at the `||`,
    // which reads as `first && (last || full)`. This decides whether a child is
    // sent back through onboarding, so the grouping is spelled out.
    final hasName =
        (record.firstName.trim().isNotEmpty && record.lastName.trim().isNotEmpty) ||
            record.fullName.trim().isNotEmpty;
    final hasAge = record.age != null;
    return data['profile_complete'] == true && hasName && hasAge;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_GateResult>(
      future: _bootFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _GateLoadingScreen();
        }

        if (snapshot.hasError) {
          return _GateErrorScreen(
            message:
                'We could not start your session.\n\nFirebase Anonymous Sign-In must be enabled so players can save their name, age, and history.\n\n${snapshot.error}',
            onRetry: _reload,
          );
        }

        final result = snapshot.data!;
        return switch (result.route) {
          _GateRoute.welcome => const WelcomePage(),
          _GateRoute.admin => const AdminDashboardPage(),
          _GateRoute.home => const HomeMenu(),
          _GateRoute.disabled => _AccountDisabledScreen(
              name: result.record?.displayName ?? 'This account',
              onBack: _reload,
            ),
          _GateRoute.onboarding => PlayerOnboardingPage(
              user: result.user!,
              initialData: result.rawData,
              onFinished: _reload,
            ),
          // Rendered rather than pushed, so it has nowhere to pop back to -
          // hence the `onFinished` callback, the same shape onboarding uses.
          _GateRoute.secureAccount => RegisterScreen(onFinished: _reload),
        };
      },
    );
  }
}

class _GateResult {
  final _GateRoute route;
  final User? user;
  final AppUserRecord? record;
  final Map<String, dynamic> rawData;

  const _GateResult({
    required this.route,
    this.user,
    this.record,
    this.rawData = const <String, dynamic>{},
  });
}

class _GateLoadingScreen extends StatelessWidget {
  const _GateLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AnimatedShapeBackground(
        gradientColors: [Color(0xFFE6F7E6), Color(0xFFD4EDD1)],
        shapes: [
          AnimatedBackgroundShape(
            kind: BackgroundShapeKind.roundedSquare,
            alignment: Alignment.topLeft,
            baseOffset: Offset(-38, -30),
            drift: Offset(16, 12),
            size: 150,
            color: Color(0x334CAF50),
            borderColor: Color(0x4D2F5233),
            cornerRadius: 34,
          ),
          AnimatedBackgroundShape(
            kind: BackgroundShapeKind.circle,
            alignment: Alignment.bottomRight,
            baseOffset: Offset(30, 36),
            drift: Offset(12, 14),
            size: 128,
            color: Color(0x33FF9800),
            borderColor: Color(0x4D2F5233),
          ),
        ],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF4CAF50)),
              SizedBox(height: 16),
              Text(
                'Getting things ready…',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2F5233),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GateErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _GateErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedShapeBackground(
        gradientColors: const [Color(0xFFFFE8D6), Color(0xFFFFD4B4)],
        shapes: const [
          AnimatedBackgroundShape(
            kind: BackgroundShapeKind.roundedSquare,
            alignment: Alignment.topLeft,
            baseOffset: Offset(-38, -30),
            drift: Offset(16, 12),
            size: 150,
            color: Color(0x33E94B3C),
            borderColor: Color(0x4D8B0000),
            cornerRadius: 34,
          ),
        ],
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5EE),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFF8B0000), width: 2.2),
                    boxShadow: AdminPalette.hardShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_rounded,
                          size: 54, color: Color(0xFFE94B3C)),
                      const SizedBox(height: 12),
                      const Text(
                        'Could not start',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF8B0000),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B0000),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE94B3C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown after an admin soft-deletes (disables) an account and that person
/// tries to come back.
class _AccountDisabledScreen extends StatelessWidget {
  final String name;
  final VoidCallback onBack;

  const _AccountDisabledScreen({required this.name, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedShapeBackground(
        gradientColors: const [Color(0xFFFFE8D6), Color(0xFFFFD4B4)],
        shapes: const [
          AnimatedBackgroundShape(
            kind: BackgroundShapeKind.circle,
            alignment: Alignment.topLeft,
            baseOffset: Offset(-34, -26),
            drift: Offset(14, 12),
            size: 142,
            color: Color(0x33E94B3C),
            borderColor: Color(0x448B0000),
          ),
        ],
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5EE),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFF8B0000), width: 2.2),
                    boxShadow: AdminPalette.hardShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_person_rounded,
                          size: 56, color: Color(0xFF8B0000)),
                      const SizedBox(height: 14),
                      const Text(
                        'Account unavailable',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF8B0000),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$name has been deactivated by a teacher.\n\nPlease ask your teacher to restore it before signing in again.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: Color(0xFF8B0000),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onBack,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE94B3C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Back to start'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
