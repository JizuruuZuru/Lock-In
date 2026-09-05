import 'package:flutter/foundation.dart';

/// How good a synthesised voice is, normalised across platforms.
///
/// Android reports `very low` … `very high`; iOS reports `default`,
/// `enhanced`, `premium`. Both are mapped onto one scale so the picker can
/// compare them with a single rule.
enum VoiceQuality {
  unknown,
  veryLow,
  low,
  normal,
  high,
  veryHigh;

  /// Higher is better. `unknown` sorts below anything that reported a value,
  /// because a voice that will not say how good it is usually is not.
  int get rank => switch (this) {
        VoiceQuality.unknown => 0,
        VoiceQuality.veryLow => 1,
        VoiceQuality.low => 2,
        VoiceQuality.normal => 3,
        VoiceQuality.high => 4,
        VoiceQuality.veryHigh => 5,
      };

  /// True for the tiers that sound noticeably synthetic to a child.
  bool get isPoor => rank > 0 && rank <= VoiceQuality.low.rank;

  String get label => switch (this) {
        VoiceQuality.unknown => 'Unknown',
        VoiceQuality.veryLow => 'Very low',
        VoiceQuality.low => 'Low',
        VoiceQuality.normal => 'Normal',
        VoiceQuality.high => 'High',
        VoiceQuality.veryHigh => 'Very high',
      };

  static VoiceQuality parse(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'very high':
      case 'premium': // iOS
        return VoiceQuality.veryHigh;
      case 'high':
      case 'enhanced': // iOS
        return VoiceQuality.high;
      case 'normal':
      case 'default': // iOS
        return VoiceQuality.normal;
      case 'low':
        return VoiceQuality.low;
      case 'very low':
        return VoiceQuality.veryLow;
      default:
        return VoiceQuality.unknown;
    }
  }
}

/// Android reports latency as one of the integer constants 100-500 from
/// `TextToSpeech.Voice.getLatency()`, which `VoiceQuality.parse` does not
/// recognise - so every voice scored 0 and the "lower latency wins" tie-break
/// never fired, leaving voices to be chosen alphabetically. iOS sends the
/// quality words, which still parse.
///
/// Rank 0 also sorts *first*, so an unreadable value used to read as the best
/// possible latency; anything unrecognised now sorts last instead.
int _latencyRank(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return _unknownLatencyRank;

  final asInt = int.tryParse(value);
  if (asInt != null) {
    // 100 is `LATENCY_VERY_LOW`, 500 is `LATENCY_VERY_HIGH`. Lower is better,
    // which is the order the comparator already wants.
    return asInt;
  }

  final quality = VoiceQuality.parse(value);
  if (quality == VoiceQuality.unknown) return _unknownLatencyRank;
  return quality.rank;
}

/// Sorts behind every voice that did report a latency.
const int _unknownLatencyRank = 1 << 20;

/// One voice the platform offers, with the properties that decide whether it
/// is worth using.
@immutable
class TtsVoice {
  final String name;
  final String locale;
  final VoiceQuality quality;

  /// Android only. A network voice sounds excellent and then stops working the
  /// moment the school Wi-Fi drops, which is exactly when a child is mid-word.
  final bool networkRequired;

  /// Android reports this through the voice's feature list. The voice appears
  /// in the list but has no data behind it until the user downloads it.
  final bool notInstalled;

  /// Lower is better. Only used to break ties between equal-quality voices.
  final int latencyRank;

  const TtsVoice({
    required this.name,
    required this.locale,
    required this.quality,
    this.networkRequired = false,
    this.notInstalled = false,
    this.latencyRank = 3,
  });

  /// Usable offline, right now, without a download.
  bool get isUsableOffline => !networkRequired && !notInstalled;

  /// The map shape [setVoice] expects.
  Map<String, String> get selector => {'name': name, 'locale': locale};

  /// Reads one entry from `FlutterTts.getVoices`, which returns loosely typed
  /// maps that differ per platform and may be missing any given key.
  static TtsVoice? fromPlatformMap(Map<Object?, Object?> raw) {
    final name = (raw['name'] ?? '').toString();
    final locale = (raw['locale'] ?? '').toString();
    if (name.isEmpty || locale.isEmpty) return null;

    // Android hands back a tab-separated feature list. `notInstalled` is
    // TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED.
    final features = (raw['features'] ?? '').toString().toLowerCase();

    return TtsVoice(
      name: name,
      locale: locale,
      quality: VoiceQuality.parse(raw['quality']?.toString()),
      networkRequired: (raw['network_required'] ?? '').toString() == '1' ||
          features.contains('networkconnectionrequired'),
      notInstalled: features.contains('notinstalled'),
      latencyRank: _latencyRank(raw['latency']?.toString()),
    );
  }

