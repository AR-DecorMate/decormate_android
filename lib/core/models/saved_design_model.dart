import 'package:cloud_firestore/cloud_firestore.dart';

class SavedDesign {
  final String itemId;
  final String category;
  final String name;
  final String thumbnailUrl;
  final DateTime savedAt;

  const SavedDesign({
    required this.itemId,
    required this.category,
    required this.name,
    required this.thumbnailUrl,
    required this.savedAt,
  });

  factory SavedDesign.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SavedDesign(
      itemId: doc.id,
      category: data['category'] ?? '',
      name: data['name'] ?? '',
      thumbnailUrl: data['thumbnail_url'] ?? '',
      savedAt: (data['saved_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'category': category,
      'name': name,
      'thumbnail_url': thumbnailUrl,
      'saved_at': Timestamp.fromDate(savedAt),
    };
  }
}
