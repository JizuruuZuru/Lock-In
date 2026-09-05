import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'tts_voice.dart';

/// Thin, lazily-initialised wrapper around device text-to-speech.
/// Speech is synthesised entirely on-device, so it keeps working offline.
class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  factory TextToSpeechService() => _instance;

  final FlutterTts _tts = FlutterTts();
  bool _configured = false;
  bool _isSpeaking = false;

  /// Android engine package ids, best first. Google's engine carries the
  /// high-quality voices; Pico is the ancient formant synthesiser that ships
  /// as a last resort and sounds like it.
  static const _preferredEngines = <String>[
    'com.google.android.tts',
    'com.samsung.SMT',
  ];
  static const _worstEngine = 'com.svox.pico';

  /// What the voice picker settled on, so the settings screen can say whether
  /// this device could do better.
  VoiceReport _report = const VoiceReport(usingPlatformDefault: true);
  VoiceReport get voiceReport => _report;

  TextToSpeechService._internal();

  /// Re-runs engine and voice selection, and reports what it found.
  ///
  /// Called after sending someone to system settings to install better voice
  /// data: the new voice only appears once the engine is asked again.
  /// Re-runs configuration from scratch. Never throws, for the same reason
  /// [ensureReady] does not - this is the button a teacher presses precisely
  /// *because* something is wrong.
  Future<VoiceReport> refreshVoice() async {
    _configured = false;
    try {
      await _ensureConfigured();
    } catch (error) {
      debugPrint('Could not reconfigure speech: $error');
    }
    return _report;
  }

  /// Selects the best available voice without speaking, so the settings screen
  /// can show what is in use before anything has been said.
  /// Always produces a report, even when the platform will not cooperate.
  ///
  /// This used to let a configuration failure escape - and on Android that is
  /// routine, since the TTS engine is often not bound yet at cold start, and a
  /// device with no engine at all throws outright. The caller in the profile
  /// screen sets a `_busy` flag before awaiting this and clears it after, so a
  /// throw left "Reading voice" stuck on "Checking..." with both **Hear it**
  /// and **Check again** permanently disabled, and no way to retry. A report
  /// method that cannot report is worse than one that reports bad news.
  Future<VoiceReport> ensureReady() async {
    try {
      await _ensureConfigured();
    } catch (error) {
      debugPrint('Could not configure speech: $error');
    }
    return _report;
  }

  /// Serialised, and only marked done once it has actually finished.
  ///
  /// `_configured = true` used to be set *before* the awaits below, so a single
  /// throw - an Android engine not yet bound at cold start is the usual one -
  /// left it true with nothing applied, and every later call short-circuited.
  /// The rate, pitch, engine and voice were then never set again for the whole
  /// process: the spelling game read at the default speed in the default
  /// voice. A second caller arriving mid-configuration also sailed past and
  /// spoke before `awaitSpeakCompletion(true)` had landed.
  Future<void>? _configuring;

  Future<void> _ensureConfigured() {
    if (_configured) return Future<void>.value();
    return _configuring ??= _configure().then((_) {
      _configured = true;
    }).whenComplete(() {
      _configuring = null;
    });
  }

  Future<void> _configure() async {
    await _tts.setLanguage('en-US');
    // A touch slower than natural speech keeps words easy for young
    // learners to follow, while pitch/volume stay close to natural so it
    // doesn't sound robotic. 0.48 reads as continuous, flowing speech;
    // slower rates make some on-device voices stretch each syllable into a
    // choppier, more robotic cadence.
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);

    // Knowing whether anything is actually playing means `speak` can skip the
    // stop-then-start round trip when nothing is in progress. On Android that
    // round trip is what clips the first syllable off a word.
    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setCancelHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((_) => _isSpeaking = false);

    await _selectBestEngine();
    await _selectBestAvailableVoice();
  }

  /// Switches Android to the best speech engine installed.
  ///
  /// The engine decides which voices exist at all, so this has to happen
  /// before voices are enumerated. A no-op everywhere else.
  Future<void> _selectBestEngine() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final raw = await _tts.getEngines;
      if (raw is! List) return;
      final engines = raw.map((engine) => engine.toString()).toSet();
      if (engines.isEmpty) return;

      final current = (await _tts.getDefaultEngine)?.toString();

      for (final preferred in _preferredEngines) {
        if (!engines.contains(preferred)) continue;
        if (current == preferred) return;
        await _tts.setEngine(preferred);
        return;
      }

      // Nothing preferred is installed. Move off Pico if there is any
      // alternative at all, since anything beats it.
      if (current == _worstEngine) {
        final alternative = engines.firstWhere(
          (engine) => engine != _worstEngine,
          orElse: () => _worstEngine,
        );
        if (alternative != _worstEngine) await _tts.setEngine(alternative);
      }
    } catch (error) {
      // Engine selection is a best-effort upgrade; the default still speaks.
      debugPrint('TTS engine selection skipped: $error');
    }
  }

  /// Picks a voice from what the platform reports about each one - its quality
  /// tier, whether it needs the network, whether its data is even downloaded -
  /// rather than guessing from the voice's name.
  Future<void> _selectBestAvailableVoice() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) {
        _report = const VoiceReport(usingPlatformDefault: true);
        return;
      }

      final voices = raw
          .whereType<Map<Object?, Object?>>()
          .map(TtsVoice.fromPlatformMap)
          .whereType<TtsVoice>()
          .toList(growable: false);

      final best = pickBestVoice(voices);
      if (best == null) {
        _report = const VoiceReport(usingPlatformDefault: true);
        return;
      }

      // A voice the device lists but has not downloaded is worth mentioning:
      // it is usually a much better one, and it is a couple of taps away in
      // system settings. The app cannot install it itself.
      final betterAwaitingDownload = voices.any(
        (voice) =>
            voice.notInstalled &&
            !voice.networkRequired &&
            voice.locale.toLowerCase().startsWith('en') &&
            voice.quality.rank > best.quality.rank,
      );

      await _tts.setVoice(best.selector);
      _report = VoiceReport(
        selected: best,
        betterVoiceNeedsDownload: betterAwaitingDownload,
      );
    } catch (error) {
      // Voice selection is a best-effort enhancement; keep the default voice
      // if the platform doesn't support enumerating or selecting one.
      debugPrint('TTS voice selection skipped: $error');
      _report = const VoiceReport(usingPlatformDefault: true);
    }
  }

  /// Reads a word the way a spelling bee does: the word in a short carrier
  /// phrase, then the same word used in a sentence.
  ///
  /// This is not decoration. A speech engine given a bare word has no sentence
  /// to draw intonation from, so it lands on a flat, clipped monotone and
  /// often swallows the first sound. Wrapping the word in a phrase gives the
  /// engine real prosody, and the example sentence is what a teacher would
  /// offer anyway - it also separates homophones like "their" and "there",
  /// which a single spoken word cannot.
  Future<void> speakSpellingWord(
    String word, {
    String? sentence,
    bool repeat = false,
  }) {
    final phrase = buildSpellingPhrase(word, sentence: sentence, repeat: repeat);
    if (phrase.isEmpty) return Future<void>.value();
    return speak(phrase);
  }

  /// Builds the sentence that gets spoken. Pure and separate from the engine
  /// so the phrasing can be tested without a speech synthesiser present.
  @visibleForTesting
  static String buildSpellingPhrase(
    String word, {
    String? sentence,
    bool repeat = false,
  }) {
    final clean = word.trim();
    if (clean.isEmpty) return '';

    final buffer = StringBuffer()
      // A repeat is shorter - hearing the whole preamble again is tiring.
      ..write(repeat ? '$clean.' : 'The word is $clean.');

    final example = sentence?.trim() ?? '';
    if (example.isNotEmpty) {
      // The pause between sentences comes from the punctuation, which every
      // engine already honours - no engine-specific silence API needed.
      buffer.write(' $example');
      if (!example.endsWith('.') &&
          !example.endsWith('!') &&
          !example.endsWith('?')) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }

  /// Speaks [text], interrupting anything already playing.
  Future<void> speak(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    try {
      await _ensureConfigured();
      // Only interrupt when there is something to interrupt. Calling stop()
      // before every utterance costs a round trip to the platform and can
      // truncate the start of the new one.
      if (_isSpeaking) {
        await _tts.stop();
        _isSpeaking = false;
      }
      _isSpeaking = true;
      await _tts.speak(clean);
    } catch (error) {
      // Text-to-speech is a nice-to-have here; silently ignore devices or
      // platforms without a working TTS engine.
      _isSpeaking = false;
      debugPrint('TextToSpeechService.speak failed: $error');
    }
  }

  Future<void> stop() async {
    _isSpeaking = false;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
