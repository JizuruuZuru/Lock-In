import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/app_user_record.dart';
import '../../services/sound_service.dart';
import '../../services/user_admin_repository.dart';
import '../../utils/admin_theme.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/offline_banner.dart';
import 'account_editor_page.dart';

/// Which slice of the account list is on screen.
enum _AccountFilter { all, students, admins, disabled }

/// The **Read** and **Delete** half of account CRUD.
///
/// Deleting is a soft delete — the account is deactivated so it can no longer
/// sign in, while its scores and leaderboard history survive. A client SDK
/// cannot remove someone else's Firebase Auth credential, so deactivation is
/// the honest and reversible equivalent.
class AccountListPage extends StatefulWidget {
  const AccountListPage({super.key});

  @override
  State<AccountListPage> createState() => _AccountListPageState();
}

class _AccountListPageState extends State<AccountListPage> {
  final UserAdminRepository _repository = UserAdminRepository();
  final TextEditingController _searchController = TextEditingController();

  /// Mirrors the debounce the question list already uses. Without it every
  /// keystroke rebuilt and re-filtered the whole (unpaginated) account list.
  Timer? _searchDebounce;
  static const Duration _searchDelay = Duration(milliseconds: 220);

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.isEmpty) {
      // Clearing should feel immediate - there is nothing to wait for.
      setState(() => _search = '');
      return;
    }
    _searchDebounce = Timer(_searchDelay, () {
      if (!mounted) return;
      setState(() => _search = value);
    });
  }

  /// Held in state so a rebuild does not open a second Firestore listener.
  /// See the matching note in QuestionListPage: the search field setStates on
  /// every keystroke, and an inline stream would flash the list back to its
  /// loading state between characters.
  late Stream<List<AppUserRecord>> _accountStream = _repository.watchAccounts();

  _AccountFilter _filter = _AccountFilter.all;
  String _search = '';

  /// Reattaches the listener after an error.
  void _reloadAccounts() {
    setState(() {
      _accountStream = _repository.watchAccounts();
    });
  }

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- actions

  Future<void> _createAccount() async {
    SoundService().playButtonSoundNow();
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AccountEditorPage()),
    );
  }

  Future<void> _editAccount(AppUserRecord record) async {
    SoundService().playButtonSoundNow();
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AccountEditorPage(existing: record)),
    );
  }

  Future<void> _toggleDisabled(AppUserRecord record) async {
    if (record.uid == _currentUid) {
      showAdminSnack(
        context,
        'You cannot deactivate the account you are signed in with.',
        isError: true,
      );
      return;
    }

    // Losing the last admin would lock everyone out of this panel.
    if (!record.disabled && record.isAdmin) {
      final remaining = await _repository.countActiveAdmins();
      if (remaining <= 1) {
        if (!mounted) return;
        showAdminSnack(
          context,
          'This is the only active admin. Promote another admin before deactivating this one.',
          isError: true,
        );
        return;
      }
    }

    if (!mounted) return;
    final confirmed = record.disabled
        ? true
        : await confirmAdminAction(
            context,
            title: 'Deactivate ${record.displayName}?',
            message:
                'They will be signed out and blocked from logging in. Their scores and leaderboard history are kept, and you can restore the account at any time.',
            confirmLabel: 'Deactivate',
          );
    if (!confirmed) return;

    try {
      await _repository.setDisabled(record.uid, !record.disabled);
      if (!mounted) return;
      showAdminSnack(
        context,
        record.disabled
            ? '${record.displayName} restored.'
            : '${record.displayName} deactivated.',
      );
    } on AccountGuardException catch (error) {
      if (!mounted) return;
      showAdminSnack(context, error.message, isError: true);
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(context, 'Could not update: $error', isError: true);
    }
  }

  Future<void> _toggleRole(AppUserRecord record) async {
    if (record.uid == _currentUid) {
      showAdminSnack(
        context,
        'You cannot change your own role while signed in.',
        isError: true,
      );
      return;
    }

    if (record.isAdmin) {
      final remaining = await _repository.countActiveAdmins();
      if (remaining <= 1) {
        if (!mounted) return;
        showAdminSnack(
          context,
          'At least one admin must remain. Promote someone else first.',
          isError: true,
        );
        return;
      }
    }

    if (!mounted) return;
    final confirmed = await confirmAdminAction(
      context,
      title: record.isAdmin
          ? 'Remove admin access?'
          : 'Make ${record.displayName} an admin?',
      message: record.isAdmin
          ? '${record.displayName} will go back to being a student and lose access to this panel.'
          : 'They will be able to create, edit, and delete questions and manage every account.',
      confirmLabel: record.isAdmin ? 'Remove access' : 'Make admin',
      confirmColor: record.isAdmin ? AdminPalette.danger : AdminPalette.accent,
    );
    if (!confirmed) return;

    try {
      await _repository.setRole(
        record.uid,
        record.isAdmin ? UserRole.student : UserRole.admin,
      );
      if (!mounted) return;
      showAdminSnack(context, 'Role updated for ${record.displayName}.');
    } on AccountGuardException catch (error) {
      if (!mounted) return;
      showAdminSnack(context, error.message, isError: true);
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(context, 'Could not update role: $error', isError: true);
    }
  }

  // ------------------------------------------------------------------- view

  List<AppUserRecord> _applyFilters(List<AppUserRecord> records) {
    final needle = _search.trim().toLowerCase();
    return records.where((record) {
      final matchesFilter = switch (_filter) {
        _AccountFilter.all => true,
        _AccountFilter.students => !record.isAdmin && !record.disabled,
        _AccountFilter.admins => record.isAdmin,
        _AccountFilter.disabled => record.disabled,
      };
      if (!matchesFilter) return false;
      if (needle.isEmpty) return true;
      return record.displayName.toLowerCase().contains(needle) ||
          record.loginId.toLowerCase().contains(needle) ||
          record.email.toLowerCase().contains(needle);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return AdminScaffold(
      title: 'Accounts',
      subtitle: 'Add, edit, and deactivate players',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAccount,
        backgroundColor: AdminPalette.success,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AdminPalette.ink, width: 2),
        ),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'New account',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              responsiveCardPadding(width),
              responsiveCardPadding(width),
              responsiveCardPadding(width),
              8,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: responsivePanelMaxWidth(width)),
                child: Column(
                  children: [
                    const OfflineBanner(),
                    _filterBar(),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AppUserRecord>>(
              stream: _accountStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AdminStateView.error(
                    'Could not load accounts.\n\n${snapshot.error}',
                    onRetry: _reloadAccounts,
                  );
                }
                if (!snapshot.hasData) {
                  return AdminStateView.loading('Loading accounts...');
                }

                final all = snapshot.data!;
                final visible = _applyFilters(all);

                if (visible.isEmpty) {
                  return AdminStateView(
                    icon: Icons.person_search_rounded,
                    title: all.isEmpty ? 'No accounts yet' : 'No matches',
                    message: all.isEmpty
                        ? 'Create the first student account with the button below.'
                        : 'No account matches your filters. Clear them to see all ${all.length}.',
                    actionLabel: all.isEmpty ? 'Create an account' : 'Clear filters',
                    onAction: all.isEmpty
                        ? _createAccount
                        : () {
                            // Cancel first, or a debounce still in flight
                            // would put the cleared text straight back.
                            _searchDebounce?.cancel();
                            _searchController.clear();
                            setState(() {
                              _search = '';
                              _filter = _AccountFilter.all;
                            });
                          },
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    responsiveCardPadding(width),
                    4,
                    responsiveCardPadding(width),
                    100,
                  ),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final record = visible[index];
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: responsivePanelMaxWidth(width),
                        ),
                        child: _AccountCard(
                          record: record,
                          isSelf: record.uid == _currentUid,
                          onEdit: () => _editAccount(record),
                          onToggleDisabled: () => _toggleDisabled(record),
                          onToggleRole: () => _toggleRole(record),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return AdminPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Search accounts',
              hintText: 'Search by name or login id',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(_AccountFilter.all, 'All'),
                _filterChip(_AccountFilter.students, 'Students'),
                _filterChip(_AccountFilter.admins, 'Admins'),
                _filterChip(_AccountFilter.disabled, 'Deactivated'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(_AccountFilter filter, String label) {
    final selected = _filter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = filter),
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : AdminPalette.ink,
        ),
        backgroundColor: AdminPalette.panel,
        selectedColor: AdminPalette.accent,
        side: const BorderSide(color: AdminPalette.ink, width: 1.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AppUserRecord record;
  final bool isSelf;
  final VoidCallback onEdit;
  final VoidCallback onToggleDisabled;
  final VoidCallback onToggleRole;

  const _AccountCard({
    required this.record,
    required this.isSelf,
    required this.onEdit,
    required this.onToggleDisabled,
    required this.onToggleRole,
  });

  @override
  Widget build(BuildContext context) {
    final accent = record.disabled
        ? AdminPalette.muted
        : (record.isAdmin ? AdminPalette.accent : AdminPalette.success);

    return AdminPanel(
      padding: const EdgeInsets.all(16),
      borderColor: record.disabled ? AdminPalette.muted : AdminPalette.ink,
      color: record.disabled ? AdminPalette.surfaceMuted : AdminPalette.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent, width: 2),
                ),
                child: Text(
                  _initials(record.displayName),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      record.displayName,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        decoration: record.disabled
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.loginId.isEmpty
                          ? (record.isAnonymous ? 'Guest session' : record.uid)
                          : record.loginId,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AdminPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AdminChip(
                label: userRoleLabel(record.role),
                color: record.isAdmin ? AdminPalette.accent : AdminPalette.success,
                icon: record.isAdmin
                    ? Icons.admin_panel_settings_rounded
                    : Icons.person_rounded,
              ),
              if (record.age != null)
                AdminChip(
                  label: 'Age ${record.age}',
                  color: AdminPalette.teal,
                  icon: Icons.cake_rounded,
                ),
              AdminChip(
                label: 'Best ${record.highscore}',
                color: AdminPalette.warning,
                icon: Icons.emoji_events_rounded,
              ),
              if (record.cheatAttempts > 0)
                AdminChip(
                  label: '${record.cheatAttempts} cheat flags',
                  color: AdminPalette.danger,
                  icon: Icons.gpp_maybe_rounded,
                ),
              if (record.isAnonymous)
                const AdminChip(
                  label: 'Guest (no password)',
                  color: AdminPalette.muted,
                  icon: Icons.help_outline_rounded,
                ),
              if (record.disabled)
                const AdminChip(
                  label: 'Deactivated',
                  color: AdminPalette.danger,
                  icon: Icons.block_rounded,
                ),
              if (isSelf)
                const AdminChip(
                  label: 'You',
                  color: AdminPalette.secondary,
                  icon: Icons.star_rounded,
                ),
            ],
          ),
          if (record.lastGame != null && record.lastGame!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Last played: ${record.lastGame}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AdminPalette.muted,
              ),
            ),
          ],
          const Divider(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: record.isAdmin ? 'Remove admin access' : 'Make admin',
                onPressed: isSelf ? null : onToggleRole,
                icon: Icon(
                  record.isAdmin
                      ? Icons.person_remove_rounded
                      : Icons.admin_panel_settings_rounded,
                  color: isSelf ? AdminPalette.muted : AdminPalette.accent,
                ),
              ),
              IconButton(
                tooltip: 'Edit details',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, color: AdminPalette.accent),
              ),
              IconButton(
                tooltip: record.disabled ? 'Restore account' : 'Deactivate account',
                onPressed: isSelf ? null : onToggleDisabled,
                icon: Icon(
                  record.disabled
                      ? Icons.restore_from_trash_rounded
                      : Icons.person_off_rounded,
                  color: isSelf
                      ? AdminPalette.muted
                      : (record.disabled ? AdminPalette.success : AdminPalette.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return '${parts.first.characters.first}${parts[1].characters.first}'.toUpperCase();
  }
}
