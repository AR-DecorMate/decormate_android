import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

final postsProvider = StreamProvider<List<PostModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).streamPosts();
});

final commentsProvider = StreamProvider.family<List<CommentModel>, String>((ref, postId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).streamComments(postId);
});
