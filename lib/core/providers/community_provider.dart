import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'user_provider.dart';

final postsProvider = StreamProvider<List<PostModel>>((ref) {
  return ref.watch(firestoreServiceProvider).streamPosts();
});

final commentsProvider = StreamProvider.family<List<CommentModel>, String>((ref, postId) {
  return ref.watch(firestoreServiceProvider).streamComments(postId);
});
