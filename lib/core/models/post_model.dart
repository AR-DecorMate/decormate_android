import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String caption;
  final String imageUrl;
  final int likesCount;
  final List<String> likedBy;
  final int commentsCount;
  final DateTime createdAt;
  final String? source;

  const PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.caption,
    required this.imageUrl,
    this.likesCount = 0,
    this.likedBy = const [],
    this.commentsCount = 0,
    required this.createdAt,
    this.source,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PostModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? 'User',
      userAvatarUrl: data['user_avatar_url'],
      caption: data['caption'] ?? '',
      imageUrl: data['image_url'] ?? '',
      likesCount: data['likes_count'] ?? 0,
      likedBy: List<String>.from(data['liked_by'] ?? []),
      commentsCount: data['comments_count'] ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      source: data['source'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'user_name': userName,
      if (userAvatarUrl != null) 'user_avatar_url': userAvatarUrl,
      'caption': caption,
      'image_url': imageUrl,
      'likes_count': likesCount,
      'liked_by': likedBy,
      'comments_count': commentsCount,
      'created_at': Timestamp.fromDate(createdAt),
      if (source != null) 'source': source,
    };
  }

  bool isLikedBy(String uid) => likedBy.contains(uid);
}
