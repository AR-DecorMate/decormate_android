import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lazy-init to avoid crash on web when no OAuth clientId is set
  GoogleSignIn? _googleSignIn;
  GoogleSignIn get _gsi => _googleSignIn ??= GoogleSignIn(
    clientId: kIsWeb ? 'YOUR_WEB_OAUTH_CLIENT_ID.apps.googleusercontent.com' : null,
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final user = credential.user;
    if (user != null) {
      // Ensure Firestore user document exists (may be missing if signed up
      // before Firestore was set up, or if the write failed during signup).
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _firestore.collection('users').doc(user.uid).set(
          UserModel(
            uid: user.uid,
            name: user.displayName ?? 'User',
            email: user.email ?? email.trim(),
            createdAt: DateTime.now(),
          ).toFirestore(),
        );
      } else {
        await _firestore.collection('users').doc(user.uid).update({
          'last_login': Timestamp.fromDate(DateTime.now()),
        });
      }
    }
    return user;
  }

  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String mobile = '',
    String dob = '',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(name.trim());
      await _firestore.collection('users').doc(user.uid).set(
        UserModel(
          uid: user.uid,
          name: name.trim(),
          email: email.trim(),
          mobile: mobile.trim(),
          dob: dob.trim(),
          createdAt: DateTime.now(),
        ).toFirestore(),
      );
    }
    return user;
  }

  Future<User?> signInWithGoogle() async {
    final googleUser = await _gsi.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? 'User',
        'last_login': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    }
    return user;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    try { await _gsi.signOut(); } catch (_) {}
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    }
  }
}
