import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_gate.dart';
import '../../models/app_user_record.dart';
import '../../models/quiz_question_record.dart';
import '../../services/custom_question_sync.dart';
import '../../services/question_repository.dart';
import '../../services/sound_service.dart';
import '../../services/user_admin_repository.dart';
import '../../utils/admin_theme.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/offline_banner.dart';
import 'account_list_page.dart';
import 'question_list_page.dart';
import 'api_console_page.dart';
import 'trivia_import_page.dart';

/// Landing screen of the admin area.
///
/// Shows live counts straight from Firestore (the **Read** side of CRUD at a
/// glance) and routes to the three working screens: questions, accounts, and
/// the Open Trivia DB importer.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final QuestionRepository _questions = QuestionRepository();
  final UserAdminRepository _accounts = UserAdminRepository();

  @override
  void initState() {
    super.initState();
    SoundService().playPageBgm(BgmPage.home);
  }

  Future<void> _signOut() async {
    final confirmed = await confirmAdminAction(
      context,
      title: 'Sign out of admin?',
      message: 'You will be returned to the start screen.',
      confirmLabel: 'Sign out',
      confirmColor: AdminPalette.accent,
    );
    if (!confirmed || !mounted) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppGate()),
      (route) => false,
    );
  }

  void _open(Widget page) {
    SoundService().playButtonSoundNow();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = isDesktopLayout(width);

    return AdminScaffold(
      title: 'Admin Panel',
      subtitle: 'Questions, accounts, and API imports',
      showBackButton: false,
      actions: [
        IconButton(
          tooltip: 'Sign out',
          onPressed: _signOut,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsiveCardPadding(width) + 4),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsivePanelMaxWidth(width)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OfflineBanner(),
                _welcomeCard(),
                const SizedBox(height: 16),
                _statsRow(isWide),
                const SizedBox(height: 16),
                _offlineCopyCard(),
                const SizedBox(height: 16),
                _actionGrid(isWide),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcomeCard() {
    return FutureBuilder<AppUserRecord?>(
      future: _accounts.fetchCurrentAccount(),
      builder: (context, snapshot) {
        final name = snapshot.data?.displayName ?? 'Admin';
        return AdminPanel(
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AdminPalette.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminPalette.accent, width: 2),
                ),
                child: const Icon(Icons.school_rounded,
                    color: AdminPalette.accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Welcome, $name',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Everything you create here reaches students the moment you save it.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: AdminPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Shows what is stored on this device, so an admin can tell at a glance
  /// whether the question bank would survive losing the network.
  Widget _offlineCopyCard() {
    final sync = CustomQuestionSync.instance;

    return ValueListenableBuilder<QuestionSourceState>(
      valueListenable: sync.sourceState,
      builder: (context, state, _) {
        return ValueListenableBuilder<DateTime?>(
          valueListenable: sync.lastSyncedAt,
          builder: (context, syncedAt, __) {
            return ValueListenableBuilder<int>(
              valueListenable: sync.loadedCount,
              builder: (context, count, ___) {
                final isLive = state == QuestionSourceState.live;
                final color = isLive ? AdminPalette.success : const Color(0xFFEF6C00);

                return AdminPanel(
                  borderColor: color,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        isLive ? Icons.cloud_done_rounded : Icons.save_rounded,
                        color: color,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLive
                                  ? 'Question bank is live'
                                  : 'Playing from the copy on this device',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$count teacher question${count == 1 ? '' : 's'} '
                              'saved offline - ${_syncedLabel(syncedAt)}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                                color: AdminPalette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _syncedLabel(DateTime? syncedAt) {
    if (syncedAt == null) return 'not synced yet';

    final elapsed = DateTime.now().difference(syncedAt);
    if (elapsed.inMinutes < 1) return 'synced just now';
    if (elapsed.inHours < 1) return 'synced ${elapsed.inMinutes} min ago';
    if (elapsed.inDays < 1) return 'synced ${elapsed.inHours} h ago';
    return 'synced ${elapsed.inDays} day${elapsed.inDays == 1 ? '' : 's'} ago';
  }

  Widget _statsRow(bool isWide) {
    final cards = [
      StreamBuilder<List<QuizQuestionRecord>>(
        stream: _questions.watchQuestions(),
        builder: (context, snapshot) {
          final all = snapshot.data;
          return _StatCard(
            icon: Icons.quiz_rounded,
            label: 'Questions',
            value: all?.length.toString(),
            caption: all == null
                ? 'Loading...'
                : '${all.where((q) => q.published).length} live for students',
            color: AdminPalette.accent,
            hasError: snapshot.hasError,
          );
        },
      ),
      StreamBuilder<List<AppUserRecord>>(
        stream: _accounts.watchAccounts(),
        builder: (context, snapshot) {
          final all = snapshot.data;
          final active = all?.where((user) => !user.disabled).length;
          return _StatCard(
            icon: Icons.groups_rounded,
            label: 'Accounts',
            value: all?.length.toString(),
            caption: active == null ? 'Loading...' : '$active active',
            color: AdminPalette.success,
            hasError: snapshot.hasError,
          );
        },
      ),
      StreamBuilder<List<QuizQuestionRecord>>(
        stream: _questions.watchQuestions(),
        builder: (context, snapshot) {
          final imported = snapshot.data
              ?.where((q) => q.source == QuestionSource.openTrivia)
              .length;
          return _StatCard(
            icon: Icons.cloud_download_rounded,
            label: 'From API',
            value: imported?.toString(),
            caption: 'Open Trivia DB imports',
            color: const Color(0xFFEF6C00),
            hasError: snapshot.hasError,
          );
        },
      ),
    ];

    if (!isWide) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            cards[i],
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }

  Widget _actionGrid(bool isWide) {
    final tiles = <Widget>[
      _ActionTile(
        icon: Icons.edit_note_rounded,
        title: 'Manage Questions',
        description:
            'Create, edit, and delete quiz questions. Choose the subject, write the question, set the correct answer and the wrong choices.',
        color: AdminPalette.accent,
        onTap: () => _open(const QuestionListPage()),
      ),
      _ActionTile(
        icon: Icons.manage_accounts_rounded,
        title: 'Manage Accounts',
        description:
            'Add students, fix names and ages, promote another admin, or deactivate an account that should no longer sign in.',
        color: AdminPalette.success,
        onTap: () => _open(const AccountListPage()),
      ),
      _ActionTile(
        icon: Icons.travel_explore_rounded,
        title: 'Import from Open Trivia DB',
        description:
            'Pull ready-made multiple-choice questions over HTTP, preview them, and publish the ones you want into your question bank.',
        color: const Color(0xFFEF6C00),
        onTap: () => _open(const TriviaImportPage()),
      ),
      _ActionTile(
        icon: Icons.lan_rounded,
        title: 'API Console',
        description:
            'Run every endpoint the app uses - GET, POST, PATCH, and DELETE - and read the real request and response for each one.',
        color: const Color(0xFF1976D2),
        onTap: () => _open(const ApiConsolePage()),
      ),
    ];

    if (!isWide) {
      return Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            tiles[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String caption;
  final Color color;
  final bool hasError;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(hasError ? Icons.cloud_off_rounded : icon,
              color: hasError ? AdminPalette.danger : color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AdminPalette.muted,
                  ),
                ),
                const SizedBox(height: 2),
                if (hasError)
                  const Text(
                    'Unavailable',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AdminPalette.danger,
                    ),
                  )
                else if (value == null)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AdminPalette.accent,
                    ),
                  )
                else
                  Text(
                    value!,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                Text(
                  hasError ? 'Check your connection' : caption,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AdminPalette.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      onTap: onTap,
      borderColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: AdminPalette.muted,
            ),
          ),
        ],
      ),
    );
  }
}
