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

  /// The project's **web** OAuth client, which is what Android mints the ID
  /// token against.
  ///
  /// Copied verbatim from `android/app/google-services.json` - the
  /// `"client_type": 3` entry under `oauth_client`. Re-read it from there if
  /// the Firebase project ever changes; a mismatch fails the same silent way
  /// an absent one does.
  ///
  /// Not a secret: it already ships inside the APK in that very file. What it
  /// is, is *required*. Calling `initialize()` without it - which is what this
  /// did - leaves `authenticate()` either returning an account whose `idToken`
  /// is null, or failing inside Credential Manager, which the plugin reports as
  /// `canceled`. Both are indistinguishable from the player simply changing
  /// their mind, which is why this looked like "the chooser cancels itself".
  static const String _serverClientId =
      '436363627484-ffiodf6qu23imbi5q4gpl2l99msas8kf.apps.googleusercontent.com';

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
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  /// Runs the Google chooser and links the chosen account to the signed-in
  /// player. Never throws — every path returns a [GoogleLinkResult].
  Future<GoogleLinkResult> linkGoogleAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      // Reachable in one non-obvious way: confirming a recovery email replaces
      // the account's sign-in address, which revokes the session. If the
      // silent re-sign-in in `EmailLinkService.confirmChange` did not manage
      // to rebuild it, everything downstream lands here.
      debugPrint(
        'linkGoogleAccount called with no signed-in user. If this followed an '
        'email confirmation, the session was revoked by the address change '
        'and could not be restored.',
      );
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
        // The on-screen message stays kid-safe, but "enable it in the console"
        // sends a developer to a switch that is usually already on. Getting
        // this far means the chooser opened and Google returned an account -
        // the token is missing because Android had no web client id to ask
        // for one with. That comes from `google-services.json`, and it is
        // empty until a SHA-1 fingerprint is registered and the file is
        // downloaded again. See docs/GOOGLE_SIGN_IN_SETUP.md.
        debugPrint(
          'Google returned an account but no ID token. Check, in order: '
          '(1) `_serverClientId` here still matches the "client_type": 3 entry '
          'in android/app/google-services.json; (2) that file has a non-empty '
          '"oauth_client" - it stays empty until a SHA-1 fingerprint is '
          'registered and the file re-downloaded; (3) flutter clean, since '
          'gradle bakes the old copy into generated resources. '
          'See docs/GOOGLE_SIGN_IN_SETUP.md.',
        );
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
        // Usually a real "changed my mind" - but not always. Android's
        // Credential Manager reports a misconfigured or unusable request the
        // same way, so a chooser that closes instantly, or never appears at
        // all, lands here too and looks identical to a deliberate dismissal.
        debugPrint(
          'Google sign-in reported canceled: ${error.description}. If the '
          'chooser never actually appeared, this is configuration rather than '
          'the player - check `_serverClientId` and the registered SHA-1.',
        );
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
        // Almost always the SHA-1 fingerprint: Google refuses to hand an
        // account to an app it cannot recognise the signature of.
        debugPrint(
          'Google rejected this app\'s configuration: ${error.description}. '
          'Check the debug SHA-1 is registered on the Android app in the '
          'Firebase console. See docs/GOOGLE_SIGN_IN_SETUP.md.',
        );
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
