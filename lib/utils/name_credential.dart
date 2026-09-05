String normalizeNamePart(String value) {
  final cleaned = value
      .trim()
      .toLowerCase()
      .replaceAll(_nonAlphanumericRun, '.')
      .replaceAll(_dotRun, '.')
      .replaceAll(_edgeDots, '');
  return cleaned;
}

String buildNameLoginId({
  required String firstName,
  required String lastName,
}) {
  final first = normalizeNamePart(firstName);
  final last = normalizeNamePart(lastName);

  if (first.isEmpty && last.isEmpty) return 'player';
  if (first.isEmpty) return last;
  if (last.isEmpty) return first;
  return '$first.$last';
}

/// The made-up domain the name-based credentials live on.
///
/// It does not resolve and never receives mail, which is exactly why an
/// account that has only this address cannot be recovered. [isNameCredential]
/// is how the rest of the app tells "this child has only their name" from
/// "this child has given us a real address we can reach them at".
const String kNameCredentialDomain = 'lockinplayers.app';

String buildNameCredentialEmail({
  required String firstName,
  required String lastName,
}) {
  final loginId = buildNameLoginId(firstName: firstName, lastName: lastName);
  return '$loginId@$kNameCredentialDomain';
}

/// Whether [email] is one of the synthetic name credentials rather than a real
/// address somebody can actually receive mail at.
bool isNameCredential(String? email) {
  final value = email?.trim().toLowerCase();
  if (value == null || value.isEmpty) return true;
  return value.endsWith('@$kNameCredentialDomain');
}

/// A deliberately permissive check - enough to catch a typo like a missing `@`
/// or a trailing comma, without trying to out-guess a mail server about what
/// is deliverable. The verification mail is the real test.
bool looksLikeRealEmail(String value) {
  final email = value.trim();
  if (email.isEmpty || email.length > 254) return false;
  if (isNameCredential(email)) return false;
  return _emailShape.hasMatch(email);
}

final RegExp _emailShape = RegExp(r'^[^@\s,]+@[^@\s,.]+(\.[^@\s,.]+)+$');

final RegExp _nonAlphanumericRun = RegExp(r'[^a-z0-9]+');
final RegExp _dotRun = RegExp(r'\.+');
final RegExp _edgeDots = RegExp(r'^\.|\.$');

/// The single rule for turning a typed password into the one Firebase stores.
///
/// Login used to `.trim()` while register and the admin account editor did not,
/// so a password created with a leading or trailing space was stored untrimmed
/// and then trimmed on the way back in - it could never be typed again, and
/// there is no password reset for a synthetic `@lockinplayers.app` address to
/// recover with. Every screen that reads a password field now goes through
/// here, so the two halves cannot drift apart again.
String normalizePassword(String value) => value.trim();
