import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/app_user_record.dart';
import '../../widgets/decorative_gif.dart';

import '../../services/sound_service.dart';
import '../../widgets/animated_shape_background.dart';

class PlayerOnboardingPage extends StatefulWidget {
  final User user;
  final Map<String, dynamic> initialData;
  final VoidCallback onFinished;

  const PlayerOnboardingPage({
    super.key,
    required this.user,
    required this.initialData,
    required this.onFinished,
  });

  @override
  State<PlayerOnboardingPage> createState() => _PlayerOnboardingPageState();
}

class _PlayerOnboardingPageState extends State<PlayerOnboardingPage> {
  static const Color _inkColor = Color(0xFF2F5233);
  static const Color _bgTopColor = Color(0xFFE6F7E6);
  static const Color _bgBottomColor = Color(0xFFD4EDD1);
  static const Color _panelColor = Color(0xFFFAFFF9);
  static const Color _accentColor = Color(0xFF4CAF50);
  static const Color _orangeColor = Color(0xFFFF9800);

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();

  int _step = 0;
  bool _loading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    SoundService().playPageBgm(BgmPage.home);
    SoundService().registerUserInteraction();

    final firstName = (widget.initialData['firstName'] ?? '').toString();
    final lastName = (widget.initialData['lastName'] ?? '').toString();
    final age = widget.initialData['age'];

    _firstNameController.text = firstName;
    _lastNameController.text = lastName;
    if (age != null) _ageController.text = age.toString();

    final hasName = firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;
    final hasAge = int.tryParse(_ageController.text.trim()) != null;
    if (hasName && !hasAge) {
      _step = 1;
    } else if (hasName && hasAge) {
      _step = 2;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveNameAndContinue() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      setState(() => _errorText = 'Please enter both first name and last name.');
      return;
    }

