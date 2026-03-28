import 'package:cloud_firestore/cloud_firestore.dart';

class CatalogItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final String style; // 'casual' or 'luxury'
  final String thumbnailUrl;
  final String modelUrl;
  final Map<String, double> dimensions;
  final DateTime? createdAt;
  final bool isTrending;

  const CatalogItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.thumbnailUrl,
    this.style = 'casual',
    this.modelUrl = '',
    this.dimensions = const {},
    this.createdAt,
    this.isTrending = false,
  });

  factory CatalogItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CatalogItem(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      style: data['style'] ?? 'casual',
      thumbnailUrl: data['thumbnail_url'] ?? '',
      modelUrl: data['model_url'] ?? '',
      dimensions: data['dimensions'] is Map
          ? Map<String, double>.from(
              (data['dimensions'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())))
          : {},
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      isTrending: data['is_trending'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'style': style,
      'thumbnail_url': thumbnailUrl,
      'model_url': modelUrl,
      'dimensions': dimensions,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'is_trending': isTrending,
    };
  }
}
