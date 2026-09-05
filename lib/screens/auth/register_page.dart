import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/sound_service.dart';
import '../../utils/game_theme.dart';
import '../../utils/auth_theme.dart';
import '../../utils/auth_error_message.dart';
import '../../utils/name_credential.dart';
import '../../widgets/animated_shape_background.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/terms_dialog.dart';
import 'login_page.dart';

class RegisterScreen extends StatefulWidget {
  /// Called instead of popping, when this screen *is* the current screen
  /// rather than a pushed route.
  ///
  /// `AppGate` renders it directly for an account that still has no password,
  /// and there is nothing underneath to pop back to. The same two-way entry
  /// [PlayerOnboardingPage] already handles.
  final VoidCallback? onFinished;

  const RegisterScreen({super.key, this.onFinished});

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
    final password = normalizePassword(_passwordController.text);
    final confirm = normalizePassword(_confirmController.text);

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
        // Written explicitly so every account carries both access fields. The
        // security rules read them with a default, but keeping the shape
        // consistent means an admin promoted by hand in the console only has
        // to change `role`.
        'role': 'student',
        'disabled': false,
        'profile_complete': true,
        'onboarding_step': 'done',
        'accountCreatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'terms_accepted_at': Timestamp.now(),
      }, SetOptions(merge: true));

      _registeredSuccessfully = true;
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // These two keep the register screen's own wording; everything else
      // falls through to the shared kid-safe mapper.
      final message = switch (e.code) {
        'email-already-in-use' || 'credential-already-in-use' =>
          'An account already exists for $_fullName. Sign in with the email address on that account.',
        _ => authErrorMessage(e, fallback: 'Could not create your account. Please try again.'),
      };
      await _showErrorDialog(message);
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog(
        'Something went wrong while creating your account. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        if (_registeredSuccessfully) {
          _leave(registered: true);
        }
      }
    }
  }

  /// Hands control back the way this screen was entered.
  void _leave({required bool registered}) {
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      onFinished();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context, registered);
    }
  }

  /// Leaving without a password means leaving without an account.
  ///
  /// An anonymous session carries no credential at all: there is no way to
  /// sign back into it, so closing the app, clearing its data, or picking up a
  /// different tablet loses the name, the age, and every score. Backing out of
  /// this screen used to drop the player straight into the games on exactly
  /// that footing, permanently. Now it asks first, and a player who means it
  /// is signed out and returned to the start rather than left holding an
  /// account nobody can ever get back into.
  ///
  /// Reached from the login screen or the profile tab there is nothing at
  /// stake, so it just goes back.
  Future<void> _handleBack() async {
    if (_loading) return;
    SoundService().playButtonSoundNow();

    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      _leave(registered: false);
      return;
    }

    final leave = await _confirmLeaveSetup();
    if (leave != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await _auth.signOut();
    } catch (error) {
      debugPrint('Could not sign out of the unfinished session: $error');
    }
    if (!mounted) return;
    setState(() => _loading = false);
    _leave(registered: false);
  }

  Future<bool?> _confirmLeaveSetup() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _panelColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _inkColor, width: 2.2),
        ),
        title: const Text(
          'Leave without a password?',
          style: TextStyle(fontWeight: FontWeight.w900, color: _inkColor),
        ),
        content: const Text(
          'Without a password there is no way to sign back in, so your name, '
          'age, and scores would be lost as soon as you close the app.',
          style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep setting up'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD84315),
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  ThemeData _buildTheme(BuildContext context) {
    return buildAuthTheme(context, ink: _inkColor, accent: _accentColor, panel: _panelColor);
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
    return gameCard(child: child, panel: _panelColor, ink: _inkColor, padding: padding);
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
    // `canPop: false` routes the Android back gesture into the same handler
    // the arrow uses, so it cannot slip past the confirmation and strand the
    // player on a password-less account.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _handleBack();
      },
      child: _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
    return Theme(
      data: _buildTheme(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          // Always offered now, even when there is nothing to pop back to:
          // rendered by `AppGate` for an account with no password, this is the
          // only way out, and it signs out rather than popping.
          leading: IconButton(
            onPressed: _loading ? null : _handleBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
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
                                    // Not a bare `Navigator.pop`. `AppGate`
                                    // renders this screen as the *root* route
                                    // for an account with no password, where
                                    // popping empties the navigator and leaves
                                    // a black screen - and it never opened the
                                    // login screen anyway, which is the one
                                    // thing the link says it does.
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const LoginPage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
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
