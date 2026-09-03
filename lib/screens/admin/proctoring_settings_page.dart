import 'package:flutter/material.dart';

import '../../services/proctoring_settings.dart';
import '../../services/sound_service.dart';
import '../../utils/admin_theme.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/offline_banner.dart';

/// Turns the front-camera proctor on and off for the whole class.
///
/// The setting lives in Firestore and reaches every device (see
/// [ProctoringSettings]). It is the outer gate: a student has their own camera
/// switch in their profile settings and can decline within what is allowed
/// here, but nothing they do can switch the camera back on where a teacher has
/// turned it off. A student who declines is not hidden - their scores carry a
/// "Camera off" badge on the leaderboard.
class ProctoringSettingsPage extends StatefulWidget {
  const ProctoringSettingsPage({super.key});

  @override
  State<ProctoringSettingsPage> createState() => _ProctoringSettingsPageState();
}

class _ProctoringSettingsPageState extends State<ProctoringSettingsPage> {
  final ProctoringSettings _settings = ProctoringSettings.instance;
  bool _saving = false;

  /// Applies one change, confirming first when it *weakens* proctoring.
  ///
  /// Turning it back on needs no confirmation - that direction is always safe.
  Future<void> _update({
    required ProctoringConfig next,
    required bool isTurningOff,
    required String what,
  }) async {
    SoundService().playButtonSoundNow();

    if (isTurningOff) {
      final confirmed = await confirmAdminAction(
        context,
        title: 'Turn off proctoring for $what?',
        message: 'The camera will stop watching, and scores from $what will no '
            'longer be marked as proctored. You can turn this back on at any '
            'time.',
        confirmLabel: 'Turn off',
        confirmColor: AdminPalette.danger,
      );
      if (!confirmed || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      await _settings.save(next);
      if (!mounted) return;
      showAdminSnack(
        context,
        isTurningOff
            ? 'Proctoring is off for $what.'
            : 'Proctoring is on for $what.',
      );
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(context, 'Could not save: $error', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return AdminScaffold(
      title: 'Exam Security',
      subtitle: 'Choose when the camera watches',
      body: Column(
        children: [
          const OfflineBanner(
            message: 'You are offline. Changes here need a connection to reach '
                'the other devices.',
          ),
          Expanded(
            child: ValueListenableBuilder<ProctoringConfig>(
              valueListenable: _settings.config,
              builder: (context, config, _) {
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    responsiveCardPadding(width),
                    16,
                    responsiveCardPadding(width),
                    32,
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: responsivePanelMaxWidth(width),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _explainer(),
                            const SizedBox(height: 14),
                            _switchPanel(
                              icon: Icons.assignment_rounded,
                              title: 'Watch during exams',
                              caption:
                                  'The front camera checks a face is present '
                                  'while an exam is being taken.',
                              value: config.faceProctorExams,
                              onChanged: (value) => _update(
                                next: config.copyWith(faceProctorExams: value),
                                isTurningOff: !value,
                                what: 'exams',
                              ),
                            ),
                            const SizedBox(height: 12),
                            _switchPanel(
                              icon: Icons.school_rounded,
                              title: 'Watch during lessons',
                              caption:
                                  'The same check during the practice games. '
                                  'Many schools leave this off, since practice '
                                  'is not graded.',
                              value: config.faceProctorLessons,
                              onChanged: (value) => _update(
                                next:
                                    config.copyWith(faceProctorLessons: value),
                                isTurningOff: !value,
                                what: 'lessons',
                              ),
                            ),
                            const SizedBox(height: 14),
                            _statusPanel(),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _explainer() {
    return const AdminPanel(
      color: AdminPalette.noticeBg,
      borderColor: AdminPalette.noticeBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 20, color: AdminPalette.noticeInk),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'These apply to every student on every device. Switching one off '
              'here stops the camera everywhere, and no student can switch it '
              'back on.\n\n'
              'Where you leave it on, a student may still turn the camera off '
              'for themselves in their profile settings — and so may a device '
              'with no front camera, or a child who declines the camera '
              'prompt. The game always runs either way. Every one of those '
              'attempts is recorded as not proctored and shows a "Camera off" '
              'badge on the leaderboard, so you can tell them apart at a '
              'glance.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AdminPalette.noticeInk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchPanel({
    required IconData icon,
    required String title,
    required String caption,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            icon: icon,
            title: title,
            caption: caption,
            trailing: Switch(
              value: value,
              // Disabled while a save is in flight so a fast double-tap cannot
              // queue two conflicting writes.
              onChanged: _saving ? null : onChanged,
            ),
          ),
          const SizedBox(height: 6),
          AdminChip(
            label: value ? 'Watching' : 'Not watching',
            color: value ? AdminPalette.success : AdminPalette.warning,
            icon: value ? Icons.videocam_rounded : Icons.videocam_off_rounded,
          ),
        ],
      ),
    );
  }

  /// Mirrors the offline-copy card the dashboard shows for the question bank,
  /// so an admin can tell whether what they are looking at reached the server.
  Widget _statusPanel() {
    return ValueListenableBuilder<ProctoringSource>(
      valueListenable: _settings.source,
      builder: (context, source, _) {
        return ValueListenableBuilder<DateTime?>(
          valueListenable: _settings.lastSyncedAt,
          builder: (context, syncedAt, _) {
            final isLive = source == ProctoringSource.live;
            return AdminPanel(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    isLive ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    size: 18,
                    color: isLive ? AdminPalette.success : AdminPalette.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isLive
                          ? 'These settings are live.'
                          : 'Showing the copy saved on this device'
                              '${syncedAt == null ? '' : ', last updated '
                                  '${_ago(syncedAt)}'}.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.muted,
                      ),
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

  String _ago(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} h ago';
    return '${diff.inDays} d ago';
  }
}
