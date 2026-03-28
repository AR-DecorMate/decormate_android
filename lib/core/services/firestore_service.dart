import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/catalog_item_model.dart';
import '../models/saved_design_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Users ────────────────────────────────────────────────────
  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    return _db.collection('users').doc(uid).update(data);
  }

  // ── Posts ────────────────────────────────────────────────────
  Stream<List<PostModel>> streamPosts({int limit = 20}) {
    return _db
        .collection('posts')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(PostModel.fromFirestore).toList());
  }

  Future<DocumentReference> createPost(PostModel post) {
    return _db.collection('posts').add(post.toFirestore());
  }

  Future<void> toggleLike(String postId, String uid) {
    final ref = _db.collection('posts').doc(postId);
    return _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final likedBy = List<String>.from(doc['liked_by'] ?? []);
      if (likedBy.contains(uid)) {
        tx.update(ref, {
          'liked_by': FieldValue.arrayRemove([uid]),
          'likes_count': FieldValue.increment(-1),
        });
      } else {
        tx.update(ref, {
          'liked_by': FieldValue.arrayUnion([uid]),
          'likes_count': FieldValue.increment(1),
        });
      }
    });
  }

  // ── Comments ────────────────────────────────────────────────
  Stream<List<CommentModel>> streamComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('created_at')
        .snapshots()
        .map((snap) => snap.docs.map(CommentModel.fromFirestore).toList());
  }

  Future<void> addComment(String postId, CommentModel comment) async {
    final batch = _db.batch();
    final commentRef = _db.collection('posts').doc(postId).collection('comments').doc();
    batch.set(commentRef, comment.toFirestore());
    batch.update(_db.collection('posts').doc(postId), {
      'comments_count': FieldValue.increment(1),
    });
    await batch.commit();
  }

  // ── Catalog ─────────────────────────────────────────────────
  Future<List<CatalogItem>> getCatalogItems(String category, {String? style}) async {
    final snap = await _db
        .collection('catalog_items')
        .where('category', isEqualTo: category)
        .get();
    final items = snap.docs.map(CatalogItem.fromFirestore).toList();
    if (style != null) {
      return items.where((item) => item.style == style).toList();
    }
    return items;
  }

  Future<CatalogItem?> getCatalogItem(String itemId) async {
    final doc = await _db.collection('catalog_items').doc(itemId).get();
    if (!doc.exists) return null;
    return CatalogItem.fromFirestore(doc);
  }

  Stream<List<CatalogItem>> streamTrendingItems({int limit = 10}) {
    return _db
        .collection('catalog_items')
        .where('is_trending', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(CatalogItem.fromFirestore).toList());
  }

  // ── Saved Designs ───────────────────────────────────────────
  Stream<List<SavedDesign>> streamSavedDesigns(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('saved_designs')
        .orderBy('saved_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SavedDesign.fromFirestore).toList());
  }

  Future<void> toggleSaveDesign(String uid, CatalogItem item) async {
    final ref = _db.collection('users').doc(uid).collection('saved_designs').doc(item.id);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set(SavedDesign(
        itemId: item.id,
        category: item.category,
        name: item.name,
        thumbnailUrl: item.thumbnailUrl,
        savedAt: DateTime.now(),
      ).toFirestore());
    }
  }

  Future<bool> isItemSaved(String uid, String itemId) async {
    final doc = await _db.collection('users').doc(uid).collection('saved_designs').doc(itemId).get();
    return doc.exists;
  }

  // ── My Designs (AR Screenshots) ────────────────────────────
  Stream<List<Map<String, dynamic>>> streamMyDesigns(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('my_designs')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> saveMyDesign(String uid, String imageUrl) {
    return _db.collection('users').doc(uid).collection('my_designs').add({
      'image_url': imageUrl,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Liked Posts ─────────────────────────────────────────────
  Stream<List<PostModel>> streamLikedPosts(String uid) {
    return _db
        .collection('posts')
        .where('liked_by', arrayContains: uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PostModel.fromFirestore).toList());
  }
}
