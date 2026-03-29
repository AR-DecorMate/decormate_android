import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/models/post_model.dart';
import '../../core/models/comment_model.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 35),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Text(
                    "Community",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.accent),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.push('/create-post'),
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.accent, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: postsAsync.when(
                data: (posts) {
                  if (posts.isEmpty) {
                    return const Center(
                      child: Text("No posts yet. Be the first to share!", style: TextStyle(color: Colors.grey)),
                    );
                  }
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (context, index) => _PostCard(post: posts[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                error: (e, _) => Center(child: Text('Error loading posts: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final PostModel post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final currentUserProfile = ref.watch(userProfileProvider).valueOrNull;
    final isLiked = currentUser != null && post.isLikedBy(currentUser.uid);
    final displayUserName = currentUser != null &&
            currentUser.uid == post.userId &&
            currentUserProfile != null &&
            currentUserProfile.name.isNotEmpty
        ? currentUserProfile.name
        : post.userName;
    final displayUserAvatarUrl = currentUser != null &&
            currentUser.uid == post.userId &&
            (currentUserProfile?.avatarUrl?.isNotEmpty ?? false)
        ? currentUserProfile!.avatarUrl
        : post.userAvatarUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // USER INFO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.backgroundBeige,
                  backgroundImage: displayUserAvatarUrl != null && displayUserAvatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(displayUserAvatarUrl)
                      : null,
                  child: displayUserAvatarUrl == null || displayUserAvatarUrl.isEmpty
                      ? Text(
                          displayUserName.isNotEmpty ? displayUserName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 20),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  displayUserName,
                  style: const TextStyle(fontSize: 15, color: AppColors.darkText, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CachedNetworkImage(
              imageUrl: post.imageUrl,
              height: 260,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, imageUrl) => Container(
                height: 260,
                color: AppColors.backgroundBeige,
                child: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
              ),
              errorWidget: (context, imageUrl, error) => Container(
                height: 260,
                color: AppColors.backgroundBeige,
                child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 48),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // CAPTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              post.caption,
              style: const TextStyle(fontSize: 14, color: AppColors.darkText),
            ),
          ),

          const SizedBox(height: 12),

          // BUTTON ROW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? AppColors.accent : Colors.grey,
                    size: 30,
                  ),
                  onPressed: () {
                    if (currentUser == null) return;
                    ref.read(firestoreServiceProvider).toggleLike(post.id, currentUser.uid);
                  },
                ),
                Text("${post.likesCount}", style: const TextStyle(color: AppColors.darkText, fontSize: 14)),
                const SizedBox(width: 18),
                IconButton(
                  icon: const Icon(Icons.mode_comment_outlined, color: Colors.grey, size: 28),
                  onPressed: () => _openCommentsSheet(context, ref),
                ),
                Text("${post.commentsCount}", style: const TextStyle(color: AppColors.darkText, fontSize: 14)),
                const SizedBox(width: 18),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.grey, size: 28),
                  onPressed: () => Share.share("Check out this design on DecorMate!"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCommentsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      builder: (ctx) => _CommentsSheet(postId: post.id),
    );
  }
}

class _CommentsSheet extends ConsumerStatefulWidget {
  final String postId;
  const _CommentsSheet({required this.postId});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(currentUserProvider);
    final userProfile = ref.read(userProfileProvider).valueOrNull;
    if (currentUser == null) return;

    final commentUserName = userProfile?.name.isNotEmpty == true
        ? userProfile!.name
        : (currentUser.displayName ?? 'User');
    final commentUserAvatarUrl = userProfile?.avatarUrl?.isNotEmpty == true
        ? userProfile!.avatarUrl
        : currentUser.photoURL;

    await ref.read(firestoreServiceProvider).addComment(
      widget.postId,
      CommentModel(
        id: '',
        userId: currentUser.uid,
        userName: commentUserName,
        userAvatarUrl: commentUserAvatarUrl,
        text: text,
        createdAt: DateTime.now(),
      ),
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final currentUser = ref.watch(currentUserProvider);
    final currentUserProfile = ref.watch(userProfileProvider).valueOrNull;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: 500,
        child: Column(
          children: [
            const SizedBox(height: 14),
            Container(
              height: 5,
              width: 55,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(102),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),
            const Text("Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Expanded(
              child: commentsAsync.when(
                data: (comments) {
                  if (comments.isEmpty) {
                    return const Center(
                      child: Text("No comments yet. Be the first!", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    );
                  }
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (_, i) {
                      final c = comments[i];
                      final displayUserName = currentUser != null &&
                              currentUser.uid == c.userId &&
                              currentUserProfile != null &&
                              currentUserProfile.name.isNotEmpty
                          ? currentUserProfile.name
                          : c.userName;
                      final displayUserAvatarUrl = currentUser != null &&
                              currentUser.uid == c.userId &&
                              (currentUserProfile?.avatarUrl?.isNotEmpty ?? false)
                          ? currentUserProfile!.avatarUrl
                          : c.userAvatarUrl;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.backgroundBeige,
                          backgroundImage: displayUserAvatarUrl != null && displayUserAvatarUrl.isNotEmpty
                              ? CachedNetworkImageProvider(displayUserAvatarUrl)
                              : null,
                          child: displayUserAvatarUrl == null || displayUserAvatarUrl.isEmpty
                              ? Text(displayUserName.isNotEmpty ? displayUserName[0].toUpperCase() : '?',
                                  style: const TextStyle(color: AppColors.accent))
                              : null,
                        ),
                        title: Text(displayUserName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(c.text),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Write a comment...",
                        hintStyle: const TextStyle(color: AppColors.hintColor),
                        filled: true,
                        fillColor: AppColors.backgroundBeige,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.accent),
                    onPressed: _addComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
