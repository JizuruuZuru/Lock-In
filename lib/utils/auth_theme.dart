import 'package:flutter/material.dart';

/// The theme the sign-in, register, welcome, Google-link, and onboarding
/// screens share.
///
/// `_buildTheme` was byte-identical between `login_page.dart` and
/// `register_page.dart` - 50 lines each, zero diff - with a fourth near-copy in
/// onboarding. It is close to [buildGameTheme] but not the same: these screens
/// have text fields, so they carry an `inputDecorationTheme`, and their primary
/// button is a size larger.
///
/// The colours are passed in rather than read from a palette because the
/// screens keep their own `_inkColor` / `_accentColor` statics, which they use
/// inside `const` expressions elsewhere.
ThemeData buildAuthTheme(
  BuildContext context, {
  required Color ink,
  required Color accent,
  required Color panel,
}) {
  final base = Theme.of(context);

  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 2),
      );

  return base.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: ink,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    inputDecorationTheme: InputDecorationTheme(
      border: border(ink),
      enabledBorder: border(ink),
      focusedBorder: border(accent),
      filled: true,
      fillColor: panel,
      labelStyle: TextStyle(color: ink),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 18,
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
  );
}
