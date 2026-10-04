import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../models/app_user.dart';

abstract class AuthService {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  });
  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({firebase.FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? firebase.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AppUser(id: user.uid, email: user.email ?? '', displayName: user.displayName ?? '', username: '');
  }

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().asyncMap((user) async {
        if (user == null) return null;
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) return AppUser.fromMap(user.uid, doc.data()!);
        return AppUser(id: user.uid, email: user.email ?? '', displayName: user.displayName ?? '', username: '');
      });

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    final doc = await _firestore.collection('users').doc(credential.user!.uid).get();
    if (doc.exists && doc.data() != null) return AppUser.fromMap(credential.user!.uid, doc.data()!);
    return AppUser(id: credential.user!.uid, email: credential.user!.email ?? '', displayName: credential.user!.displayName ?? '', username: '');
  }

  @override
  Future<AppUser> signUp({required String email, required String password, required String displayName, required String username}) async {
    final normalizedUsername = username.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(normalizedUsername)) {
      throw ArgumentError('Username must be 3–24 characters using letters, numbers, or underscores.');
    }

    final usernameRef = _firestore.collection('usernames').doc(normalizedUsername);
    final existing = await usernameRef.get();
    if (existing.exists) throw StateError('That username is already taken.');

    final credential = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final uid = credential.user!.uid;
    final user = AppUser(id: uid, email: email.trim(), displayName: displayName.trim(), username: normalizedUsername);

    try {
      await credential.user!.updateDisplayName(user.displayName);
      final batch = _firestore.batch();
      batch.set(_firestore.collection('users').doc(uid), {
        ...user.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(usernameRef, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
      await batch.commit();
      return user;
    } catch (_) {
      await credential.user?.delete();
      rethrow;
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
