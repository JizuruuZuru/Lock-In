import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_gate.dart';
import '../../models/app_user_record.dart';
import '../../models/quiz_question_record.dart';
import '../../services/custom_question_sync.dart';
import '../../services/proctoring_settings.dart';
import '../../services/question_repository.dart';
import '../../services/leaderboard_service.dart';
import '../../services/sound_service.dart';
import '../../services/user_admin_repository.dart';
import '../../utils/admin_theme.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/offline_banner.dart';
import 'account_list_page.dart';
import 'question_list_page.dart';
import 'api_console_page.dart';
import 'proctoring_settings_page.dart';
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

  /// Held in state so a rebuild does not open a fresh set of Firestore
  /// listeners. Two of the three stat cards read the same question
  /// collection, so they share one subscription rather than opening two.
  late final Stream<List<QuizQuestionRecord>> _questionStream =
      _questions.watchQuestions();
  late final Stream<List<AppUserRecord>> _accountStream =
      _accounts.watchAccounts();

  /// Held in state for the same reason as the streams above. Built inside
  /// `build()` this re-read `users/{uid}` on every rebuild - and the four
  /// `ValueListenableBuilder`s plus both stat streams rebuild this page often.
  late final Future<AppUserRecord?> _currentAccount =
      _accounts.fetchCurrentAccount();

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

    resetPlayerNameCache();
    await CustomQuestionSync.instance.stop();
    await ProctoringSettings.instance.stop();
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
      // An admin reaching this from the game has a route underneath, and
      // hardcoding this to false left them with no visible way back - only the
      // OS gesture, or Sign out, which tears the whole stack down.
      showBackButton: Navigator.of(context).canPop(),
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
      future: _currentAccount,
      builder: (context, snapshot) {
        // Falls back to "Admin" while loading and if the read fails - the
        // dashboard is still usable either way, so this never blocks the page.
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
                final color = isLive ? AdminPalette.success : AdminPalette.warning;

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
        stream: _questionStream,
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
        stream: _accountStream,
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
        stream: _questionStream,
        builder: (context, snapshot) {
          final imported = snapshot.data
              ?.where((q) => q.source == QuestionSource.openTrivia)
              .length;
          return _StatCard(
            icon: Icons.cloud_download_rounded,
            label: 'From API',
            value: imported?.toString(),
            caption: 'Open Trivia DB imports',
            color: AdminPalette.warning,
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
        color: AdminPalette.warning,
        onTap: () => _open(const TriviaImportPage()),
      ),
      _ActionTile(
        icon: Icons.lan_rounded,
        title: 'Connection Check',
        description:
            'Check the app can reach the internet services it needs, and that '
            'questions can be saved, edited, searched, and deleted. Safe to run '
            'any time - it cleans up after itself.',
        color: AdminPalette.info,
        onTap: () => _open(const ApiConsolePage()),
      ),
      _ActionTile(
        icon: Icons.videocam_rounded,
        title: 'Exam Security',
        description:
            'Choose whether the front camera watches during exams and during '
            'lessons. Applies to every student on every device.',
        color: AdminPalette.secondary,
        onTap: () => _open(const ProctoringSettingsPage()),
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

    // Two rows rather than one.
    //
    // A single Row was already tight with four tiles - about 215px each at the
    // 900px breakpoint, holding a 44px icon, a title, and a three-line
    // description. With a fifth it would be unreadable. Splitting keeps each
    // tile roughly the width it had before.
    final perRow = (tiles.length / 2).ceil();
    final rows = <List<Widget>>[
      tiles.sublist(0, perRow),
      tiles.sublist(perRow),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < rows[r].length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: rows[r][i]),
                ],
                // Keeps the last row's tiles the same width as the first
                // row's when the count is odd, instead of stretching them.
                for (var i = rows[r].length; i < perRow; i++) ...[
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ],
            ),
          ),
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
