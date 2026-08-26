/// Turns a display name into the Firestore-safe key a game's scores, logs,
/// and leaderboard entry are stored under - "English: Word Study" becomes
/// `english_word_study`.
///
/// Four separate places used to carry their own byte-identical copy of this,
/// each rebuilding three RegExps on every call. They all had to stay in
/// lockstep too: the key is part of the stored document shape, so a copy that
/// drifted would split one game's history across two keys.
library;

final RegExp _nonAlphanumericRun = RegExp(r'[^a-z0-9]+');
final RegExp _underscoreRun = RegExp(r'_+');
final RegExp _edgeUnderscores = RegExp(r'^_|_$');

String safeGameKey(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(_nonAlphanumericRun, '_')
      .replaceAll(_underscoreRun, '_')
      .replaceAll(_edgeUnderscores, '');
}
