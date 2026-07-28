import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Thin, lazily-initialised wrapper around device text-to-speech.
/// Speech is synthesised entirely on-device, so it keeps working offline.
class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  factory TextToSpeechService() => _instance;

  final FlutterTts _tts = FlutterTts();
  bool _configured = false;

  TextToSpeechService._internal();

  /// Voice name substrings that tend to mark a higher-quality, more
  /// natural-sounding voice on each platform's TTS engine.
  static const _preferredVoiceKeywords = [
    'neural',
    'enhanced',
    'premium',
    'natural',
    'wavenet',
    'studio',
  ];

  /// Windows ships two tiers of the same built-in voice: a larger, clearer
  /// "Desktop" model and a compact "Mobile" model meant for low-resource
  /// devices. Neither name matches the premium keywords above, so without
  /// this tier we'd otherwise pick whichever one the platform happens to
  /// list first — prefer the clearer one explicitly.
  static const _secondaryPreferredKeywords = ['desktop'];
  static const _deprioritizedKeywords = ['mobile'];

  /// Voice name substrings that mean the "voice" is actually a cloud
  /// service call (e.g. Windows' "Microsoft Aria Online (Natural)"). These
  /// can sound the smoothest of all, but silently fail once the device is
  /// offline — never select one, since spelling practice must keep working
  /// offline.
  static const _cloudOnlyVoiceKeywords = ['online', 'cloud', 'network'];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    _configured = true;
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
    await _selectBestAvailableVoice();
  }

  bool _isOfflineCapable(String name) =>
      !_cloudOnlyVoiceKeywords.any(name.contains);

  Future<void> _selectBestAvailableVoice() async {
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return;

      final englishVoices = voices
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .where((voice) {
            final locale = (voice['locale'] ?? '').toString().toLowerCase();
            final name = (voice['name'] ?? '').toString().toLowerCase();
            return locale.startsWith('en') && _isOfflineCapable(name);
          })
          .toList();

      Map<String, dynamic>? findByKeyword(List<String> keywords) {
        for (final keyword in keywords) {
          for (final voice in englishVoices) {
            final name = (voice['name'] ?? '').toString().toLowerCase();
            if (name.contains(keyword)) return voice;
          }
        }
        return null;
      }

      // Tier 1: an explicitly premium/neural-sounding voice.
      // Tier 2: the "Desktop" (not "Mobile") build of a platform voice.
      // Tier 3: any voice that isn't a compact/low-quality "Mobile" build.
      // Tier 4: whatever's left, so speech still works either way.
      final bestVoice = findByKeyword(_preferredVoiceKeywords) ??
          findByKeyword(_secondaryPreferredKeywords) ??
          englishVoices.cast<Map<String, dynamic>?>().firstWhere(
                (voice) => !_deprioritizedKeywords
                    .any((kw) => (voice!['name'] ?? '').toString().toLowerCase().contains(kw)),
                orElse: () => englishVoices.isEmpty ? null : englishVoices.first,
              );

      if (bestVoice != null) {
        await _tts.setVoice({
          'name': bestVoice['name'].toString(),
          'locale': bestVoice['locale'].toString(),
        });
      }
    } catch (_) {
      // Voice selection is a best-effort enhancement; keep the default
      // voice if the platform doesn't support enumerating/selecting one.
    }
  }

  /// Speaks [text], stopping any speech already in progress first.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _ensureConfigured();
      await _tts.stop();
      await _tts.speak(text);
    } catch (error) {
      // Text-to-speech is a nice-to-have here; silently ignore devices or
      // platforms without a working TTS engine.
      debugPrint('TextToSpeechService.speak failed: $error');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
