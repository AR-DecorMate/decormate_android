import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String text;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CommentModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? 'User',
      userAvatarUrl: data['user_avatar_url'],
      text: data['text'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'user_name': userName,
      if (userAvatarUrl != null) 'user_avatar_url': userAvatarUrl,
      'text': text,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
