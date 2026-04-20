import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

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
      } catch (_) {}
    }
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

  Future<void> sendPasswordReset(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    await _auth.sendPasswordResetEmail(email: normalizedEmail);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      final uid = user.uid;

      // Delete all user posts
      final posts = await _firestore
          .collection('posts')
          .where('user_id', isEqualTo: uid)
          .get();

      WriteBatch batch = _firestore.batch();
      int opCount = 0;

      for (final post in posts.docs) {
        // Delete post comments subcollection
        final comments = await post.reference.collection('comments').get();
        for (final comment in comments.docs) {
          batch.delete(comment.reference);
          opCount++;
          if (opCount >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            opCount = 0;
          }
        }
        batch.delete(post.reference);
        opCount++;
        if (opCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          opCount = 0;
        }
      }

      // Delete saved_designs subcollection
      final saved = await _firestore
          .collection('users')
          .doc(uid)
          .collection('saved_designs')
          .get();
      for (final doc in saved.docs) {
        batch.delete(doc.reference);
        opCount++;
        if (opCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          opCount = 0;
        }
      }

      // Delete my_designs subcollection
      final myDesigns = await _firestore
          .collection('users')
          .doc(uid)
          .collection('my_designs')
          .get();
      for (final doc in myDesigns.docs) {
        batch.delete(doc.reference);
        opCount++;
        if (opCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          opCount = 0;
        }
      }

      // Delete user document
      batch.delete(_firestore.collection('users').doc(uid));
      opCount++;

      if (opCount > 0) {
        await batch.commit();
      }

      // Remove user's likes from other posts
      final likedPosts = await _firestore
          .collection('posts')
          .where('liked_by', arrayContains: uid)
          .get();
      for (final post in likedPosts.docs) {
        await post.reference.update({
          'liked_by': FieldValue.arrayRemove([uid]),
          'likes_count': FieldValue.increment(-1),
        });
      }

      // Finally delete the auth account
      await user.delete();
    }
  }
}
