import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/api/api_exception.dart';
import '../services/api/dictionary_api.dart';

/// Student-facing view of the Free Dictionary API.
///
/// Opened from a quiz with the word a student is stuck on. It performs an HTTP
/// GET against https://api.dictionaryapi.dev, parses the JSON, and shows the
/// phonetic spelling, part of speech, definitions, an example sentence, and
/// synonyms — with an explicit spinner while the request is in flight and a
/// friendly message (plus retry) when the word is unknown or the network is
/// down.
///
/// Pronunciation uses the device's text-to-speech engine, which the app
/// already depends on, rather than streaming the API's audio file.
class WordLookupSheet extends StatefulWidget {
  final String word;

  /// Colours are passed in so the sheet matches whichever subject opened it.
  final Color inkColor;
  final Color accentColor;
  final Color panelColor;

  const WordLookupSheet({
    super.key,
    required this.word,
    this.inkColor = const Color(0xFF26324A),
    this.accentColor = const Color(0xFF1976D2),
    this.panelColor = const Color(0xFFFFFEFA),
  });

  /// Opens the sheet. Returns once the student dismisses it.
  static Future<void> show(
    BuildContext context, {
    required String word,
    Color inkColor = const Color(0xFF26324A),
    Color accentColor = const Color(0xFF1976D2),
    Color panelColor = const Color(0xFFFFFEFA),
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WordLookupSheet(
        word: word,
        inkColor: inkColor,
        accentColor: accentColor,
        panelColor: panelColor,
      ),
    );
  }

  @override
  State<WordLookupSheet> createState() => _WordLookupSheetState();
}

class _WordLookupSheetState extends State<WordLookupSheet>
    with WidgetsBindingObserver {
  /// Shared across lookups so the in-memory cache survives between sheets.
  static final DictionaryApi _api = DictionaryApi();

  final FlutterTts _tts = FlutterTts();

  late Future<DictionaryEntry> _lookupFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lookupFuture = _api.lookup(widget.word);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // This sheet builds its own `FlutterTts` rather than going through
    // `TextToSpeechService`, so the app-level observer cannot reach it - a
    // word being read aloud carried on talking after the app was gone.
    if (state != AppLifecycleState.resumed) {
      _tts.stop().catchError((Object error) {
        debugPrint('Could not stop speech on background: $error');
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Unawaited, but not unhandled: the same throw that `_speak` guards
    // against is possible here too, during teardown.
    _tts.stop().catchError((Object error) {
      debugPrint('Could not stop speech on dispose: $error');
    });
    super.dispose();
  }

  void _retry() {
    setState(() => _lookupFuture = _api.lookup(widget.word));
  }

  /// Guarded, because a device with no TTS engine throws here - and this
  /// widget builds its own `FlutterTts` rather than going through
  /// `TextToSpeechService`, which already catches exactly this. Unhandled, the
  /// tap simply did nothing and said nothing.
  Future<void> _speak(String word) async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.42);
      await _tts.speak(word);
    } catch (error) {
      debugPrint('Could not speak "$word": $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('This device cannot read words out loud.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: widget.panelColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border(top: BorderSide(color: widget.inkColor, width: 2.5)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: widget.inkColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: FutureBuilder<DictionaryEntry>(
                  future: _lookupFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return _loading();
                    }
                    if (snapshot.hasError) {
                      return _error(ApiException.from(snapshot.error!).message);
                    }
                    return _content(snapshot.data!, scrollController);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _loading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: widget.accentColor),
          const SizedBox(height: 16),
          Text(
            'Looking up "${widget.word}"…',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: widget.inkColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'dictionaryapi.dev',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: widget.inkColor.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 52, color: widget.inkColor.withValues(alpha: 0.5)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.4,
                color: widget.inkColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _retry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.inkColor,
                    side: BorderSide(color: widget.inkColor, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Try again',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back to quiz',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(DictionaryEntry entry, ScrollController controller) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.word,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: widget.inkColor,
                    ),
                  ),
                  if (entry.phonetic != null)
                    Text(
                      entry.phonetic!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: widget.accentColor,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Hear it',
              onPressed: () => _speak(entry.word),
              iconSize: 34,
              icon: Icon(Icons.volume_up_rounded, color: widget.accentColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: widget.accentColor, width: 1.4),
          ),
          child: Text(
            'Free Dictionary API',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: widget.accentColor,
            ),
          ),
        ),
        const SizedBox(height: 18),
        for (final meaning in entry.meanings.take(3)) ...[
          _meaningBlock(meaning),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _meaningBlock(DictionaryMeaning meaning) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.inkColor, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x222C3550), offset: Offset(3, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meaning.partOfSpeech.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: widget.accentColor,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < meaning.definitions.take(3).length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: widget.accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meaning.definitions[i],
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: widget.inkColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if ((meaning.example ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote_rounded, size: 18, color: widget.accentColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      meaning.example!,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                        color: widget.inkColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (meaning.synonyms.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Similar words',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: widget.inkColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final synonym in meaning.synonyms)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.panelColor,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: widget.inkColor.withValues(alpha: 0.4),
                        width: 1.4,
                      ),
                    ),
                    child: Text(
                      synonym,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: widget.inkColor,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