  @override
  String toString() => '$name ($locale, ${quality.label})';
}

/// Voice names that mark a cut-down or formant-synthesised build. Used only to
/// break ties, and to rank voices on platforms that report no quality at all.
const _lowGradeNameHints = <String>[
  'espeak', // Android's formant fallback - the most robotic thing available
  'compact', // the small build of a voice, made to save space not to sound good
  'mobile', // Windows ships a "Mobile" cut-down beside a "Desktop" full build
  'legacy',
  'pico',
];

/// Voice names that usually mark a better build, for the same tie-breaking.
const _highGradeNameHints = <String>[
  'neural',
  'enhanced',
  'premium',
  'natural',
  'wavenet',
  'studio',
  'siri', // Apple's on-device Siri voices are the best it offers
  'desktop', // the full Windows build
];

/// Cloud-backed "voices" that stop working offline. Never selected: spelling
/// practice has to keep working with no connection.
const _cloudOnlyNameHints = <String>['online', 'cloud', 'network'];

int _nameBonus(String name) {
  final lower = name.toLowerCase();
  if (_lowGradeNameHints.any(lower.contains)) return -1;
  if (_highGradeNameHints.any(lower.contains)) return 1;
  return 0;
}

/// Picks the best voice for [languagePrefix] from what the platform offers.
///
/// Ranked on what the platform actually reports rather than on guesses about
/// its naming: quality tier first, then the name hints, then latency. Voices
/// that need the network or a download are dropped, because the games have to
/// work on a dead connection.
///
/// Pure and separate from the engine so the rule can be tested without a
/// speech synthesiser present.
TtsVoice? pickBestVoice(
  Iterable<TtsVoice> voices, {
  String languagePrefix = 'en',
}) {
  final candidates = voices
      .where((voice) => voice.locale.toLowerCase().startsWith(languagePrefix))
      .where((voice) => voice.isUsableOffline)
      .where((voice) => !_cloudOnlyNameHints.any(voice.name.toLowerCase().contains))
      .toList();

  if (candidates.isEmpty) return null;

  candidates.sort((a, b) {
    final byQuality = b.quality.rank.compareTo(a.quality.rank);
    if (byQuality != 0) return byQuality;

    final byName = _nameBonus(b.name).compareTo(_nameBonus(a.name));
    if (byName != 0) return byName;

    // Lower latency wins, but only once quality is equal - a snappy bad voice
    // is still a bad voice.
    final byLatency = a.latencyRank.compareTo(b.latencyRank);
    if (byLatency != 0) return byLatency;

    return a.name.compareTo(b.name);
  });

  return candidates.first;
}

/// What the app ended up with, so the UI can say whether the device can do
/// better and how.
@immutable
class VoiceReport {
  final TtsVoice? selected;

  /// A better voice exists on this device but needs downloading first.
  final bool betterVoiceNeedsDownload;

  /// Nothing could be enumerated - the platform default is in use.
  final bool usingPlatformDefault;

  const VoiceReport({
    this.selected,
    this.betterVoiceNeedsDownload = false,
    this.usingPlatformDefault = false,
  });

  VoiceQuality get quality => selected?.quality ?? VoiceQuality.unknown;

  /// True when the teacher could meaningfully improve things by installing
  /// better voice data in the system settings.
  bool get canBeImproved => betterVoiceNeedsDownload || quality.isPoor;

  /// One line for the settings screen.
  String get summary {
    if (usingPlatformDefault) {
      return 'Using the device default voice.';
    }
    final voice = selected;
    if (voice == null) return 'No speech voice is available on this device.';
    return '${voice.name} - ${voice.quality.label} quality';
  }

  /// What to actually do about it, or null when nothing is worth saying.
  String? get advice {
    if (betterVoiceNeedsDownload) {
      return 'A better-sounding voice is available on this device but has not '
          'been downloaded yet. Open Settings, search for "Text-to-speech", '
          'then install the voice data for English.';
    }
    if (quality.isPoor) {
      return 'This device only has a basic voice installed, which is why '
          'speech sounds robotic. Open Settings, search for "Text-to-speech", '
          'and install a higher-quality English voice.';
    }
    return null;
  }
}
