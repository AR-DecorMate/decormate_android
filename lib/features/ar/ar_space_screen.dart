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
import '../../core/services/ar_placement_support_service.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/ai_prompts.dart';
import '../../core/utils/category_icons.dart';

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
  bool _aiLoading = false;

  // Catalog state - kept in parent so it survives model switches
  String _selectedCategory = 'Sofa';
  String _selectedStyle = 'All';

  ArPlacementSupport? _arPlacementSupport;

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) {
      _currentItemId = widget.itemId;
    }
    _loadArPlacementSupport();
  }

  Future<void> _loadArPlacementSupport() async {
    final support = await ArPlacementSupportService.getSupport();
    if (mounted) setState(() => _arPlacementSupport = support);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _selectItem(CatalogItem item) {
    setState(() {
      _currentModelUrl = item.modelUrl;
      _currentItemName = item.name;
      _currentItemId = item.id;
      _aiTip = null;
    });
  }

  Future<void> _handlePlaceInRoom(String modelUrl, String name) async {
    if (_arPlacementSupport == null) {
      await _loadArPlacementSupport();
      if (!mounted) return;
    }

    final support = _arPlacementSupport;
    if (support == null || !support.isSupported) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AR Placement Unavailable'),
          content: Text(support?.message ?? 'This device cannot start AR placement.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    await context.push(
      Uri(path: '/ar-placement', queryParameters: {'model': modelUrl, 'name': name}).toString(),
    );
  }

  Future<void> _fetchAiTip(String itemName) async {
    final aiService = AiService();
    if (!aiService.isAvailable) return;
    setState(() => _aiLoading = true);
    try {
      var tip = await aiService.sendMessage(AiPrompts.contextualTip(itemName));
      tip = AiPrompts.cleanResponse(tip);
      if (mounted) setState(() { _aiTip = tip; _aiLoading = false; });
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

      final status = await Permission.storage.request();
      if (status.isGranted || status.isLimited) {
        await ImageGallerySaverPlus.saveImage(bytes, quality: 100, name: 'DecorMate_AR_${DateTime.now().millisecondsSinceEpoch}');
      }

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
    // Load initial item if provided via query param
    if (widget.itemId != null && _currentModelUrl == null) {
      final itemAsync = ref.watch(catalogItemProvider(widget.itemId!));
      return itemAsync.when(
        data: (item) {
          if (item != null && item.modelUrl.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_currentModelUrl == null && mounted) {
                setState(() {
                  _currentModelUrl = item.modelUrl;
                  _currentItemName = item.name;
                  _currentItemId = item.id;
                  _selectedCategory = item.category;
                });
              }
            });
          }
          return _buildMainLayout();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
        ),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      );
    }

    return _buildMainLayout();
  }

  Widget _buildMainLayout() {
    final hasModel = _currentModelUrl != null && _currentModelUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: hasModel ? const Color(0xFFF5F0EB) : Colors.black,
      appBar: AppBar(
        backgroundColor: hasModel ? Colors.white : Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: hasModel ? AppColors.darkText : Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _currentItemName ?? "AR Space",
          style: TextStyle(
            color: hasModel ? AppColors.primaryPink : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: hasModel
            ? [
                IconButton(
                  icon: _arPlacementSupport == null
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                      : Icon(Icons.view_in_ar, color: _arPlacementSupport!.isSupported ? AppColors.accent : Colors.grey),
                  onPressed: _arPlacementSupport == null ? null : () => _handlePlaceInRoom(_currentModelUrl!, _currentItemName!),
                  tooltip: 'Place in Room',
                ),
                IconButton(
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                      : const Icon(Icons.camera_alt, color: AppColors.darkText),
                  onPressed: _isSaving ? null : _takeScreenshot,
                  tooltip: 'Take Screenshot',
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          // TOP: Model viewer or placeholder
          Expanded(
            flex: 3,
            child: hasModel
                ? RepaintBoundary(
                    key: _repaintKey,
                    child: ModelViewer(
                      // Key forces WebView rebuild when model changes
                      key: ValueKey(_currentModelUrl),
                      src: _currentModelUrl!,
                      alt: _currentItemName ?? 'Model',
                      ar: false,
                      autoRotate: true,
                      cameraControls: true,
                      disableZoom: false,
                      backgroundColor: const Color(0xFFF5F0EB),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.view_in_ar, size: 48, color: Colors.white),
                          SizedBox(height: 12),
                          Text("Select furniture below", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 8),
                          Text("Tap an item to preview its 3D model", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
          ),

          // AI TIP
          if (hasModel && _aiTip != null)
            _AiTipBanner(tip: _aiTip!, onDismiss: () => setState(() => _aiTip = null))
          else if (hasModel)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _aiLoading || _currentItemName == null ? null : () => _fetchAiTip(_currentItemName!),
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

          // BOTTOM: Catalog - ALWAYS shown, state preserved
          Expanded(
            flex: 2,
            child: _buildCatalog(),
          ),
        ],
      ),
    );
  }

  String get _providerKey {
    if (_selectedStyle == 'All') return _selectedCategory;
    return '$_selectedCategory|${_selectedStyle.toLowerCase()}';
  }

  static const _categories = [
    'Sofa', 'Bed', 'Table', 'Chair', 'Lamps', 'Frames', 'Fan',
    'Lights', 'Curtains', 'Washbasin', 'Tap', 'Windows', 'Decor', 'Chandelier',
  ];
  static const _styles = ['All', 'Casual', 'Luxury'];

  Widget _buildCatalog() {
    final itemsAsync = ref.watch(catalogItemsProvider(_providerKey));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            width: 40, height: 5,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
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
                  label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : AppColors.darkText, fontSize: 11)),
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

          // ITEMS GRID
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('No items in this category', style: TextStyle(color: Colors.grey, fontSize: 13)));
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, childAspectRatio: 0.85, crossAxisSpacing: 8, mainAxisSpacing: 8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final isActive = item.id == _currentItemId;
                    final hasModel = item.modelUrl.isNotEmpty;
                    return GestureDetector(
                      onTap: () {
                        if (hasModel) {
                          _selectItem(item);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Model coming soon!'), duration: Duration(seconds: 1)),
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: isActive ? Border.all(color: AppColors.accent, width: 2) : Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                child: Container(
                                  color: AppColors.backgroundBeige,
                                  width: double.infinity,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(CategoryIcons.forCategory(item.category), color: hasModel ? AppColors.accent : Colors.grey.shade400, size: 28),
                                      if (hasModel)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(Icons.view_in_ar, size: 10, color: AppColors.primaryPink),
                                        ),
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
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(fontSize: 12))),
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
            child: Text(tip, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
          GestureDetector(onTap: onDismiss, child: const Icon(Icons.close, color: Colors.white70, size: 18)),
        ],
      ),
    );
  }
}
