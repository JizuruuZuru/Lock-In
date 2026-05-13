import 'package:flutter/foundation.dart';

class AppSettingsService {
  static final AppSettingsService _instance = AppSettingsService._internal();

  final ValueNotifier<double> brightnessNotifier = ValueNotifier<double>(1.0);

  factory AppSettingsService() => _instance;

  AppSettingsService._internal();

  double get brightness => brightnessNotifier.value;

  void setBrightness(double value) {
    final clamped = value.clamp(0.6, 1.3).toDouble();
    if (brightnessNotifier.value == clamped) return;
    brightnessNotifier.value = clamped;
  }
}
