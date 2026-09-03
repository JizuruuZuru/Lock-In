import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../english/adjectives_and_adverbs_game.dart';
import '../english/comprehension_game.dart';
import '../english/conjunctions_and_interjections_game.dart';
import '../english/determiners_and_prepositions_game.dart';
import '../english/nouns_and_pronouns_game.dart';
import '../english/phonics_game.dart';
import '../english/punctuation_and_capitalization_game.dart';
import '../english/questions_and_speech_game.dart';
import '../english/sentence_structure_game.dart';
import '../english/spelling_game.dart';
import '../english/subject_verb_agreement_game.dart';
import '../english/verbs_and_tenses_game.dart';
import '../english/word_study_game.dart';
import '../math/math_game.dart';
import '../math/number_memory_game.dart';
import '../math/roman_numerals_game.dart';
import '../math/analog_clock_game.dart';
import '../math/place_value_game.dart';
import '../math/rounding_numbers_game.dart';
import '../math/order_operations_game.dart';
import '../math/fractions_game.dart';
import '../math/measurements_game.dart';
import '../exams/exam_game.dart';
import '../admin/admin_dashboard_page.dart';
import '../auth/register_page.dart';
import '../auth/login_page.dart';
import '../profile/leaderboard_screen.dart';
import '../science/earth_and_space_game.dart';
import '../science/humans_and_animals_game.dart';
import '../science/investigating_and_classifying_game.dart';
import '../science/life_science_and_plants_game.dart';
import '../science/materials_and_chemistry_game.dart';
import '../science/physics_and_forces_game.dart';
import '../../app_gate.dart';
import '../../models/app_user_record.dart';
import '../../services/app_settings_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/custom_question_sync.dart';
import '../../services/player_proctoring_preference.dart';
import '../../services/proctoring_settings.dart';
import '../../services/google_link_service.dart';
import '../../services/leaderboard_service.dart';
import '../../services/sound_service.dart';
import '../../services/text_to_speech_service.dart';
import '../../services/tts_voice.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/app_brightness_overlay.dart';
import '../../widgets/animated_shape_background.dart';
import '../../widgets/decorative_gif.dart';

class _HomeGameItem {
  final String name;
  final IconData icon;
  final Widget widget;
  final String subtitle;

  const _HomeGameItem({
    required this.name,
    required this.icon,
    required this.widget,
    required this.subtitle,
  });
}

class _ExamMenuItem {
  final ExamDifficulty difficulty;
  final String title;
  final String subtitle;

  const _ExamMenuItem({
    required this.difficulty,
    required this.title,
    required this.subtitle,
  });
}

enum _HomeMode { chooser, lesson, exam }

enum _LessonSubject { english, math, science }

