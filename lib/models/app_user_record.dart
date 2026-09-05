import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/name_credential.dart';

/// Access level stored on `users/{uid}.role`.
///
/// Anything that is not exactly `'admin'` is treated as a student, so existing
/// documents written before this field existed stay students by default.
enum UserRole { student, admin }

const String kAdminRoleValue = 'admin';

UserRole userRoleFromName(String? name) {
  return name == kAdminRoleValue ? UserRole.admin : UserRole.student;
}

String userRoleLabel(UserRole role) {
  return role == UserRole.admin ? 'Admin / Teacher' : 'Student';
}

/// A player or admin account as stored in the `users` collection.
///
/// Deleting an account is a *soft* delete: [disabled] flips to true and the
/// login screens refuse entry. A client SDK cannot remove another person's
/// Firebase Auth credential — only a server holding the Admin SDK can — so
/// disabling is the honest client-side equivalent, and it keeps the player's
/// game logs and leaderboard history intact.
class AppUserRecord {
  final String uid;
  final String firstName;
  final String lastName;
  final String fullName;
  final int? age;
  final String loginId;
  final String email;
  final UserRole role;
  final bool disabled;
  final bool isAnonymous;
  final bool profileComplete;

  /// The real address the player confirmed, empty until they do.
  ///
  /// Every account signs in with a made-up `@lockinplayers.app` credential
  /// built from the child's name, which no mail can reach - so an account
  /// without this is one nobody can recover when the password is forgotten.
  final String recoveryEmail;
  final bool recoveryEmailVerified;
  final int highscore;
  final int cheatAttempts;
  final String? lastGame;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSeenAt;

  const AppUserRecord({
    required this.uid,
    this.firstName = '',
    this.lastName = '',
    this.fullName = '',
    this.age,
    this.loginId = '',
    this.email = '',
    this.role = UserRole.student,
    this.disabled = false,
    this.isAnonymous = false,
    this.profileComplete = false,
    this.recoveryEmail = '',
    this.recoveryEmailVerified = false,
    this.highscore = 0,
    this.cheatAttempts = 0,
    this.lastGame,
    this.createdAt,
    this.updatedAt,
    this.lastSeenAt,
  });

  static const int minAge = 4;
  static const int maxAge = 100;

  bool get isAdmin => role == UserRole.admin;

  /// Whether this account can be got back into if the password is forgotten.
  bool get isRecoverable =>
      recoveryEmailVerified && recoveryEmail.trim().isNotEmpty;

  String get displayName {
    final combined = '$firstName $lastName'.trim();
    if (combined.isNotEmpty) return combined;
    if (fullName.trim().isNotEmpty) return fullName.trim();
    if (loginId.isNotEmpty) return loginId;
    return isAnonymous ? 'Guest player' : uid;
  }

  AppUserRecord copyWith({
    String? firstName,
    String? lastName,
    int? age,
    UserRole? role,
    bool? disabled,
  }) {
    final nextFirst = firstName ?? this.firstName;
    final nextLast = lastName ?? this.lastName;
    return AppUserRecord(
      uid: uid,
      firstName: nextFirst,
      lastName: nextLast,
      fullName: '$nextFirst $nextLast'.trim(),
      age: age ?? this.age,
      loginId: loginId,
      email: email,
      role: role ?? this.role,
      disabled: disabled ?? this.disabled,
      isAnonymous: isAnonymous,
      profileComplete: profileComplete,
      highscore: highscore,
      cheatAttempts: cheatAttempts,
      lastGame: lastGame,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastSeenAt: lastSeenAt,
    );
  }

  factory AppUserRecord.fromMap(String uid, Map<String, dynamic> data) {
    return AppUserRecord(
      uid: uid,
      firstName: (data['firstName'] ?? '').toString(),
      lastName: (data['lastName'] ?? '').toString(),
      fullName: (data['fullName'] ?? data['username'] ?? '').toString(),
      age: _asInt(data['age']),
      loginId: (data['loginId'] ?? '').toString(),
      email: (data['loginEmail'] ?? data['email'] ?? '').toString(),
      role: userRoleFromName(data['role']?.toString()),
      disabled: data['disabled'] == true,
      isAnonymous: data['isAnonymous'] == true,
      profileComplete: data['profile_complete'] == true,
      recoveryEmail: (data['recoveryEmail'] ?? '').toString(),
      recoveryEmailVerified: data['recoveryEmailVerified'] == true,
      highscore: _asInt(data['highscore']) ?? 0,
      cheatAttempts: _asInt(data['cheat_attempts_count']) ?? 0,
      lastGame: data['last_game']?.toString(),
      createdAt: _asDate(data['createdAt']) ?? _asDate(data['accountCreatedAt']),
      updatedAt: _asDate(data['updatedAt']),
      lastSeenAt: _asDate(data['lastSeenAt']) ?? _asDate(data['lastLoginAt']),
    );
  }

  factory AppUserRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return AppUserRecord.fromMap(
      snapshot.id,
      snapshot.data() ?? const <String, dynamic>{},
    );
  }

  /// The subset of fields an admin is allowed to rewrite. Auth-owned fields
  /// (uid, email, password) are deliberately excluded.
  Map<String, dynamic> toUpdateMap() {
    return {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'fullName': '${firstName.trim()} ${lastName.trim()}'.trim(),
      'username': '${firstName.trim()} ${lastName.trim()}'.trim(),
      'loginId': buildNameLoginId(firstName: firstName, lastName: lastName),
      'age': age,
      'role': role == UserRole.admin ? kAdminRoleValue : 'student',
      'disabled': disabled,
    };
  }

  /// Returns `fieldName -> message`; empty means the edit is safe to save.
  Map<String, String> validate() {
    final errors = <String, String>{};
    final namePattern = RegExp(r"^[A-Za-zÀ-ÿ' .-]+$");

    final first = firstName.trim();
    if (first.isEmpty) {
      errors['firstName'] = 'First name is required.';
    } else if (first.length > 40) {
      errors['firstName'] = 'Keep the first name under 40 characters.';
    } else if (!namePattern.hasMatch(first)) {
      errors['firstName'] = 'Use letters only for the first name.';
    }

    final last = lastName.trim();
    if (last.isEmpty) {
      errors['lastName'] = 'Last name is required.';
    } else if (last.length > 40) {
      errors['lastName'] = 'Keep the last name under 40 characters.';
    } else if (!namePattern.hasMatch(last)) {
      errors['lastName'] = 'Use letters only for the last name.';
    }

    if (age == null) {
      errors['age'] = 'Age is required.';
    } else if (age! < minAge || age! > maxAge) {
      errors['age'] = 'Age must be between $minAge and $maxAge.';
    }

    return errors;
  }

  bool get isValid => validate().isEmpty;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _asDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
