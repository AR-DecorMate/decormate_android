import 'dart:ui' as ui;
import 'package:camera/camera.dart';
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

  CameraController? _cameraController;
  bool _isCameraReady = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) {
      _currentItemId = widget.itemId;
    }
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) setState(() => _cameraError = 'Camera permission denied');
        return;
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = 'No camera found');
        return;
      }
      // Use back camera
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      if (mounted) setState(() => _cameraError = 'Camera error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
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

  Widget _buildCameraBackground() {
    if (_isCameraReady && _cameraController != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _cameraController!.value.previewSize?.height ?? 1,
            height: _cameraController!.value.previewSize?.width ?? 1,
            child: CameraPreview(_cameraController!),
          ),
        ),
      );
    }
    if (_cameraError != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
              const SizedBox(height: 12),
              Text(_cameraError!, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ),
      );
    }
    return Container(
      color: Colors.black,
      child: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
    );
  }

  Widget _buildNoModelScreen() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text("AR Space", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // CAMERA BACKGROUND
          _buildCameraBackground(),

          // OVERLAY HINT
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.view_in_ar, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    "Point your camera at a space",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Select furniture from below to place it in your room",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          // CAMERA BACKGROUND
          _buildCameraBackground(),

          // 3D MODEL VIEWER OVERLAY
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

          // PROMINENT AR CAMERA BUTTON
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tap the AR icon (cube) on the 3D viewer to open your camera and place this furniture in your room!'),
                      duration: Duration(seconds: 4),
                    ),
                  );
                },
                icon: const Icon(Icons.view_in_ar, size: 22),
                label: const Text('View in Your Room', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 6,
                ),
              ),
            ),
          ),

          // AI TIP BANNER
          if (_aiTip != null)
            Positioned(
              bottom: 80,
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
