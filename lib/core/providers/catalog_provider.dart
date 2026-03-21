import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/catalog_item_model.dart';
import 'user_provider.dart';

final catalogItemsProvider = FutureProvider.family<List<CatalogItem>, String>((ref, category) {
  return ref.watch(firestoreServiceProvider).getCatalogItems(category);
});

final catalogItemProvider = FutureProvider.family<CatalogItem?, String>((ref, itemId) {
  return ref.watch(firestoreServiceProvider).getCatalogItem(itemId);
});

final trendingItemsProvider = StreamProvider<List<CatalogItem>>((ref) {
  return ref.watch(firestoreServiceProvider).streamTrendingItems();
});
