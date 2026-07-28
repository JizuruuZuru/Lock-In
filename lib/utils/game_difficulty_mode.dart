/// Shared difficulty mode applied consistently across every game and the exam.
///
/// - [easy]: untimed practice, standard hearts.
/// - [normal]: standard timer, standard hearts.
/// - [hard]: standard timer, but only a single heart.
enum GameDifficultyMode { easy, normal, hard }

String gameDifficultyModeLabel(GameDifficultyMode mode) {
  switch (mode) {
    case GameDifficultyMode.easy:
      return 'Easy';
    case GameDifficultyMode.normal:
      return 'Normal';
    case GameDifficultyMode.hard:
      return 'Hard';
  }
}

String gameDifficultyModeDescription(GameDifficultyMode mode) {
  switch (mode) {
    case GameDifficultyMode.easy:
      return 'No timer, 3 hearts';
    case GameDifficultyMode.normal:
      return 'Timed, 3 hearts';
    case GameDifficultyMode.hard:
      return 'Timed, 1 heart';
  }
}

bool gameDifficultyModeHasTimer(GameDifficultyMode mode) {
  return mode != GameDifficultyMode.easy;
}

int gameDifficultyModeHearts(GameDifficultyMode mode) {
  return mode == GameDifficultyMode.hard ? 1 : 3;
}
