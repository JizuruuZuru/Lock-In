import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import '../utils/game_difficulty_mode.dart';

/// A row of choice chips for picking [GameDifficultyMode], styled to match
/// the subject choice chips used across the app so every game and the exam
/// present the same control for this choice.
class DifficultyModeSelector extends StatelessWidget {
  final GameDifficultyMode selected;
  final ValueChanged<GameDifficultyMode> onChanged;
  final Color accentColor;

  const DifficultyModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final mode in GameDifficultyMode.values) _chip(mode),
      ],
    );
  }

  Widget _chip(GameDifficultyMode mode) {
    final isSelected = selected == mode;
    return ChoiceChip(
      label: Text(gameDifficultyModeLabel(mode)),
      selected: isSelected,
      selectedColor: accentColor.withValues(alpha: 0.18),
      onSelected: (_) {
        SoundService().playButtonSoundNow();
        onChanged(mode);
      },
    );
  }
}
