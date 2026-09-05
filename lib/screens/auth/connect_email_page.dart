import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/email_link_service.dart';
import '../../services/sound_service.dart';
import '../../utils/name_credential.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/animated_shape_background.dart';
import 'login_page.dart';

/// "Add your email so you can get back in" — the step that turns a
/// name-and-password account into a recoverable one.
///
/// Every account signs in with a made-up address built from the child's name,
/// on a domain that does not exist. Nothing can be sent there, so a forgotten
/// password is the end of that account and its scores. This asks for a real
/// address and proves it works by sending a link to it.
///
/// Shaped like [ConnectGooglePage], with one deliberate difference: Google
/// verifies the person inside its own chooser, so that screen finishes in one
/// tap. Email cannot — the child has to leave for their mail app and come
/// back — so this one has a second state that waits for them.
///
/// "Maybe later" stays a first-class answer. A child with no address of their
/// own, or no way to reach an inbox at school, must never be locked out of the
/// games over it.
class ConnectEmailPage extends StatefulWidget {
  /// Greeting name, when we have one.
  final String? playerName;

  /// Shown when the prompt is a reminder rather than part of signing up.
  final bool isReminder;

  const ConnectEmailPage({
    super.key,
    this.playerName,
    this.isReminder = false,
  });

  @override
  State<ConnectEmailPage> createState() => _ConnectEmailPageState();
}

class _ConnectEmailPageState extends State<ConnectEmailPage> {
  static const Color _inkColor = Color(0xFF2F5233);
  static const Color _bgTopColor = Color(0xFFE6F7E6);
  static const Color _bgBottomColor = Color(0xFFD4EDD1);
  static const Color _panelColor = Color(0xFFFAFFF9);
  static const Color _accentColor = Color(0xFF4CAF50);
  static const Color _bodyColor = Color(0xFF5C6B5E);

  final EmailLinkService _service = EmailLinkService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _busy = false;
  EmailLinkResult? _result;

  /// Set once a link is on its way, which swaps the card over to the
  /// "check your inbox" state.
  String? _sentTo;

  /// Set when Firebase specifically complains the session is too old, so the
  /// password box can explain itself a second time.
  bool _staleSession = false;

  @override
  void initState() {
    super.initState();
    SoundService().playPageBgm(BgmPage.home);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    SoundService().playButtonSoundNow();

    // Checked before anything is sent. Without it the link goes out, the child
    // opens it, the address changes, the session is revoked - and only then
    // does the missing password surface, by which point the only way back is
    // the login screen.
    if (normalizePassword(_passwordController.text).isEmpty) {
      setState(() {
        _result = const EmailLinkResult(
          outcome: EmailLinkOutcome.needsPassword,
          message: 'Type your password too, so we can move your sign-in to '
              'this address.',
        );
      });
      return;
    }

    setState(() {
      _busy = true;
      _result = null;
    });

    final result = await _service.sendVerification(
      _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;

    setState(() {
      _busy = false;
      _result = result;
      if (result.needsPassword) _staleSession = true;
      if (result.isSuccess) _sentTo = result.email;
      if (result.outcome == EmailLinkOutcome.alreadyVerified) _sentTo = null;
    });

    if (result.outcome == EmailLinkOutcome.alreadyVerified) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (mounted) _finish();
    }
  }

