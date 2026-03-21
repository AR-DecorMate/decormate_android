import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_design_model.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

final savedDesignsProvider = StreamProvider<List<SavedDesign>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).streamSavedDesigns(user.uid);
});

final isItemSavedProvider = FutureProvider.family<bool, String>((ref, itemId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value(false);
  return ref.watch(firestoreServiceProvider).isItemSaved(user.uid, itemId);
});
