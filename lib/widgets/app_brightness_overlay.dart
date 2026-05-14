import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';

class AppBrightnessOverlay extends StatelessWidget {
  final Widget child;

  const AppBrightnessOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: AppSettingsService().brightnessNotifier,
      builder: (context, brightness, _) {
        final darkenOpacity = (1.0 - brightness).clamp(0.0, 0.45);
        final lightenOpacity = (brightness - 1.0).clamp(0.0, 0.25);

        if (darkenOpacity == 0.0 && lightenOpacity == 0.0) {
          return child;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (darkenOpacity > 0.0)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Colors.black.withOpacity(darkenOpacity),
                  ),
                ),
              ),
            if (lightenOpacity > 0.0)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Colors.white.withOpacity(lightenOpacity),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
