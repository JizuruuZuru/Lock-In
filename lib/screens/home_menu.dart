import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'math_game.dart';
import 'number_memory_game.dart';
import 'register_page.dart';
import 'login_page.dart';
import 'leaderboard_screen.dart';
import '../services/app_settings_service.dart';
import '../services/sound_service.dart';
import '../widgets/app_brightness_overlay.dart';
import '../widgets/animated_shape_background.dart';
import '../onboarding_gate.dart';

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

  @override
  void initState() {
    super.initState();
    SoundService().playPageBgm(BgmPage.home);
    SoundService().registerUserInteraction();
    _auth.authStateChanges().listen((u) {
      setState(() {
        user = u;
      });
      fetchUserData();
    });
  }

  Future<void> fetchUserData() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists) {
        setState(() => userData = doc.data());
      }
    } else {
      setState(() => userData = null);
    }
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
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900),
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
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(true),
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

    if (!mounted) return;

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


  String _playerDisplayName() {
    final fullName = (userData?['fullName'] ?? '').toString().trim();
    if (fullName.isNotEmpty) return fullName;

    final firstName = (userData?['firstName'] ?? '').toString().trim();
    final lastName = (userData?['lastName'] ?? '').toString().trim();
    final combinedName = '$firstName $lastName'.trim();
    if (combinedName.isNotEmpty) return combinedName;

    final username = (userData?['username'] ?? '').toString().trim();
    if (username.isNotEmpty) return username;

    final authName = user?.displayName?.trim();
    if (authName != null && authName.isNotEmpty) return authName;

    return 'Player';
  }

  String _playerSubtitle() {
    final age = userData?['age'];
    final loginId = (userData?['loginId'] ?? '').toString().trim();
    if (user?.isAnonymous == true) {
      if (age != null) return 'Age: $age • temporary player profile';
      return 'Temporary player profile saved in Firebase';
    }
    if (loginId.isNotEmpty) return 'Login: $loginId';
    final email = user?.email;
    if (email != null && email.trim().isNotEmpty) return email;
    if (age != null) return 'Age: $age';
    return 'Profile ready';
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
    final grouped = <String,
        List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
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
    final pages = [
      _buildHome(),
      _buildHistories(),
      _buildSettings(),
    ];

    return Theme(
      data: _buildTheme(context),
      child: AppBrightnessOverlay(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Lock In'),
            actions: [
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
                    position: animation.drive(
                      CurveTween(curve: Curves.easeOutCubic),
                    ).drive(slideTween),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: pages[_currentIndex],
              ),
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: _panelColor,
              border: Border(
                top: BorderSide(color: _inkColor, width: 2.2),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x332C3550),
                  offset: Offset(0, -3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _buildHome() {
    final games = [
      {
        'name': 'Math Game',
        'icon': Icons.calculate,
        'widget': const MathGame()
      },
      {
        'name': 'Number Memory',
        'icon': Icons.memory,
        'widget': const NumberMemoryGame()
      },
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'Pick a game and start improving your mind.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...games.asMap().entries.map((entry) {
            final index = entry.key;
            final game = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Transform.rotate(
                angle: index.isEven ? -0.01 : 0.01,
                child: _card(
                  padding: const EdgeInsets.all(14),
                  child: ListTile(
                    leading: Icon(
                      game['icon'] as IconData,
                      size: 32,
                      color: _accentColor,
                    ),
                    title: Text(
                      game['name'] as String,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      SoundService().playButtonSoundNow();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => game['widget'] as Widget,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistories() {
    final displayName = _playerDisplayName();
    final joinedTime = userData?['joinedAt'] != null
        ? DateTime.parse(userData!['joinedAt'])
        : null;
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
                      stream: () {
                        Query<Map<String, dynamic>> query = FirebaseFirestore
                            .instance
                            .collection('users')
                            .doc(user!.uid)
                            .collection('game_logs');
                        final clearedAt = userData?['history_cleared_at'];
                        if (clearedAt is Timestamp) {
                          query = query.where(
                            'timestamp',
                            isGreaterThan: clearedAt,
                          );
                        }
                        return query
                            .orderBy('timestamp', descending: true)
                            .snapshots();
                      }(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: _accentColor),
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
                              child: ListView(
                                children: groupedGames.map((entry) {
                                  final gameLogs = entry.value;
                                  final topGameLogs = _topScoreLogs(gameLogs);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
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
                                              color: _accentColor
                                                  .withValues(alpha: 0.15),
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
                                                padding:
                                                    const EdgeInsets.only(
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
                                                    ...topGameLogs.asMap().entries
                                                        .map((entry) {
                                                      final rank = entry.key;
                                                      final data = entry.value
                                                          .data();
                                                      final scoreValue =
                                                          data['score'];
                                                      final scoreText =
                                                          scoreValue == null
                                                              ? '-'
                                                              : '$scoreValue';
                                                      final timestamp =
                                                          data['timestamp']
                                                              as Timestamp?;
                                                      final when =
                                                          _formatTimestamp(
                                                              timestamp);
                                                      return Container(
                                                        margin: const EdgeInsets
                                                            .only(top: 4),
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 8,
                                                            vertical: 6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .grey[200],
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
                                              return ListTile(
                                                dense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 0),
                                                leading: const Icon(
                                                    Icons.history_rounded,
                                                    color: _accentColor),
                                                title: Text(
                                                    'Score: $scoreText',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                subtitle: Text(
                                                    _formatTimestamp(timestamp),
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

  Widget _buildSettings() {
    final displayName = _playerDisplayName();
    final email = _playerSubtitle();

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
                        if (user!.isAnonymous) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEE),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _accentColor, width: 2),
                            ),
                            child: const Text(
                              'Secure your player profile: use your first name + last name as your login credential and set a password.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                SoundService().playButtonSoundNow();
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                                if (result == true && mounted) {
                                  await fetchUserData();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                              ),
                              child: const Text('Create Account'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                SoundService().playButtonSoundNow();
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                );
                                if (result == true && mounted) {
                                  await fetchUserData();
                                }
                              },
                              child: const Text('Login Existing Account'),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
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

                              if (shouldSignOut == true) {
                                await _auth.signOut();
                                if (mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const OnboardingGate(),
                                    ),
                                    (route) => false,
                                  );
                                }
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
                      ],
                    )
                  else
                    Column(
                      children: [
                        const Text(
                          'Set up your player profile to save history.',
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