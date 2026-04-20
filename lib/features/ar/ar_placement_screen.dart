import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../../app/constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/catalog_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/ar_placement_support_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/category_icons.dart';

class ArPlacementScreen extends ConsumerStatefulWidget {
  final String modelPath;
  final String itemName;

  const ArPlacementScreen({
    super.key,
    required this.modelPath,
    required this.itemName,
  });

  @override
  ConsumerState<ArPlacementScreen> createState() => _ArPlacementScreenState();
}

class _ArPlacementScreenState extends ConsumerState<ArPlacementScreen> {
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARAnchorManager? _arAnchorManager;

  final List<ARNode> _nodes = [];
  final List<ARAnchor> _anchors = [];
  bool _planeDetected = false;
  bool _isPlacing = false;
  bool _isSaving = false;
  ArPlacementSupport? _arPlacementSupport;

  // Multi-object: currently selected model to place
  late String _activeModelUrl;
  late String _activeItemName;
  bool _showCatalog = false;

  // Catalog state
  String _selectedCategory = 'Sofa';
  String _selectedStyle = 'All';

  static const _categories = [
    'Sofa', 'Bed', 'Table', 'Chair', 'Lamps', 'Frames', 'Fan',
    'Lights', 'Curtains', 'Washbasin', 'Tap', 'Windows', 'Decor', 'Chandelier',
  ];
  static const _styles = ['All', 'Casual', 'Luxury'];

  @override
  void initState() {
    super.initState();
    _activeModelUrl = widget.modelPath;
    _activeItemName = widget.itemName;
    _loadArPlacementSupport();
  }

  Future<void> _loadArPlacementSupport() async {
    final support = await ArPlacementSupportService.getSupport();
    if (!mounted) return;
    setState(() => _arPlacementSupport = support);
  }

  @override
  void dispose() {
    _arSessionManager?.dispose();
    super.dispose();
  }

