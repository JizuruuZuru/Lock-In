import 'package:flutter/material.dart';
import '../services/sound_service.dart';

class TermsDialog extends StatefulWidget {
  const TermsDialog({super.key});

  @override
  State<TermsDialog> createState() => _TermsDialogState();
}

class _TermsDialogState extends State<TermsDialog> {
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    // Play warning sound (optional, but matches other dialogs)
    SoundService().playLeaveWarningSoundNow();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0), // cream
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD84315), // orange
            width: 2.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_rounded,
              color: Color(0xFFD84315),
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Terms and Conditions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3E2723),
              ),
            ),
            const SizedBox(height: 16),
            // Scrollable terms text
            Expanded(
              child: SingleChildScrollView(
                child: _buildTermsText(),
              ),
            ),
            const SizedBox(height: 20),
            // Checkbox and acceptance
            Row(
              children: [
                Checkbox(
                  value: _accepted,
                  onChanged: (value) {
                    setState(() {
                      _accepted = value ?? false;
                    });
                    SoundService().playButtonSoundNow();
                  },
                  activeColor: const Color(0xFFD84315),
                  checkColor: Colors.white,
                ),
                const Expanded(
                  child: Text(
                    'I have read and agree to the Terms and Conditions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4E342E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Confirm button (enabled only if accepted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _accepted
                    ? () {
                        SoundService().playButtonSoundNow();
                        Navigator.of(context).pop(true);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: const Color(0xFFD84315),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return const Text(
      '''
Welcome to Lock In!

These Terms and Conditions govern your use of our brain training application. By creating an account, you agree to the following:

1. **Account Registration**
   - You must provide accurate and complete information.
   - You are responsible for maintaining the confidentiality of your login credentials.

2. **Data Collection and Privacy**
   - We collect your username, email, and game progress (scores, levels, history) to provide and improve our services.
   - Game logs and leaderboard entries are stored securely in Firebase.
   - Your data may be used for anonymized analytics to enhance user experience.

3. **Fair Play and Anti-Cheat**
   - The app can use face detection (front camera) to check you are present during games. Your teacher decides whether it is available, and you can turn it off for yourself under Camera anti-cheat in your profile settings.
   - The camera is only used to check that a face is present. No photo or video is recorded, stored, or sent anywhere.
   - Scores are labelled on the leaderboard with whether the camera was on, so playing without it is allowed but visible to everyone.
   - Attempting to cheat or exploit the system may result in account suspension.

4. **Leaderboards and Public Profiles**
   - Your username and scores will be visible on public leaderboards.
   - You can request removal of your data by contacting support.

5. **Changes to Terms**
   - We may update these terms from time to time. Continued use of the app constitutes acceptance of the revised terms.

6. **Contact**
   - For any questions, please contact support@lockinapp.example.

By checking the box and continuing, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.
      ''',
      style: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: Color(0xFF3E2723),
      ),
    );
  }
}