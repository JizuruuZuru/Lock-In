import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/animated_shape_background.dart';
import '../services/sound_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const Color _inkColor = Color(0xFF2F5233);
  static const Color _bgTopColor = Color(0xFFE6F7E6);
  static const Color _bgBottomColor = Color(0xFFD4EDD1);
  static const Color _panelColor = Color(0xFFFAFFF9);

  String? _selectedGame; // null = all games

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _buildTheme(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leaderboard'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              SoundService().playButtonSoundNow();
              Navigator.pop(context);
            },
          ),
        ),
        body: _buildBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('leaderboard_entries')
                    .orderBy('score', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _card(
                      child: const Center(
                        child: Text(
                          'No scores yet. Play some games!',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }

                  final allDocs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final game = (data['game'] ?? '').toString();

                    return game.startsWith('Math Game') ||
                        game == 'Number Memory' ||
                        game == 'Roman Numerals' ||
                        game == 'Analog Clock' ||
                        game == 'Place Value' ||
                        game == 'Rounding Numbers' ||
                        game == 'Order of Operations' ||
                        game == 'Fractions' ||
                        game == 'Measurements' ||
                        game.startsWith('Measurements -') ||
                        game == 'Easy Exam' ||
                        game == 'Medium Exam' ||
                        game == 'Hard Exam';
                  }).toList();

                  if (allDocs.isEmpty) {
                    return _card(
                      child: const Center(
                        child: Text(
                          'No scores yet. Play some games!',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }

                  // Extract unique game names for dropdown
                  final gameSet = <String>{};
                  for (final doc in allDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final game = data['game'] as String?;
                    if (game != null) gameSet.add(game);
                  }
                  final gameList = gameSet.toList()..sort();

                  // Filter docs by selected game
                  final docs = _selectedGame == null
                      ? allDocs
                      : allDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['game'] == _selectedGame;
                        }).toList();

                  return Column(
                    children: [
                      // Dropdown filter – styled to match system design
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _panelColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _inkColor, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x332C3550),
                              offset: Offset(3, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedGame,
                            hint: const Text(
                              'All Games',
                              style: TextStyle(
                                color: _inkColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'All Games',
                                  style: TextStyle(
                                    color: _inkColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              ...gameList.map((game) {
                                return DropdownMenuItem<String>(
                                  value: game,
                                  child: Text(
                                    game,
                                    style: const TextStyle(
                                      color: _inkColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedGame = value;
                              });
                            },
                            style: const TextStyle(
                              color: _inkColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            dropdownColor: _panelColor,
                            icon: Icon(Icons.arrow_drop_down, color: _inkColor, size: 28),
                            iconSize: 28,
                          ),
                        ),
                      ),
                      // Leaderboard list
                      Expanded(
                        child: ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final rank = index + 1;
                            final username = data['username'] ?? 'Anonymous';
                            final game = data['game'] ?? 'Unknown';
                            final score = data['score'] ?? 0;
                            final timestamp = data['timestamp'] as Timestamp?;
                            final timeStr = timestamp != null
                                ? _formatTimestamp(timestamp.toDate())
                                : '';

                            // Highlight top 3 with special styling
                            Color? bgColor;
                            Color borderColor = _inkColor;
                            if (rank == 1) {
                              bgColor = const Color(0xFFFFD700).withValues(alpha: 0.25); // gold
                              borderColor = const Color(0xFFB8860B);
                            } else if (rank == 2) {
                              bgColor = const Color(0xFFC0C0C0).withValues(alpha: 0.25); // silver
                              borderColor = const Color(0xFF808080);
                            } else if (rank == 3) {
                              bgColor = const Color(0xFFCD7F32).withValues(alpha: 0.25); // bronze
                              borderColor = const Color(0xFF8B4513);
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: bgColor ?? _panelColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x332C3550),
                                      offset: Offset(3, 4),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: borderColor,
                                    child: Text(
                                      '$rank',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    username,
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  subtitle: Text(
                                    '$game • $timeStr',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Text(
                                    '$score',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: borderColor,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'just now';
    }
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
      ],
      child: child,
    );
  }

  Widget _card({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(18)}) {
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
}