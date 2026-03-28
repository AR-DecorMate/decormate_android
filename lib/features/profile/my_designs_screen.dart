import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_provider.dart';

final _myDesignsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).streamMyDesigns(user.uid);
});

class MyDesignsScreen extends ConsumerWidget {
  const MyDesignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final designsAsync = ref.watch(_myDesignsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("My Designs", style: TextStyle(color: AppColors.primaryPink)),
        centerTitle: true,
      ),
      body: designsAsync.when(
        data: (designs) {
          if (designs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.design_services, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No designs shared yet", style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: designs.length,
            itemBuilder: (_, i) {
              final design = designs[i];
              final imageUrl = (design['image_url'] as String?) ?? '';

              return ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, imageUrl, error) => Container(
                          color: AppColors.backgroundBeige,
                          child: const Icon(Icons.image, size: 40, color: AppColors.accent),
                        ),
                      )
                    else
                      Container(
                        color: AppColors.backgroundBeige,
                        child: const Icon(Icons.image, size: 40, color: AppColors.accent),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withAlpha(153)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          'AR Design',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
