import 'package:flutter/material.dart';

enum UnitType { meter, feet }

class ProjectModel {
  final String id;
  final String name;
  final double plotWidth;
  final double plotHeight;
  final UnitType unit;
  final List<WallModel> walls;
  final List<FurnitureModel> furniture;
  final String? thumbnailUrl;

  ProjectModel({
    required this.id,
    required this.name,
    required this.plotWidth,
    required this.plotHeight,
    this.unit = UnitType.meter,
    this.walls = const [],
    this.furniture = const [],
    this.thumbnailUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'plotWidth': plotWidth,
    'plotHeight': plotHeight,
    'unit': unit.name,
    'walls': walls.map((e) => e.toJson()).toList(),
    'furniture': furniture.map((e) => e.toJson()).toList(),
  };

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'].toString(),
      name: json['name'],
      plotWidth: json['plotWidth'].toDouble(),
      plotHeight: json['plotHeight'].toDouble(),
      unit: json['unit'] == 'feet' ? UnitType.feet : UnitType.meter,
      walls: (json['walls'] as List? ?? []).map((e) => WallModel.fromJson(e)).toList(),
      furniture: (json['furniture'] as List? ?? []).map((e) => FurnitureModel.fromJson(e)).toList(),
    );
  }
}

class WallModel {
  Offset start;
  Offset end;
  final double thickness;
  final Color color;
  List<OpeningModel> openings;

  WallModel({
    required this.start,
    required this.end,
    this.thickness = 15.0,
    this.color = const Color(0xFF2D3436),
    this.openings = const [],
  });

  Map<String, dynamic> toJson() => {
    'start': {'x': start.dx, 'y': start.dy},
    'end': {'x': end.dx, 'y': end.dy},
    'thickness': thickness,
    'color': color.value,
    'openings': openings.map((e) => e.toJson()).toList(),
  };

  factory WallModel.fromJson(Map<String, dynamic> json) {
    return WallModel(
      start: Offset(json['start']['x'], json['start']['y']),
      end: Offset(json['end']['x'], json['end']['y']),
      thickness: json['thickness'].toDouble(),
      color: Color(json['color']),
      openings: (json['openings'] as List? ?? []).map((e) => OpeningModel.fromJson(e)).toList(),
    );
  }
}

enum OpeningType { door, window }

class OpeningModel {
  final OpeningType type;
  double position; // 0.0 to 1.0 along the wall
  double width;

  OpeningModel({
    required this.type,
    required this.position,
    this.width = 40.0,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'position': position,
    'width': width,
  };

  factory OpeningModel.fromJson(Map<String, dynamic> json) {
    return OpeningModel(
      type: json['type'] == 'window' ? OpeningType.window : OpeningType.door,
      position: json['position'].toDouble(),
      width: json['width'].toDouble(),
    );
  }
}

class FurnitureModel {
  final String id;
  final String type; // bed, chair, etc.
  Offset position;
  double rotation;
  double width;
  double height;

  FurnitureModel({
    required this.id,
    required this.type,
    required this.position,
    this.rotation = 0,
    this.width = 60,
    this.height = 60,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'position': {'x': position.dx, 'y': position.dy},
    'rotation': rotation,
    'width': width,
    'height': height,
  };

  factory FurnitureModel.fromJson(Map<String, dynamic> json) {
    return FurnitureModel(
      id: json['id'],
      type: json['type'],
      position: Offset(json['position']['x'], json['position']['y']),
      rotation: json['rotation'].toDouble(),
      width: json['width'].toDouble(),
      height: json['height'].toDouble(),
    );
  }
}
