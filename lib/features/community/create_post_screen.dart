import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/storage_service.dart';
import '../../core/models/post_model.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  /// Pre-existing image URL (e.g. from a saved design or AR screenshot).
  final String? preImageUrl;
  const CreatePostScreen({super.key, this.preImageUrl});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionController = TextEditingController();
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1200, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _createPost() async {
    if (_imageBytes == null && widget.preImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (user == null) return;

      String imageUrl;
      if (widget.preImageUrl != null) {
        imageUrl = widget.preImageUrl!;
      } else {
        final postId = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await StorageService().uploadPostImage(postId, _imageBytes!);
      }

      await ref.read(firestoreServiceProvider).createPost(PostModel(
        id: '',
        userId: user.uid,
        userName: profile?.name ?? user.displayName ?? 'User',
        userAvatarUrl: (profile?.avatarUrl?.isNotEmpty ?? false) ? profile!.avatarUrl : user.photoURL,
        caption: _captionController.text.trim(),
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      ));

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.darkText),
          onPressed: () => context.pop(),
        ),
        title: const Text("New Post", style: TextStyle(color: AppColors.primaryPink)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("Post", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // IMAGE PICKER
            GestureDetector(
              onTap: () => _showImageSourceDialog(),
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.backgroundBeige,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  image: _imageBytes != null
                      ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                      : widget.preImageUrl != null
                          ? DecorationImage(image: NetworkImage(widget.preImageUrl!), fit: BoxFit.cover)
                          : null,
                ),
                child: _imageBytes == null && widget.preImageUrl == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 48, color: AppColors.accent),
                          SizedBox(height: 8),
                          Text("Tap to select an image", style: TextStyle(color: AppColors.accent)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // CAPTION
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Write a caption...",
                hintStyle: const TextStyle(color: AppColors.hintColor),
                filled: true,
                fillColor: AppColors.backgroundBeige,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}
