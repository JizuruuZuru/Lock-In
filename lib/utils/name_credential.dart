String normalizeNamePart(String value) {
  final cleaned = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
      .replaceAll(RegExp(r'\.+'), '.')
      .replaceAll(RegExp(r'^\.|\.$'), '');
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
