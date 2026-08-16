import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_user_record.dart';
import '../utils/firebase_options.dart';
import '../utils/name_credential.dart';

/// Thrown when an account write is rejected before it reaches Firebase.
class AccountValidationException implements Exception {
  final Map<String, String> errors;

  const AccountValidationException(this.errors);

  String get summary => errors.values.join('\n');

  @override
  String toString() => 'AccountValidationException: $summary';
}

/// Create / Read / Update / Delete for the `users` collection.
///
/// "Delete" here is a soft delete ([setDisabled]) because a client SDK cannot
/// remove another person's Firebase Auth credential. Disabling blocks sign-in
/// at the gate while keeping the player's history for the leaderboard.
class UserAdminRepository {
  static const String collectionPath = 'users';

  /// Name of the throwaway secondary [FirebaseApp] used to create accounts.
  /// Calling `createUserWithEmailAndPassword` on the default app would swap the
  /// signed-in user, kicking the admin out of their own session — so account
  /// creation runs on its own app instance instead.
  static const String _workerAppName = 'lockInAdminWorker';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserAdminRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionPath);

  // ---------------------------------------------------------------- CREATE

  /// Creates a real, loginable account on behalf of an admin.
  ///
  /// Returns the new uid. Throws [AccountValidationException] for bad input and
  /// [FirebaseAuthException] when the credential is already taken.
  Future<String> createAccount({
    required String firstName,
    required String lastName,
    required int? age,
    required String password,
    UserRole role = UserRole.student,
  }) async {
    final draft = AppUserRecord(
      uid: '',
      firstName: firstName,
      lastName: lastName,
      age: age,
      role: role,
    );
    final errors = draft.validate();
    if (password.length < 6) {
      errors['password'] = 'Password must be at least 6 characters.';
    }
    if (errors.isNotEmpty) throw AccountValidationException(errors);

    final loginEmail =
        buildNameCredentialEmail(firstName: firstName, lastName: lastName);
    final loginId = buildNameLoginId(firstName: firstName, lastName: lastName);

    final workerApp = await _resolveWorkerApp();
    final workerAuth = FirebaseAuth.instanceFor(app: workerApp);

    try {
      final credential = await workerAuth.createUserWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'Firebase did not return a user for the new account.',
        );
      }

      final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
      await _collection.doc(uid).set({
        'uid': uid,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'fullName': fullName,
        'username': fullName,
        'loginId': loginId,
        'loginEmail': loginEmail,
        'email': loginEmail,
        'age': age,
        'role': role == UserRole.admin ? kAdminRoleValue : 'student',
        'disabled': false,
        'isAnonymous': false,
        'authProvider': 'email',
        'profile_complete': true,
        'onboarding_step': 'done',
        'createdBy': _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'accountCreatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return uid;
    } finally {
      // Leave no signed-in session behind on the worker app.
      await workerAuth.signOut();
    }
  }

  Future<FirebaseApp> _resolveWorkerApp() async {
    // Firebase.app throws when the named app has not been created yet. The
    // exact exception type differs across platforms, so any failure here is
    // treated as "not created" and the app is initialized.
    try {
      return Firebase.app(_workerAppName);
    } catch (_) {
      return Firebase.initializeApp(
        name: _workerAppName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  // ------------------------------------------------------------------ READ

  /// Live account list. Sorting happens client-side so no composite index is
  /// needed when the caller also filters by role.
  Stream<List<AppUserRecord>> watchAccounts() {
    return _collection.snapshots().map((snapshot) {
      final records = snapshot.docs.map(AppUserRecord.fromSnapshot).toList();
      records.sort(
        (a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      return records;
    });
  }

  Future<AppUserRecord?> fetchAccount(String uid) async {
    if (uid.isEmpty) return null;
    final snapshot = await _collection.doc(uid).get();
    if (!snapshot.exists) return null;
    return AppUserRecord.fromSnapshot(snapshot);
  }

  /// Reads the signed-in user's own record. Returns null when signed out.
  Future<AppUserRecord?> fetchCurrentAccount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Future.value(null);
    return fetchAccount(uid);
  }

  // ---------------------------------------------------------------- UPDATE

  Future<void> updateAccount(AppUserRecord record) async {
    final errors = record.validate();
    if (errors.isNotEmpty) throw AccountValidationException(errors);

    await _collection.doc(record.uid).update({
      ...record.toUpdateMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setRole(String uid, UserRole role) async {
    await _collection.doc(uid).update({
      'role': role == UserRole.admin ? kAdminRoleValue : 'student',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------- DELETE

  /// Soft delete. A disabled account is refused at the gate and shown a
  /// "contact your teacher" message.
  Future<void> setDisabled(String uid, bool disabled) async {
    await _collection.doc(uid).update({
      'disabled': disabled,
      'disabledAt': disabled ? FieldValue.serverTimestamp() : null,
      'disabledBy': disabled ? _auth.currentUser?.uid : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Guards against an admin locking every admin out of the panel.
  Future<int> countActiveAdmins() async {
    final snapshot =
        await _collection.where('role', isEqualTo: kAdminRoleValue).get();
    return snapshot.docs
        .map(AppUserRecord.fromSnapshot)
        .where((record) => !record.disabled)
        .length;
  }
}
