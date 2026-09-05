import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'register_page.dart';
import '../../app_gate.dart';
import '../../services/sound_service.dart';
import '../../utils/game_theme.dart';
import '../../utils/auth_theme.dart';
import '../../services/app_settings_service.dart';
import '../../services/email_link_service.dart';
import '../../services/game_result_recorder.dart';
import '../../utils/auth_error_message.dart';
import '../../utils/name_credential.dart';
import '../../widgets/animated_shape_background.dart';
import '../../widgets/error_dialog.dart';

class LoginPage extends StatefulWidget {
  /// Prefills the email box and opens the screen in email mode.
  ///
  /// Used when an address was confirmed but the session could not be rebuilt
  /// in place - the child arrives here already knowing which address to use,
  /// rather than being asked to remember what just changed.
  final String? initialEmail;

  const LoginPage({super.key, this.initialEmail});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color _inkColor = Color(0xFF0D47A1);
  static const Color _bgTopColor = Color(0xFFE1F5FE);
  static const Color _bgBottomColor = Color(0xFFB3E5FC);
  static const Color _panelColor = Color(0xFFF0F8FF);
  static const Color _accentColor = Color(0xFF0097A7);

  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final EmailLinkService _emailService = EmailLinkService();
  bool _loading = false;


  @override
  void initState() {
    super.initState();
    SoundService().playPageBgm(BgmPage.login);
    SoundService().registerUserInteraction();
    final handedOver = widget.initialEmail?.trim();
    if (handedOver != null && handedOver.isNotEmpty) {
      _emailController.text = handedOver;
    } else {
      _restoreLastEmail();
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Fills in the address this device last signed in with, so a returning
  /// player only has to type their password.
  Future<void> _restoreLastEmail() async {
    final remembered = await AppSettingsService().lastEmailSignIn();
    if (remembered == null || !mounted) return;
    if (_emailController.text.trim().isNotEmpty) return;

    setState(() => _emailController.text = remembered);
  }



  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ErrorDialog(
        title: 'Login Failed',
        message: message,
      ),
    );
  }

  /// Only works for an account that has confirmed a real address - which is
  /// exactly what [ConnectEmailPage] exists to arrange. Until then there is
  /// nothing to send to, and the copy says so rather than pretending.
  Future<void> _forgotPassword() async {
    SoundService().playButtonSoundNow();

    final typed = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _ForgotPasswordDialog(
        initialEmail: _emailController.text.trim(),
        ink: _inkColor,
        panel: _panelColor,
        accent: _accentColor,
      ),
    );
    if (typed == null || !mounted) return;

