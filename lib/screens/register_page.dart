import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/sound_service.dart';
import '../utils/name_credential.dart';
import '../widgets/animated_shape_background.dart';
import '../widgets/error_dialog.dart';
import '../widgets/terms_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color _inkColor = Color(0xFF8B0000);
  static const Color _bgTopColor = Color(0xFFFFE8D6);
  static const Color _bgBottomColor = Color(0xFFFFD4B4);
  static const Color _panelColor = Color(0xFFFFF5EE);
  static const Color _accentColor = Color(0xFFE94B3C);

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _loading = false;
  bool _profileLoading = true;
  bool _registeredSuccessfully = false;
  int? _age;

  @override
  void initState() {
    super.initState();
    SoundService().playPageBgm(BgmPage.register);
    SoundService().registerUserInteraction();
    _loadExistingPlayerProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingPlayerProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _profileLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final data = snapshot.data();

      if (data != null) {
        final firstName = (data['firstName'] ?? '').toString().trim();
        final lastName = (data['lastName'] ?? '').toString().trim();
        final fullName = (data['fullName'] ?? '').toString().trim();

        if (firstName.isNotEmpty) {
          _firstNameController.text = firstName;
        }
        if (lastName.isNotEmpty) {
          _lastNameController.text = lastName;
        }

        if ((firstName.isEmpty || lastName.isEmpty) && fullName.isNotEmpty) {
          final parts = fullName.split(RegExp(r'\s+'));
          if (_firstNameController.text.trim().isEmpty && parts.isNotEmpty) {
            _firstNameController.text = parts.first;
          }
          if (_lastNameController.text.trim().isEmpty && parts.length > 1) {
            _lastNameController.text = parts.sublist(1).join(' ');
          }
        }

        final ageValue = data['age'];
        if (ageValue is int) _age = ageValue;
        if (ageValue is String) _age = int.tryParse(ageValue);
      }
    } finally {
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  String get _firstName => _firstNameController.text.trim();
  String get _lastName => _lastNameController.text.trim();
  String get _fullName => '$_firstName $_lastName'.trim();
  String get _loginId => buildNameLoginId(firstName: _firstName, lastName: _lastName);
  String get _loginEmail => buildNameCredentialEmail(firstName: _firstName, lastName: _lastName);

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ErrorDialog(
        title: 'Registration Failed',
        message: message,
      ),
    );
  }

  Future<bool> _showTermsDialog() async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const TermsDialog(),
    );
    return accepted ?? false;
  }

  Future<void> register() async {
    final firstName = _firstName;
    final lastName = _lastName;
    final fullName = _fullName;
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (firstName.isEmpty || lastName.isEmpty) {
      await _showErrorDialog('Please enter your first name and last name first.');
      return;
    }

    if (password.length < 6) {
      await _showErrorDialog('Password must be at least 6 characters.');
      return;
    }

    if (password != confirm) {
      await _showErrorDialog('Passwords do not match.');
      return;
    }

    final termsAccepted = await _showTermsDialog();
    if (!termsAccepted) return;

    if (!mounted) return;
    setState(() {
      _loading = true;
      _registeredSuccessfully = false;
    });

    try {
      final currentUser = _auth.currentUser;
      UserCredential credential;

      if (currentUser != null && currentUser.isAnonymous) {
        credential = await currentUser.linkWithCredential(
          EmailAuthProvider.credential(
            email: _loginEmail,
            password: password,
          ),
        );
      } else {
        credential = await _auth.createUserWithEmailAndPassword(
          email: _loginEmail,
          password: password,
        );
      }

      final createdUser = credential.user ?? _auth.currentUser;
      if (createdUser == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'Could not create your account. Please try again.',
        );
      }

      await createdUser.updateDisplayName(fullName);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(createdUser.uid)
          .set({
        'uid': createdUser.uid,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'username': fullName,
        'loginId': _loginId,
        'loginEmail': _loginEmail,
        'email': _loginEmail,
        'age': _age,
        'isAnonymous': false,
        'authProvider': 'email',
        'profile_complete': true,
        'onboarding_step': 'done',
        'accountCreatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'terms_accepted_at': Timestamp.now(),
      }, SetOptions(merge: true));

      _registeredSuccessfully = true;
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'email-already-in-use' || 'credential-already-in-use' =>
          'An account already exists for $_fullName. Please login using your first name, last name, and password.',
        'invalid-email' => 'The generated name credential is invalid. Please check the spelling of your first and last name.',
        'weak-password' => 'Password is too weak. Please use a stronger password.',
        _ => e.message ?? 'Registration failed.',
      };
      await _showErrorDialog(message);
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        if (_registeredSuccessfully) {
          Navigator.pop(context, true);
        }
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
          kind: BackgroundShapeKind.roundedSquare,
          alignment: Alignment.topLeft,
          baseOffset: Offset(-36, -30),
          drift: Offset(16, 10),
          size: 146,
          color: Color(0x38E94B3C),
          borderColor: Color(0x4D8B0000),
          cornerRadius: 32,
          initialRotation: -0.22,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.diamond,
          alignment: Alignment.topRight,
          baseOffset: Offset(28, 86),
          drift: Offset(10, 14),
          size: 104,
          color: Color(0x2FD4AF37),
          borderColor: Color(0x4D8B0000),
          cornerRadius: 18,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.circle,
          alignment: Alignment.bottomLeft,
          baseOffset: Offset(36, 36),
          drift: Offset(12, 12),
          size: 124,
          color: Color(0x2BE94B3C),
          borderColor: Color(0x478B0000),
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

  Widget _credentialPreview() {
    final loginId = _loginId;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your login credential',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            loginId,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Use this first-name + last-name credential with your password to login and appear on leaderboards.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
          ),
        ],
      ),
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
          title: const Text('Create Your Account'),
        ),
        body: _buildBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: _card(
                    child: _profileLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Secure Your Player Profile',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Your first and last name become your login credential. Just set your password.',
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
                                      onChanged: (_) => setState(() {}),
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
                                      onChanged: (_) => setState(() {}),
                                      decoration: const InputDecoration(
                                        labelText: 'Last Name',
                                        prefixIcon: Icon(Icons.badge),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _credentialPreview(),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock),
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _confirmController,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: Icon(Icons.lock),
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loading
                                      ? null
                                      : () {
                                          SoundService().playButtonSoundNow();
                                          register();
                                        },
                                  child: _loading
                                      ? const SizedBox(
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Create Account'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    SoundService().playButtonSoundNow();
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'Already have an account? Login',
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
