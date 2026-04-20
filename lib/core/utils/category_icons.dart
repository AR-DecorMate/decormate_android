import 'package:flutter/material.dart';

class CategoryIcons {
  static IconData forCategory(String category) {
    switch (category) {
      case 'Sofa': return Icons.weekend;
      case 'Bed': return Icons.bed;
      case 'Table': return Icons.table_restaurant;
      case 'Chair': return Icons.chair;
      case 'Lamps': return Icons.light;
      case 'Frames': return Icons.crop_portrait;
      case 'Fan': return Icons.air;
      case 'Lights': return Icons.lightbulb;
      case 'Curtains': return Icons.curtains;
      case 'Washbasin': return Icons.wash;
      case 'Tap': return Icons.water_drop;
      case 'Windows': return Icons.window;
      case 'Decor': return Icons.spa;
      case 'Chandelier': return Icons.light_mode;
      default: return Icons.chair;
    }
  }
}
