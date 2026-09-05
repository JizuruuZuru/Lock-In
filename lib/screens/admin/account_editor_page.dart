import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_user_record.dart';
import '../../services/sound_service.dart';
import '../../services/user_admin_repository.dart';
import '../../utils/admin_theme.dart';
import '../../widgets/offline_banner.dart';
import '../../utils/name_credential.dart';
import '../../utils/responsive_layout.dart';

/// The **Create** and **Update** half of account CRUD.
///
/// Creating runs through [UserAdminRepository.createAccount], which spins up a
/// throwaway secondary Firebase app so making a student account does not sign
/// the admin out of their own session.
///
/// Editing changes profile fields only. Email and password belong to Firebase
/// Auth and cannot be rewritten for another user from a client, so those
/// fields are shown read-only rather than pretending to be editable.
class AccountEditorPage extends StatefulWidget {
  /// Null when creating a new account.
  final AppUserRecord? existing;

  const AccountEditorPage({super.key, this.existing});

  @override
  State<AccountEditorPage> createState() => _AccountEditorPageState();
}

class _AccountEditorPageState extends State<AccountEditorPage> {
  final UserAdminRepository _repository = UserAdminRepository();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _ageController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  late UserRole _role;
  late bool _disabled;

  Map<String, String> _errors = const {};

  /// Form contents as of first open.
  late List<Object?> _savedSignature;
  bool _saving = false;
  bool _obscurePassword = true;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _firstNameController = TextEditingController(text: existing?.firstName ?? '');
    _lastNameController = TextEditingController(text: existing?.lastName ?? '');
    _ageController = TextEditingController(text: existing?.age?.toString() ?? '');
    _role = existing?.role ?? UserRole.student;
    _disabled = existing?.disabled ?? false;