class _LessonSubjectItem {
  final _LessonSubject subject;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _LessonSubjectItem({
    required this.subject,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _ExamSubjectItem {
  final Set<ExamSubjectSelection> subject;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ExamSubjectItem({
    required this.subject,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class HomeMenu extends StatefulWidget {
  const HomeMenu({super.key});

  @override
  State<HomeMenu> createState() => _HomeMenuState();
}

class _HomeMenuState extends State<HomeMenu> {
  static const Color _inkColor = Color(0xFF2F5233);
  static const Color _bgTopColor = Color(0xFFE6F7E6);
  static const Color _bgBottomColor = Color(0xFFD4EDD1);
  static const Color _panelColor = Color(0xFFFAFFF9);
  static const Color _accentColor = Color(0xFF4CAF50);

  int _currentIndex = 0;
  int _previousIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  Map<String, dynamic>? userData;
  _HomeMode _homeMode = _HomeMode.chooser;
  _LessonSubject? _selectedLessonSubject;
  Set<ExamSubjectSelection>? _selectedExamSubject;
  bool _isOffline = false;

  /// Held so it can be cancelled in dispose. Without this the callback keeps
  /// firing after the screen is gone - calling setState on a dead State the
  /// moment the player signs out.
  StreamSubscription<User?>? _authSubscription;

  /// The profile history query, cached with the value it was built from.
  /// Unlike the admin lists this stream is not constant: clearing history
  /// adds a `timestamp >` bound. Rebuilding it inline on every frame would
  /// reopen the listener constantly, so it is rebuilt only when that bound
  /// actually changes.
  Stream<QuerySnapshot<Map<String, dynamic>>>? _historyStream;
  String? _historyStreamKey;

  /// True while Google's account chooser is open, so the button cannot be
  /// tapped twice.
  bool _isLinkingGoogle = false;

  @override
  void initState() {
    super.initState();
    SoundService().playPageBgm(BgmPage.home);
    SoundService().registerUserInteraction();
    _authSubscription = _auth.authStateChanges().listen((u) {
      if (!mounted) return;
      setState(() {
        user = u;
        // Force the history query to be rebuilt for whoever signed in.
        _historyStream = null;
        _historyStreamKey = null;
      });
      fetchUserData();
    });
    _checkOfflineOnOpen();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkOfflineOnOpen() async {
    final offline = await ConnectivityService.isOffline();
    if (!mounted) return;
    setState(() => _isOffline = offline);
    if (!offline) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          backgroundColor: const Color(0xFFFFF3E0),
          leading: const Icon(Icons.wifi_off_rounded, color: Color(0xFFE65100)),
          content: const Text(
            "You're offline. You can still play, but scores will not be recorded until you're back online.",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              },
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> fetchUserData() async {
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        if (!mounted) return;
        if (doc.exists) {
          setState(() {
            userData = doc.data();
            // history_cleared_at may have changed with the new data.
            _historyStream = null;
            _historyStreamKey = null;
          });
        }
      } catch (error) {
        debugPrint('fetchUserData failed (likely offline): $error');
      }
    } else {
      if (!mounted) return;
      setState(() => userData = null);
    }
  }

  /// The player's game history, rebuilt only when the signed-in account or
  /// the "history cleared" bound changes. Returning a new stream on every
  /// build would drop and reopen the Firestore listener each frame, flashing
  /// the list back to its spinner.
  /// How many finished games the History tab keeps live.
  static const int _historyLimit = 200;

  Stream<QuerySnapshot<Map<String, dynamic>>> _gameHistoryStream(String uid) {
    final clearedAt = userData?['history_cleared_at'];
    final key = '$uid|${clearedAt is Timestamp ? clearedAt.toString() : ''}';

    final cached = _historyStream;
    if (cached != null && _historyStreamKey == key) return cached;

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('game_logs');
    if (clearedAt is Timestamp) {
      query = query.where('timestamp', isGreaterThan: clearedAt);
    }

    // Capped. This is a live listener over a player's whole history, and an
    // account with hundreds of finished games streamed - and re-streamed on
    // every change - every one of them. The History tab only ever shows recent
    // runs and per-game bests, both of which this covers comfortably.
    final stream = query
        .orderBy('timestamp', descending: true)
        .limit(_historyLimit)
        .snapshots();
    _historyStream = stream;
    _historyStreamKey = key;
    return stream;
  }

  Future<void> _showSettingsSheet() async {
    final soundService = SoundService();
    final appSettings = AppSettingsService();

    var soundEnabled = soundService.soundEnabled;
    var musicLevel = soundService.musicLevel;
    var sfxLevel = soundService.sfxLevel;
    var brightness = appSettings.brightness;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _panelColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.settings_rounded,
                              color: _accentColor, size: 28),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Settings',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Enable Sound',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      value: soundEnabled,
                      onChanged: (value) {
                        setModalState(() => soundEnabled = value);
                        soundService.setSoundEnabled(value);
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Music Volume (${(musicLevel * 100).round()}%)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Slider(
                      value: musicLevel,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      onChanged: soundEnabled
                          ? (value) {
                              setModalState(() => musicLevel = value);
                              soundService.setMusicLevel(value);
                            }
                          : null,
                    ),
                    Text(
                      'Effects Volume (${(sfxLevel * 100).round()}%)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Slider(
                      value: sfxLevel,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      onChanged: soundEnabled
                          ? (value) {
                              setModalState(() => sfxLevel = value);
                              soundService.setSfxLevel(value);
                            }
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Brightness (${(brightness * 100).round()}%)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Slider(
                      value: brightness,
                      min: 0.6,
                      max: 1.3,
                      divisions: 14,
                      onChanged: (value) {
                        setModalState(() => brightness = value);
                        appSettings.setBrightness(value);
                      },
                    ),
                    const Divider(height: 26),
                    const _ReadingVoiceSection(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _clearUserData() async {
    final currentUser = user;
    if (currentUser == null) return;

    final shouldClear = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _panelColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (dialogContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD84315).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.delete_forever_rounded,
                          color: Color(0xFFD84315), size: 28),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Clear history data?',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'This clears your history view in the app. Raw logs stay in Firebase.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD84315),
                        ),
                        child: const Text('Clear'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldClear != true) return;

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(currentUser.uid);
    final now = Timestamp.now();

    await userRef.collection('data_clear_events').add({
      'action': 'clear_history_and_profile_view',
      'timestamp': now,
      'source': 'profile_clear_data_button',
    });

    await userRef.set(
      {
        'history_cleared_at': now,
        'last_data_clear_at': now,
        'last_data_clear_source': 'profile_clear_data_button',
        'data_clear_count': FieldValue.increment(1),
        'email': currentUser.email,
      },
      SetOptions(merge: true),
    );

    if (!mounted || !context.mounted) return;

    final updatedUserData = Map<String, dynamic>.from(userData ?? {});
    updatedUserData['history_cleared_at'] = now;
    updatedUserData['last_data_clear_at'] = now;
    updatedUserData['last_data_clear_source'] = 'profile_clear_data_button';
    updatedUserData['data_clear_count'] =
        (updatedUserData['data_clear_count'] ?? 0) + 1;

    setState(() {
      userData = updatedUserData;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data cleared from app history view.')),
    );
  }

  ThemeData _buildTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: _inkColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: _inkColor,
        displayColor: _inkColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _inkColor, width: 2),
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _accentColor,
        unselectedItemColor: Color(0xFFBDBDBD),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _panelColor,
      ),
    );
  }

  Widget _buildBackground({required Widget child}) {
    return AnimatedShapeBackground(
      gradientColors: const [_bgTopColor, _bgBottomColor],
      shapes: const [
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.diamond,
          alignment: Alignment.topLeft,
          baseOffset: Offset(-38, -24),
          drift: Offset(16, 12),
          size: 150,
          color: Color(0x334CAF50),
          borderColor: Color(0x4D2F5233),
          initialRotation: -0.2,
          cornerRadius: 20,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.capsule,
          alignment: Alignment.topRight,
          baseOffset: Offset(24, 76),
          drift: Offset(14, 18),
          size: 112,
          color: Color(0x33FF9800),
          borderColor: Color(0x4D2F5233),
          initialRotation: 0.18,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.circle,
          alignment: Alignment.bottomLeft,
          baseOffset: Offset(36, 38),
          drift: Offset(12, 14),
          size: 126,
          color: Color(0x2E4CAF50),
          borderColor: Color(0x4D2F5233),
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.roundedSquare,
          alignment: Alignment.bottomRight,
          baseOffset: Offset(22, 30),
          drift: Offset(10, 15),
          size: 92,
          color: Color(0x26FF9800),
          borderColor: Color(0x442F5233),
          cornerRadius: 26,
          initialRotation: 0.32,
        ),
      ],
      child: child,
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _inkColor, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332C3550),
            offset: Offset(5, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final dt = timestamp.toDate().toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  List<MapEntry<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>>
      _groupLogsByGame(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final grouped =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final doc in docs) {
      final data = doc.data();
      final game = (data['game'] as String?)?.trim();
      final key = (game == null || game.isEmpty) ? 'Unknown Game' : game;
      grouped.putIfAbsent(key, () => []).add(doc);
    }

    final entries = grouped.entries.toList();
    entries.sort((a, b) {
      final aTimestamp = a.value.first.data()['timestamp'] as Timestamp?;
      final bTimestamp = b.value.first.data()['timestamp'] as Timestamp?;
      final aMicros = aTimestamp?.microsecondsSinceEpoch ?? 0;
      final bMicros = bTimestamp?.microsecondsSinceEpoch ?? 0;
      return bMicros.compareTo(aMicros);
    });
    return entries;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _topScoreLogs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final withScores = docs.where((doc) {
      final score = doc.data()['score'];
      return score is num;
    }).toList();

    withScores.sort((a, b) {
      final aData = a.data();
      final bData = b.data();
      final aScore = (aData['score'] as num).toDouble();
      final bScore = (bData['score'] as num).toDouble();
      final byScore = bScore.compareTo(aScore);
      if (byScore != 0) return byScore;

      final aTimestamp = aData['timestamp'] as Timestamp?;
      final bTimestamp = bData['timestamp'] as Timestamp?;
      final aMicros = aTimestamp?.microsecondsSinceEpoch ?? 0;
      final bMicros = bTimestamp?.microsecondsSinceEpoch ?? 0;
      return bMicros.compareTo(aMicros);
    });

    return withScores.take(3).toList();
  }

  Widget _buildTopScoresCard(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> topLogs,
  ) {
    const rankColors = <Color>[
      Color(0xFFFFD54F), // Top 1 (gold)
      Color(0xFFB0BEC5), // Top 2 (silver)
      Color(0xFFFFAB91), // Top 3 (bronze)
    ];
    const rankInkColors = <Color>[
      Color(0xFF5D4037),
      Color(0xFF37474F),
      Color(0xFF6D4C41),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          if (topLogs.isEmpty)
            const Text(
              'No scored attempts yet.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            )
          else
            ...topLogs.asMap().entries.map((entry) {
              final rank = entry.key;
              final data = entry.value.data();
              final game = (data['game'] as String?) ?? 'Unknown Game';
              final scoreValue = data['score'];
              final scoreText = scoreValue == null ? '-' : '$scoreValue';
              final timestamp = data['timestamp'] as Timestamp?;
              final when = _formatTimestamp(timestamp);
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: rankColors[rank].withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: rankInkColors[rank],
                    width: 1.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: rankInkColors[rank],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Top ${rank + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: rankInkColors[rank],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            when,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: rankInkColors[rank],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      scoreText,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: rankInkColors[rank],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Built on demand. As a list literal all three tabs were constructed on
    // every rebuild - and this page rebuilds on every nav tap, auth event,
    // profile fetch, and mode selection - so the History tab's StreamBuilder
    // and ExpansionTile tree and the Settings profile card were assembled in
    // full even while the Play tab was showing.
    final Widget page = switch (_currentIndex) {
      0 => _buildHome(),
      1 => _buildHistories(),
      _ => _buildSettings(),
    };

    return Theme(
      data: _buildTheme(context),
      child: AppBrightnessOverlay(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Lock In'),
            actions: [
              if (_isOffline)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Tooltip(
                    message: "Offline — scores won't be recorded",
                    child: Icon(Icons.wifi_off_rounded),
                  ),
                ),
              IconButton(
                onPressed: () {
                  SoundService().playButtonSoundNow();
                  _showSettingsSheet();
                },
                icon: const Icon(Icons.settings_rounded),
                tooltip: 'Settings',
              ),
            ],
          ),
          body: _buildBackground(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slideStartX =
                    _currentIndex >= _previousIndex ? 0.08 : -0.08;
                final slideTween = Tween<Offset>(
                  begin: Offset(slideStartX, 0),
                  end: Offset.zero,
                );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: animation
                        .drive(
                          CurveTween(curve: Curves.easeOutCubic),
                        )
                        .drive(slideTween),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: page,
              ),
            ),
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: _panelColor,
              border: Border(
                top: BorderSide(color: _inkColor, width: 2.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x332C3550),
                  offset: Offset(0, -3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      icon: Icons.sports_esports,
                      label: 'Play',
                      index: 0,
                    ),
                    _buildNavItem(
                      icon: Icons.history,
                      label: 'History',
                      index: 1,
                    ),
                    _buildNavItem(
                      icon: Icons.person,
                      label: 'Profile',
                      index: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          SoundService().playButtonSoundNow();
          if (_currentIndex == index) return;
          setState(() {
            _previousIndex = _currentIndex;
            _currentIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? _accentColor.withValues(alpha: 0.2) : _panelColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? _accentColor : _inkColor.withValues(alpha: 0.2),
              width: isActive ? 2.2 : 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.3),
                      offset: const Offset(2, 3),
                      blurRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: isActive ? _accentColor : _inkColor,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                  color: isActive ? _accentColor : _inkColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_LessonSubjectItem> get _lessonSubjectItems => const [
        _LessonSubjectItem(
          subject: _LessonSubject.english,
          title: 'English',
          icon: Icons.menu_book_rounded,
          color: Color(0xFF1976D2),
          subtitle:
              'Word-level and sentence-level grammar, reading, word study, and phonics.',
        ),
        _LessonSubjectItem(
          subject: _LessonSubject.math,
          title: 'Math',
          icon: Icons.calculate_rounded,
          color: Color(0xFF9C27B0),
          subtitle:
              'Numbers, operations, memory, time, fractions, and measurements.',
        ),
        _LessonSubjectItem(
          subject: _LessonSubject.science,
          title: 'Science',
          icon: Icons.science_rounded,
          color: Color(0xFF00897B),
          subtitle:
              'Investigating, life science, humans and animals, materials, physics, and Earth and space.',
        ),
      ];

  List<_HomeGameItem> get _englishLessonGames => const [
        _HomeGameItem(
          name: 'Nouns and Pronouns',
          icon: Icons.menu_book_rounded,
          widget: EnglishNounsAndPronounsGame(),
          subtitle: 'Nouns, plural and possessive forms, and pronouns.',
        ),
        _HomeGameItem(
          name: 'Verbs and Tenses',
          icon: Icons.update_rounded,
          widget: EnglishVerbsAndTensesGame(),
          subtitle: 'Action verbs and simple present, past, and future tense.',
        ),
        _HomeGameItem(
          name: 'Adjectives and Adverbs',
          icon: Icons.palette_rounded,
          widget: EnglishAdjectivesAndAdverbsGame(),
          subtitle: 'Describing words for nouns and verbs.',
        ),
        _HomeGameItem(
          name: 'Determiners and Prepositions',
          icon: Icons.place_rounded,
          widget: EnglishDeterminersAndPrepositionsGame(),
          subtitle: 'Articles, determiners, and prepositions.',
        ),
        _HomeGameItem(
          name: 'Conjunctions and Interjections',
          icon: Icons.link_rounded,
          widget: EnglishConjunctionsAndInterjectionsGame(),
          subtitle: 'Joining words and short exclamations.',
        ),
        _HomeGameItem(
          name: 'Sentence Structure',
          icon: Icons.edit_note_rounded,
          widget: EnglishSentenceStructureGame(),
          subtitle: 'Complete sentences and compound sentences.',
        ),
        _HomeGameItem(
          name: 'Subject-Verb Agreement',
          icon: Icons.rule_rounded,
          widget: EnglishSubjectVerbAgreementGame(),
          subtitle: 'Matching subjects and verbs, plus objects.',
        ),
        _HomeGameItem(
          name: 'Punctuation and Capitalization',
          icon: Icons.format_quote_rounded,
          widget: EnglishPunctuationAndCapitalizationGame(),
          subtitle: 'Capital letters, end punctuation, and commas.',
        ),
        _HomeGameItem(
          name: 'Questions and Speech',
          icon: Icons.question_answer_rounded,
          widget: EnglishQuestionsAndSpeechGame(),
          subtitle: 'Questions, active/passive voice, and reported speech.',
        ),
        _HomeGameItem(
          name: 'Comprehension',
          icon: Icons.chrome_reader_mode_rounded,
          widget: EnglishComprehensionGame(),
          subtitle: 'Main idea, details, sequencing, causes, and inference.',
        ),
        _HomeGameItem(
          name: 'Word Study',
          icon: Icons.auto_stories_rounded,
          widget: EnglishWordStudyGame(),
          subtitle: 'Synonyms, antonyms, homophones, and compound words.',
        ),
        _HomeGameItem(
          name: 'Phonics',
          icon: Icons.spellcheck_rounded,
          widget: EnglishPhonicsGame(),
          subtitle: 'Spelling patterns, letter sounds, blends, and vowels.',
        ),
        _HomeGameItem(
          name: 'Spelling',
          icon: Icons.record_voice_over_rounded,
          widget: EnglishSpellingGame(),
          subtitle: 'Listen to a word and spell it on the keyboard.',
        ),
      ];

  List<_HomeGameItem> get _scienceLessonGames => const [
        _HomeGameItem(
          name: 'Investigating and Classifying',
          icon: Icons.travel_explore_rounded,
          widget: ScienceInvestigatingAndClassifyingGame(),
          subtitle: 'Scientific method, tools, and living vs. nonliving.',
        ),
        _HomeGameItem(
          name: 'Life Science and Plants',
          icon: Icons.eco_rounded,
          widget: ScienceLifeScienceAndPlantsGame(),
          subtitle: 'Plant parts, needs, life cycles, and pollination.',
        ),
        _HomeGameItem(
          name: 'Humans and Animals',
          icon: Icons.health_and_safety_rounded,
          widget: ScienceHumansAndAnimalsGame(),
          subtitle: 'Animal groups, habitats, senses, and the human body.',
        ),
        _HomeGameItem(
          name: 'Materials and Chemistry',
          icon: Icons.category_rounded,
          widget: ScienceMaterialsAndChemistryGame(),
          subtitle: 'States of matter, material properties, and mixtures.',
        ),
        _HomeGameItem(
          name: 'Physics and Forces',
          icon: Icons.bolt_rounded,
          widget: SciencePhysicsAndForcesGame(),
          subtitle: 'Forces, motion, simple machines, and energy.',
        ),
        _HomeGameItem(
          name: 'Earth and Space',
          icon: Icons.nightlight_round,
          widget: ScienceEarthAndSpaceGame(),
          subtitle: 'Solar system, rocks, weather, and seasons.',
        ),
      ];

  List<_HomeGameItem> get _mathLessonGames => const [
        _HomeGameItem(
          name: 'Math Game',
          icon: Icons.calculate,
          widget: MathGame(),
          subtitle:
              'Addition, subtraction, multiplication, and division drills.',
        ),
        _HomeGameItem(
          name: 'Number Memory',
          icon: Icons.memory,
          widget: NumberMemoryGame(),
          subtitle: 'Remember and type the number sequence correctly.',
        ),
        _HomeGameItem(
          name: 'Roman Numerals',
          icon: Icons.format_list_numbered_rounded,
          widget: RomanNumeralsGame(),
          subtitle: 'Practice Roman numerals and number conversion.',
        ),
        _HomeGameItem(
          name: 'Analog Clock',
          icon: Icons.schedule_rounded,
          widget: AnalogClockGame(),
          subtitle: 'Read analog clocks and enter the correct time.',
        ),
        _HomeGameItem(
          name: 'Place Value',
          icon: Icons.view_week_rounded,
          widget: PlaceValueGame(),
          subtitle: 'Build numbers and find missing place values.',
        ),
        _HomeGameItem(
          name: 'Rounding Numbers',
          icon: Icons.exposure_plus_1_rounded,
          widget: RoundingNumbersGame(),
          subtitle: 'Round numbers to tens, hundreds, and thousands.',
        ),
        _HomeGameItem(
          name: 'Order of Operations',
          icon: Icons.functions_rounded,
          widget: OrderOperationsGame(),
          subtitle: 'Solve expressions using the correct operation order.',
        ),
        _HomeGameItem(
          name: 'Fractions',
          icon: Icons.splitscreen_rounded,
          widget: FractionsGame(),
          subtitle: 'Compare, simplify, convert, add, and subtract fractions.',
        ),
        _HomeGameItem(
          name: 'Measurements',
          icon: Icons.straighten_rounded,
          widget: MeasurementsGame(),
          subtitle:
              'Practice length, weight, capacity, and temperature conversions.',
        ),
      ];

  List<_HomeGameItem> _lessonGamesFor(_LessonSubject subject) {
    switch (subject) {
      case _LessonSubject.english:
        return _englishLessonGames;
      case _LessonSubject.math:
        return _mathLessonGames;
      case _LessonSubject.science:
        return _scienceLessonGames;
    }
  }

  List<_ExamSubjectItem> get _examSubjectItems => const [
        _ExamSubjectItem(
          subject: {ExamSubjectSelection.english},
          title: 'English',
          icon: Icons.menu_book_rounded,
          color: Color(0xFF1976D2),
          subtitle: 'Grammar, reading, vocabulary, and phonics questions.',
        ),
        _ExamSubjectItem(
          subject: {ExamSubjectSelection.math},
          title: 'Math',
          icon: Icons.calculate_rounded,
          color: Color(0xFF9C27B0),
          subtitle: 'Operations, number skills, time, fractions, and measures.',
        ),
        _ExamSubjectItem(
          subject: {ExamSubjectSelection.science},
          title: 'Science',
          icon: Icons.science_rounded,
          color: Color(0xFF00897B),
          subtitle: 'Life, physical, Earth, and space science questions.',
        ),
        _ExamSubjectItem(
          subject: {
            ExamSubjectSelection.english,
            ExamSubjectSelection.math,
            ExamSubjectSelection.science,
          },
          title: 'All Subjects',
          icon: Icons.auto_awesome_rounded,
          color: Color(0xFFFF9800),
          subtitle:
              'Mixed English, Math, and Science exam questions. You can '
              'fine-tune the exact mix on the next screen.',
        ),
      ];

  List<_ExamMenuItem> get _examItems => const [
        _ExamMenuItem(
          difficulty: ExamDifficulty.easy,
          title: 'Easy',
          subtitle: 'Short elementary questions with friendly pacing.',
        ),
        _ExamMenuItem(
          difficulty: ExamDifficulty.medium,
          title: 'Medium',
          subtitle: 'More steps, stronger reading, and applied topics.',
        ),
        _ExamMenuItem(
          difficulty: ExamDifficulty.hard,
          title: 'Hard',
          subtitle: 'Longer challenges from the selected subject set.',
        ),
      ];

  void _openGame(Widget page) {
    SoundService().playButtonSoundNow();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  String _lessonSubjectName(_LessonSubject subject) {
    switch (subject) {
      case _LessonSubject.english:
        return 'English';
      case _LessonSubject.math:
        return 'Math';
      case _LessonSubject.science:
        return 'Science';
    }
  }

  void _handleHomeHeaderBack() {
    SoundService().playButtonSoundNow();
    setState(() {
      if (_homeMode == _HomeMode.lesson && _selectedLessonSubject != null) {
        _selectedLessonSubject = null;
        return;
      }

      if (_homeMode == _HomeMode.exam && _selectedExamSubject != null) {
        _selectedExamSubject = null;
        return;
      }

      _homeMode = _HomeMode.chooser;
      _selectedLessonSubject = null;
      _selectedExamSubject = null;
    });
  }

  String _examSubjectName(Set<ExamSubjectSelection> subjects) =>
      examSubjectSetTitle(subjects);

  String _homeHeaderTitle() {
    switch (_homeMode) {
      case _HomeMode.chooser:
        return 'Welcome Back!';
      case _HomeMode.lesson:
        final subject = _selectedLessonSubject;
        return subject == null
            ? 'Choose a Subject'
            : '${_lessonSubjectName(subject)} Lessons';
      case _HomeMode.exam:
        final subject = _selectedExamSubject;
        return subject == null
            ? 'Choose Exam Subject'
            : '${_examSubjectName(subject)} Exam';
    }
  }

  String _homeHeaderSubtitle() {
    switch (_homeMode) {
      case _HomeMode.chooser:
        return 'Pick Lesson for practice or Exam for randomized challenges.';
      case _HomeMode.lesson:
        final subject = _selectedLessonSubject;
        return subject == null
            ? 'Choose English, Math, or Science first.'
            : 'Select a ${_lessonSubjectName(subject)} lesson to begin.';
      case _HomeMode.exam:
        final subject = _selectedExamSubject;
        return subject == null
            ? 'Choose English, Math, Science, or a mixed exam first.'
            : 'Select Easy, Medium, or Hard for ${_examSubjectName(subject)}.';
    }
  }

  Widget _buildHome() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final desktop = isDesktopLayout(width);
          final horizontalPadding = desktop ? 28.0 : 16.0;
          final maxWidth = responsivePanelMaxWidth(width);

          // Desktop: header stays put and the body fills all remaining
          // height (via Expanded) so few-item screens (chooser, subject
          // pickers) stretch to use the whole window instead of leaving a
          // blank gap underneath. Individual views add their own scroll
          // region only where the item count can actually overflow.
          final body = AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: switch (_homeMode) {
              _HomeMode.chooser => _buildMainChoiceView(),
              _HomeMode.lesson => _buildLessonView(),
              _HomeMode.exam => _buildExamView(),
            },
          );

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: maxWidth,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: desktop ? 10 : 16,
                ),
                child: desktop
                    ? Column(
                        children: [
                          _buildHomeHeader(),
                          const SizedBox(height: 10),
                          Expanded(child: body),
                        ],
                      )
                    : Scrollbar(
                        child: ListView(
                          children: [
                            _buildHomeHeader(),
                            const SizedBox(height: 16),
                            body,
                          ],
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = isDesktopLayout(MediaQuery.sizeOf(context).width);
        return _card(
          padding: desktop
              ? const EdgeInsets.fromLTRB(14, 12, 14, 14)
              : const EdgeInsets.fromLTRB(18, 18, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_homeMode != _HomeMode.chooser) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _handleHomeHeaderBack,
                      child: Container(
                        padding: EdgeInsets.all(desktop ? 6 : 8),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _accentColor, width: 1.8),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: _accentColor,
                          size: desktop ? 20 : 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      _homeHeaderTitle(),
                      style: TextStyle(
                        fontSize: desktop ? 22 : 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: desktop ? 4 : 8),
              Text(
                _homeHeaderSubtitle(),
                style: TextStyle(fontSize: desktop ? 13 : 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainChoiceView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final desktop = isDesktopLayout(width);
        const contentWidth = double.infinity;

        final lessonCard = _buildGifChoiceCard(
          title: 'Lesson',
          subtitle: 'Practice every subject one by one.',
          gifPath: 'assets/gifs/lesson.gif',
          icon: Icons.school_rounded,
          onTap: () {
            SoundService().playButtonSoundNow();
            setState(() {
              _homeMode = _HomeMode.lesson;
              _selectedLessonSubject = null;
            });
          },
        );
        final examCard = _buildGifChoiceCard(
          title: 'Exam',
          subtitle: 'Choose a subject, then take a randomized test.',
          gifPath: 'assets/gifs/exam.gif',
          icon: Icons.quiz_rounded,
          onTap: () {
            SoundService().playButtonSoundNow();
            setState(() {
              _homeMode = _HomeMode.exam;
              _selectedExamSubject = null;
            });
          },
        );

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: contentWidth),
            child: desktop
                ? Row(
                    key: const ValueKey('home-choice'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: lessonCard),
                      const SizedBox(width: 14),
                      Expanded(child: examCard),
                    ],
                  )
                : Column(
                    key: const ValueKey('home-choice'),
                    children: [
                      lessonCard,
                      const SizedBox(height: 16),
                      examCard,
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildGifChoiceCard({
    required String title,
    required String subtitle,
    required String gifPath,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: _card(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final desktop = isDesktopLayout(MediaQuery.sizeOf(context).width);
            final gifHeight = (width * 0.55).clamp(170.0, 260.0);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: desktop ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.30),
                          width: 1.6,
                        ),
                      ),
                      child: Icon(icon, color: _accentColor, size: desktop ? 22 : 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: desktop ? 20 : 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: desktop ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: desktop ? 12 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded,
                        color: _accentColor),
                  ],
                ),
                SizedBox(height: desktop ? 8 : 12),
                (desktop
                    ? Expanded(
                        child: _gifBox(gifPath, _accentColor,
                            displayWidth: width),
                      )
                    : SizedBox(
                        height: gifHeight.toDouble(),
                        child: _gifBox(gifPath, _accentColor,
                            displayWidth: width),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _gifBox(String gifPath, Color color, {double? displayWidth}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _inkColor.withValues(alpha: 0.18),
          width: 1.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: DecorativeGif(
        assetPath: gifPath,
        displayWidth: displayWidth,
      ),
    );
  }

  Widget _buildLessonView() {
    final selectedSubject = _selectedLessonSubject;
    if (selectedSubject == null) return _buildLessonSubjectView();

    final lessonGames = _lessonGamesFor(selectedSubject);
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = isDesktopLayout(constraints.maxWidth);
        final list = Column(
          key: ValueKey('lesson-view-${selectedSubject.name}'),
          children: [
            ...lessonGames.asMap().entries.map((entry) {
              return _buildLessonGameCard(game: entry.value, index: entry.key);
            }),
          ],
        );
        // This list can run to 13 items, so unlike the other (fixed,
        // small-count) desktop views it gets its own scrollbar rather than
        // being force-stretched to fill the screen.
        if (!desktop) return list;
        return Scrollbar(
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(child: list),
        );
      },
    );
  }

  Widget _buildLessonSubjectView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = isDesktopLayout(constraints.maxWidth);
        final items = _lessonSubjectItems;
        if (desktop) {
          return Row(
            key: const ValueKey('lesson-subject-view'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                Expanded(
                  child: _buildLessonSubjectCard(
                    item: items[i],
                    index: i,
                    fillHeight: true,
                  ),
                ),
                if (i != items.length - 1) const SizedBox(width: 14),
              ],
            ],
          );
        }
        return Column(
          key: const ValueKey('lesson-subject-view'),
          children: [
            for (final entry in items.asMap().entries)
              _buildLessonSubjectCard(item: entry.value, index: entry.key),
          ],
        );
      },
    );
  }

  /// A single tappable row used for every subject/lesson/exam list on the
  /// home screen. Deliberately not a [ListTile] — Material enforces a
  /// minimum tile height even when `dense: true`, which made desktop lists
  /// too tall to fit a screen without scrolling. This gives full control.
  Widget _buildCompactRowCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required int index,
    // When true, this card is one of a handful of tiles stretched (via a
    // parent Row + CrossAxisAlignment.stretch) to fill the whole desktop
    // screen height, so its content is centered in a bigger tile instead of
    // sitting in a thin, top-aligned row.
    bool fillHeight = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = isDesktopLayout(MediaQuery.sizeOf(context).width);
        final bigTile = fillHeight && desktop;
        // Squared (low-radius) icon chip, sized generously so it reads
        // clearly from normal monitor viewing distance.
        final iconSize = bigTile ? 88.0 : (desktop ? 48.0 : 46.0);
        final iconGlyphSize = bigTile ? 44.0 : (desktop ? 26.0 : 28.0);
        final iconRadius = bigTile ? 18.0 : (desktop ? 12.0 : 15.0);

        final Widget content;
        if (bigTile) {
          content = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(iconRadius),
                  border: Border.all(color: color, width: 2.2),
                ),
                child: Icon(icon, size: iconGlyphSize, color: color),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Icon(Icons.arrow_forward_rounded, size: 28, color: color),
            ],
          );
        } else {
          content = Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(iconRadius),
                  border: Border.all(color: color, width: desktop ? 1.8 : 1.8),
                ),
                child: Icon(icon, size: iconGlyphSize, color: color),
              ),
              SizedBox(width: desktop ? 14 : 12),
              Expanded(
                child: desktop
                    ? Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ],
                      ),
              ),
              Icon(Icons.arrow_forward_rounded, size: desktop ? 22 : 24),
            ],
          );
        }

        final cardChild = InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: bigTile ? Center(child: content) : content,
        );

        final card = _card(
          padding: EdgeInsets.symmetric(
            horizontal: bigTile ? 18 : (desktop ? 16 : 14),
            vertical: bigTile ? 18 : (desktop ? 12 : 14),
          ),
          child: cardChild,
        );

        if (bigTile) {
          return Transform.rotate(
            angle: index.isEven ? -0.006 : 0.006,
            child: card,
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(vertical: desktop ? 5 : 6),
          child: Transform.rotate(
            angle: index.isEven ? -0.006 : 0.006,
            child: card,
          ),
        );
      },
    );
  }

  Widget _buildLessonSubjectCard({
    required _LessonSubjectItem item,
    required int index,
    bool fillHeight = false,
  }) {
    return _buildCompactRowCard(
      icon: item.icon,
      color: item.color,
      title: item.title,
      subtitle: item.subtitle,
      index: index,
      fillHeight: fillHeight,
      onTap: () {
        SoundService().playButtonSoundNow();
        setState(() => _selectedLessonSubject = item.subject);
      },
    );
  }

  Widget _buildLessonGameCard({
    required _HomeGameItem game,
    required int index,
  }) {
    return _buildCompactRowCard(
      icon: game.icon,
      color: _accentColor,
      title: game.name,
      subtitle: game.subtitle,
      index: index,
      onTap: () => _openGame(game.widget),
    );
  }

  Widget _buildExamView() {
    final selectedSubject = _selectedExamSubject;
    if (selectedSubject == null) return _buildExamSubjectView();

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = isDesktopLayout(constraints.maxWidth);
        const contentWidth = double.infinity;

        final cards = [
          _buildExamGifCard(
            item: _examItems[0],
            subject: selectedSubject,
            gifPath: 'assets/gifs/easy.gif',
            color: const Color(0xFF43A047),
          ),
          _buildExamGifCard(
            item: _examItems[1],
            subject: selectedSubject,
            gifPath: 'assets/gifs/medium.gif',
            color: const Color(0xFFFF9800),
          ),
          _buildExamGifCard(
            item: _examItems[2],
            subject: selectedSubject,
            gifPath: 'assets/gifs/hard.gif',
            color: const Color(0xFFD84315),
          ),
        ];

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: contentWidth),
            child: desktop
                ? Row(
                    key: ValueKey('exam-view-${examSubjectSetTitle(selectedSubject)}'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        Expanded(child: cards[i]),
                        if (i != cards.length - 1) const SizedBox(width: 12),
                      ],
                    ],
                  )
                : Column(
                    key: ValueKey('exam-view-${examSubjectSetTitle(selectedSubject)}'),
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        cards[i],
                        if (i != cards.length - 1) const SizedBox(height: 14),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildExamSubjectView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = isDesktopLayout(constraints.maxWidth);
        final items = _examSubjectItems;
        if (desktop) {
          return Row(
            key: const ValueKey('exam-subject-view'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                Expanded(
                  child: _buildExamSubjectCard(
                    item: items[i],
                    index: i,
                    fillHeight: true,
                  ),
                ),
                if (i != items.length - 1) const SizedBox(width: 14),
              ],
            ],
          );
        }
        return Column(
          key: const ValueKey('exam-subject-view'),
          children: [
            for (final entry in items.asMap().entries)
              _buildExamSubjectCard(item: entry.value, index: entry.key),
          ],
        );
      },
    );
  }

  Widget _buildExamSubjectCard({
    required _ExamSubjectItem item,
    required int index,
    bool fillHeight = false,
  }) {
    return _buildCompactRowCard(
      icon: item.icon,
      color: item.color,
      title: item.title,
      subtitle: item.subtitle,
      index: index,
      fillHeight: fillHeight,
      onTap: () {
        SoundService().playButtonSoundNow();
        setState(() => _selectedExamSubject = item.subject);
      },
    );
  }

  Widget _buildExamGifCard({
    required _ExamMenuItem item,
    required Set<ExamSubjectSelection> subject,
    required String gifPath,
    required Color color,
  }) {
    final subjectName = _examSubjectName(subject);
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => _openGame(
        ExamGame(
          difficulty: item.difficulty,
          subjectSelection: subject,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = isDesktopLayout(MediaQuery.sizeOf(context).width);
          final gifHeight = (constraints.maxWidth * 0.46).clamp(145.0, 230.0);
          return _card(
            padding: EdgeInsets.all(desktop ? 10 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: desktop ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: desktop ? 10 : 14,
                    vertical: desktop ? 8 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: desktop ? 34 : 42,
                        height: desktop ? 34 : 42,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.shuffle_rounded,
                          color: Colors.white,
                          size: desktop ? 20 : 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$subjectName ${item.title} Exam',
                              maxLines: desktop ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: desktop ? 15 : 22,
                                fontWeight: FontWeight.w900,
                                color: color,
                              ),
                            ),
                            if (!desktop) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: desktop ? 8 : 12),
                (desktop
                    ? Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color.withValues(alpha: 0.45),
                              width: 1.8,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: DecorativeGif(
                            assetPath: gifPath,
                            displayWidth: constraints.maxWidth,
                          ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: gifHeight.toDouble(),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: color.withValues(alpha: 0.45),
                            width: 1.8,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: DecorativeGif(
                          assetPath: gifPath,
                          displayWidth: constraints.maxWidth,
                        ),
                      )),
                SizedBox(height: desktop ? 8 : 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openGame(
                      ExamGame(
                        difficulty: item.difficulty,
                        subjectSelection: subject,
                      ),
                    ),
                    icon: Icon(Icons.play_arrow_rounded, size: desktop ? 18 : 24),
                    label: Text(
                      desktop ? 'Start' : 'Start $subjectName ${item.title} Exam',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      minimumSize: Size.fromHeight(
                        desktop ? 40 : responsiveButtonHeight(MediaQuery.sizeOf(context).width),
                      ),
                      padding: EdgeInsets.symmetric(vertical: desktop ? 8 : 16),
                      textStyle: TextStyle(
                        fontSize: desktop ? 14 : 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Accepts a Firestore `Timestamp`, an ISO-8601 string, or null, and never
  /// throws - a malformed value simply reads as "no date".
  static DateTime? _asDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Widget _buildHistories() {
    final displayName = userData?['username'] ?? 'Guest User';
    // Nothing in the app writes `joinedAt`, so this has always rendered "-".
    // It also ran an unguarded `DateTime.parse` inside `build()`: a legacy or
    // admin-written document holding a Timestamp (or any unparseable string)
    // threw straight out of build and red-screened the History tab. Read the
    // account creation time instead, and accept either shape.
    final joinedTime = _asDateTime(userData?['joinedAt'] ?? userData?['createdAt']);
    final joinedAgo = joinedTime != null
        ? '${DateTime.now().difference(joinedTime).inDays} days ago'
        : '—';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Joined: $joinedAgo',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: user != null
                  ? StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _gameHistoryStream(user!.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child:
                                CircularProgressIndicator(color: _accentColor),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _card(
                            child: const Center(
                              child: Text(
                                "No history yet. Play some games!",
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        final docs = snapshot.data!.docs;
                        final topLogs = _topScoreLogs(docs);
                        final groupedGames = _groupLogsByGame(docs);
                        return Column(
                          children: [
                            Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                title: const Text(
                                  'Top Highscores',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900),
                                ),
                                children: [
                                  _buildTopScoresCard(topLogs),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Scrollbar(
                                thumbVisibility: isDesktopLayout(MediaQuery.sizeOf(context).width),
                                child: ListView(
                                children: groupedGames.map((entry) {
                                  final gameLogs = entry.value;
                                  final topGameLogs = _topScoreLogs(gameLogs);
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: _card(
                                      padding: const EdgeInsets.all(14),
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          dividerColor: Colors.transparent,
                                        ),
                                        child: ExpansionTile(
                                          onExpansionChanged: (_) {
                                            SoundService().playButtonSoundNow();
                                          },
                                          collapsedShape:
                                              const RoundedRectangleBorder(
                                            side: BorderSide.none,
                                          ),
                                          shape: const RoundedRectangleBorder(
                                            side: BorderSide.none,
                                          ),
                                          title: Text(
                                            entry.key,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 17,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${gameLogs.length} attempt(s)',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _accentColor.withValues(
                                                  alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _accentColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Text(
                                              '${gameLogs.length}x',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: _accentColor,
                                              ),
                                            ),
                                          ),
                                          children: [
                                            if (topGameLogs.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 8),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Top ${topGameLogs.length} score${topGameLogs.length == 1 ? '' : 's'} for this game:',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 15),
                                                    ),
                                                    ...topGameLogs
                                                        .asMap()
                                                        .entries
                                                        .map((entry) {
                                                      final rank = entry.key;
                                                      final data =
                                                          entry.value.data();
                                                      final scoreValue =
                                                          data['score'];
                                                      final scoreText =
                                                          scoreValue == null
                                                              ? '-'
                                                              : '$scoreValue';
                                                      final timestamp =
                                                          data['timestamp']
                                                              as Timestamp?;
                                                      final difficulty =
                                                          data['difficulty']
                                                              as String?;
                                                      final when = difficulty ==
                                                              null
                                                          ? _formatTimestamp(
                                                              timestamp)
                                                          : '$difficulty • ${_formatTimestamp(timestamp)}';
                                                      return Container(
                                                        margin: const EdgeInsets
                                                            .only(top: 4),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[200],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                              'Top ${rank + 1}',
                                                              style:
                                                                  const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                when,
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ),
                                                            Text(
                                                              scoreText,
                                                              style:
                                                                  const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }),
                                                  ],
                                                ),
                                              ),
                                            ...gameLogs.map((logDoc) {
                                              final data = logDoc.data();
                                              final scoreValue = data['score'];
                                              final scoreText =
                                                  scoreValue == null
                                                      ? '-'
                                                      : '$scoreValue';
                                              final timestamp =
                                                  data['timestamp']
                                                      as Timestamp?;
                                              final difficulty =
                                                  data['difficulty']
                                                      as String?;
                                              final subtitleText = difficulty ==
                                                      null
                                                  ? _formatTimestamp(timestamp)
                                                  : '$difficulty • ${_formatTimestamp(timestamp)}';
                                              return ListTile(
                                                dense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 0),
                                                leading: const Icon(
                                                    Icons.history_rounded,
                                                    color: _accentColor),
                                                title: Text('Score: $scoreText',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                subtitle: Text(
                                                    subtitleText,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : _card(
                      child: const Center(
                        child: Text("Please login to view history."),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Either a "Connect Google account" button or, once connected, a quiet
  /// status line naming the linked address.
  Widget _buildGoogleLinkButton() {
    final service = GoogleLinkService();

    if (service.isCurrentUserLinked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F7EA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4CAF50), width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded,
                color: Color(0xFF2E7D32), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Google connected\n${service.linkedEmail ?? ''}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLinkingGoogle
            ? null
            : () async {
                SoundService().playButtonSoundNow();
                setState(() => _isLinkingGoogle = true);

                final result = await service.linkGoogleAccount();
                if (!mounted) return;
                setState(() => _isLinkingGoogle = false);

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: result.isSuccess
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF8A6100),
                    ),
                  );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2F5233),
        ),
        icon: _isLinkingGoogle
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : const Icon(Icons.account_circle_rounded, size: 20),
        label: Text(
          _isLinkingGoogle ? 'Opening Google...' : 'Connect Google account',
        ),
      ),
    );
  }

  /// The player's own half of the camera anti-cheat decision.
  ///
  /// The teacher's switch still gates it: when they have the camera off for
  /// both exams and lessons there is nothing here to choose, so this says so
  /// rather than offering a switch that would change nothing. Within what the
  /// teacher allows a player may say no - and the leaderboard shows which
  /// scores were set with the camera on, so saying no is visible rather than
  /// secret. That visibility is what makes the choice safe to offer at all.
  Widget _buildCameraPreferenceCard() {
    return ValueListenableBuilder<ProctoringConfig>(
      valueListenable: ProctoringSettings.instance.config,
      builder: (context, config, _) {
        final teacherAllows =
            config.faceProctorExams || config.faceProctorLessons;

        return ValueListenableBuilder<bool>(
          valueListenable: PlayerProctoringPreference.instance.optedIn,
          builder: (context, optedIn, _) {
            final on = teacherAllows && optedIn;

            final String caption;
            if (!teacherAllows) {
              caption = 'Your teacher has the camera turned off for everyone '
                  'right now, so your scores will show "Camera off".';
            } else if (on) {
              caption = 'The front camera checks you are there while you play. '
                  'Scores you set this way show a "Camera on" badge on the '
                  'leaderboard.';
            } else {
              caption = 'The camera stays off. Scores you set will show '
                  '"Camera off" on the leaderboard.';
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentColor, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        on
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        size: 22,
                        color: const Color(0xFF2F5233),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Camera anti-cheat',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Switch(
                        value: on,
                        // Nothing to choose when the teacher has it off
                        // everywhere, so the switch is shown in its real
                        // position and disabled rather than hidden.
                        onChanged: teacherAllows ? _setCameraOptIn : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    caption,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Confirms only when the camera is being turned *off*. Turning it back on
  /// is always the safe direction, and asking twice for that just trains a
  /// child to tap straight through the dialog.
  Future<void> _setCameraOptIn(bool value) async {
    SoundService().playButtonSoundNow();

    if (!value) {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => const _CameraOptOutDialog(),
          ) ??
          false;
      if (!confirmed || !mounted) return;
    }

    await PlayerProctoringPreference.instance.setOptedIn(value);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Camera on. Scores you set from now on show a "Camera on" '
                    'badge.'
                : 'Camera off. Scores you set from now on show "Camera off".',
          ),
          backgroundColor:
              value ? const Color(0xFF2E7D32) : const Color(0xFF8A6100),
        ),
      );
  }

  Widget _buildSettings() {
    final displayName = userData?['username'] ?? 'Guest User';
    final email = user?.email ?? 'Not logged in';

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _card(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Your Profile',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentColor, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (user != null)
                    Column(
                      children: [
                        _buildCameraPreferenceCard(),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              SoundService().playButtonSoundNow();

                              final shouldSignOut = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (dialogContext) {
                                  return const _SignOutConfirmationDialog();
                                },
                              );

                              if (!context.mounted) return;

                              if (shouldSignOut == true) {
                                resetPlayerNameCache();
                                await CustomQuestionSync.instance.stop();
                                await ProctoringSettings.instance.stop();
                                PlayerProctoringPreference.instance.reset();
                                await _auth.signOut();
                                if (!mounted) return;
                                // Back to the start screen, which asks again
                                // whether they have an account.
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (_) => const AppGate()),
                                  (route) => false,
                                );
                              }
                            },
                            child: const Text('Sign Out'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              SoundService().playButtonSoundNow();
                              _clearUserData();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD84315),
                            ),
                            child: const Text('Clear Data'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              SoundService().playButtonSoundNow();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LeaderboardScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                            ),
                            child: const Text('Leaderboard'),
                          ),
                        ),
                        // The "later" half of the sign-up offer: a player who
                        // skipped connecting Google can do it from here. Once
                        // connected the button turns into a status line.
                        if (GoogleLinkService.isSupportedPlatform) ...[
                          const SizedBox(height: 12),
                          _buildGoogleLinkButton(),
                        ],
                        // Only accounts flagged as admins in Firestore get a
                        // way into the admin panel from inside the app.
                        if (userData?['role'] == kAdminRoleValue) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                SoundService().playButtonSoundNow();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AdminDashboardPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A3FC4),
                              ),
                              icon: const Icon(
                                  Icons.admin_panel_settings_rounded, size: 20),
                              label: const Text('Admin Panel'),
                            ),
                          ),
                        ],
                      ],
                    )
                  else
                    Column(
                      children: [
                        const Text(
                          'You are a Guest User.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              SoundService().playButtonSoundNow();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text('Create Account'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              SoundService().playButtonSoundNow();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                              );
                            },
                            child: const Text('Login'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Sign‑Out Confirmation Dialog – exact replica of LeaveWarningOverlay
// ---------------------------------------------------------------------
/// Asks once before a player turns the camera off, so the leaderboard
/// consequence is stated before it happens rather than discovered afterwards.
class _CameraOptOutDialog extends StatelessWidget {
  const _CameraOptOutDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF8A6100), width: 2.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_rounded,
              color: Color(0xFF8A6100),
              size: 52,
            ),
            const SizedBox(height: 12),
            const Text(
              'Turn the camera off?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3E2723),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You can still play everything. Scores you set will show '
              '"Camera off" on the leaderboard, so everyone can see they were '
              'not checked.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4E342E),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      SoundService().playButtonSoundNow();
                      Navigator.of(context).pop(false);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(
                        color: Color(0xFF6D4C41),
                        width: 2,
                      ),
                      foregroundColor: const Color(0xFF4E342E),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Keep it on'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      SoundService().playButtonSoundNow();
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: const Color(0xFF8A6100),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Turn it off'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SignOutConfirmationDialog extends StatefulWidget {
  const _SignOutConfirmationDialog();

  @override
  State<_SignOutConfirmationDialog> createState() =>
      _SignOutConfirmationDialogState();
}

class _SignOutConfirmationDialogState
    extends State<_SignOutConfirmationDialog> {
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    SoundService().playLeaveWarningSoundNow();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD84315),
            width: 2.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_rounded,
              color: Color(0xFFD84315),
              size: 52,
            ),
            const SizedBox(height: 12),
            const Text(
              'Sign Out?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3E2723),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Are you sure you want to sign out?\nYour progress is saved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4E342E),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 18),
            if (_isSigningOut) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Color(0xFFD84315),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Signing out...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSigningOut
                        ? null
                        : () {
                            SoundService().playButtonSoundNow();
                            Navigator.of(context).pop(false);
                          },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(
                        color: Color(0xFF6D4C41),
                        width: 2,
                      ),
                      foregroundColor: const Color(0xFF4E342E),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSigningOut
                        ? null
                        : () async {
                            setState(() => _isSigningOut = true);
                            SoundService().playButtonSoundNow();
                            Navigator.of(context).pop(true);
                          },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: const Color(0xFFD84315),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows which voice the spelling game reads with, and - when the device has
/// only a basic one - how to get a better one.
///
/// The app cannot install voice data itself; that lives behind the system
/// text-to-speech settings. What it can do is notice that the installed voice
/// is a poor one, or that a better one is listed but not yet downloaded, and
/// say so instead of just sounding robotic for no visible reason.
class _ReadingVoiceSection extends StatefulWidget {
  const _ReadingVoiceSection();

  @override
  State<_ReadingVoiceSection> createState() => _ReadingVoiceSectionState();
}

class _ReadingVoiceSectionState extends State<_ReadingVoiceSection> {
  VoiceReport? _report;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool recheck = false}) async {
    setState(() => _busy = true);
    final report = recheck
        ? await TextToSpeechService().refreshVoice()
        : await TextToSpeechService().ensureReady();
    if (!mounted) return;
    setState(() {
      _report = report;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final advice = report?.advice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reading voice',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          _busy ? 'Checking...' : (report?.summary ?? 'Not available'),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        if (advice != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4DC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0A800), width: 1.4),
            ),
            child: Text(
              advice,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: Color(0xFF7A5600),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: _busy
                  ? null
                  : () => TextToSpeechService().speakSpellingWord(
                        'spelling',
                        sentence: 'This is how the reading voice sounds.',
                      ),
              icon: const Icon(Icons.volume_up_rounded, size: 18),
              label: const Text('Hear it'),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: _busy ? null : () => _load(recheck: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Check again'),
            ),
          ],
        ),
      ],
    );
  }
}
