import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';

/// A slim strip that appears only while the device is offline.
///
/// Used across the admin screens so the person writing questions always knows
/// whether their work is reaching the server or being queued on the device.
/// It collapses to nothing when online, so it costs no layout in the normal
/// case.
class OfflineBanner extends StatefulWidget {
  /// What being offline means on this particular screen.
  final String message;

  /// Set for screens that genuinely cannot work without a connection (the API
  /// importer), which paints the strip as a warning rather than a note.
  final bool blocking;

  const OfflineBanner({
    super.key,
    this.message = 'You are offline. Changes are saved on this device and will '
        'sync when you reconnect.',
    this.blocking = false,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  /// Held in state so a rebuild does not start a second connectivity probe.
  late final Stream<bool> _offlineStream = ConnectivityService.offlineStream();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _offlineStream,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();

        final background =
            widget.blocking ? const Color(0xFFFFE3E0) : const Color(0xFFFFF4DC);
        final border =
            widget.blocking ? const Color(0xFFC62828) : const Color(0xFFE0A800);
        final foreground =
            widget.blocking ? const Color(0xFF8B1F1A) : const Color(0xFF7A5600);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                widget.blocking
                    ? Icons.wifi_off_rounded
                    : Icons.cloud_off_rounded,
                size: 19,
                color: foreground,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