    setState(() => _loading = true);
    final result = await _emailService.sendPasswordReset(typed);
    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.isSuccess
              ? const Color(0xFF2E7D32)
              : const Color(0xFF8A6100),
        ),
      );
  }

  Future<void> login() async {
    final password = normalizePassword(_passwordController.text);
    final typedEmail = _emailController.text.trim();

    if (typedEmail.isEmpty || password.isEmpty) {
      await _showErrorDialog('Enter your email address and password.');
      return;
    }

    setState(() => _loading = true);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: typedEmail,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);

        // An admin can deactivate an account; a valid password must not be
        // enough to get back in once they have.
        final existing = await userRef.get();
        if (existing.data()?['disabled'] == true) {
          await _auth.signOut();
          await _showErrorDialog(
            'This account has been deactivated by a teacher. Please ask them to restore it.',
          );
          return;
        }

        // Signing in must not rewrite the player's identity. The Firebase
        // credential email is fixed at creation, so a student an admin renamed
        // still signs in under the *old* name - and writing these fields back
        // from the login box silently reverted the admin's edit on the very
        // next sign-in. Only session bookkeeping is written here; names are
        // owned by the account editor and by registration.
        final signedInEmail = user.email ?? typedEmail;

        final sessionFields = <String, dynamic>{
          'uid': user.uid,
          'loginEmail': signedInEmail,
          'email': signedInEmail,
          'isAnonymous': false,
          'authProvider': 'email',
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Backstop for the recovery record. Confirming an address revokes the
        // session mid-flow, so the write that normally records it can be lost
        // - but signing in with that address is itself proof it landed.
        if (user.emailVerified && !isNameCredential(user.email)) {
          sessionFields['recoveryEmail'] = signedInEmail;
          sessionFields['recoveryEmailVerified'] = true;
          sessionFields['recoveryEmailPending'] = FieldValue.delete();
        }

        // Deliberately no name seeding. This screen no longer asks for one,
        // and a profile that does not exist yet is a case for onboarding -
        // `AppGate` routes there - not for inventing a name here.

        // Bounded. Offline this never returns, so the `finally` below
        // never ran and the Login button spun forever - while the
        // child was, in fact, already signed in.
        await saveBeforeLeaving(
          () => userRef.set(sessionFields, SetOptions(merge: true)),
        );

        // Keep the Firebase display name in step with the stored profile.
        // Cosmetic bookkeeping. It used to be able to fail an otherwise
        // successful sign-in with "Something went wrong".
        final storedFullName =
            (existing.data()?['fullName'] as String?)?.trim();
        if (storedFullName != null && storedFullName.isNotEmpty) {
          await saveBeforeLeaving(
            () => user.updateDisplayName(storedFullName),
          );
        }
      }

      // Only ever written after a sign-in that actually succeeded, so the
      // next visit just needs a password.
      AppSettingsService().saveLastEmailSignIn(typedEmail);

      if (!mounted) return;
      // Route through the gate rather than jumping straight to HomeMenu, so an
      // admin signing in here still lands in the admin panel.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppGate()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      await _showErrorDialog(
        authErrorMessage(e, fallback: 'Could not sign you in. Please try again.'),
      );
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog(
        'Something went wrong while signing you in. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  ThemeData _buildTheme(BuildContext context) {
    return buildAuthTheme(context, ink: _inkColor, accent: _accentColor, panel: _panelColor);
  }

  Widget _buildBackground({required Widget child}) {
    return AnimatedShapeBackground(
      gradientColors: const [_bgTopColor, _bgBottomColor],
      shapes: const [
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.circle,
          alignment: Alignment.topLeft,
          baseOffset: Offset(-34, -26),
          drift: Offset(14, 12),
          size: 142,
          color: Color(0x330097A7),
          borderColor: Color(0x440D47A1),
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.roundedSquare,
          alignment: Alignment.topRight,
          baseOffset: Offset(26, 84),
          drift: Offset(12, 16),
          size: 106,
          color: Color(0x30FF6F00),
          borderColor: Color(0x440D47A1),
          cornerRadius: 28,
          initialRotation: 0.2,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.capsule,
          alignment: Alignment.bottomLeft,
          baseOffset: Offset(30, 34),
          drift: Offset(14, 10),
          size: 120,
          color: Color(0x2A0097A7),
          borderColor: Color(0x3F0D47A1),
          initialRotation: 0.1,
        ),
      ],
      child: child,
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
  }) {
    return gameCard(child: child, panel: _panelColor, ink: _inkColor, padding: padding);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _buildTheme(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  onPressed: () {
                    SoundService().playButtonSoundNow();
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                )
              : null,
          title: const Text('Unlock Your Potential'),
        ),
        body: _buildBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: _card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in with your email address and password. '
                          'Teachers and admins sign in here too.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            hintText: 'name@example.com',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                          onSubmitted: (_) => login(),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _loading ? null : _forgotPassword,
                            child: const Text(
                              'Forgot your password?',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _inkColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    SoundService().playButtonSoundNow();
                                    login();
                                  },
                            child: _loading
                                ? const SizedBox(
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Login'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              SoundService().playButtonSoundNow();
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                              // Registering succeeds and signs the player in,
                              // so leaving them looking at the login form was
                              // a dead end. Hand off to the gate, exactly as a
                              // successful sign-in above does.
                              if (result == true && context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AppGate(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                            child: const Text(
                              "Don't have an account? Create Account",
                              style: TextStyle(
                                color: _accentColor,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
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
      ),
    );
  }
}

/// Asks which address to send the reset link to.
///
/// Deliberately a plain address box rather than the name fields: a reset can
/// only go to an address Firebase can actually reach, which means one the
/// player confirmed through [ConnectEmailPage]. The made-up name credential
/// has no inbox behind it.
class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  final Color ink;
  final Color panel;
  final Color accent;

  const _ForgotPasswordDialog({
    required this.initialEmail,
    required this.ink,
    required this.panel,
    required this.accent,
  });

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: widget.ink, width: 2.2),
      ),
      title: Text(
        'Reset your password',
        style: TextStyle(fontWeight: FontWeight.w900, color: widget.ink),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'We can send a reset link to the email address on your account.',
            style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Email address',
              hintText: 'name@example.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No email on your account yet? Ask your teacher - they can set a '
            'new password for you from the admin panel.',
            style: TextStyle(fontSize: 12, height: 1.35),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.of(context).pop(_controller.text.trim()),
          style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
          child: const Text('Send link'),
        ),
      ],
    );
  }
}
