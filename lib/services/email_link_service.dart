import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../utils/auth_error_message.dart';
import '../utils/name_credential.dart';

/// How an attempt to attach a real email address ended.
enum EmailLinkOutcome {
  /// A verification link is on its way to the address they typed.
  verificationSent,

  /// The address is already on this account and already verified.
  alreadyVerified,

  /// They typed the address that is already pending verification.
  alreadyPending,

  /// Not an address we can send anything to.
  invalidEmail,

  /// Another Lock In player already uses that address.
  takenByAnotherAccount,

  /// Firebase wants the password typed again before it will change the
  /// sign-in address. Not an error - the screen asks and retries.
  needsPassword,

  /// Nobody is signed in.
  notSignedIn,

  /// Anything else.
  failed,
}

/// How a "have they opened the link yet?" check ended.
enum EmailChangeOutcome {
  /// The address is on the account, confirmed, and the session is usable.
  verified,

  /// The link has not been opened yet. Nothing is wrong; ask again later.
  notYet,

  /// The change landed, but signing back in afterwards failed. The player has
  /// to sign in by hand with their new address.
  signInRequired,
}

/// Result of an [EmailLinkService] call, carrying a message already safe to
/// put on screen.
class EmailLinkResult {
  final EmailLinkOutcome outcome;
  final String message;

  /// The address involved, when there is one.
  final String? email;

  const EmailLinkResult({
    required this.outcome,
    required this.message,
    this.email,
  });

  bool get isSuccess => outcome == EmailLinkOutcome.verificationSent;

  /// The screen should collect the password and call again.
  bool get needsPassword => outcome == EmailLinkOutcome.needsPassword;

  /// Already done - nothing left to ask for.
  bool get isSettled =>
      outcome == EmailLinkOutcome.alreadyVerified ||
      outcome == EmailLinkOutcome.alreadyPending;
}

