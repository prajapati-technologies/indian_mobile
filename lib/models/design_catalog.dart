import 'package:flutter/material.dart';

class DoorDesign {
  final String name;
  final IconData icon;
  final Color color;
  final double width;
  final String description;

  const DoorDesign({
    required this.name,
    required this.icon,
    required this.color,
    this.width = 40.0,
    this.description = '',
  });
}

class WindowDesign {
  final String name;
  final IconData icon;
  final Color color;
  final double width;
  final String description;

  const WindowDesign({
    required this.name,
    required this.icon,
    required this.color,
    this.width = 40.0,
    this.description = '',
  });
}

class FurnitureDesign {
  final String name;
  final IconData icon;
  final Color color;
  final double width;
  final double height;
  final double defaultScale;

  const FurnitureDesign({
    required this.name,
    required this.icon,
    required this.color,
    this.width = 60,
    this.height = 60,
    this.defaultScale = 1.0,
  });
}

class TextureDesign {
  final String name;
  final Color color;
  final Color borderColor;
  final IconData icon;

  const TextureDesign({
    required this.name,
    required this.color,
    required this.borderColor,
    required this.icon,
  });
}

class DesignCatalog {
  static const doors = [
    DoorDesign(name: 'Wooden', icon: Icons.door_front_door, color: Color(0xFF8B5E3C), width: 36, description: 'Classic wooden door'),
    DoorDesign(name: 'French', icon: Icons.door_sliding, color: Color(0xFFD4C5A9), width: 50, description: 'Glass panel door'),
    DoorDesign(name: 'Sliding', icon: Icons.door_sliding, color: Color(0xFF78909C), width: 56, description: 'Modern sliding door'),
    DoorDesign(name: 'Glass', icon: Icons.door_front_door, color: Color(0xFFB0BEC5), width: 40, description: 'Full glass door'),
    DoorDesign(name: 'Classic', icon: Icons.door_front_door, color: Color(0xFF5D4037), width: 38, description: 'Ornate classic door'),
    DoorDesign(name: 'Pvc', icon: Icons.door_front_door, color: Color(0xFFE0E0E0), width: 36, description: 'White PVC door'),
  ];

  static const windows = [
    WindowDesign(name: 'Casement', icon: Icons.window, color: Color(0xFF81D4FA), width: 40, description: 'Side-opening window'),
    WindowDesign(name: 'Sliding', icon: Icons.window, color: Color(0xFF4FC3F7), width: 56, description: 'Sliding window'),
    WindowDesign(name: 'Bay', icon: Icons.window, color: Color(0xFF29B6F6), width: 64, description: 'Bay window'),
    WindowDesign(name: 'Arched', icon: Icons.window, color: Color(0xFF039BE5), width: 40, description: 'Arched top window'),
    WindowDesign(name: 'Jalousie', icon: Icons.window, color: Color(0xFFB3E5FC), width: 48, description: 'Louvered window'),
  ];

