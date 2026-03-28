import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/catalog_item_model.dart';
import 'user_provider.dart';

/// Query key: "category" or "category|style"
final catalogItemsProvider = FutureProvider.family<List<CatalogItem>, String>((ref, key) {
  final parts = key.split('|');
  final category = parts[0];
  final style = parts.length > 1 ? parts[1] : null;
  return ref.watch(firestoreServiceProvider).getCatalogItems(category, style: style);
});

final catalogItemProvider = FutureProvider.family<CatalogItem?, String>((ref, itemId) {
  return ref.watch(firestoreServiceProvider).getCatalogItem(itemId);
});

final trendingItemsProvider = StreamProvider<List<CatalogItem>>((ref) {
  return ref.watch(firestoreServiceProvider).streamTrendingItems();
});
