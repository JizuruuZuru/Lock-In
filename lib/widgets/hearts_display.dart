import 'package:flutter/material.dart';

class HeartsDisplay extends StatelessWidget {
  final int hearts;
  final Color color;

  const HeartsDisplay({
    super.key,
    required this.hearts,
    this.color = const Color(0xFFF44336),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
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