  static const furnitureCategories = {
    'Sofa': [
      FurnitureDesign(name: '3-Seater', icon: Icons.weekend, color: Color(0xFF78909C), width: 100, height: 50, defaultScale: 1.5),
      FurnitureDesign(name: 'L-Shape', icon: Icons.weekend, color: Color(0xFF546E7A), width: 120, height: 60, defaultScale: 1.8),
      FurnitureDesign(name: 'Sofa Set', icon: Icons.weekend, color: Color(0xFF37474F), width: 140, height: 55, defaultScale: 2.0),
      FurnitureDesign(name: 'Recliner', icon: Icons.weekend, color: Color(0xFF8D6E63), width: 70, height: 50, defaultScale: 1.2),
    ],
    'Bed': [
      FurnitureDesign(name: 'Single', icon: Icons.bed, color: Color(0xFF90CAF9), width: 60, height: 90, defaultScale: 1.0),
      FurnitureDesign(name: 'Double', icon: Icons.bed, color: Color(0xFF64B5F6), width: 80, height: 90, defaultScale: 1.3),
      FurnitureDesign(name: 'Queen', icon: Icons.bed, color: Color(0xFF42A5F5), width: 90, height: 95, defaultScale: 1.5),
      FurnitureDesign(name: 'King', icon: Icons.bed, color: Color(0xFF2196F3), width: 100, height: 100, defaultScale: 1.7),
    ],
    'Table': [
      FurnitureDesign(name: 'Dining', icon: Icons.table_restaurant, color: Color(0xFFA1887F), width: 80, height: 50, defaultScale: 1.3),
      FurnitureDesign(name: 'Coffee', icon: Icons.table_restaurant, color: Color(0xFF8D6E63), width: 50, height: 35, defaultScale: 0.8),
      FurnitureDesign(name: 'Side', icon: Icons.table_restaurant, color: Color(0xFF6D4C41), width: 30, height: 30, defaultScale: 0.5),
      FurnitureDesign(name: 'Study', icon: Icons.table_restaurant, color: Color(0xFF5D4037), width: 60, height: 40, defaultScale: 1.0),
    ],
    'Chair': [
      FurnitureDesign(name: 'Armchair', icon: Icons.chair, color: Color(0xFFFFCC80), width: 40, height: 40, defaultScale: 0.7),
      FurnitureDesign(name: 'Dining', icon: Icons.chair, color: Color(0xFFFFB74D), width: 30, height: 30, defaultScale: 0.5),
      FurnitureDesign(name: 'Rocking', icon: Icons.chair, color: Color(0xFFA1887F), width: 40, height: 50, defaultScale: 0.7),
      FurnitureDesign(name: 'Office', icon: Icons.chair, color: Color(0xFF90A4AE), width: 35, height: 40, defaultScale: 0.6),
    ],
    'Wardrobe': [
      FurnitureDesign(name: '2-Door', icon: Icons.shelves, color: Color(0xFF8D6E63), width: 50, height: 70, defaultScale: 1.0),
      FurnitureDesign(name: '3-Door', icon: Icons.shelves, color: Color(0xFF6D4C41), width: 70, height: 70, defaultScale: 1.3),
      FurnitureDesign(name: 'Sliding', icon: Icons.shelves, color: Color(0xFF5D4037), width: 80, height: 70, defaultScale: 1.5),
      FurnitureDesign(name: 'Corner', icon: Icons.shelves, color: Color(0xFF4E342E), width: 55, height: 55, defaultScale: 1.0),
    ],
    'Desk': [
      FurnitureDesign(name: 'Computer', icon: Icons.desk, color: Color(0xFF7986CB), width: 60, height: 35, defaultScale: 1.0),
      FurnitureDesign(name: 'Writing', icon: Icons.desk, color: Color(0xFF5C6BC0), width: 70, height: 40, defaultScale: 1.1),
      FurnitureDesign(name: 'Corner', icon: Icons.desk, color: Color(0xFF3F51B5), width: 80, height: 55, defaultScale: 1.3),
      FurnitureDesign(name: 'Standing', icon: Icons.desk, color: Color(0xFF3949AB), width: 60, height: 45, defaultScale: 1.0),
    ],
  };

  static const textures = [
    TextureDesign(name: 'White', color: Colors.white, borderColor: Colors.grey, icon: Icons.format_paint),
    TextureDesign(name: 'Brick', color: Color(0xFFB5651D), borderColor: Colors.brown, icon: Icons.grid_on),
    TextureDesign(name: 'Wood', color: Color(0xFF8B5E3C), borderColor: Color(0xFF6D4C41), icon: Icons.park),
    TextureDesign(name: 'Marble', color: Color(0xFFE0E0E0), borderColor: Colors.grey, icon: Icons.spa),
    TextureDesign(name: 'Tile', color: Color(0xFFD7CCC8), borderColor: Color(0xFFBCAAA4), icon: Icons.grid_view),
    TextureDesign(name: 'Stone', color: Color(0xFF9E9E9E), borderColor: Color(0xFF757575), icon: Icons.terrain),
    TextureDesign(name: 'Glass', color: Color(0xFFB3E5FC), borderColor: Color(0xFF81D4FA), icon: Icons.window),
    TextureDesign(name: 'Metal', color: Color(0xFF90A4AE), borderColor: Color(0xFF607D8B), icon: Icons.hardware),
  ];
}
