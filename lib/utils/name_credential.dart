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

String buildNameCredentialEmail({
  required String firstName,
  required String lastName,
}) {
  final loginId = buildNameLoginId(firstName: firstName, lastName: lastName);
  return '$loginId@lockinplayers.app';
}

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
