import 'package:flutter/material.dart';

class HeartsDisplay extends StatelessWidget {
  final int hearts;

  /// How many hearts this run *can* have, i.e. the row's length.
  ///
  /// This used to be hardcoded to 3, but Hard mode grants only one
  /// ([gameDifficultyModeHearts]) - so a Hard player opened the game looking at
  /// one filled and two empty hearts, which reads as "you have already lost two
  /// lives" before a single question.
  final int maxHearts;

  final Color color;

  const HeartsDisplay({
    super.key,
    required this.hearts,
    this.maxHearts = 3,
    this.color = const Color(0xFFF44336),
  });

  @override
  Widget build(BuildContext context) {
    // Never fewer slots than there are hearts to show, so a caller that passes
    // a stale capacity still renders every life the player actually has.
    final slots = maxHearts < hearts ? hearts : maxHearts;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(slots, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            index < hearts ? Icons.favorite : Icons.favorite_border,
            color: color,
            size: 28,
          ),
        );
      }),
    );
  }
}