    SoundService().playPageBgm(BgmPage.home);
    _savedSignature = _signature();
  }

  /// Everything the form owns, flattened, so an edit can be detected without
  /// tracking each field. Compared against [_savedSignature] on the way out.
  List<Object?> _signature() => [
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _ageController.text.trim(),
        _role.name,
        _disabled,
        // Only meaningful when creating; harmless to include either way.
        _passwordController.text,
        _confirmController.text,
      ];

  bool get _hasUnsavedChanges => !listEquals(_signature(), _savedSignature);

  /// Asks before discarding an edit. The back arrow and the Android back
  /// gesture used to throw away a half-filled account with no prompt.
  Future<void> _handlePop() async {
    if (!_hasUnsavedChanges) {
      Navigator.pop(context);
      return;
    }

    final discard = await confirmAdminAction(
      context,
      title: 'Discard your changes?',
      message: _isEditing
          ? 'This account has edits that have not been saved yet.'
          : 'This account has not been created yet.',
      confirmLabel: 'Discard',
      confirmColor: AdminPalette.danger,
    );
    if (!discard || !mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ state

  AppUserRecord _buildRecord() {
    final base = widget.existing;
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());

    if (base != null) {
      return base.copyWith(
        firstName: first,
        lastName: last,
        age: age,
        role: _role,
        disabled: _disabled,
      );
    }

    return AppUserRecord(
      uid: '',
      firstName: first,
      lastName: last,
      fullName: '$first $last'.trim(),
      age: age,
      role: _role,
    );
  }

  void _revalidateIfNeeded() {
    if (_errors.isEmpty) return;
    setState(() => _errors = _validateAll());
  }

  /// Rebuilds on every keystroke so the derived login-id preview stays in step,
  /// and re-runs validation only once the admin has already tried to save.
  void _onNameChanged() {
    setState(() {
      if (_errors.isNotEmpty) _errors = _validateAll();
    });
  }

  Map<String, String> _validateAll() {
    final errors = _buildRecord().validate();

    if (!_isEditing) {
      final password = normalizePassword(_passwordController.text);
      if (password.length < 6) {
        errors['password'] = 'Password must be at least 6 characters.';
      } else if (password != normalizePassword(_confirmController.text)) {
        errors['confirm'] = 'The two passwords do not match.';
      }
    }
    return errors;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final errors = _validateAll();

    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      showAdminSnack(context, 'Please fix the highlighted fields.', isError: true);
      return;
    }

    setState(() {
      _errors = const {};
      _saving = true;
    });

    try {
      if (_isEditing) {
        await _repository.updateAccount(_buildRecord());
        if (!mounted) return;
        showAdminSnack(context, 'Account updated.');
      } else {
        await _repository.createAccount(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          age: int.tryParse(_ageController.text.trim()),
          password: normalizePassword(_passwordController.text),
          role: _role,
        );
        if (!mounted) return;
        showAdminSnack(context, 'Account created.');
      }
      if (mounted) Navigator.pop(context, true);
    } on AccountValidationException catch (error) {
      if (!mounted) return;
      setState(() => _errors = error.errors);
      showAdminSnack(context, error.summary, isError: true);
    } on AccountGuardException catch (error) {
      // Refused because the change would lock somebody out of the panel, not
      // because a field is wrong - so it is reported on its own rather than
      // painted under an unrelated input.
      if (!mounted) return;
      showAdminSnack(context, error.message, isError: true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'email-already-in-use' =>
          'An account already uses that first and last name. Try a different spelling or add a middle initial.',
        'invalid-email' =>
          'That name cannot be turned into a valid login id. Check the spelling.',
        'weak-password' => 'Password is too weak. Use at least 6 characters.',
        _ => error.message ?? 'Could not create the account.',
      };
      setState(() => _errors = {'password': message});
      showAdminSnack(context, message, isError: true);
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(context, 'Could not save: $error', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ------------------------------------------------------------------- view

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _handlePop();
      },
      child: _buildEditor(context, width),
    );
  }

  Widget _buildEditor(BuildContext context, double width) {
    return AdminScaffold(
      title: _isEditing ? 'Edit Account' : 'New Account',
      subtitle: _isEditing ? widget.existing!.displayName : 'Create a student or admin',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsiveCardPadding(width) + 4),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The question editor has always had this; without it a
                // teacher on a dead connection got no warning at all,
                // just a Save button that span.
                const OfflineBanner(
                  message: 'You are offline. Changes are saved on this '
                      'device and will sync when you reconnect.',
                ),
                _detailsPanel(),
                const SizedBox(height: 14),
                if (!_isEditing) ...[
                  _passwordPanel(),
                  const SizedBox(height: 14),
                ],
                _accessPanel(),
                const SizedBox(height: 20),
                _saveButton(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailsPanel() {
    final loginId = buildNameLoginId(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
    );

    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminSectionHeader(
            icon: Icons.badge_rounded,
            title: 'Player details',
            caption: 'The first and last name together become the login id.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _onNameChanged(),
                  decoration: InputDecoration(
                    labelText: 'First name',
                    prefixIcon: const Icon(Icons.person_rounded),
                    errorText: _errors['firstName'],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _onNameChanged(),
                  decoration: InputDecoration(
                    labelText: 'Last name',
                    prefixIcon: const Icon(Icons.badge_rounded),
                    errorText: _errors['lastName'],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            onChanged: (_) => _revalidateIfNeeded(),
            onSubmitted: (_) => _saving ? null : _save(),
            decoration: InputDecoration(
              labelText: 'Age',
              prefixIcon: const Icon(Icons.cake_rounded),
              helperText:
                  'Between ${AppUserRecord.minAge} and ${AppUserRecord.maxAge}',
              errorText: _errors['age'],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminPalette.accent, width: 1.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.key_rounded, size: 18, color: AdminPalette.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Login id',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AdminPalette.muted,
                        ),
                      ),
                      Text(
                        loginId == 'player' ? '-' : loginId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AdminPalette.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordPanel() {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminSectionHeader(
            icon: Icons.lock_rounded,
            title: 'Password',
            caption: 'Give this to the student so they can sign in.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _revalidateIfNeeded(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_rounded),
              errorText: _errors['password'],
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirmController,
            obscureText: _obscurePassword,
            // Last field in the form, so Enter saves.
            textInputAction: TextInputAction.done,
            onChanged: (_) => _revalidateIfNeeded(),
            onSubmitted: (_) => _saving ? null : _save(),
            decoration: InputDecoration(
              labelText: 'Confirm password',
              prefixIcon: const Icon(Icons.lock_reset_rounded),
              errorText: _errors['confirm'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accessPanel() {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminSectionHeader(
            icon: Icons.shield_rounded,
            title: 'Access',
          ),
          const SizedBox(height: 8),
          RadioGroup<UserRole>(
            groupValue: _role,
            onChanged: (value) {
              if (value != null) setState(() => _role = value);
            },
            child: const Column(
              children: [
                RadioListTile<UserRole>(
                  value: UserRole.student,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AdminPalette.success,
                  title: Text(
                    'Student',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'Plays the games and appears on leaderboards.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AdminPalette.muted,
                    ),
                  ),
                ),
                RadioListTile<UserRole>(
                  value: UserRole.admin,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AdminPalette.accent,
                  title: Text(
                    'Admin / Teacher',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'Full access to questions and every account.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AdminPalette.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isEditing) ...[
            const Divider(height: 20),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: !_disabled,
              activeThumbColor: AdminPalette.success,
              onChanged: (value) => setState(() => _disabled = !value),
              title: const Text(
                'Account active',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                _disabled
                    ? 'Deactivated - this person cannot sign in. Scores are kept.'
                    : 'This person can sign in and play.',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _disabled ? AdminPalette.danger : AdminPalette.muted,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminPalette.noticeBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminPalette.noticeBorder, width: 1.6),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: AdminPalette.noticeInk),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Passwords are held by Firebase Authentication and cannot be read or reset for another person from inside the app.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: AdminPalette.noticeInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _saving
            ? null
            : () {
                SoundService().playButtonSoundNow();
                _save();
              },
        icon: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
              )
            : Icon(_isEditing ? Icons.save_rounded : Icons.person_add_alt_1_rounded),
        label: Text(
          _saving ? 'Saving...' : (_isEditing ? 'Save changes' : 'Create account'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
