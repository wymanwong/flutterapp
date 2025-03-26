import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user.dart' as app;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance);
});

class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository(this._auth);

  Stream<app.User?> get authStateChanges {
    return _auth.authStateChanges().map((user) {
      return user != null ? app.User.fromFirebaseUser(user) : null;
    });
  }

  app.User? get currentUser {
    final user = _auth.currentUser;
    return user != null ? app.User.fromFirebaseUser(user) : null;
  }

  Future<app.User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user != null ? app.User.fromFirebaseUser(result.user!) : null;
    } catch (e) {
      rethrow;
    }
  }

  Future<app.User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user != null ? app.User.fromFirebaseUser(result.user!) : null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoUrl);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await user.updateEmail(newEmail);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await user.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await user.delete();
    } catch (e) {
      rethrow;
    }
  }
} 