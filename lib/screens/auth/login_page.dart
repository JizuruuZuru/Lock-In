import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'register_page.dart';
import '../../app_gate.dart';
import '../../services/sound_service.dart';
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
    final password = _passwordController.text.trim();

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

        final fullName = '$firstName $lastName'.trim();
        await user.updateDisplayName(fullName);
        await userRef.set({
          'uid': user.uid,
          'firstName': firstName,
          'lastName': lastName,
          'fullName': fullName,
          'username': fullName,
          'loginId': buildNameLoginId(firstName: firstName, lastName: lastName),
          'loginEmail': _loginEmail,
          'email': _loginEmail,
          'isAnonymous': false,
          'authProvider': 'email',
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
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
      final message = switch (e.code) {
        'user-not-found' || 'invalid-credential' || 'wrong-password' =>
          'No account matched that name and password. Create an account first or check your spelling.',
        _ => e.message ?? 'Unknown error',
      };
      await _showErrorDialog(message);
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  ThemeData _buildTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: _inkColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: _inkColor,
        displayColor: _inkColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _inkColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _inkColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentColor, width: 2),
        ),
        filled: true,
        fillColor: _panelColor,
        labelStyle: const TextStyle(color: _inkColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _inkColor, width: 2),
          ),
          elevation: 0,
        ),
      ),
    );
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
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _inkColor, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332C3550),
            offset: Offset(5, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
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
                              if (result == true && mounted) {
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
