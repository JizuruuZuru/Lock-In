import 'package:flutter/material.dart';

import '../widgets/animated_shape_background.dart';

/// Palette and building blocks shared by every admin screen.
///
/// The rest of the app declares its colours as private statics inside each
/// screen; the admin area is new surface, so its five colours live here once
/// and the screens read them from [AdminPalette] instead of redeclaring them.
class AdminPalette {
  const AdminPalette._();

  static const Color ink = Color(0xFF2B1B4D);
  static const Color bgTop = Color(0xFFF0EBFF);
  static const Color bgBottom = Color(0xFFDCD3FA);
  static const Color panel = Color(0xFFFCFAFF);
  static const Color accent = Color(0xFF6A3FC4);
  static const Color danger = Color(0xFFC62828);
  static const Color success = Color(0xFF2E7D32);
  static const Color muted = Color(0xFF6B6382);

  /// The app-wide hard-shadow signature: offset, zero blur.
  static const List<BoxShadow> hardShadow = [
    BoxShadow(color: Color(0x332C3550), offset: Offset(5, 6), blurRadius: 0),
  ];

  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x222C3550), offset: Offset(3, 4), blurRadius: 0),
  ];
}

/// Local theme applied by [AdminScaffold]. Matches the chunky, high-contrast
/// look the games use so the admin area does not feel like a different app.
ThemeData buildAdminTheme(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: AdminPalette.ink,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AdminPalette.ink,
      displayColor: AdminPalette.ink,
    ),
    iconTheme: const IconThemeData(color: AdminPalette.ink),
    dividerColor: const Color(0x332B1B4D),
    inputDecorationTheme: InputDecorationTheme(
      border: _adminBorder(AdminPalette.ink),
      enabledBorder: _adminBorder(AdminPalette.ink),
      focusedBorder: _adminBorder(AdminPalette.accent),
      errorBorder: _adminBorder(AdminPalette.danger),
      focusedErrorBorder: _adminBorder(AdminPalette.danger),
      filled: true,
      fillColor: AdminPalette.panel,
      labelStyle: const TextStyle(
        color: AdminPalette.ink,
        fontWeight: FontWeight.w700,
      ),
      helperStyle: const TextStyle(color: AdminPalette.muted, fontSize: 12),
      errorStyle: const TextStyle(
        color: AdminPalette.danger,
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AdminPalette.accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFB9AEDA),
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AdminPalette.ink, width: 2),
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AdminPalette.ink,
        backgroundColor: AdminPalette.panel,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        side: const BorderSide(color: AdminPalette.ink, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AdminPalette.ink,
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

OutlineInputBorder _adminBorder(Color color) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: 2),
  );
}

/// Scaffold + animated background + local theme, so each admin screen only has
/// to supply its title and body.
class AdminScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final bool showBackButton;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.floatingActionButton,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildAdminTheme(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: showBackButton,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xCCFFFFFF),
                  ),
                ),
            ],
          ),
          actions: actions,
        ),
        floatingActionButton: floatingActionButton,
        body: AnimatedShapeBackground(
          gradientColors: const [AdminPalette.bgTop, AdminPalette.bgBottom],
          shapes: const [
            AnimatedBackgroundShape(
              kind: BackgroundShapeKind.roundedSquare,
              alignment: Alignment.topLeft,
              baseOffset: Offset(-40, -32),
              drift: Offset(16, 12),
              size: 150,
              color: Color(0x336A3FC4),
              borderColor: Color(0x442B1B4D),
              cornerRadius: 34,
              initialRotation: -0.18,
            ),
            AnimatedBackgroundShape(
              kind: BackgroundShapeKind.circle,
              alignment: Alignment.bottomRight,
              baseOffset: Offset(34, 40),
              drift: Offset(12, 14),
              size: 132,
              color: Color(0x2FFF9800),
              borderColor: Color(0x442B1B4D),
            ),
            AnimatedBackgroundShape(
              kind: BackgroundShapeKind.capsule,
              alignment: Alignment.topRight,
              baseOffset: Offset(28, 96),
              drift: Offset(10, 16),
              size: 104,
              color: Color(0x2A6A3FC4),
              borderColor: Color(0x3F2B1B4D),
              initialRotation: 0.22,
            ),
          ],
          child: SafeArea(child: body),
        ),
      ),
    );
  }
}

/// The bordered, hard-shadowed card used for every block of admin content.
class AdminPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const AdminPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.color,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AdminPalette.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? AdminPalette.ink, width: 2.2),
        boxShadow: AdminPalette.hardShadow,
      ),
      child: child,
    );

    if (onTap == null) return panel;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: panel,
    );
  }
}

/// Section heading with an optional trailing action.
class AdminSectionHeader extends StatelessWidget {
  final String title;
  final String? caption;
  final Widget? trailing;
  final IconData? icon;

  const AdminSectionHeader({
    super.key,
    required this.title,
    this.caption,
    this.trailing,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: AdminPalette.accent, size: 22),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              if (caption != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    caption!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AdminPalette.muted,
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Small rounded label used for subject / source / status tags.
class AdminChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const AdminChip({
    super.key,
    required this.label,
    this.color = AdminPalette.accent,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// The three states every data-backed admin view can be in. Having one widget
/// for all of them keeps loading and failure handling consistent across
/// screens, which is what the API screens need most.
class AdminStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color color;

  const AdminStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.color = AdminPalette.muted,
  });

  /// Centred spinner with a caption, used while a request is in flight.
  static Widget loading(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AdminPalette.accent),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AdminPalette.ink,
            ),
          ),
        ],
      ),
    );
  }

  /// Failure state with a retry affordance.
  static Widget error(String message, {VoidCallback? onRetry}) {
    return AdminStateView(
      icon: Icons.cloud_off_rounded,
      title: 'Something went wrong',
      message: message,
      color: AdminPalette.danger,
      actionLabel: onRetry == null ? null : 'Try again',
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AdminPanel(
            borderColor: color,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 46, color: color),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: AdminPalette.muted,
                    ),
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Confirmation dialog for destructive actions (delete a question, disable an
/// account). Returns true only when the admin explicitly confirms.
Future<bool> confirmAdminAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  Color confirmColor = AdminPalette.danger,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Theme(
      data: buildAdminTheme(dialogContext),
      child: AlertDialog(
        backgroundColor: AdminPalette.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AdminPalette.ink, width: 2.2),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            height: 1.4,
            fontSize: 14.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AdminPalette.muted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

/// Consistent success / failure toast.
void showAdminSnack(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: isError ? const Color(0xFFFF8A80) : const Color(0xFF9CE7A5),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
}
