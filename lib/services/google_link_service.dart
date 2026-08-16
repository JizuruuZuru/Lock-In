import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// How an attempt to connect a Google account ended.
enum GoogleLinkOutcome {
  /// The Google account is now attached to this player's profile.
  linked,

  /// The player backed out of the Google chooser. Not an error.
  cancelled,

  /// This device or platform cannot show the Google chooser at all
  /// (Windows, Linux, and the web all fall in here).
  unsupported,

  /// Google sign-in has not been switched on for this Firebase project, so
  /// there is nothing to sign in against yet.
  notConfigured,

  /// This player already has a Google account attached.
  alreadyLinked,

  /// That Google account belongs to a different Lock In player.
  takenByAnotherAccount,

  /// Anything else.
  failed,
}

/// Result of [GoogleLinkService.linkGoogleAccount], carrying a message that is
/// already safe to put on screen.
class GoogleLinkResult {
  final GoogleLinkOutcome outcome;
  final String message;

  /// The Gmail address that got attached, when [outcome] is
  /// [GoogleLinkOutcome.linked].
  final String? email;

  const GoogleLinkResult({
    required this.outcome,
    required this.message,
    this.email,
  });

  bool get isSuccess => outcome == GoogleLinkOutcome.linked;

  /// True when there is no point offering a retry button.
  bool get isBlocked =>
      outcome == GoogleLinkOutcome.unsupported ||
      outcome == GoogleLinkOutcome.notConfigured;
}

/// Attaches a Google (Gmail) account to the player's existing Lock In profile.
///
/// This is a *link*, not a second account: the player keeps the same uid,
/// scores, and leaderboard history, and simply gains Google as an extra way to
/// sign in. Nothing here is required — a player who skips it keeps using their
/// name and password.
///
/// Google verifies the person's identity during its own sign-in flow, which is
/// why no separate code needs to be typed into the app.
///
/// Written against google_sign_in v7, whose API differs from earlier versions:
/// there is a single [GoogleSignIn.instance], `initialize()` must run once
/// before anything else, and `authenticate()` replaces the old `signIn()`.
class GoogleLinkService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  GoogleLinkService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// `initialize()` is only meaningful once per process.
  static bool _initialized = false;

  /// Whether this platform can show Google's interactive chooser.
  ///
  /// v7 only implements `authenticate()` on Android, iOS, and macOS. The web
  /// build uses a rendered button instead, and Windows and Linux have no
  /// implementation at all — so the button is hidden rather than offered and
  /// then failing.
  static bool get isSupportedPlatform {
    try {
      return GoogleSignIn.instance.supportsAuthenticate();
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize();
    _initialized = true;
  }

  /// Runs the Google chooser and links the chosen account to the signed-in
  /// player. Never throws — every path returns a [GoogleLinkResult].
  Future<GoogleLinkResult> linkGoogleAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const GoogleLinkResult(
        outcome: GoogleLinkOutcome.failed,
        message: 'You need to be signed in before connecting a Google account.',
      );
    }

    if (user.providerData.any((info) => info.providerId == 'google.com')) {
      return const GoogleLinkResult(
        outcome: GoogleLinkOutcome.alreadyLinked,
        message: 'This profile already has a Google account connected.',
      );
    }

    if (!isSupportedPlatform) {
      return const GoogleLinkResult(
        outcome: GoogleLinkOutcome.unsupported,
        message:
            'Connecting a Google account works on the phone app. Open Lock In on your phone or tablet to add it.',
      );
    }

    try {
      await _ensureInitialized();

      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;

      // No ID token means the project has no OAuth client for this app, which
      // is a setup gap rather than something the player did wrong.
      if (idToken == null || idToken.isEmpty) {
        return const GoogleLinkResult(
          outcome: GoogleLinkOutcome.notConfigured,
          message:
              'Google sign-in is not set up for this app yet. Ask your teacher to enable it in the Firebase console.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final linked = await user.linkWithCredential(credential);
      final email = linked.user?.email ?? account.email;

      await _recordLink(uid: user.uid, email: email);

      return GoogleLinkResult(
        outcome: GoogleLinkOutcome.linked,
        message: 'Connected to $email.',
        email: email,
      );
    } on GoogleSignInException catch (error) {
      return _fromGoogleException(error);
    } on FirebaseAuthException catch (error) {
      return _fromFirebaseException(error);
    } catch (error) {
      debugPrint('Google link failed: $error');
      return const GoogleLinkResult(
        outcome: GoogleLinkOutcome.failed,
        message: 'Could not connect that Google account. Please try again.',
      );
    }
  }

  GoogleLinkResult _fromGoogleException(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return const GoogleLinkResult(
          outcome: GoogleLinkOutcome.cancelled,
          message: 'No problem - you can connect a Google account later.',
        );
      case GoogleSignInExceptionCode.uiUnavailable:
        return const GoogleLinkResult(
          outcome: GoogleLinkOutcome.unsupported,
          message:
              'Google sign-in cannot open on this device. Try the app on your phone or tablet.',
        );
      case GoogleSignInExceptionCode.clientConfigurationError:
        return const GoogleLinkResult(
          outcome: GoogleLinkOutcome.notConfigured,
          message:
              'Google sign-in is not set up for this app yet. Ask your teacher to enable it in the Firebase console.',
        );
      default:
        debugPrint('GoogleSignInException: ${error.code} ${error.description}');
        return const GoogleLinkResult(
          outcome: GoogleLinkOutcome.failed,
          message: 'Google sign-in did not finish. Please try again.',
        );
    }
  }

  GoogleLinkResult _fromFirebaseException(FirebaseAuthException error) {
    switch (error.code) {
      case 'provider-already-linked':
        return const GoogleLinkResult(
          outcome: GoogleLinkOutcome.alreadyLinked,
          message: 'This profile already has a Google account connected.',
        );
      case 'credential-already-in-use':
      case 'email-already-in-use':
        return const GoogleLinkResult(
          outcome: GoogleLinkOutcome.takenByAnotherAccount,
          message:
              'That Google account is already connected to a different Lock In player. Pick another one.',
        );
      case 'operation-not-allowed':
        return const GoogleLinkResult(
          outcome: GoogleLinkOutcome.notConfigured,
          message:
              'Google sign-in is turned off for this project. Ask your teacher to enable it in the Firebase console.',
        );
      default:
        return GoogleLinkResult(
          outcome: GoogleLinkOutcome.failed,
          message: error.message ?? 'Could not connect that Google account.',
        );
    }
  }

  /// Notes the connection on the player's profile so the admin account list and
  /// the profile screen can show it. A failure here is not worth surfacing —
  /// the accounts are already linked in Firebase Auth, which is what matters.
  Future<void> _recordLink({required String uid, String? email}) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'googleLinked': true,
        if (email != null) 'googleEmail': email,
        'googleLinkedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Could not record the Google link on the profile: $error');
    }
  }

  /// Whether the signed-in player already has Google attached.
  bool get isCurrentUserLinked {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == 'google.com');
  }

  /// The connected Gmail address, or null when there is none.
  String? get linkedEmail {
    final user = _auth.currentUser;
    if (user == null) return null;
    for (final info in user.providerData) {
      if (info.providerId == 'google.com') return info.email;
    }
    return null;
  }
}
