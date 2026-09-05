import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_gate.dart';
import '../../services/sound_service.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/animated_shape_background.dart';
import '../../widgets/error_dialog.dart';
import '../onboarding/player_onboarding_page.dart';
import '../../services/google_link_service.dart';
import 'connect_email_page.dart';
import 'connect_google_page.dart';
import 'login_page.dart';
import 'register_page.dart';

/// The first screen of the app: "Do you already have an account?"
///
/// Answering *yes* goes to [LoginPage]. Answering *no* starts the new-player
/// flow — an anonymous session is created so the profile has somewhere to
/// live, then [PlayerOnboardingPage] collects name and age, then
/// [RegisterScreen] turns that session into a real account with a password.
///
/// Admins sign in through the same [LoginPage] as everyone else. There is no
/// separate admin entrance: [LoginPage] hands control back to `AppGate`, which
/// reads the account's role and routes an admin to the dashboard.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  static const Color _inkColor = Color(0xFF2F5233);
  static const Color _bgTopColor = Color(0xFFE6F7E6);
  static const Color _bgBottomColor = Color(0xFFD4EDD1);
  static const Color _panelColor = Color(0xFFFAFFF9);
  static const Color _accentColor = Color(0xFF4CAF50);

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    SoundService().playPageBgm(BgmPage.home);
  }

  Future<void> _showError(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ErrorDialog(title: 'Could not continue', message: message),
    );
  }

  void _goToLogin() {
    SoundService().playButtonSoundNow();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  /// New-player path: anonymous session -> profile questions -> real account.
  Future<void> _startNewPlayer() async {
    SoundService().playButtonSoundNow();
    setState(() => _busy = true);

    try {
      final user = await _ensurePlayerSession();
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (routeContext) => PlayerOnboardingPage(
            user: user,
            initialData: const <String, dynamic>{},
            onFinished: () => _finishOnboarding(routeContext),
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      await _showError(
        error.code == 'operation-not-allowed'
            ? 'Anonymous sign-in is turned off for this Firebase project. Enable it in Authentication → Sign-in method so new players can be set up.'
            : (error.message ?? 'Could not start a new player session.'),
      );
    } catch (error) {
      await _showError('Could not start a new player session.\n\n$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Signs in anonymously (if needed) and makes sure the profile document
  /// exists before onboarding starts writing to it.
  Future<User> _ensurePlayerSession() async {
    final auth = FirebaseAuth.instance;
    var user = auth.currentUser;

    if (user == null) {
      final credential = await auth.signInAnonymously();
      user = credential.user;
    }
    if (user == null) {
      throw StateError('Firebase did not return a player session.');
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'isAnonymous': user.isAnonymous,
      'authProvider': user.isAnonymous ? 'anonymous' : 'email',
      'role': 'student',
      'disabled': false,
      'profile_complete': false,
      'onboarding_step': 'name',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return user;
  }

  /// Onboarding finished — secure the account with a password, offer to
  /// connect a Google account, then hand control back to [AppGate], which
  /// decides where the player lands.
  Future<void> _finishOnboarding(BuildContext onboardingContext) async {
    final navigator = Navigator.of(onboardingContext);

    final registered = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );

    // Only offer the recovery steps to someone who actually finished creating
    // an account. Both of them attach to a real account, and a player who
    // backed out of registration is still anonymous - `AppGate` sends them
    // straight back to the password screen.
    if (registered == true) {
      final addedEmail = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (_) => ConnectEmailPage(playerName: _firstNameOfCurrentUser()),
        ),
      );

      // Google is a second way to sign in and a second way back into a
      // forgotten account. Somebody who just confirmed an email address has
      // both already, so they are not asked twice in a row - and it is not
      // offered at all where the chooser cannot open, which used to push a
      // screen whose only content was an "unsupported" banner.
      // `currentUser` is checked because confirming an email address replaces
      // the sign-in address and revokes the session; `ConnectEmailPage`
      // normally rebuilds it, but if that failed there is nothing for Google
      // to link to and this screen could only show an error.
      if (addedEmail != true &&
          FirebaseAuth.instance.currentUser != null &&
          GoogleLinkService.isSupportedPlatform) {
        await navigator.push<void>(
          MaterialPageRoute(
            builder: (_) => ConnectGooglePage(playerName: _firstNameOfCurrentUser()),
          ),
        );
      }
    }

    if (!mounted) return;
    // Whether or not they set a password or connected Google, the profile is
    // complete, so restart the gate and let it route them.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppGate()),
      (route) => false,
    );
  }

  /// First name for the Google step's greeting, taken from the display name
  /// the onboarding and register screens have already set.
  String? _firstNameOfCurrentUser() {
    final displayName = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (displayName == null || displayName.isEmpty) return null;
    return displayName.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedShapeBackground(
        gradientColors: const [_bgTopColor, _bgBottomColor],
        shapes: const [
          AnimatedBackgroundShape(
            kind: BackgroundShapeKind.roundedSquare,
            alignment: Alignment.topLeft,
            baseOffset: Offset(-38, -30),
            drift: Offset(16, 12),
            size: 152,
            color: Color(0x334CAF50),
            borderColor: Color(0x4D2F5233),
            cornerRadius: 34,
            initialRotation: -0.16,
          ),
          AnimatedBackgroundShape(
            kind: BackgroundShapeKind.circle,
            alignment: Alignment.bottomRight,
            baseOffset: Offset(32, 38),
            drift: Offset(12, 14),
            size: 130,
            color: Color(0x33FF9800),
            borderColor: Color(0x4D2F5233),
          ),
          AnimatedBackgroundShape(
            kind: BackgroundShapeKind.diamond,
            alignment: Alignment.topRight,
            baseOffset: Offset(28, 92),
            drift: Offset(10, 16),
            size: 100,
            color: Color(0x2A1976D2),
            borderColor: Color(0x3F2F5233),
            cornerRadius: 18,
          ),
        ],
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(responsiveCardPadding(width) + 8),
              child: ConstrainedBox(
                // The welcome card is a single column of choices, so it reads
                // better narrow than at the full desktop panel width.
                constraints: BoxConstraints(
                  maxWidth: responsivePanelMaxWidth(width).clamp(360.0, 520.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _header(),
                    const SizedBox(height: 22),
                    _questionCard(width),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: _panelColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _inkColor, width: 2.2),
            boxShadow: const [
              BoxShadow(color: Color(0x332C3550), offset: Offset(4, 5), blurRadius: 0),
            ],
          ),
          child: const Text(
            'LOCK IN',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: _inkColor,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Brain training for English, Science, and Math',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _inkColor,
          ),
        ),
      ],
    );
  }

  Widget _questionCard(double width) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _inkColor, width: 2.4),
        boxShadow: const [
          BoxShadow(color: Color(0x332C3550), offset: Offset(6, 7), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Do you already have an account?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: _inkColor,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your account keeps your scores, levels, and leaderboard place.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C6B5E),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          _choiceButton(
            width: width,
            icon: Icons.login_rounded,
            title: 'Yes, I have an account',
            subtitle: 'Log in with your email and password',
            background: _accentColor,
            foreground: Colors.white,
            onTap: _busy ? null : _goToLogin,
          ),
          const SizedBox(height: 14),
          _choiceButton(
            width: width,
            icon: Icons.person_add_alt_1_rounded,
            title: "No, I'm new here",
            subtitle: 'Tell us your name and age, then pick a password',
            background: const Color(0xFFFFF3D6),
            foreground: _inkColor,
            onTap: _busy ? null : _startNewPlayer,
            showSpinner: _busy,
          ),
        ],
      ),
    );
  }

  Widget _choiceButton({
    required double width,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color background,
    required Color foreground,
    required VoidCallback? onTap,
    bool showSpinner = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: BoxConstraints(minHeight: responsiveButtonHeight(width)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: onTap == null ? background.withValues(alpha: 0.55) : background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _inkColor, width: 2.2),
            boxShadow: const [
              BoxShadow(color: Color(0x332C3550), offset: Offset(4, 5), blurRadius: 0),
            ],
          ),
          child: Row(
            children: [
              if (showSpinner)
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: foreground),
                )
              else
                Icon(icon, size: 28, color: foreground),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: foreground.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: foreground),
            ],
          ),
        ),
      ),
    );
  }

}
