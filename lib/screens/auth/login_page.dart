import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'register_page.dart';
import '../../app_gate.dart';
import '../../services/sound_service.dart';
import '../../utils/game_theme.dart';
import '../../utils/auth_theme.dart';
import '../../utils/auth_error_message.dart';
import '../../utils/name_credential.dart';
import '../../widgets/animated_shape_background.dart';
import '../../widgets/error_dialog.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color _inkColor = Color(0xFF0D47A1);
  static const Color _bgTopColor = Color(0xFFE1F5FE);
  static const Color _bgBottomColor = Color(0xFFB3E5FC);
  static const Color _panelColor = Color(0xFFF0F8FF);
  static const Color _accentColor = Color(0xFF0097A7);

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    SoundService().playPageBgm(BgmPage.login);
    SoundService().registerUserInteraction();
    _prefillNameFromCurrentProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _prefillNameFromCurrentProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final data = snapshot.data();
    if (data == null || !mounted) return;

    _firstNameController.text = (data['firstName'] ?? '').toString();
    _lastNameController.text = (data['lastName'] ?? '').toString();
  }

  String get _loginEmail => buildNameCredentialEmail(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
      );

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

  Future<void> login() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final password = normalizePassword(_passwordController.text);

    if (firstName.isEmpty || lastName.isEmpty || password.isEmpty) {
      await _showErrorDialog('Enter your first name, last name, and password.');
      return;
    }

    setState(() => _loading = true);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: _loginEmail,
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
        final sessionFields = <String, dynamic>{
          'uid': user.uid,
          'loginEmail': _loginEmail,
          'email': _loginEmail,
          'isAnonymous': false,
          'authProvider': 'email',
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (!existing.exists) {
          // No profile yet - this is the one case where the typed name is the
          // only name there is, so seed it.
          final typedFullName = '$firstName $lastName'.trim();
          sessionFields.addAll({
            'firstName': firstName,
            'lastName': lastName,
            'fullName': typedFullName,
            'username': typedFullName,
            'loginId':
                buildNameLoginId(firstName: firstName, lastName: lastName),
          });
        }

        await userRef.set(sessionFields, SetOptions(merge: true));

        // Keep the Firebase display name in step with the stored profile
        // rather than with what was typed into the login box.
        final storedFullName =
            (existing.data()?['fullName'] as String?)?.trim();
        final displayName = (storedFullName != null && storedFullName.isNotEmpty)
            ? storedFullName
            : '$firstName $lastName'.trim();
        await user.updateDisplayName(displayName);
      }

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
                          'Login using your first name, last name, and password. '
                          'Teachers and admins sign in here too.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _firstNameController,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'First Name',
                                  prefixIcon: Icon(Icons.person),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _lastNameController,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Last Name',
                                  prefixIcon: Icon(Icons.badge),
                                ),
                              ),
                            ),
                          ],
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
                        const SizedBox(height: 24),
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