  /// The child says they have opened the link.
  ///
  /// Firebase does not push that - it happened in their mail app - and opening
  /// the link also ends this session, so the service both checks and signs
  /// straight back in. See [EmailLinkService.confirmChange].
  Future<void> _checkVerified() async {
    SoundService().playButtonSoundNow();
    setState(() => _busy = true);

    final outcome = await _service.confirmChange(
      newEmail: _sentTo ?? _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;

    switch (outcome) {
      case EmailChangeOutcome.verified:
        setState(() {
          _busy = false;
          _result = EmailLinkResult(
            outcome: EmailLinkOutcome.alreadyVerified,
            message: 'Confirmed. You sign in with $_sentTo from now on.',
            email: _sentTo,
          );
        });
        await Future<void>.delayed(const Duration(milliseconds: 1400));
        if (mounted) _finish();

      case EmailChangeOutcome.notYet:
        setState(() {
          _busy = false;
          _result = const EmailLinkResult(
            outcome: EmailLinkOutcome.failed,
            message:
                'Not yet. Open the link in the email, then tap this again.',
          );
        });

      case EmailChangeOutcome.signInRequired:
        // The address did change - the session is simply gone and could not be
        // rebuilt here. Hand them to the login screen rather than leaving them
        // on a screen whose buttons can no longer do anything.
        setState(() => _busy = false);
        await _handOverToLogin();
    }
  }

  /// Last resort when the session could not be restored: sign out cleanly and
  /// open the login screen with the new address already filled in.
  Future<void> _handOverToLogin() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (error) {
      debugPrint('Could not sign out after the email change: $error');
    }
    if (!mounted) return;

    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LoginPage(initialEmail: _sentTo),
      ),
      (route) => false,
    );
  }

  /// Pops with whether the account ended up with a verified address, so the
  /// caller can skip offering a second recovery route to somebody who now has
  /// one.
  /// Guarded because both success paths pop after a readable delay, and the
  /// "Finish later" button stays live during it - two pops would take the
  /// screen underneath with them.
  bool _finished = false;

  void _finish() {
    if (!mounted || _finished) return;
    _finished = true;
    Navigator.of(context).pop(_service.hasVerifiedEmail);
  }

  void _skip() {
    SoundService().playButtonSoundNow();
    _finish();
  }

  void _useAnotherAddress() {
    SoundService().playButtonSoundNow();
    setState(() {
      _sentTo = null;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return PopScope(
      // Backing out is the same as choosing "later", so let it through.
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedShapeBackground(
          gradientColors: const [_bgTopColor, _bgBottomColor],
          shapes: const [
            AnimatedBackgroundShape(
              kind: BackgroundShapeKind.circle,
              alignment: Alignment.topLeft,
              baseOffset: Offset(-34, -26),
              drift: Offset(14, 12),
              size: 148,
              color: Color(0x334CAF50),
              borderColor: Color(0x4D2F5233),
            ),
            AnimatedBackgroundShape(
              kind: BackgroundShapeKind.capsule,
              alignment: Alignment.bottomRight,
              baseOffset: Offset(26, 34),
              drift: Offset(12, 16),
              size: 118,
              color: Color(0x33FF9800),
              borderColor: Color(0x4D2F5233),
              initialRotation: 0.2,
            ),
          ],
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(responsiveCardPadding(width) + 8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: responsivePanelMaxWidth(width).clamp(360.0, 520.0),
                  ),
                  child: _card(width),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(double width) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _inkColor, width: 2.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332C3550),
            offset: Offset(6, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            _sentTo == null ? _askForAddress(width) : _waitForLink(width),
      ),
    );
  }

  // ------------------------------------------------------- state one: ask

  List<Widget> _askForAddress(double width) {
    final name = widget.playerName;
    return [
      const Icon(Icons.alternate_email_rounded, size: 52, color: _accentColor),
      const SizedBox(height: 14),
      Text(
        widget.isReminder
            ? 'Keep your scores safe'
            : (name == null ? 'One last thing' : 'Nice to meet you, $name!'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: _inkColor,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'What is your email address?',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: _inkColor,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Right now there is no way to get back into your account if you '
        'forget your password. Adding your email fixes that. Your scores and '
        'level stay exactly the same.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, height: 1.4, color: _bodyColor),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _emailController,
        enabled: !_busy,
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
      const SizedBox(height: 12),
      TextField(
        controller: _passwordController,
        enabled: !_busy,
        obscureText: true,
        textInputAction: TextInputAction.done,
        onSubmitted: _busy ? null : (_) => _send(),
        decoration: InputDecoration(
          labelText: 'Your password',
          helperText: _staleSession
              ? 'Type it again so we know it is you.'
              : 'Needed to move your sign-in to this address.',
          helperMaxLines: 2,
          prefixIcon: const Icon(Icons.lock_outline_rounded),
        ),
      ),
      if (_result != null) ...[
        const SizedBox(height: 14),
        _resultBanner(_result!),
      ],
      const SizedBox(height: 16),
      _primaryButton(
        width: width,
        icon: Icons.send_rounded,
        label: _busy ? 'Sending...' : 'Send me the link',
        onPressed: _busy ? null : _send,
      ),
      const SizedBox(height: 6),
      _laterButton('Maybe later'),
      const SizedBox(height: 4),
      _footnote('You can add it any time from your profile.'),
    ];
  }

  // --------------------------------------------------- state two: waiting

  List<Widget> _waitForLink(double width) {
    return [
      const Icon(Icons.mark_email_unread_rounded,
          size: 52, color: _accentColor),
      const SizedBox(height: 14),
      const Text(
        'Check your inbox',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: _inkColor,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'We sent a link to $_sentTo.\nOpen it, then come back here.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w700,
          color: _inkColor,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'From then on you sign in with your email instead of your name, and '
        'you can reset your password whenever you need to. We will put you '
        'straight back in - your scores and level do not change.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.5, height: 1.4, color: _bodyColor),
      ),
      if (_result != null && !_result!.isSuccess) ...[
        const SizedBox(height: 14),
        _resultBanner(_result!),
      ],
      const SizedBox(height: 16),
      _primaryButton(
        width: width,
        icon: Icons.check_circle_outline_rounded,
        label: _busy ? 'Checking...' : "I've opened the link",
        onPressed: _busy ? null : _checkVerified,
      ),
      const SizedBox(height: 6),
      TextButton(
        onPressed: _busy ? null : _useAnotherAddress,
        child: const Text(
          'Use a different address',
          style: TextStyle(fontWeight: FontWeight.w800, color: _inkColor),
        ),
      ),
      _laterButton('Finish later'),
    ];
  }

  // ------------------------------------------------------------ fragments

  Widget _primaryButton({
    required double width,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: responsiveButtonHeight(width),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFEFEFEF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _inkColor, width: 2.2),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        icon: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: _inkColor,
                ),
              )
            : Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }

  Widget _laterButton(String label) {
    return TextButton(
      onPressed: _busy ? null : _skip,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, color: _bodyColor),
      ),
    );
  }

  Widget _footnote(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 11.5, color: Color(0xFF7A8A7C)),
    );
  }

  Widget _resultBanner(EmailLinkResult result) {
    final (Color background, Color border, IconData icon) =
        switch (result.outcome) {
      EmailLinkOutcome.verificationSent ||
      EmailLinkOutcome.alreadyVerified =>
        (const Color(0xFFE8F7EA), _accentColor, Icons.check_circle_rounded),
      EmailLinkOutcome.needsPassword => (
          const Color(0xFFEFF4FF),
          const Color(0xFF3F6FB5),
          Icons.lock_outline_rounded,
        ),
      _ => (
          const Color(0xFFFFF4DC),
          const Color(0xFFE0A800),
          Icons.warning_amber_rounded,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: border),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              result.message,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: _inkColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
