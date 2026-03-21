import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/constants.dart';
import '../../core/models/catalog_item_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/catalog_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/ai_prompts.dart';
import 'widgets/ar_catalog_sheet.dart';

class ArSpaceScreen extends ConsumerStatefulWidget {
  final String? itemId;
  const ArSpaceScreen({super.key, this.itemId});

  @override
  ConsumerState<ArSpaceScreen> createState() => _ArSpaceScreenState();
}

class _ArSpaceScreenState extends ConsumerState<ArSpaceScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  String? _currentModelUrl;
  String? _currentItemName;
  String? _currentItemId;
  bool _isSaving = false;
  String? _aiTip;

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) {
      _currentItemId = widget.itemId;
    }
  }

  void _selectItem(CatalogItem item) {
    setState(() {
      _currentModelUrl = item.modelUrl;
      _currentItemName = item.name;
      _currentItemId = item.id;
      _aiTip = null;
    });
    _fetchAiTip(item.name);
  }

  Future<void> _fetchAiTip(String itemName) async {
    final aiService = AiService();
    if (!aiService.isAvailable) return;
    try {
      final tip = await aiService.sendMessage(AiPrompts.contextualTip(itemName));
      if (mounted) {
        setState(() => _aiTip = tip);
      }
    } catch (_) {}
  }

  Future<void> _takeScreenshot() async {
    setState(() => _isSaving = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not capture screenshot')),
          );
        }
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      // Save to gallery
      final status = await Permission.storage.request();
      if (status.isGranted || status.isLimited) {
        await ImageGallerySaverPlus.saveImage(bytes, quality: 100, name: 'DecorMate_AR_${DateTime.now().millisecondsSinceEpoch}');
      }

      // Upload to Firebase and save to Firestore
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final url = await StorageService().uploadArScreenshotBytes(user.uid, bytes);
        await ref.read(firestoreServiceProvider).saveMyDesign(user.uid, url);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Screenshot saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If an itemId was provided and we haven't loaded it yet, fetch it
    if (widget.itemId != null && _currentModelUrl == null) {
      final itemAsync = ref.watch(catalogItemProvider(widget.itemId!));
      return itemAsync.when(
        data: (item) {
          if (item == null || item.modelUrl.isEmpty) {
            return _buildNoModelScreen();
          }
          // Set state once loaded
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_currentModelUrl == null && mounted) {
              setState(() {
                _currentModelUrl = item.modelUrl;
                _currentItemName = item.name;
                _currentItemId = item.id;
              });
              _fetchAiTip(item.name);
            }
          });
          return _buildArViewer(context, item.modelUrl, item.name);
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
        ),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      );
    }

    if (_currentModelUrl != null && _currentModelUrl!.isNotEmpty) {
      return _buildArViewer(context, _currentModelUrl!, _currentItemName ?? 'Model');
    }

    return _buildNoModelScreen();
  }

  Widget _buildNoModelScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkText),
          onPressed: () => context.pop(),
        ),
        title: const Text("AR Space", style: TextStyle(color: AppColors.primaryPink)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: AppColors.backgroundBeige,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.view_in_ar, size: 64, color: AppColors.accent),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "AR Visualizer",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkText),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Select a furniture item from the catalog below to view it in augmented reality",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          ArCatalogSheet(
            selectedItemId: _currentItemId,
            onItemSelected: _selectItem,
          ),
        ],
      ),
    );
  }

  Widget _buildArViewer(BuildContext context, String modelUrl, String name) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: _isSaving ? null : _takeScreenshot,
            tooltip: 'Take Screenshot',
          ),
        ],
      ),
      body: Stack(
        children: [
          RepaintBoundary(
            key: _repaintKey,
            child: ModelViewer(
              src: modelUrl,
              alt: name,
              ar: true,
              arModes: const ['scene-viewer', 'webxr', 'quick-look'],
              autoRotate: true,
              cameraControls: true,
              disableZoom: false,
              backgroundColor: Colors.transparent,
            ),
          ),

          // AI TIP BANNER
          if (_aiTip != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _AiTipBanner(
                tip: _aiTip!,
                onDismiss: () => setState(() => _aiTip = null),
              ),
            ),

          // CATALOG SHEET
          ArCatalogSheet(
            selectedItemId: _currentItemId,
            onItemSelected: _selectItem,
          ),
        ],
      ),
    );
  }
}

class _AiTipBanner extends StatelessWidget {
  final String tip;
  final VoidCallback onDismiss;
  const _AiTipBanner({required this.tip, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }
}
