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
