import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/home/home_menu.dart';
import 'screens/onboarding/player_onboarding_page.dart';
import 'widgets/animated_shape_background.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late Future<_OnboardingGateResult> _bootFuture;

  @override
  void initState() {
    super.initState();
    _bootFuture = _preparePlayer();
  }

  Future<_OnboardingGateResult> _preparePlayer() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    User? user = auth.currentUser;
    final isReturningUser = user != null;
    if (user == null) {
      final credential = await auth.signInAnonymously();
      user = credential.user;
    }

    if (user == null) {
      throw StateError('Could not create a player session.');
    }

    final userRef = firestore.collection('users').doc(user.uid);
    Map<String, dynamic> data = <String, dynamic>{};

    try {
      final snapshot = await userRef.get();
      data = snapshot.data() ?? <String, dynamic>{};

      if (!snapshot.exists) {
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'isAnonymous': user.isAnonymous,
          'authProvider': user.isAnonymous ? 'anonymous' : 'email',
          'createdAt': FieldValue.serverTimestamp(),
          'profile_complete': false,
          'onboarding_step': 'name',
        }, SetOptions(merge: true));
      } else {
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'isAnonymous': user.isAnonymous,
          'authProvider': user.isAnonymous ? 'anonymous' : 'email',
          'lastSeenAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (error) {
      // Offline (or Firestore unreachable). A brand-new player can't be
      // created without a network round trip, so surface the error for
      // them. A returning player already has a local profile cache, so
      // let them straight into the app instead of blocking on Firestore.
      if (!isReturningUser) rethrow;
    }

    final hasName = ((data['firstName'] ?? '').toString().trim().isNotEmpty &&
            (data['lastName'] ?? '').toString().trim().isNotEmpty) ||
        (data['fullName'] ?? '').toString().trim().isNotEmpty ||
        (data['username'] ?? '').toString().trim().isNotEmpty;
    final hasAge = data['age'] is int ||
        int.tryParse((data['age'] ?? '').toString()) != null;
    final isComplete = (isReturningUser && data.isEmpty) ||
        (data['profile_complete'] == true && hasName && hasAge);

    return _OnboardingGateResult(
      user: user,
      initialData: data,
      profileComplete: isComplete,
    );
  }

  void _reloadGate() {
    setState(() {
      _bootFuture = _preparePlayer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_OnboardingGateResult>(
      future: _bootFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingGateScreen();
        }

        if (snapshot.hasError) {
          return _OnboardingErrorScreen(
            message:
                'Firebase Anonymous Sign-In must be enabled so players can save their name, age, and history before logging in.\n\n${snapshot.error}',
            onRetry: _reloadGate,
          );
        }

        final result = snapshot.data!;
        if (result.profileComplete) {
          return const HomeMenu();
        }

        return PlayerOnboardingPage(
          user: result.user,
          initialData: result.initialData,
          onFinished: _reloadGate,
        );
      },
    );
  }
}

class _OnboardingGateResult {
  final User user;
  final Map<String, dynamic> initialData;
  final bool profileComplete;

  const _OnboardingGateResult({
    required this.user,
    required this.initialData,
    required this.profileComplete,
  });
}

class _LoadingGateScreen extends StatelessWidget {
  const _LoadingGateScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedShapeBackground(
        gradientColors: const [Color(0xFFE6F7E6), Color(0xFFD4EDD1)],
        shapes: const [
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
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
        ),
      ),
    );
  }
}

class _OnboardingErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _OnboardingErrorScreen({
    required this.message,
    required this.onRetry,
  });

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
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5EE),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF8B0000), width: 2.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x332C3550),
                    offset: Offset(5, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_rounded,
                      size: 54, color: Color(0xFFE94B3C)),
                  const SizedBox(height: 12),
                  const Text(
                    'Player setup needs Firebase',
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
                      fontSize: 15,
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
    );
  }
}
