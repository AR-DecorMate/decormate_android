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

  Future<void> syncUserPostsPublicData({
    required String uid,
    required String name,
    String? avatarUrl,
  }) async {
    final posts = await _db.collection('posts').where('user_id', isEqualTo: uid).get();
    if (posts.docs.isEmpty) return;

    WriteBatch batch = _db.batch();
    var operationCount = 0;

    Future<void> flushBatch() async {
      if (operationCount == 0) return;
      await batch.commit();
      batch = _db.batch();
      operationCount = 0;
    }

    for (final post in posts.docs) {
      final updates = <String, dynamic>{
        'user_name': name,
        'user_avatar_url': avatarUrl != null && avatarUrl.isNotEmpty ? avatarUrl : FieldValue.delete(),
      };
      batch.update(post.reference, updates);
      operationCount += 1;

      if (operationCount >= 450) {
        await flushBatch();
      }
    }

    await flushBatch();
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

  Future<void> deletePost(String postId) async {
    final postRef = _db.collection('posts').doc(postId);
    // Delete comments subcollection first
    final comments = await postRef.collection('comments').get();
    WriteBatch batch = _db.batch();
    int opCount = 0;
    for (final comment in comments.docs) {
      batch.delete(comment.reference);
      opCount++;
      if (opCount >= 450) {
        await batch.commit();
        batch = _db.batch();
        opCount = 0;
      }
    }
    batch.delete(postRef);
    opCount++;
    await batch.commit();
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

  // Hosted GLB model URLs from KhronosGroup glTF Sample Assets (reliable GitHub CDN)
  static const _kChair = 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/SheenChair/glTF-Binary/SheenChair.glb';
  static const _kLantern = 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Lantern/glTF-Binary/Lantern.glb';
  static const _kDuck = 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Duck/glTF-Binary/Duck.glb';
  static const _kBox = 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/BoxAnimated/glTF-Binary/BoxAnimated.glb';
  static const _kBottle = 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/WaterBottle/glTF-Binary/WaterBottle.glb';
  static const _kAvocado = 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Avocado/glTF-Binary/Avocado.glb';

  static const _testItems = [
    // ── Sofa ──
    CatalogItem(id: 'sofa_casual', name: 'Modern Sofa', description: 'A comfortable modern sofa for your living room.', category: 'Sofa', style: 'casual', thumbnailUrl: '', modelUrl: _kChair, isTrending: true),
    CatalogItem(id: 'sofa_luxury', name: 'Luxury Velvet Sofa', description: 'An elegant velvet sofa with premium finish.', category: 'Sofa', style: 'luxury', thumbnailUrl: '', modelUrl: _kChair, isTrending: true),
    // ── Bed ──
    CatalogItem(id: 'bed_casual', name: 'Casual Bed', description: 'A casual bed for everyday comfort.', category: 'Bed', style: 'casual', thumbnailUrl: '', modelUrl: _kBox, isTrending: true),
    CatalogItem(id: 'bed_luxury', name: 'King Size Bed', description: 'A luxury king-size bed with premium mattress.', category: 'Bed', style: 'luxury', thumbnailUrl: '', modelUrl: _kBox),
    // ── Table ──
    CatalogItem(id: 'table_casual', name: 'Coffee Table', description: 'A wooden coffee table for your living room.', category: 'Table', style: 'casual', thumbnailUrl: '', modelUrl: _kBox),
    CatalogItem(id: 'table_luxury', name: 'Marble Dining Table', description: 'An elegant marble dining table for six.', category: 'Table', style: 'luxury', thumbnailUrl: '', modelUrl: _kBox, isTrending: true),
    // ── Chair ──
    CatalogItem(id: 'chair_casual', name: 'Simple Chair', description: 'A simple wooden chair.', category: 'Chair', style: 'casual', thumbnailUrl: '', modelUrl: _kChair),
    CatalogItem(id: 'chair_luxury', name: 'Royal Armchair', description: 'A premium leather armchair.', category: 'Chair', style: 'luxury', thumbnailUrl: '', modelUrl: _kChair, isTrending: true),
    // ── Lamps ──
    CatalogItem(id: 'lamp_casual', name: 'Desk Lamp', description: 'A modern desk lamp with adjustable arm.', category: 'Lamps', style: 'casual', thumbnailUrl: '', modelUrl: _kLantern),
    CatalogItem(id: 'lamp_luxury', name: 'Crystal Lamp', description: 'An elegant crystal table lamp.', category: 'Lamps', style: 'luxury', thumbnailUrl: '', modelUrl: _kLantern),
    // ── Frames ──
    CatalogItem(id: 'frame_casual', name: 'Photo Frame', description: 'A simple wooden photo frame.', category: 'Frames', style: 'casual', thumbnailUrl: '', modelUrl: _kDuck),
    CatalogItem(id: 'frame_luxury', name: 'Gold Frame', description: 'An ornate gold-plated picture frame.', category: 'Frames', style: 'luxury', thumbnailUrl: '', modelUrl: _kDuck),
    // ── Fan ──
    CatalogItem(id: 'fan_casual', name: 'Ceiling Fan', description: 'A standard 3-blade ceiling fan.', category: 'Fan', style: 'casual', thumbnailUrl: '', modelUrl: _kAvocado),
    CatalogItem(id: 'fan_luxury', name: 'Designer Fan', description: 'A premium designer ceiling fan with LED light.', category: 'Fan', style: 'luxury', thumbnailUrl: '', modelUrl: _kAvocado),
    // ── Lights ──
    CatalogItem(id: 'light_casual', name: 'LED Panel', description: 'A modern LED panel light for ceilings.', category: 'Lights', style: 'casual', thumbnailUrl: '', modelUrl: _kLantern),
    CatalogItem(id: 'light_luxury', name: 'Pendant Light', description: 'A luxurious pendant light fixture.', category: 'Lights', style: 'luxury', thumbnailUrl: '', modelUrl: _kLantern, isTrending: true),
    // ── Curtains ──
    CatalogItem(id: 'curtain_casual', name: 'Cotton Curtains', description: 'Simple cotton curtains for everyday use.', category: 'Curtains', style: 'casual', thumbnailUrl: '', modelUrl: _kBottle),
    CatalogItem(id: 'curtain_luxury', name: 'Silk Drapes', description: 'Premium silk drapes with gold accents.', category: 'Curtains', style: 'luxury', thumbnailUrl: '', modelUrl: _kBottle),
    // ── Washbasin ──
    CatalogItem(id: 'basin_casual', name: 'Ceramic Basin', description: 'A standard ceramic washbasin.', category: 'Washbasin', style: 'casual', thumbnailUrl: '', modelUrl: _kBottle),
    CatalogItem(id: 'basin_luxury', name: 'Stone Basin', description: 'A premium natural stone washbasin.', category: 'Washbasin', style: 'luxury', thumbnailUrl: '', modelUrl: _kBottle),
    // ── Tap ──
    CatalogItem(id: 'tap_casual', name: 'Chrome Tap', description: 'A standard chrome mixer tap.', category: 'Tap', style: 'casual', thumbnailUrl: '', modelUrl: _kBottle),
    CatalogItem(id: 'tap_luxury', name: 'Gold Tap', description: 'A luxury gold-finish waterfall tap.', category: 'Tap', style: 'luxury', thumbnailUrl: '', modelUrl: _kBottle),
    // ── Windows ──
    CatalogItem(id: 'window_casual', name: 'Sliding Window', description: 'A standard aluminum sliding window.', category: 'Windows', style: 'casual', thumbnailUrl: '', modelUrl: _kBox),
    CatalogItem(id: 'window_luxury', name: 'Bay Window', description: 'A premium bay window with wooden frame.', category: 'Windows', style: 'luxury', thumbnailUrl: '', modelUrl: _kBox),
    // ── Decor ──
    CatalogItem(id: 'decor_casual', name: 'Plant Pot', description: 'A minimalist ceramic plant pot.', category: 'Decor', style: 'casual', thumbnailUrl: '', modelUrl: _kAvocado, isTrending: true),
    CatalogItem(id: 'decor_luxury', name: 'Crystal Vase', description: 'An elegant crystal flower vase.', category: 'Decor', style: 'luxury', thumbnailUrl: '', modelUrl: _kAvocado),
    // ── Chandelier ──
    CatalogItem(id: 'chandelier_casual', name: 'Mini Chandelier', description: 'A compact modern chandelier.', category: 'Chandelier', style: 'casual', thumbnailUrl: '', modelUrl: _kLantern),
    CatalogItem(id: 'chandelier_luxury', name: 'Grand Chandelier', description: 'A grand crystal chandelier for large spaces.', category: 'Chandelier', style: 'luxury', thumbnailUrl: '', modelUrl: _kLantern, isTrending: true),
  ];

  Future<List<CatalogItem>> getCatalogItems(String category, {String? style}) async {
    final snap = await _db
        .collection('catalog_items')
        .where('category', isEqualTo: category)
        .get();
    var items = snap.docs.map(CatalogItem.fromFirestore).toList();

    // Add hardcoded test items if Firestore is empty
    if (items.isEmpty) {
      items = _testItems.where((i) => i.category == category).toList();
    }

    if (style != null) {
      return items.where((item) => item.style == style).toList();
    }
    return items;
  }

  Future<CatalogItem?> getCatalogItem(String itemId) async {
    final doc = await _db.collection('catalog_items').doc(itemId).get();
    if (!doc.exists) {
      // Check hardcoded test items
      final match = _testItems.where((i) => i.id == itemId);
      return match.isNotEmpty ? match.first : null;
    }
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
        .snapshots()
        .map((snap) {
          final posts = snap.docs.map(PostModel.fromFirestore).toList();
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return posts;
        });
  }
}
