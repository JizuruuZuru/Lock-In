import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/admin_theme.dart';

/// A tappable "where this came from" link.
///
/// Opens the page in the device's browser. If no browser can be reached — a
/// locked-down school tablet, or a platform that refuses the intent — the URL
/// is copied to the clipboard instead and the user is told, rather than the tap
/// appearing to do nothing.
class SourceLink extends StatelessWidget {
  /// The page to open.
  final String url;

  /// What the link is, in plain words. Shown as the main line.
  final String label;

  /// Optional second line explaining why the link is here.
  final String? description;

  final IconData icon;

  const SourceLink({
    super.key,
    required this.url,
    required this.label,
    this.description,
    this.icon = Icons.open_in_new_rounded,
  });

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(url);

    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (opened) return;

    await Clipboard.setData(ClipboardData(text: url));
    messenger.showSnackBar(
      SnackBar(
        content: Text('Could not open a browser, so the link was copied:\n$url'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: AdminPalette.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: AdminPalette.accent,
                        decoration: TextDecoration.underline,
                        decorationColor: AdminPalette.accent,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        description!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: AdminPalette.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
