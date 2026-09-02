import 'package:flutter/material.dart';

/// The five colour slots every game screen defines.
///
/// Each game declared its own `_inkColor` / `_bgTopColor` / `_bgBottomColor` /
/// `_panelColor` / `_accentColor` statics, and across the nine Math games there
/// were only four distinct sets. These are those sets, named - so a new game
/// picks a look instead of inventing a fifth palette, and so a tweak to the
/// house style lands everywhere at once.
///
/// This mirrors `AdminPalette` in `admin_theme.dart`, which already does the
/// same job for the admin area.
class GamePalette {
  final Color ink;
  final Color bgTop;
  final Color bgBottom;
  final Color panel;
  final Color accent;

  const GamePalette({
    required this.ink,
    required this.bgTop,
    required this.bgBottom,
    required this.panel,
    required this.accent,
  });

  /// Green - the default. Fractions, Measurements, Order of Operations,
  /// Place Value, Rounding, and the Exam.
  static const GamePalette green = GamePalette(
    ink: Color(0xFF2F5233),
    bgTop: Color(0xFFE6F7E6),
    bgBottom: Color(0xFFD4EDD1),
    panel: Color(0xFFFAFFF9),
    accent: Color(0xFF4CAF50),
  );

  /// Warm purple. Math and Roman Numerals.
  static const GamePalette violet = GamePalette(
    ink: Color(0xFF2C1B47),
    bgTop: Color(0xFFFFF4E6),
    bgBottom: Color(0xFFFFE0D6),
    panel: Color(0xFFFFFBEE),
    accent: Color(0xFF9C27B0),
  );

  /// Blue ink over the green ground. Analog Clock.
  static const GamePalette ocean = GamePalette(
    ink: Color(0xFF1B4965),
    bgTop: Color(0xFFE6F7E6),
    bgBottom: Color(0xFFD4EDD1),
    panel: Color(0xFFFAFFF9),
    accent: Color(0xFF4CAF50),
  );

  /// Peach ground, teal accent. Number Memory.
  static const GamePalette sunset = GamePalette(
    ink: Color(0xFF1B4965),
    bgTop: Color(0xFFFFE5D9),
    bgBottom: Color(0xFFFFCCB3),
    panel: Color(0xFFFFF9E6),
    accent: Color(0xFF069A8E),
  );
}

/// The app-wide hard-shadow signature: offset, zero blur.
///
/// The same three values were retyped in every game's card and in
/// `AdminPalette.hardShadow`.
const List<BoxShadow> kGameHardShadow = [
  BoxShadow(color: Color(0x332C3550), offset: Offset(5, 6), blurRadius: 0),
];

/// The chunky, high-contrast theme every game screen applies.
///
/// This was hand-copied into eleven game screens - byte-identical in four of
/// them, and differing only in which two colours were substituted in the rest.
/// [ink] and [accent] are passed in rather than read from a [GamePalette] so
/// callers can keep their existing colour constants, which several of them use
/// inside `const` expressions elsewhere.
ThemeData buildGameTheme(
  BuildContext context, {
  required Color ink,
  required Color accent,
}) {
  final base = Theme.of(context);
  return base.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: ink,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: ink, width: 2),
        ),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

/// The bordered panel every game draws its content on.
///
/// Was eleven byte-identical private `_card` methods.
Widget gameCard({
  required Widget child,
  required Color panel,
  required Color ink,
  EdgeInsetsGeometry padding = const EdgeInsets.all(18),
}) {
  return Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: ink, width: 2.2),
      boxShadow: kGameHardShadow,
    ),
    child: child,
  );
}