  String get _providerKey {
    if (_selectedStyle == 'All') return _selectedCategory;
    return '$_selectedCategory|${_selectedStyle.toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final support = _arPlacementSupport;
    if (support == null) {
      return _buildCompatibilityLoadingScreen();
    }
    if (!support.isSupported) {
      return _buildUnsupportedScreen(support.message ?? 'This device cannot start the AR placement experience.');
    }

    return Scaffold(
      body: Stack(
        children: [
          // AR View
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontal,
          ),

            // Top bar
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          _activeItemName,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Screenshot button
                      IconButton(
                        icon: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                        onPressed: _isSaving ? null : _takeScreenshot,
                        tooltip: 'Screenshot',
                      ),
                      // Remove all button
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
                        onPressed: _removeAll,
                        tooltip: 'Remove all',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Loading overlay while model downloads
            if (_isPlacing)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          SizedBox(height: 12),
                          Text('Downloading & placing model...', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Instruction banners
            if (!_isPlacing && !_planeDetected)
              _buildBanner(
                icon: Icons.phone_android,
                text: 'Move your phone slowly to detect surfaces',
                color: Colors.black.withOpacity(0.6),
              ),

            if (!_isPlacing && _planeDetected && _nodes.isEmpty)
              _buildBanner(
                icon: Icons.touch_app,
                text: 'Tap on a surface to place $_activeItemName',
                color: AppColors.accent.withOpacity(0.85),
              ),

            if (!_isPlacing && _nodes.isNotEmpty && !_showCatalog)
              _buildBanner(
                icon: Icons.check_circle,
                text: '${_nodes.length} item${_nodes.length > 1 ? "s" : ""} placed. Tap + to add more',
                color: Colors.green.withOpacity(0.7),
              ),

            // Bottom action buttons
            Positioned(
              bottom: _showCatalog ? 280 : 24,
              left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Add more items button
                  _circleButton(
                    icon: Icons.add,
                    label: 'Add',
                    onTap: () => setState(() => _showCatalog = !_showCatalog),
                    highlighted: _showCatalog,
                  ),
                  const SizedBox(width: 16),
                  // Undo last
                  if (_nodes.isNotEmpty)
                    _circleButton(
                      icon: Icons.undo,
                      label: 'Undo',
                      onTap: _removeLast,
                    ),
                ],
              ),
            ),

            // Bottom catalog sheet for multi-object
            if (_showCatalog)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: _buildCatalogPicker(),
              ),
          ],
        ),
      );
  }

  Widget _buildBanner({required IconData icon, required String text, required Color color}) {
    return Positioned(
      bottom: _showCatalog ? 340 : 80,
      left: 24, right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required String label, required VoidCallback onTap, bool highlighted = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: highlighted ? AppColors.accent : Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, shadows: [Shadow(blurRadius: 4, color: Colors.black)])),
      ],
    );
  }

  Widget _buildCatalogPicker() {
    final itemsAsync = ref.watch(catalogItemsProvider(_providerKey));

    return Container(
      height: 270,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(
        children: [
          // Drag handle + close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Text('Select furniture to place', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showCatalog = false),
                  child: const Icon(Icons.close, size: 20, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Category chips
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : AppColors.darkText, fontSize: 10)),
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

          // Style toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _styles.map((style) {
                final isSelected = style == _selectedStyle;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(style, style: TextStyle(color: isSelected ? Colors.white : AppColors.darkText, fontSize: 10, fontWeight: FontWeight.w600)),
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

          // Items grid
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('No items', style: TextStyle(color: Colors.grey, fontSize: 12)));
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final hasModel = item.modelUrl.isNotEmpty;
                    final isActive = item.modelUrl == _activeModelUrl;
                    return GestureDetector(
                      onTap: () {
                        if (hasModel) {
                          setState(() {
                            _activeModelUrl = item.modelUrl;
                            _activeItemName = item.name;
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('3D model coming soon!'), duration: Duration(seconds: 1)),
                          );
                        }
                      },
                      child: Container(
                        width: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: isActive ? Border.all(color: AppColors.accent, width: 2) : Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundBeige,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CategoryIcons.forCategory(item.category),
                                        color: hasModel ? AppColors.accent : Colors.grey.shade400,
                                        size: 24,
                                      ),
                                      if (!hasModel)
                                        Text('Soon', style: TextStyle(fontSize: 8, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                                      if (hasModel)
                                        const Icon(Icons.view_in_ar, size: 10, color: AppColors.primaryPink),
                                    ],
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
                                style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: hasModel ? AppColors.darkText : Colors.grey),
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
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(fontSize: 11))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityLoadingScreen() {
    return Scaffold(
      appBar: AppBar(title: Text(widget.itemName)),
      body: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
    );
  }

  Widget _buildUnsupportedScreen(String message) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.itemName)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_android, size: 48, color: Colors.orange.shade800),
                const SizedBox(height: 16),
                const Text('AR placement is unavailable', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.5)),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.pop(),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                  child: const Text('Back to 3D Preview'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    _arSessionManager = arSessionManager;
    _arObjectManager = arObjectManager;
    _arAnchorManager = arAnchorManager;
    _arSessionManager!.onPlaneOrPointTap = _onPlaneOrPointTapped;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      _arSessionManager?.onInitialize(
        showFeaturePoints: false,
        showPlanes: true,
        showWorldOrigin: false,
        handlePans: true,
        handleRotation: true,
      );
      _arObjectManager?.onInitialize();

      // Auto-detect plane after a delay
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && !_planeDetected) {
          setState(() => _planeDetected = true);
        }
      });
    });
  }

  Future<void> _onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    if (_arAnchorManager == null || _arObjectManager == null) return;
    if (_activeModelUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a furniture item first'), duration: Duration(seconds: 1)),
        );
      }
      return;
    }

    // Only use plane hits - point hits crash ARPlaneAnchor
    final planeHit = hitTestResults.where((hit) => hit.type == ARHitTestResultType.plane);
    if (planeHit.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No flat surface here. Try tapping on the floor.'), duration: Duration(seconds: 2)),
        );
      }
      return;
    }

    if (!_planeDetected && mounted) {
      setState(() => _planeDetected = true);
    }

    // Prevent double-tap while loading
    if (_isPlacing) return;
    setState(() => _isPlacing = true);

    // Show loading toast immediately
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading 3D model...'), duration: Duration(seconds: 10)),
      );
    }

    try {
      final hit = planeHit.first;
      final newAnchor = ARPlaneAnchor(transformation: hit.worldTransform);
      final didAddAnchor = await _arAnchorManager!.addAnchor(newAnchor);
      if (didAddAnchor != true) {
        if (mounted) setState(() => _isPlacing = false);
        return;
      }

      _anchors.add(newAnchor);

      final NodeType nodeType;
      final String uri;
      if (_activeModelUrl.startsWith('http')) {
        nodeType = NodeType.webGLB;
        uri = _activeModelUrl;
      } else {
        nodeType = NodeType.localGLTF2;
        uri = _activeModelUrl;
      }

      final newNode = ARNode(
        type: nodeType,
        uri: uri,
        scale: vm.Vector3(0.5, 0.5, 0.5),
        position: vm.Vector3(0.0, 0.0, 0.0),
        rotation: vm.Vector4(1.0, 0.0, 0.0, 0.0),
      );

      final didAddNode = await _arObjectManager!.addNode(newNode, planeAnchor: newAnchor);
      if (didAddNode == true) {
        _nodes.add(newNode);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_activeItemName} placed!'), duration: const Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  Future<void> _removeLast() async {
    if (_anchors.isEmpty || _arAnchorManager == null) return;
    await _arAnchorManager!.removeAnchor(_anchors.last);
    _anchors.removeLast();
    _nodes.removeLast();
    if (mounted) setState(() {});
  }

  Future<void> _removeAll() async {
    if (_arAnchorManager == null) return;
    for (final anchor in _anchors) {
      await _arAnchorManager!.removeAnchor(anchor);
    }
    _anchors.clear();
    _nodes.clear();
    if (mounted) setState(() {});
  }

  Future<void> _takeScreenshot() async {
    if (_arSessionManager == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      // ar_flutter_plugin snapshot() returns an ImageProvider
      final imageProvider = await _arSessionManager!.snapshot();

      // Resolve ImageProvider → raw PNG bytes
      final completer = Completer<Uint8List>();
      final stream = imageProvider.resolve(const ImageConfiguration());
      late ImageStreamListener listener;
      listener = ImageStreamListener((info, _) async {
        try {
          final byteData = await info.image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null && !completer.isCompleted) {
            completer.complete(byteData.buffer.asUint8List());
          }
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
        stream.removeListener(listener);
      }, onError: (e, _) {
        if (!completer.isCompleted) completer.completeError(e);
        stream.removeListener(listener);
      });
      stream.addListener(listener);

      final bytes = await completer.future.timeout(const Duration(seconds: 10));

      // Save to gallery
      final status = await Permission.storage.request();
      if (status.isGranted || status.isLimited) {
        await ImageGallerySaverPlus.saveImage(
          bytes,
          quality: 100,
          name: 'DecorMate_AR_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // Upload + save to My Designs in Firestore
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final url = await StorageService().uploadArScreenshotBytes(user.uid, bytes);
        await ref.read(firestoreServiceProvider).saveMyDesign(user.uid, url);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to gallery & My Designs!'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Screenshot failed: $e'), duration: const Duration(seconds: 2)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
