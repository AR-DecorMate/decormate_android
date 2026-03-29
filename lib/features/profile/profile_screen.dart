import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/saved_designs_provider.dart';
import '../../core/providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final savedDesignsAsync = ref.watch(savedDesignsProvider);
    final myDesignsAsync = ref.watch(myDesignsProvider);
    final likedPostsAsync = ref.watch(likedPostsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: userAsync.when(
            data: (user) {
              final designsCount = myDesignsAsync.maybeWhen(
                data: (designs) => designs.length.toString(),
                orElse: () => '...',
              );
              final savedCount = savedDesignsAsync.maybeWhen(
                data: (saved) => saved.length.toString(),
                orElse: () => '...',
              );
              final likesCount = likedPostsAsync.maybeWhen(
                data: (posts) => posts.length.toString(),
                orElse: () => '...',
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 35),
                    const Center(
                      child: Text(
                        "Profile",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.accent),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // AVATAR
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: AppColors.backgroundBeige,
                      backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(user.avatarUrl!)
                          : null,
                      child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                          ? Text(
                              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 40,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.darkText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // STATS ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statBox("Designs", designsCount),
                        _statBox("Saved", savedCount),
                        _statBox("Likes", likesCount),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // MENU ITEMS
                    _menuItem(context, Icons.edit, "Edit Profile", () => context.push('/profile/edit')),
                    _menuItem(context, Icons.design_services, "My Designs", () => context.push('/profile/my-designs')),
                    _menuItem(context, Icons.favorite_outline, "Liked Posts", () => context.push('/profile/liked-posts')),
                    _menuItem(context, Icons.settings, "Settings", () => context.push('/profile/settings')),
                    _menuItem(context, Icons.privacy_tip_outlined, "Privacy Policy", () => context.push('/profile/privacy')),
                    _menuItem(context, Icons.help_outline, "Help & Support", () => context.push('/profile/help')),

                    const SizedBox(height: 20),
                    _menuItem(context, Icons.logout, "Logout", () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/welcome');
                    }, isDestructive: true),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.accent)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDestructive ? Colors.red.withAlpha(13) : AppColors.backgroundBeige,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : AppColors.accent),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : AppColors.darkText,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: isDestructive ? Colors.red : Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
