double responsivePanelMaxWidth(double width) {
  if (width >= 1500) return (width * 0.82).clamp(1200.0, 1680.0);
  if (width >= 1000) return (width * 0.88).clamp(900.0, 1300.0);
  if (width >= 700) return 760;
  return 560;
}

double responsiveButtonHeight(double width) {
  if (width >= 900) return 72;
  if (width >= 700) return 64;
  return 56;
}

double responsiveCardPadding(double width) {
  if (width >= 900) return 24;
  if (width >= 700) return 20;
  return 16;
}

bool isDesktopLayout(double width) => width >= 900;

/// A smaller vertical gap for desktop widths so start panels stay compact
/// enough to fit without scrolling on typical computer window sizes.
double responsiveCompactGap(double width, double base) {
  return isDesktopLayout(width) ? (base * 0.55).clamp(4.0, base) : base;
}
