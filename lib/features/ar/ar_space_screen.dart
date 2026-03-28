import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  bool _aiLoading = false;

  void _selectItem(CatalogItem item) {
    setState(() {
      _currentModelUrl = item.modelUrl;
      _currentItemName = item.name;
      _currentItemId = item.id;
      _aiTip = null;
    });
  }

  Future<void> _fetchAiTip(String itemName) async {
    final aiService = AiService();
    if (!aiService.isAvailable) return;
    setState(() => _aiLoading = true);
    try {
      var tip = await aiService.sendMessage(AiPrompts.contextualTip(itemName));
      // Strip markdown formatting
      tip = tip
          .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
          .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
          .replaceAll(RegExp(r'#{1,6}\s'), '')
          .replaceAll(RegExp(r'`(.+?)`'), r'$1');
      if (mounted) {
        setState(() { _aiTip = tip; _aiLoading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _aiLoading = false);
    }
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
              // Don't auto-trigger AI
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
    // Fallback: gradient background when camera isn't available
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
      ),
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
          _buildCameraBackground(),
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
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkText),
          onPressed: () => context.pop(),
        ),
        title: Text(name, style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                : const Icon(Icons.camera_alt, color: AppColors.darkText),
            onPressed: _isSaving ? null : _takeScreenshot,
            tooltip: 'Take Screenshot',
          ),
        ],
      ),
      body: Column(
        children: [
          // 3D MODEL VIEWER — takes upper portion, no gesture conflict
          Expanded(
            flex: 3,
            child: RepaintBoundary(
              key: _repaintKey,
              child: ModelViewer(
                src: modelUrl,
                alt: name,
                ar: true,
                arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                autoRotate: true,
                cameraControls: true,
                disableZoom: false,
                backgroundColor: const Color(0xFFF5F0EB),
              ),
            ),
          ),

          // AI TIP BANNER or ASK AI BUTTON
          if (_aiTip != null)
            _AiTipBanner(
              tip: _aiTip!,
              onDismiss: () => setState(() => _aiTip = null),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _aiLoading || _currentItemName == null
                      ? null
                      : () => _fetchAiTip(_currentItemName!),
                  icon: _aiLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_aiLoading ? 'Thinking...' : 'Ask AI about this piece'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),

          // CATALOG SECTION — bottom portion, fully scrollable
          Expanded(
            flex: 2,
            child: _BottomCatalog(
              selectedItemId: _currentItemId,
              onItemSelected: _selectItem,
            ),
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

class _BottomCatalog extends ConsumerStatefulWidget {
  final String? selectedItemId;
  final ValueChanged<CatalogItem> onItemSelected;

  const _BottomCatalog({
    this.selectedItemId,
    required this.onItemSelected,
  });

  @override
  ConsumerState<_BottomCatalog> createState() => _BottomCatalogState();
}

class _BottomCatalogState extends ConsumerState<_BottomCatalog> {
  String _selectedCategory = 'Sofa';
  String _selectedStyle = 'All';

  static const _categories = [
    'Sofa', 'Bed', 'Table', 'Chair', 'Lamps', 'Frames', 'Fan',
    'Lights', 'Curtains', 'Washbasin', 'Tap', 'Windows', 'Decor', 'Chandelier',
  ];

  static const _styles = ['All', 'Casual', 'Luxury'];

  String get _providerKey {
    if (_selectedStyle == 'All') return _selectedCategory;
    return '$_selectedCategory|${_selectedStyle.toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(catalogItemsProvider(_providerKey));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(
        children: [
          // DRAG HANDLE
          Container(
            width: 40, height: 5,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // CATEGORY CHIPS
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat, style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.darkText,
                    fontSize: 11,
                  )),
                  selected: isSelected,
                  selectedColor: AppColors.accent,
                  backgroundColor: AppColors.backgroundBeige,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
          const SizedBox(height: 4),

          // STYLE TOGGLE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _styles.map((style) {
                final isSelected = style == _selectedStyle;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(style, style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.darkText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    )),
                    selected: isSelected,
                    selectedColor: AppColors.primaryPink,
                    backgroundColor: Colors.grey.shade100,
                    onSelected: (_) => setState(() => _selectedStyle = style),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),

          // ITEMS GRID
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No items in this category', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final isActive = item.id == widget.selectedItemId;
                    final hasModel = item.modelUrl.isNotEmpty;
                    return GestureDetector(
                      onTap: () {
                        if (hasModel) {
                          widget.onItemSelected(item);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Model coming soon!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: isActive
                              ? Border.all(color: AppColors.accent, width: 2)
                              : Border.all(color: Colors.grey.shade200),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                    child: Container(
                                      color: AppColors.backgroundBeige,
                                      width: double.infinity,
                                      child: Icon(
                                        hasModel ? Icons.view_in_ar : Icons.chair,
                                        color: hasModel ? AppColors.accent : Colors.grey.shade400,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                      color: hasModel ? AppColors.darkText : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!hasModel)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Soon',
                                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                                  ),
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
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(fontSize: 12))),
            ),
          ),
        ],
      ),
    );
  }
}
