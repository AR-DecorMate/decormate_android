import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Lazy-init to avoid crash on web when no OAuth clientId is set
  GoogleSignIn? _googleSignIn;
  String get _googleOAuthClientId => dotenv.env['GOOGLE_OAUTH_CLIENT_ID']?.trim() ?? '';

  GoogleSignIn get _gsi => _googleSignIn ??= GoogleSignIn(
    clientId: kIsWeb && _googleOAuthClientId.isNotEmpty ? _googleOAuthClientId : null,
    serverClientId: !kIsWeb && _googleOAuthClientId.isNotEmpty ? _googleOAuthClientId : null,
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  Future<void> _upsertUserFromAuth(
    User user, {
    String? fallbackName,
    String? fallbackEmail,
  }) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();
    final data = doc.data() ?? <String, dynamic>{};

    final existingName = (data['name'] as String?)?.trim() ?? '';
    final existingAvatarUrl = (data['avatar_url'] as String?)?.trim() ?? '';
    final resolvedName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (fallbackName?.trim().isNotEmpty == true
            ? fallbackName!.trim()
            : (existingName.isNotEmpty ? existingName : 'User'));
    final resolvedAvatarUrl = user.photoURL?.trim().isNotEmpty == true
        ? user.photoURL!.trim()
        : existingAvatarUrl;

    final updates = <String, dynamic>{
      'uid': user.uid,
      'email': _normalizeEmail(user.email ?? fallbackEmail ?? ''),
      'name': resolvedName,
      'last_login': FieldValue.serverTimestamp(),
    };

    if (!doc.exists) {
      updates['created_at'] = FieldValue.serverTimestamp();
    }

    if (resolvedAvatarUrl.isNotEmpty) {
      updates['avatar_url'] = resolvedAvatarUrl;
    }

    await userRef.set(updates, SetOptions(merge: true));

    final profileChanged = resolvedName != existingName || resolvedAvatarUrl != existingAvatarUrl;
    if (profileChanged) {
      try {
        await _firestoreService.syncUserPostsPublicData(
          uid: user.uid,
          name: resolvedName,
          avatarUrl: resolvedAvatarUrl.isNotEmpty ? resolvedAvatarUrl : null,
        );
      } catch (_) {
        // Do not block auth if post profile sync is rejected by Firestore rules.
      }
    }
  }

  String _googleSignInErrorMessage(Object error) {
    if (error is PlatformException) {
      if (error.code == 'sign_in_canceled') return 'Google sign-in was cancelled.';
      if (error.code == 'network_error') return 'Google sign-in failed because the network is unavailable.';
      if (error.code == 'sign_in_failed' || error.code == '10') {
        return 'Google sign-in is not configured correctly for Android. Update the Firebase OAuth setup and download a fresh google-services.json.';
      }
      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!.trim();
      }
    }

    if (error is FirebaseAuthException && error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!.trim();
    }

    return 'Google sign-in failed. Please try again.';
  }

  Future<User?> signInWithEmail(String email, String password) async {
    final normalizedEmail = _normalizeEmail(email);
    final credential = await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password.trim(),
    );
    final user = credential.user;
    if (user != null) {
      await _upsertUserFromAuth(user, fallbackEmail: normalizedEmail);
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
    final normalizedEmail = _normalizeEmail(email);
    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password.trim(),
    );

    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(name.trim());
      await _firestore.collection('users').doc(user.uid).set(
        UserModel(
          uid: user.uid,
          name: name.trim(),
          email: normalizedEmail,
          mobile: mobile.trim(),
          dob: dob.trim(),
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        ).toFirestore(),
      );
    }
    return user;
  }

  Future<User?> signInWithGoogle() async {
    try {
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
        await _upsertUserFromAuth(
          user,
          fallbackName: googleUser.displayName,
          fallbackEmail: googleUser.email,
        );
      }
      return user;
    } catch (error) {
      throw Exception(_googleSignInErrorMessage(error));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    final methods = await _auth.fetchSignInMethodsForEmail(normalizedEmail);

    if (methods.contains(GoogleAuthProvider.PROVIDER_ID) &&
        !methods.contains(EmailAuthProvider.EMAIL_PASSWORD_SIGN_IN_METHOD)) {
      throw FirebaseAuthException(
        code: 'wrong-provider',
        message: 'This account uses Google sign-in. Please use Google to log in.',
      );
    }

    await _auth.sendPasswordResetEmail(email: normalizedEmail);
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
