import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/saved_designs_provider.dart';

class SavedDesignsScreen extends ConsumerWidget {
  const SavedDesignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedDesignsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 35),
              const Center(
                child: Text(
                  "Saved Designs",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.accent),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: savedAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "No Designs Saved yet",
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Browse categories and save items you love",
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return GestureDetector(
                          onTap: () => context.push('/item/${item.itemId}'),
                          onLongPress: () {
                            _showDeleteDialog(context, ref, item.itemId);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                    child: item.thumbnailUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: item.thumbnailUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            placeholder: (_, __) => Container(
                                              color: AppColors.backgroundBeige,
                                              child: const Center(
                                                  child: CircularProgressIndicator(color: AppColors.accent)),
                                            ),
                                            errorWidget: (_, __, ___) => Container(
                                              color: AppColors.backgroundBeige,
                                              child: const Icon(Icons.image, color: AppColors.accent, size: 40),
                                            ),
                                          )
                                        : Container(
                                            color: AppColors.backgroundBeige,
                                            child: const Center(
                                              child: Icon(Icons.image, color: AppColors.accent, size: 40),
                                            ),
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppColors.darkText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryPink.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                item.category,
                                                style: const TextStyle(fontSize: 11, color: AppColors.accent),
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => context.push('/create-post?imageUrl=${Uri.encodeComponent(item.thumbnailUrl)}'),
                                            child: const Icon(Icons.share, size: 18, color: AppColors.accent),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String itemId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Saved?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                final item = await ref.read(firestoreServiceProvider).getCatalogItem(itemId);
                if (item != null) {
                  await ref.read(firestoreServiceProvider).toggleSaveDesign(user.uid, item);
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
