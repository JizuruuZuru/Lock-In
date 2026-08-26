import 'package:benchmark/services/tts_voice.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which voice gets picked decides how robotic the spelling game sounds.
///
/// Both platforms report real quality metadata - Android grades voices
/// "very low" to "very high" and flags ones whose data is not downloaded; iOS
/// reports default/enhanced/premium. The picker ranks on that rather than
/// guessing from voice names, and these tests pin the rules.
void main() {
  TtsVoice voice(
    String name, {
    String locale = 'en-US',
    String quality = 'normal',
    bool network = false,
    bool notInstalled = false,
    int latency = 3,
  }) {
    return TtsVoice(
      name: name,
      locale: locale,
      quality: VoiceQuality.parse(quality),
      networkRequired: network,
      notInstalled: notInstalled,
      latencyRank: latency,
    );
  }

  group('VoiceQuality.parse', () {
    test('maps the Android scale', () {
      expect(VoiceQuality.parse('very high'), VoiceQuality.veryHigh);
      expect(VoiceQuality.parse('high'), VoiceQuality.high);
      expect(VoiceQuality.parse('normal'), VoiceQuality.normal);
      expect(VoiceQuality.parse('low'), VoiceQuality.low);
      expect(VoiceQuality.parse('very low'), VoiceQuality.veryLow);
    });

    test('maps the iOS scale onto the same ranks', () {
      expect(VoiceQuality.parse('premium'), VoiceQuality.veryHigh);
      expect(VoiceQuality.parse('enhanced'), VoiceQuality.high);
      expect(VoiceQuality.parse('default'), VoiceQuality.normal);
    });

    test('treats anything unrecognised as unknown', () {
      expect(VoiceQuality.parse(null), VoiceQuality.unknown);
      expect(VoiceQuality.parse(''), VoiceQuality.unknown);
      expect(VoiceQuality.parse('excellent'), VoiceQuality.unknown);
    });

    test('only the bottom two tiers count as poor', () {
      expect(VoiceQuality.veryLow.isPoor, isTrue);
      expect(VoiceQuality.low.isPoor, isTrue);
      expect(VoiceQuality.normal.isPoor, isFalse);
      // Unknown is not "poor" - there is nothing to act on.
      expect(VoiceQuality.unknown.isPoor, isFalse);
    });
  });

  group('pickBestVoice', () {
    test('prefers the highest quality tier', () {
      final best = pickBestVoice([
        voice('a', quality: 'low'),
        voice('b', quality: 'very high'),
        voice('c', quality: 'normal'),
      ]);
      expect(best?.name, 'b');
    });

    test('never picks a voice that needs the network', () {
      // These sound great and then stop working the moment the school Wi-Fi
      // drops, which is exactly when a child is mid-word.
      final best = pickBestVoice([
        voice('online-voice', quality: 'very high', network: true),
        voice('offline-voice', quality: 'normal'),
      ]);
      expect(best?.name, 'offline-voice');
    });

    test('never picks a voice whose data is not downloaded', () {
      final best = pickBestVoice([
        voice('undownloaded', quality: 'very high', notInstalled: true),
        voice('present', quality: 'normal'),
      ]);
      expect(best?.name, 'present');
    });

    test('ignores voices for other languages', () {
      final best = pickBestVoice([
        voice('french', locale: 'fr-FR', quality: 'very high'),
        voice('english', locale: 'en-GB', quality: 'low'),
      ]);
      expect(best?.name, 'english');
    });

    test('rejects cloud voices even when the flag is not set', () {
      // Windows names them "Microsoft Aria Online (Natural)" without setting
      // any network flag, so the name is the only signal.
      final best = pickBestVoice([
        voice('Microsoft Aria Online (Natural)', quality: 'very high'),
        voice('Microsoft Zira Desktop', quality: 'normal'),
      ]);
      expect(best?.name, 'Microsoft Zira Desktop');
    });

    test('breaks a quality tie with the name, avoiding cut-down builds', () {
      final best = pickBestVoice([
        voice('en-us-x-sfg-compact', quality: 'normal'),
        voice('en-us-x-sfg-local', quality: 'normal'),
      ]);
      expect(best?.name, 'en-us-x-sfg-local');
    });

    test('never picks espeak when anything else exists', () {
      final best = pickBestVoice([
        voice('espeak-en', quality: 'normal'),
        voice('plain-en', quality: 'normal'),
      ]);
      expect(best?.name, 'plain-en');
    });

    test('quality still beats a promising name', () {
      // A voice called "neural" that reports "low" is still low.
      final best = pickBestVoice([
        voice('neural-sounding', quality: 'low'),
        voice('plain', quality: 'high'),
      ]);
      expect(best?.name, 'plain');
    });

    test('breaks a full tie with latency, lower first', () {
      final best = pickBestVoice([
        voice('slow', quality: 'high', latency: 5),
        voice('fast', quality: 'high', latency: 1),
      ]);
      expect(best?.name, 'fast');
    });

    test('returns null when nothing is usable', () {
      expect(pickBestVoice(const []), isNull);
      expect(
        pickBestVoice([voice('only-online', network: true)]),
        isNull,
      );
    });
  });

  group('TtsVoice.fromPlatformMap', () {
    test('reads the Android shape', () {
      final parsed = TtsVoice.fromPlatformMap(const {
        'name': 'en-us-x-tpf-local',
        'locale': 'en-US',
        'quality': 'very high',
        'latency': 'low',
        'network_required': '0',
        'features': 'networkTimeoutMs\tnetworkRetriesCount',
      });

      expect(parsed, isNotNull);
      expect(parsed!.quality, VoiceQuality.veryHigh);
      expect(parsed.networkRequired, isFalse);
      expect(parsed.notInstalled, isFalse);
      expect(parsed.isUsableOffline, isTrue);
    });

    test('spots a voice whose data still needs downloading', () {
      // Android lists these before they exist on the device.
      final parsed = TtsVoice.fromPlatformMap(const {
        'name': 'en-gb-x-gba-local',
        'locale': 'en-GB',
        'quality': 'very high',
        'features': 'notInstalled',
      });

      expect(parsed!.notInstalled, isTrue);
      expect(parsed.isUsableOffline, isFalse);
    });

    test('reads the iOS shape', () {
      final parsed = TtsVoice.fromPlatformMap(const {
        'name': 'Samantha',
        'locale': 'en-US',
        'quality': 'enhanced',
        'gender': 'female',
        'identifier': 'com.apple.voice.enhanced.en-US.Samantha',
      });

      expect(parsed!.quality, VoiceQuality.high);
      expect(parsed.isUsableOffline, isTrue);
    });

    test('rejects an entry with no name or locale', () {
      expect(TtsVoice.fromPlatformMap(const {'locale': 'en-US'}), isNull);
      expect(TtsVoice.fromPlatformMap(const {'name': 'x'}), isNull);
    });

    test('survives a map with none of the optional fields', () {
      final parsed = TtsVoice.fromPlatformMap(const {
        'name': 'basic',
        'locale': 'en-US',
      });
      expect(parsed, isNotNull);
      expect(parsed!.quality, VoiceQuality.unknown);
      expect(parsed.isUsableOffline, isTrue);
    });
  });

  group('VoiceReport', () {
    test('advises a download when a better voice is waiting', () {
      const report = VoiceReport(
        selected: TtsVoice(
          name: 'basic',
          locale: 'en-US',
          quality: VoiceQuality.normal,
        ),
        betterVoiceNeedsDownload: true,
      );

      expect(report.canBeImproved, isTrue);
      expect(report.advice, contains('Text-to-speech'));
    });

    test('advises installing a better voice when only a poor one exists', () {
      const report = VoiceReport(
        selected: TtsVoice(
          name: 'espeak',
          locale: 'en-US',
          quality: VoiceQuality.veryLow,
        ),
      );

      expect(report.canBeImproved, isTrue);
      expect(report.advice, isNotNull);
    });

    test('says nothing when the voice is already good', () {
      const report = VoiceReport(
        selected: TtsVoice(
          name: 'en-us-x-tpf-local',
          locale: 'en-US',
          quality: VoiceQuality.veryHigh,
        ),
      );

      expect(report.canBeImproved, isFalse);
      expect(report.advice, isNull);
      expect(report.summary, contains('Very high'));
    });

    test('reports the platform default when nothing could be enumerated', () {
      const report = VoiceReport(usingPlatformDefault: true);
      expect(report.summary, contains('device default'));
    });
  });
}
