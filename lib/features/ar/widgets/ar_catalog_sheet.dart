import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/constants.dart';
import '../../../core/models/catalog_item_model.dart';
import '../../../core/providers/catalog_provider.dart';

class ArCatalogSheet extends ConsumerStatefulWidget {
  final String? selectedItemId;
  final ValueChanged<CatalogItem> onItemSelected;

  const ArCatalogSheet({
    super.key,
    this.selectedItemId,
    required this.onItemSelected,
  });

  @override
  ConsumerState<ArCatalogSheet> createState() => _ArCatalogSheetState();
}

class _ArCatalogSheetState extends ConsumerState<ArCatalogSheet> {
  String _selectedCategory = 'Sofa';
  String _selectedStyle = 'All'; // 'All', 'Casual', 'Luxury'

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

    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.08,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Column(
            children: [
              // DRAG HANDLE
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),

              // CATEGORY CHIPS
              SizedBox(
                height: 40,
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
                        fontSize: 12,
                      )),
                      selected: isSelected,
                      selectedColor: AppColors.accent,
                      backgroundColor: AppColors.backgroundBeige,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),

              // STYLE TOGGLE (Casual / Luxury)
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
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        )),
                        selected: isSelected,
                        selectedColor: AppColors.primaryPink,
                        backgroundColor: Colors.grey.shade100,
                        onSelected: (_) => setState(() => _selectedStyle = style),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // ITEMS GRID
              Expanded(
                child: itemsAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(
                        child: Text('No items in this category', style: TextStyle(color: Colors.grey)),
                      );
                    }
                    return GridView.builder(
                      controller: scrollController,
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
                                            size: 28,
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
                                          fontSize: 11,
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
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
