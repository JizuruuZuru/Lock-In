import 'package:flutter/material.dart';

import '../../services/google_link_service.dart';
import '../../services/sound_service.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/animated_shape_background.dart';

/// The final, optional step of signing up: "connect a Google account now, or
/// later?"
///
/// Connecting attaches a Gmail address to the profile the player just created.
/// It is a *link*, so their uid, scores, and leaderboard place all stay put —
/// they simply gain a second way to sign in. Google verifies the person during
/// its own chooser, so there is no separate code to type in here.
///
/// "Maybe later" is a first-class answer. The player already has a working
/// name-and-password login, and the same option is offered again from their
/// profile screen.
class ConnectGooglePage extends StatefulWidget {
  /// Shown in the heading so the step feels like part of their sign-up.
  final String? playerName;

  const ConnectGooglePage({super.key, this.playerName});

  @override
  State<ConnectGooglePage> createState() => _ConnectGooglePageState();
}

class _ConnectGooglePageState extends State<ConnectGooglePage> {
  static const Color _inkColor = Color(0xFF2F5233);
  static const Color _bgTopColor = Color(0xFFE6F7E6);
  static const Color _bgBottomColor = Color(0xFFD4EDD1);
  static const Color _panelColor = Color(0xFFFAFFF9);
  static const Color _accentColor = Color(0xFF4CAF50);

  final GoogleLinkService _service = GoogleLinkService();

  bool _busy = false;
  GoogleLinkResult? _result;

  @override
  void initState() {
    super.initState();
    SoundService().playPageBgm(BgmPage.home);
  }

  Future<void> _connect() async {
    SoundService().playButtonSoundNow();
    setState(() {
      _busy = true;
      _result = null;
    });

    final result = await _service.linkGoogleAccount();
    if (!mounted) return;

    setState(() {
      _busy = false;
      _result = result;
    });

    // Give them a moment to read the confirmation before moving on.
    if (result.isSuccess) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (mounted) _finish();
    }
  }

  void _finish() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _skip() {
    SoundService().playButtonSoundNow();
    _finish();
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
              baseOffset: Offset(-36, -28),
              drift: Offset(14, 12),
              size: 146,
              color: Color(0x334CAF50),
              borderColor: Color(0x4D2F5233),
            ),
            AnimatedBackgroundShape(
              kind: BackgroundShapeKind.roundedSquare,
              alignment: Alignment.bottomRight,
              baseOffset: Offset(30, 36),
              drift: Offset(12, 14),
              size: 126,
              color: Color(0x2F1976D2),
              borderColor: Color(0x4D2F5233),
              cornerRadius: 30,
              initialRotation: 0.18,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mark_email_read_rounded, size: 52, color: _accentColor),
          const SizedBox(height: 14),
          Text(
            widget.playerName == null
                ? 'One last thing'
                : 'Nice to meet you, ${widget.playerName}!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _inkColor,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Do you want to connect a Gmail account now?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _inkColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'It gives you a second way to sign in and helps you get back into '
            'your account if you forget your password. Your scores and level '
            'stay exactly the same.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C6B5E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          if (_result != null) ...[
            _resultBanner(_result!),
            const SizedBox(height: 16),
          ],
          if (!(_result?.isBlocked ?? false)) _connectButton(width),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _busy ? null : _skip,
            child: Text(
              _result?.isSuccess == true ? 'Continue' : 'Maybe later',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _inkColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'You can connect it any time from your profile.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7A8A7C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectButton(double width) {
    return SizedBox(
      height: responsiveButtonHeight(width),
      child: ElevatedButton.icon(
        onPressed: _busy ? null : _connect,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _inkColor,
          disabledBackgroundColor: const Color(0xFFEFEFEF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _inkColor, width: 2.2),
          ),
        ),
        icon: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: _inkColor),
              )
            : const _GoogleGlyph(),
        label: Text(
          _busy ? 'Opening Google...' : 'Connect with Google',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _resultBanner(GoogleLinkResult result) {
    final (Color background, Color border, IconData icon) = switch (result.outcome) {
      GoogleLinkOutcome.linked => (
          const Color(0xFFE8F7EA),
          _accentColor,
          Icons.check_circle_rounded,
        ),
      GoogleLinkOutcome.cancelled => (
          const Color(0xFFF2F4F2),
          const Color(0xFF8A9A8C),
          Icons.info_outline_rounded,
        ),
      _ => (
          const Color(0xFFFFF4DC),
          const Color(0xFFE0A800),
          Icons.warning_amber_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: border),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              result.message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: _inkColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Google "G", drawn rather than shipped as an image so the button needs
/// no extra asset.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDADCE0), width: 1.2),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: Color(0xFF4285F4),
          height: 1,
        ),
      ),
    );
  }
}