    final fullName = '$firstName $lastName';
    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      await widget.user.updateDisplayName(fullName);
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
        'uid': widget.user.uid,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'username': fullName,
        'email': widget.user.email,
        'isAnonymous': widget.user.isAnonymous,
        'authProvider': widget.user.isAnonymous ? 'anonymous' : 'email',
        'onboarding_step': 'age',
        'profile_complete': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': widget.initialData['createdAt'] ?? FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _loading = false;
        _step = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = 'Could not save your name. $e';
      });
    }
  }

  Future<void> _saveAgeAndContinue() async {
    final age = int.tryParse(_ageController.text.trim());
    // Uses the record's own bounds rather than a second, wider pair. Onboarding
    // used to accept 3-120 while AppUserRecord requires 4-100, so a
    // self-onboarded 3-year-old was written to Firestore and then failed
    // validation on every later admin edit - the teacher could not save any
    // change until they also corrected the age.
    if (age == null ||
        age < AppUserRecord.minAge ||
        age > AppUserRecord.maxAge) {
      setState(() => _errorText =
          'Please enter an age between ${AppUserRecord.minAge} and ${AppUserRecord.maxAge}.');
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
        'age': age,
        'onboarding_step': 'ready',
        'profile_complete': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _loading = false;
        _step = 2;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = 'Could not save your age. $e';
      });
    }
  }

  /// Steps back one screen, or leaves setup entirely from the first one.
  ///
  /// There are two ways in here and they need different exits. WelcomePage
  /// pushes this page, so there is a route to pop back to. AppGate renders it
  /// as the home widget when a signed-in player has an unfinished profile -
  /// nothing to pop, so leaving means signing out and letting the gate route
  /// back to the start screen.
  Future<void> _goBack() async {
    if (_loading) return;
    SoundService().playButtonSoundNow();

    if (_step > 0) {
      setState(() {
        _errorText = null;
        _step -= 1;
      });
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    final leave = await _confirmLeaveSetup();
    if (leave != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Even if sign-out fails, fall through to the gate: it re-reads the
      // auth state and will simply show this page again rather than stranding
      // the player on a dead screen.
    }
    if (!mounted) return;
    widget.onFinished();
  }

  Future<bool?> _confirmLeaveSetup() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _panelColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: _inkColor, width: 2),
        ),
        title: const Text(
          'Leave setup?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'You will go back to the start screen and can set up your player '
          'again later.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Keep setting up',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = '$firstName $lastName'.trim();
      final age = int.tryParse(_ageController.text.trim());

      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
        'uid': widget.user.uid,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'username': fullName.isEmpty ? widget.user.displayName : fullName,
        'age': age,
        'email': widget.user.email,
        'isAnonymous': widget.user.isAnonymous,
        'authProvider': widget.user.isAnonymous ? 'anonymous' : 'email',
        'profile_complete': true,
        'onboarding_step': 'done',
        'profileCompletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      widget.onFinished();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = 'Could not finish setup. $e';
      });
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
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _inkColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _inkColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _accentColor, width: 2.4),
        ),
        filled: true,
        fillColor: _panelColor,
        labelStyle: const TextStyle(
          color: _inkColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
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
          baseOffset: Offset(-38, -32),
          drift: Offset(16, 12),
          size: 156,
          color: Color(0x334CAF50),
          borderColor: Color(0x4D2F5233),
          cornerRadius: 34,
          initialRotation: -0.18,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.diamond,
          alignment: Alignment.topRight,
          baseOffset: Offset(28, 80),
          drift: Offset(12, 16),
          size: 104,
          color: Color(0x33FF9800),
          borderColor: Color(0x4D2F5233),
          cornerRadius: 18,
          initialRotation: 0.18,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.circle,
          alignment: Alignment.bottomLeft,
          baseOffset: Offset(36, 38),
          drift: Offset(12, 14),
          size: 126,
          color: Color(0x2E4CAF50),
          borderColor: Color(0x4D2F5233),
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.roundedSquare,
          alignment: Alignment.bottomRight,
          baseOffset: Offset(22, 30),
          drift: Offset(10, 15),
          size: 92,
          color: Color(0x26FF9800),
          borderColor: Color(0x442F5233),
          cornerRadius: 26,
          initialRotation: 0.32,
        ),
      ],
      child: child,
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(24),
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

  Widget _stepDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final active = index == _step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: active ? 34 : 12,
          height: 12,
          decoration: BoxDecoration(
            color: active ? _orangeColor : _inkColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _inkColor, width: 1.6),
          ),
        );
      }),
    );
  }

  Widget _bottomGif(String assetPath) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = MediaQuery.sizeOf(context);
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screen.width;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : screen.height * 0.45;

        // Bigger onboarding character GIF that still scales down safely
        // on small phones and web windows.
        final gifSize = [
          availableWidth * 0.68,
          availableHeight * 0.92,
          screen.shortestSide * 0.62,
        ].reduce((a, b) => a < b ? a : b).clamp(230.0, 430.0);

        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: gifSize,
            height: gifSize,
            padding: EdgeInsets.all((gifSize * 0.035).clamp(8.0, 16.0)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular((gifSize * 0.12).clamp(28.0, 48.0)),
              border: Border.all(color: Colors.white70, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular((gifSize * 0.09).clamp(22.0, 38.0)),
              child: DecorativeGif(
                assetPath: assetPath,
                displayWidth: gifSize,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _errorBox() {
    if (_errorText == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8E4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE94B3C), width: 1.8),
      ),
      child: Text(
        _errorText!,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF8B0000),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _nameStep() {
    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'What is your name?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'This will be saved to Firebase and used in your profile, history, and leaderboard.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _firstNameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'First Name',
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastNameController,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
            onSubmitted: (_) {
              if (!_loading) _saveNameAndContinue();
            },
          ),
          _errorBox(),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loading ? null : _saveNameAndContinue,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _ageStep() {
    final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            fullName.isEmpty ? 'How old are you?' : 'Nice to meet you, $fullName!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'What is your age?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Age',
              prefixIcon: Icon(Icons.cake_rounded),
            ),
            onSubmitted: (_) {
              if (!_loading) _saveAgeAndContinue();
            },
          ),
          _errorBox(),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : _goBack,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    side: const BorderSide(color: _inkColor, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _saveAgeAndContinue,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _readyStep() {
    final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Are you ready to play?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            fullName.isEmpty
                ? 'Your profile is ready. Your game history will now be saved.'
                : '$fullName, your profile is ready. Your game history will now be saved.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          _errorBox(),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : _goBack,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    side: const BorderSide(color: _inkColor, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _finishOnboarding,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Playing'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = switch (_step) {
      0 => _nameStep(),
      1 => _ageStep(),
      _ => _readyStep(),
    };

    final gifAsset = switch (_step) {
      0 => 'assets/gifs/name.gif',
      1 => 'assets/gifs/age.gif',
      _ => 'assets/gifs/ready_to_play.gif',
    };

    return Theme(
      data: _buildTheme(context),
      child: PopScope(
        // Take over the system/browser back gesture too, so it steps back
        // through setup instead of closing the app or dropping the player
        // somewhere the gate will just send them back from.
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goBack();
        },
        child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: _step > 0 ? 'Back' : 'Back to start',
            onPressed: _loading ? null : _goBack,
          ),
          title: const Text('Player Setup'),
        ),
        body: _buildBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 42),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            _stepDots(),
                            const SizedBox(height: 16),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: KeyedSubtree(
                                key: ValueKey(_step),
                                child: content,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: _bottomGif(gifAsset),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        ),
      ),
    );
  }
}
