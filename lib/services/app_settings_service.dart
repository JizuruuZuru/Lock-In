import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The player's own preferences: screen brightness, and the sound levels held
/// by [SoundService].
///
/// These used to live only in memory, so a child re-set the brightness and the
/// music volume on every single launch. `shared_preferences` was already a
/// dependency (it backs the offline question cache), it just was not used here.
class AppSettingsService {
  static final AppSettingsService _instance = AppSettingsService._internal();

  static const String _brightnessKey = 'lockin.settings.brightness.v1';
  static const String _soundEnabledKey = 'lockin.settings.sound_enabled.v1';
  static const String _musicLevelKey = 'lockin.settings.music_level.v1';
  static const String _sfxLevelKey = 'lockin.settings.sfx_level.v1';

  static const double minBrightness = 0.6;
  static const double maxBrightness = 1.3;

  final ValueNotifier<double> brightnessNotifier = ValueNotifier<double>(1.0);

  factory AppSettingsService() => _instance;

  AppSettingsService._internal();

  double get brightness => brightnessNotifier.value;

  /// Restores what was saved last run. Never throws: a device with no usable
  /// preference store just starts at the defaults, which is what happened
  /// every launch before this existed.
  Future<void> load({
    required void Function(bool soundEnabled, double music, double sfx) applySound,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final storedBrightness = prefs.getDouble(_brightnessKey);
      if (storedBrightness != null) {
        brightnessNotifier.value =
            storedBrightness.clamp(minBrightness, maxBrightness).toDouble();
      }

      applySound(
        prefs.getBool(_soundEnabledKey) ?? true,
        (prefs.getDouble(_musicLevelKey) ?? 1.0).clamp(0.0, 1.0).toDouble(),
        (prefs.getDouble(_sfxLevelKey) ?? 1.0).clamp(0.0, 1.0).toDouble(),
      );
    } catch (error) {
      debugPrint('Could not read saved settings: $error');
    }
  }

  void setBrightness(double value) {
    final clamped = value.clamp(minBrightness, maxBrightness).toDouble();
    if (brightnessNotifier.value == clamped) return;
    brightnessNotifier.value = clamped;
    _write((prefs) => prefs.setDouble(_brightnessKey, clamped));
  }

  void saveSoundEnabled(bool enabled) =>
      _write((prefs) => prefs.setBool(_soundEnabledKey, enabled));

  void saveMusicLevel(double level) =>
      _write((prefs) => prefs.setDouble(_musicLevelKey, level));

  void saveSfxLevel(double level) =>
      _write((prefs) => prefs.setDouble(_sfxLevelKey, level));

  /// Fire and forget. A slider must not wait on a disk write, and a failed
  /// write costs the player nothing worse than the setting not sticking.
  void _write(Future<void> Function(SharedPreferences prefs) action) {
    SharedPreferences.getInstance().then(action).catchError((Object error) {
      debugPrint('Could not save a setting: $error');
    });
  }
}