/// Attaches a real, reachable email address to a player's existing account.
///
/// Every account signs in with a made-up address built from the child's name
/// (`ana.cruz@lockinplayers.app`, see [buildNameCredentialEmail]). That domain
/// does not exist, so nothing can ever be sent to it - which means a forgotten
/// password is unrecoverable and a lost session takes the scores with it. This
/// is what fixes that.
///
/// **It changes the sign-in address.** `verifyBeforeUpdateEmail` sends a link
/// to the new address and, once it is clicked, Firebase *replaces* the
/// account's email with it. Firebase allows exactly one email per account, so
/// there is no way to hold a real address alongside the name credential. From
/// then on the child signs in with their email, and [LoginPage] says so when
/// the name no longer matches. What that buys is real password recovery
/// ([sendPasswordReset]), which is the entire point of collecting an address
/// on an app whose users forget passwords constantly.
///
/// Confirming also **ends the current session** - Firebase revokes the refresh
/// token the instant the address changes. [confirmChange] treats that as the
/// success signal and signs straight back in with the new address and the same
/// password, on the same uid, so the child never sees it happen.
///
/// Modelled on [GoogleLinkService]: the uid, scores, and leaderboard place all
/// stay exactly where they are, and no method here ever throws - every path
/// returns a result with a message a child can read.
class EmailLinkService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  EmailLinkService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get _user => _auth.currentUser;

  /// Whether this account already signs in with a real address it has proved
  /// it can receive mail at.
  bool get hasVerifiedEmail {
    final user = _user;
    if (user == null) return false;
    return user.emailVerified && !isNameCredential(user.email);
  }

  /// The real address on the account, or null while it is still the synthetic
  /// name credential.
  String? get verifiedEmail {
    final user = _user;
    if (user == null || !hasVerifiedEmail) return null;
    return user.email;
  }

  /// Sends the verification link.
  ///
  /// [password] is only needed when a previous call came back
  /// [EmailLinkOutcome.needsPassword] - Firebase refuses to change a sign-in
  /// address on a session that has been open a while, and wants the password
  /// re-entered first.
  Future<EmailLinkResult> sendVerification(
    String email, {
    String? password,
  }) async {
    final user = _user;
    if (user == null) {
      return const EmailLinkResult(
        outcome: EmailLinkOutcome.notSignedIn,
        message: 'You need to be signed in before adding an email address.',
      );
    }

    final address = email.trim();
    if (!looksLikeRealEmail(address)) {
      return const EmailLinkResult(
        outcome: EmailLinkOutcome.invalidEmail,
        message: 'That does not look like an email address. '
            'It should look like name@example.com.',
      );
    }

    if (user.emailVerified &&
        (user.email ?? '').toLowerCase() == address.toLowerCase()) {
      return EmailLinkResult(
        outcome: EmailLinkOutcome.alreadyVerified,
        message: '$address is already confirmed on this account.',
        email: address,
      );
    }

    try {
      // Normalised exactly as the register and login screens do it, or a
      // trailing space from a soft keyboard silently produces a different
      // string from the one the credential was stored with.
      final secret = normalizePassword(password ?? '');
      if (secret.isNotEmpty) {
        await _reauthenticate(user, secret);
      }

      await user.verifyBeforeUpdateEmail(address);
      _rememberPending(user.uid, address);

      return EmailLinkResult(
        outcome: EmailLinkOutcome.verificationSent,
        message: 'Check $address for a message from us, and open the link '
            'inside it.',
        email: address,
      );
    } on FirebaseAuthException catch (error) {
      return _fromFirebaseException(error, address);
    } catch (error) {
      debugPrint('Email verification failed: $error');
      return const EmailLinkResult(
        outcome: EmailLinkOutcome.failed,
        message: 'Could not send the email just now. Please try again.',
      );
    }
  }

  /// Checks whether the link has been opened, and puts the session back.
  ///
  /// Firebase does not push this - the child opens the link in their mail app,
  /// which is a different app entirely - so the screen asks when they come
  /// back and say they are done.
  ///
  /// **A dead session is the success signal, not a failure.** Changing the
  /// address revokes the refresh token, which is why Firebase's own
  /// confirmation page ends with "You can now sign in with your new email". So
  /// `reload()` throws `user-token-expired`, and `currentUser` keeps handing
  /// back a stale cached [User] still carrying the old synthetic address with
  /// `emailVerified: false`.
  ///
  /// An earlier version of this method read that stale object and concluded
  /// "not yet" - forever, no matter how many times the link was opened. It was
  /// structurally incapable of ever returning true.
  ///
  /// Once the change is detected, signing in again with the new address and the
  /// same password restores the session on the **same uid**, so the scores,
  /// level, and leaderboard place are all untouched and the child never sees a
  /// sign-out.
  Future<EmailChangeOutcome> confirmChange({
    required String newEmail,
    required String password,
  }) async {
    final address = newEmail.trim();
    var sessionEnded = _user == null;

    final user = _user;
    if (user != null) {
      try {
        await user.reload();
        final refreshed = _auth.currentUser;
        if (refreshed == null) {
          sessionEnded = true;
        } else if (refreshed.emailVerified &&
            !isNameCredential(refreshed.email)) {
          // The token outlived the change. Nothing else to do.
          _rememberVerified(refreshed.uid, refreshed.email!);
          return EmailChangeOutcome.verified;
        }
      } on FirebaseAuthException catch (error) {
        sessionEnded = error.code == 'user-token-expired' ||
            error.code == 'user-not-found' ||
            error.code == 'user-disabled';
        if (!sessionEnded) {
          debugPrint('Could not refresh the account: ${error.code}');
          return EmailChangeOutcome.notYet;
        }
      } catch (error) {
        // Offline, most likely. Nothing has been proved either way.
        debugPrint('Could not refresh the account: $error');
        return EmailChangeOutcome.notYet;
      }
    }

    if (!sessionEnded) return EmailChangeOutcome.notYet;

    final secret = normalizePassword(password);
    if (secret.isEmpty) return EmailChangeOutcome.signInRequired;

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: address,
        password: secret,
      );
      final restored = credential.user;
      if (restored == null) return EmailChangeOutcome.signInRequired;

      _rememberVerified(restored.uid, address);
      return EmailChangeOutcome.verified;
    } on FirebaseAuthException catch (error) {
      // No account on the new address yet means the link really is still
      // sitting unopened in the inbox.
      if (error.code == 'user-not-found') {
        return EmailChangeOutcome.notYet;
      }

      // A rejected *password*, though, means the address exists and the
      // change already landed - the opposite of "not yet". Reporting it as
      // "not yet" left a child tapping "I've opened the link" forever on a
      // session that was already revoked, with no way to say what was wrong.
      if (error.code == 'invalid-credential' ||
          error.code == 'wrong-password') {
        debugPrint('The new address exists but the password was rejected.');
        return EmailChangeOutcome.signInRequired;
      }
      debugPrint('Could not sign back in after the email change: '
          '${error.code}');
      return EmailChangeOutcome.signInRequired;
    } catch (error) {
      debugPrint('Could not sign back in after the email change: $error');
      return EmailChangeOutcome.signInRequired;
    }
  }

  /// Sends a password-reset mail. Only works once a real address is on the
  /// account, which is the whole reason [sendVerification] exists.
  Future<EmailLinkResult> sendPasswordReset(String email) async {
    final address = email.trim();
    if (!looksLikeRealEmail(address)) {
      return const EmailLinkResult(
        outcome: EmailLinkOutcome.invalidEmail,
        message: 'Type the email address on your account, '
            'like name@example.com.',
      );
    }

    try {
      await _auth.sendPasswordResetEmail(email: address);
      return EmailLinkResult(
        outcome: EmailLinkOutcome.verificationSent,
        message: 'If $address is on an account, a reset link is on its way.',
        email: address,
      );
    } on FirebaseAuthException catch (error) {
      // Deliberately not distinguishing "no such account" here - saying so
      // would let anybody check which addresses are registered.
      if (error.code == 'user-not-found') {
        return EmailLinkResult(
          outcome: EmailLinkOutcome.verificationSent,
          message: 'If $address is on an account, a reset link is on its way.',
          email: address,
        );
      }
      return EmailLinkResult(
        outcome: EmailLinkOutcome.failed,
        message: authErrorMessage(
          error,
          fallback: 'Could not send the reset email. Please try again.',
        ),
      );
    } catch (error) {
      debugPrint('Password reset failed: $error');
      return const EmailLinkResult(
        outcome: EmailLinkOutcome.failed,
        message: 'Could not send the reset email. Please try again.',
      );
    }
  }

  Future<void> _reauthenticate(User user, String password) async {
    final current = user.email;
    if (current == null || current.isEmpty) return;
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: current, password: password),
    );
  }

  EmailLinkResult _fromFirebaseException(
    FirebaseAuthException error,
    String address,
  ) {
    switch (error.code) {
      case 'requires-recent-login':
        return const EmailLinkResult(
          outcome: EmailLinkOutcome.needsPassword,
          message: 'Type your password once more so we know it is you.',
        );
      case 'email-already-in-use':
      case 'credential-already-in-use':
        return EmailLinkResult(
          outcome: EmailLinkOutcome.takenByAnotherAccount,
          message: 'Another Lock In player already uses $address. '
              'Try a different one.',
          email: address,
        );
      case 'invalid-email':
        return const EmailLinkResult(
          outcome: EmailLinkOutcome.invalidEmail,
          message: 'That does not look like an email address. '
              'It should look like name@example.com.',
        );
      case 'invalid-credential':
      case 'wrong-password':
        return const EmailLinkResult(
          outcome: EmailLinkOutcome.needsPassword,
          message: 'That password did not match. Try typing it again.',
        );
      default:
        return EmailLinkResult(
          outcome: EmailLinkOutcome.failed,
          // Routed through the shared mapper rather than Firebase's own
          // wording, which is written for developers.
          message: authErrorMessage(
            error,
            fallback: 'Could not add that email address. Please try again.',
          ),
        );
    }
  }

  /// Bookkeeping so the profile screen and the admin list can show the state.
  ///
  /// Fire-and-forget on purpose: Firebase Auth is the source of truth for
  /// whether an address is verified, and a Firestore write future does not
  /// complete until the server acknowledges it - awaiting one here would hang
  /// the screen on a flaky connection for a value nothing reads back
  /// immediately.
  void _rememberPending(String uid, String address) {
    unawaited(
      _firestore.collection('users').doc(uid).set({
        'recoveryEmailPending': address,
        'recoveryEmailPendingAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((Object error) {
        debugPrint('Could not record the pending email: $error');
      }),
    );
  }

  void _rememberVerified(String uid, String address) {
    unawaited(
      _firestore.collection('users').doc(uid).set({
        'recoveryEmail': address,
        'recoveryEmailVerified': true,
        'recoveryEmailVerifiedAt': FieldValue.serverTimestamp(),
        'recoveryEmailPending': FieldValue.delete(),
        // The sign-in address really did change, and `AppUserRecord.email`
        // reads `loginEmail` first - so leaving these on the old synthetic
        // value would show the child a credential that no longer works.
        'loginEmail': address,
        'email': address,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((Object error) {
        debugPrint('Could not record the verified email: $error');
      }),
    );
  }
}
