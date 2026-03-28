import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/catalog_provider.dart';
import '../../core/providers/saved_designs_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../shared/widgets/ai_chat_fab.dart';

class ItemDetailScreen extends ConsumerWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(catalogItemProvider(itemId));
    final isSavedAsync = ref.watch(isItemSavedProvider(itemId));

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: AiChatFab(contextItemName: itemAsync.valueOrNull?.name),
      body: itemAsync.when(
        data: (item) {
          if (item == null) {
            return const Center(child: Text("Item not found"));
          }
          final isSaved = isSavedAsync.valueOrNull ?? false;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: Colors.white,
                leading: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: AppColors.darkText, size: 20),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () {
                      final user = ref.read(currentUserProvider);
                      if (user != null) {
                        ref.read(firestoreServiceProvider).toggleSaveDesign(user.uid, item);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? AppColors.accent : AppColors.darkText,
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: CachedNetworkImage(
                    imageUrl: item.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.backgroundBeige,
                      child: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.backgroundBeige,
                      child: const Icon(Icons.chair, size: 64, color: AppColors.accent),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkText),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: item.style == 'luxury'
                                  ? Colors.amber.shade50
                                  : AppColors.backgroundBeige,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.style == 'luxury' ? '✨ Luxury' : '🪑 Casual',
                              style: TextStyle(
                                color: item.style == 'luxury' ? Colors.amber.shade800 : AppColors.darkText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPink.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(item.category, style: const TextStyle(color: AppColors.accent, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item.description,
                        style: const TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
                      ),
                      if (item.dimensions.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _infoRow(Icons.straighten, "Dimensions", item.dimensions.entries.map((e) => '${e.key}: ${e.value}').join(', ')),
                      ],
                      const SizedBox(height: 30),

                      // AR BUTTON
                      if (item.modelUrl.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/ar-space?itemId=${item.id}'),
                            icon: const Icon(Icons.view_in_ar),
                            label: const Text("View in AR", style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.button),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final user = ref.read(currentUserProvider);
                            if (user != null) {
                              ref.read(firestoreServiceProvider).toggleSaveDesign(user.uid, item);
                            }
                          },
                          icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                          label: Text(isSaved ? "Saved" : "Save Design", style: const TextStyle(fontSize: 16)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: const BorderSide(color: AppColors.accent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.button),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkText)),
        Text(value, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
