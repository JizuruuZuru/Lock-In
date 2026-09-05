import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'app_settings_service.dart';
import 'package:flutter/services.dart';

/// Centralised, optimised sound service.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;

  // ------------------------------------------------------------------------
  // Configuration
  // ------------------------------------------------------------------------
  static const int _sfxPlayerPoolSize = 4;

  // Asset paths – grouped by type for preloading and retrieval.
  static const Map<String, List<String>> _soundAssets = {
    // 🟢 HOME now has all 4 tracks
    'bgm_home': [
      'bgm_home_1.mp3',
      'bgm_home_2.mp3',
      'bgm_home_3.mp3',
      'bgm_home_4.mp3',
    ],
    // 🔁 Redirected groups – kept empty, never accessed
    'bgm_login': [],
    'bgm_register': [],
    // bgm_english_1.mp3 / bgm_english_2.mp3 are documented in
    // assets/sounds/README.md but were never actually added to the
    // project (not on disk, not declared in pubspec.yaml). Requesting
    // them threw an uncaught AudioPlayerException/MediaError, especially
    // on web. Left empty — and redirected to bgm_home below — until real
    // tracks are supplied; see README.md for the expected filenames.
    'bgm_english': [],

    // Other BGM groups
    'bgm_math': ['bgm_math_1.mp3', 'bgm_math_2.mp3'],
    'bgm_memory': ['bgm_memory_1.mp3', 'bgm_memory_2.mp3'],

    // SFX groups
    'correct': ['correct_1.mp3', 'correct_2.mp3', 'correct_3.mp3', 'correct_4.mp3'],
    'incorrect': ['incorrect_1.mp3', 'incorrect_2.mp3', 'incorrect_3.mp3', 'incorrect_4.mp3'],
    'levelup': ['levelup.wav'],
    'button': ['button_sound_1.mp3', 'button_sound_2.mp3', 'button_sound_3.mp3'],
    'leave_warning': ['leave_warning.wav'],
  };

  // 🔁 Redirect login, register, and english to the home group — english
  // doesn't have its own tracks yet (see the 'bgm_english' comment above).
  static const Map<BgmPage, String> _bgmGroupKey = {
    BgmPage.home: 'bgm_home',
    BgmPage.login: 'bgm_home',
    BgmPage.register: 'bgm_home',
    BgmPage.math: 'bgm_math',
    BgmPage.english: 'bgm_home',
    BgmPage.memory: 'bgm_memory',
  };

  // ------------------------------------------------------------------------
  // Internal State
  // ------------------------------------------------------------------------
  final AudioPlayer _bgmPlayer = AudioPlayer(playerId: 'bgm_player');
  final List<AudioPlayer> _sfxPool = List.generate(
    _sfxPlayerPoolSize,
    (i) => AudioPlayer(playerId: 'sfx_$i'),
  );

  // Preloaded sources (cached)
  final Map<String, Source> _sourceCache = {};

  // BGM state
  BgmPage? _currentBgmPage;
  bool _bgmIsPlaying = false;
  double _bgmTargetVolume = 0.33;
  bool _bgmFading = false;
  bool _bgmPaused = false; // for web autoplay

  /// Whether the app is currently the thing on screen.
  ///
  /// Deliberately separate from [_bgmPaused], which means "the browser will not
  /// let us start audio yet" - a different condition with a different recovery.
  /// Nothing in this app was lifecycle-aware at all, so background music and
  /// every sound effect carried on playing after the player alt-tabbed away.
  bool _inForeground = true;

  /// Whether the music was playing when the app went away, so the right thing
  /// happens on the way back: silence stays silent, music resumes.
  bool _resumeBgmOnReturn = false;
  Timer? _bgmFadeTimer;
  int _bgmFadeVersion = 0;

  // SFX state
  final Random _random = Random();
  final Map<String, String> _lastPlayedAsset = {};
  final Map<String, DateTime> _lastPlayedTime = {};
  static const Duration _sfxCooldown = Duration(milliseconds: 150);

  // User interaction flag (web autoplay)
  bool _userInteracted = !kIsWeb;
  BgmPage? _pendingBgmPage;

  // Volume levels
  bool _soundEnabled = true;
  double _musicLevel = 1.0;
  double _sfxLevel = 1.0;

  // ------------------------------------------------------------------------
  // Initialisation & Disposal
  // ------------------------------------------------------------------------
  SoundService._internal() {
    _preloadAllSounds();
  }

  Future<void> _preloadAllSounds() async {
    final allPaths = _soundAssets.values.expand((l) => l).toSet();
    await Future.wait(allPaths.map((path) async {
      final key = _assetKey(path);
      _sourceCache[key] = await _loadSource(path);
    }));
  }

  Future<Source> _loadSource(String fileName) async {
    return AssetSource('sounds/$fileName');
  }

  String _assetKey(String fileName) => 'sounds/$fileName';

  Future<void> dispose() async {
    await _bgmPlayer.dispose();
    for (final p in _sfxPool) {
      await p.dispose();
    }
  }

  // ------------------------------------------------------------------------
  // Volume Control
  // ------------------------------------------------------------------------
  bool get soundEnabled => _soundEnabled;
  double get musicLevel => _musicLevel;
  double get sfxLevel => _sfxLevel;

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    AppSettingsService().saveSoundEnabled(enabled);
    await _syncBgmVolume();
  }

  Future<void> setMusicLevel(double level) async {
    _musicLevel = level.clamp(0.0, 1.0);
    AppSettingsService().saveMusicLevel(_musicLevel);
    await _syncBgmVolume();
  }

  void setSfxLevel(double level) {
    _sfxLevel = level.clamp(0.0, 1.0);
    AppSettingsService().saveSfxLevel(_sfxLevel);
  }

  /// Silences everything because the app is no longer on screen.
  ///
  /// The BGM player is paused rather than stopped, so returning picks the
  /// track up where it left off instead of restarting it from the top.
  Future<void> pauseForBackground() async {
    if (!_inForeground) return;
    _inForeground = false;
    _resumeBgmOnReturn = _bgmIsPlaying;

    try {
      await _bgmPlayer.pause();
    } catch (error) {
      debugPrint('Could not pause the music: $error');
    }
  }

  /// Brings the music back, if there was any.
  Future<void> resumeFromForeground() async {
    if (_inForeground) return;
    _inForeground = true;
    if (!_resumeBgmOnReturn) return;
    _resumeBgmOnReturn = false;

    try {
      await _syncBgmVolume();
      await _bgmPlayer.resume();
    } catch (error) {
      debugPrint('Could not resume the music: $error');
    }
  }

  /// Applies levels restored from disk at start-up, without writing them back.
  Future<void> applyRestoredSettings({
    required bool soundEnabled,
    required double musicLevel,
    required double sfxLevel,
  }) async {
    _soundEnabled = soundEnabled;
    _musicLevel = musicLevel.clamp(0.0, 1.0);
    _sfxLevel = sfxLevel.clamp(0.0, 1.0);
    await _syncBgmVolume();
  }

  Future<void> _syncBgmVolume() async {
    final effective = _soundEnabled && !_bgmPaused && _inForeground
        ? (_bgmTargetVolume * _musicLevel)
        : 0.0;
    await _bgmPlayer.setVolume(effective.clamp(0.0, 1.0));
  }

  // ------------------------------------------------------------------------
  // BGM Playback – with group‑based continuity
  // ------------------------------------------------------------------------
  Future<void> playPageBgm(
    BgmPage page, {
    double targetVolume = 0.33,
    Duration fadeDuration = const Duration(milliseconds: 800),
  }) async {
    if (kIsWeb && !_userInteracted) {
      _pendingBgmPage = page;
      return;
    }

    final groupKey = _bgmGroupKey[page]!;

    // 🔁 CONTINUITY: If the same BGM group is already playing, do nothing.
    if (_currentBgmPage != null) {
      final currentGroupKey = _bgmGroupKey[_currentBgmPage!];
      if (currentGroupKey == groupKey && _bgmIsPlaying && !_bgmPaused) {
        // Same group – keep playing current track without interruption.
        return;
      }
    }

    final candidates = _soundAssets[groupKey] ?? [];
    if (candidates.isEmpty) {
      await _stopBgm();
      return;
    }

    // Select next track (avoid immediate repetition)
    final lastAsset = _lastPlayedAsset[groupKey];
    var available = List<String>.from(candidates);
    if (available.length > 1 && lastAsset != null) {
      available.remove(lastAsset);
    }
    final asset = available[_random.nextInt(available.length)];
    final sourceKey = _assetKey(asset);
    final source = _sourceCache[sourceKey];
    if (source == null) return;

    _lastPlayedAsset[groupKey] = asset;

    // Cancel any ongoing fade
    _bgmFadeVersion++;
    _bgmFadeTimer?.cancel();
    _bgmFading = false;

    // If already playing a different group, fade out first
    if (_bgmIsPlaying) {
      await _fadeBgmVolume(0.0, const Duration(milliseconds: 300));
    }

    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.0);
      await _bgmPlayer.play(source);
      _currentBgmPage = page;
      _bgmIsPlaying = true;
      _bgmPaused = false;
      await _fadeBgmVolume(targetVolume, fadeDuration);
    } catch (e) {
      if (_isWebAutoplayBlocked(e)) {
        _pendingBgmPage = page;
        _bgmPaused = true;
      }
    }
  }

  Future<void> _stopBgm() async {
    _bgmFadeVersion++;
    _bgmFadeTimer?.cancel();
    await _bgmPlayer.stop();
    _bgmIsPlaying = false;
    _currentBgmPage = null;
    _bgmPaused = false;
  }

  Future<void> _fadeBgmVolume(double target, Duration duration) async {
    if (!_bgmIsPlaying) return;

    _bgmFading = true;
    final startVol = _bgmTargetVolume;
    final version = ++_bgmFadeVersion;
    _bgmTargetVolume = target;

    final steps = (duration.inMilliseconds ~/ 50).clamp(5, 30);
    final stepDuration = duration ~/ steps;

    for (int i = 0; i <= steps; i++) {
      if (_bgmFadeVersion != version || !_bgmFading) break;
      final t = Curves.easeInOut.transform(i / steps);
      final vol = startVol + (target - startVol) * t;
      await _bgmPlayer.setVolume(vol * _musicLevel * (_soundEnabled ? 1 : 0));
      await Future.delayed(stepDuration);
    }
    _bgmFading = false;
  }

  Future<void> stopBgm({Duration fadeOut = const Duration(milliseconds: 500)}) async {
    if (!_bgmIsPlaying) return;
    await _fadeBgmVolume(0.0, fadeOut);
    await _bgmPlayer.stop();
    _bgmIsPlaying = false;
    _currentBgmPage = null;
  }

  // ------------------------------------------------------------------------
  // SFX Playback (Player Pool, Cached Sources, Cooldown)
  // ------------------------------------------------------------------------
  Future<void> playCorrectSound() =>
      _playSfxGroup('correct', fallback: SystemSoundType.click);

  Future<void> playIncorrectSplashSound() =>
      _playSfxGroup('incorrect', fallback: SystemSoundType.alert);

  Future<void> playLevelUpSound() =>
      _playSfxGroup('levelup', fallback: SystemSoundType.click);

  Future<void> playButtonSound() =>
      _playSfxGroup('button', fallback: SystemSoundType.click);

  Future<void> playLeaveWarningSound() =>
      _playSfxGroup('leave_warning', fallback: SystemSoundType.alert);

  void playButtonSoundNow() => unawaited(playButtonSound());
  void playLeaveWarningSoundNow() => unawaited(playLeaveWarningSound());

  Future<void> _playSfxGroup(
    String groupKey, {
    required SystemSoundType fallback,
  }) async {
    if (!_soundEnabled) return;
    // A splash sound queued just before the app was backgrounded would
    // otherwise still play, out of nowhere, over whatever the player switched
    // to.
    if (!_inForeground) return;

    final now = DateTime.now();
    final last = _lastPlayedTime[groupKey];
    if (last != null && now.difference(last) < _sfxCooldown) {
      return;
    }
    _lastPlayedTime[groupKey] = now;

    final candidates = _soundAssets[groupKey] ?? [];
    if (candidates.isEmpty) {
      await SystemSound.play(fallback);
      return;
    }

    var available = List<String>.from(candidates);
    final lastAsset = _lastPlayedAsset[groupKey];
    if (available.length > 1 && lastAsset != null) {
      available.remove(lastAsset);
    }
    final asset = available[_random.nextInt(available.length)];
    _lastPlayedAsset[groupKey] = asset;

    final sourceKey = _assetKey(asset);
    final source = _sourceCache[sourceKey];
    if (source == null) {
      await SystemSound.play(fallback);
      return;
    }

    final player = _getIdleSfxPlayer();
    try {
      await player.stop();
      await player.setVolume(_sfxLevel);
      await player.play(source);
    } catch (e) {
      await SystemSound.play(fallback);
    }
  }

  AudioPlayer _getIdleSfxPlayer() {
    _lastUsedSfxIndex = (_lastUsedSfxIndex + 1) % _sfxPool.length;
    return _sfxPool[_lastUsedSfxIndex];
  }

  int _lastUsedSfxIndex = 0;

  // ------------------------------------------------------------------------
  // Web Autoplay Handling
  // ------------------------------------------------------------------------
  void registerUserInteraction() {
    if (_userInteracted) return;
    _userInteracted = true;

    final pending = _pendingBgmPage;
    if (pending != null) {
      _pendingBgmPage = null;
      unawaited(playPageBgm(pending));
    }
  }

  bool _isWebAutoplayBlocked(Object error) {
    if (!kIsWeb) return false;
    final msg = error.toString().toLowerCase();
    return msg.contains('notallowederror') && msg.contains('interact');
  }
}

enum BgmPage {
  home,
  login,
  register,
  math,
  english,
  memory,
}