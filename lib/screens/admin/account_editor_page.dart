import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_user_record.dart';
import '../../services/sound_service.dart';
import '../../services/user_admin_repository.dart';
import '../../utils/admin_theme.dart';
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
      final password = _passwordController.text;
      if (password.length < 6) {
        errors['password'] = 'Password must be at least 6 characters.';
      } else if (password != _confirmController.text) {
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
          password: _passwordController.text,
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
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            onChanged: (_) => _revalidateIfNeeded(),
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
            onChanged: (_) => _revalidateIfNeeded(),
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
            child: Column(
              children: [
                RadioListTile<UserRole>(
                  value: UserRole.student,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AdminPalette.success,
                  title: const Text(
                    'Student',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
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
                  title: const Text(
                    'Admin / Teacher',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
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
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0A800), width: 1.6),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF8A6100)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Passwords are held by Firebase Authentication and cannot be read or reset for another person from inside the app.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: Color(0xFF8A6100),
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
