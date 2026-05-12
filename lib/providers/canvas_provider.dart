import 'dart:math';
import 'package:flutter/material.dart';
import '../models/home_design_models.dart';

class CanvasProvider extends ChangeNotifier {
  List<WallModel> walls = [];
  List<FurnitureModel> furniture = [];
  List<RoomData> rooms = [];
  double plotWidthFt = 0;
  double plotHeightFt = 0;

  dynamic selectedObject;
  int? selectedRoomIndex;

  bool isDrawingWall = false;
  WallModel? tempWall;

  double scale = 1.0;
  Offset offset = Offset.zero;
  double gridSize = 50.0;
  bool snapToGrid = true;

  int _furnitureId = 0;
  final List<_CanvasSnapshot> _undoStack = [];
  final List<_CanvasSnapshot> _redoStack = [];
  static const int _maxUndoSteps = 30;

  void _saveSnapshot() {
    _undoStack.add(_CanvasSnapshot(
      walls: walls.map((w) => WallModel(
        start: w.start, end: w.end, thickness: w.thickness,
        color: w.color, openings: List.from(w.openings),
      )).toList(),
      furniture: furniture.map((f) => FurnitureModel(
        id: f.id, type: f.type, position: f.position,
        rotation: f.rotation, width: f.width, height: f.height,
      )).toList(),
      rooms: List.from(rooms),
    ));
    if (_undoStack.length > _maxUndoSteps) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void undo() {
    if (_undoStack.isEmpty) return;
    final s = _undoStack.removeLast();
    _redoStack.add(_CanvasSnapshot(
      walls: List.from(walls), furniture: List.from(furniture), rooms: List.from(rooms),
    ));
    walls = s.walls; furniture = s.furniture; rooms = s.rooms;
    selectedObject = null;
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final s = _redoStack.removeLast();
    _undoStack.add(_CanvasSnapshot(
      walls: List.from(walls), furniture: List.from(furniture), rooms: List.from(rooms),
    ));
    walls = s.walls; furniture = s.furniture; rooms = s.rooms;
    selectedObject = null;
    notifyListeners();
  }

  void addWall(Offset start, Offset end) {
    _saveSnapshot();
    walls.add(WallModel(start: _snap(start), end: _snap(end)));
    notifyListeners();
  }

  void initializePlot(double widthFt, double heightFt) {
    plotWidthFt = widthFt;
    plotHeightFt = heightFt;
    walls.clear();
    furniture.clear();
    rooms.clear();
    _undoStack.clear();
    _redoStack.clear();
    selectedObject = null;
    _furnitureId = 0;

    double ppf = 10.0;
    double w = widthFt * ppf;
    double h = heightFt * ppf;
    Offset o = const Offset(50, 50);

    walls.add(WallModel(start: o, end: o + Offset(w, 0)));
    walls.add(WallModel(start: o + Offset(w, 0), end: o + Offset(w, h)));
    walls.add(WallModel(start: o + Offset(w, h), end: o + Offset(0, h)));
    walls.add(WallModel(start: o + Offset(0, h), end: o));

    _autoGenerateLayout(widthFt, heightFt, o, ppf);
    notifyListeners();
  }

  double get canvasWidth => max(500, plotWidthFt * 10 + 100);
  double get canvasHeight => max(500, plotHeightFt * 10 + 100);

  void _autoGenerateLayout(double wFt, double hFt, Offset o, double ppf) {
    if (wFt < 15 || hFt < 15) return;

    double w = wFt * ppf;
    double h = hFt * ppf;
    double area = wFt * hFt;
    int numRooms = area <= 600 ? 1 : area <= 1000 ? 2 : 3;
    double margin = 10 * ppf;
    double uW = w - 2 * margin;
    double uH = h - 2 * margin;

    if (numRooms == 1) _add1BHK(o + Offset(margin, margin), uW, uH);
    else if (numRooms == 2) _add2BHK(o + Offset(margin, margin), uW, uH);
    else _add3BHK(o + Offset(margin, margin), uW, uH);
  }

  void _add1BHK(Offset o, double w, double h) {
    double t = 12;
    double lw = w * 0.55;
    _roomWalls(o, Offset(lw, h), t, const Color(0xFFE8D5B7), 'Living');
    double kw = w - lw;
    _roomWalls(o + Offset(lw, 0), Offset(kw, h * 0.5), t, const Color(0xFFD4E8D0), 'Kitchen');
    _roomWalls(o + Offset(lw, h * 0.5), Offset(kw, h * 0.5), t, const Color(0xFFC5DFF0), 'Bath');
    _placeFurniture('Sofa', o + Offset(lw * 0.3, h * 0.25));
    _placeFurniture('Table', o + Offset(lw * 0.5, h * 0.55));
    _placeFurniture('Bed', o + Offset(lw * 0.4, h * 0.8));
  }

  void _add2BHK(Offset o, double w, double h) {
    double t = 12;
    double lw = w * 0.5;
    double lh = h * 0.6;
    _roomWalls(o, Offset(lw, lh), t, const Color(0xFFE8D5B7), 'Living');
    _roomWalls(o + Offset(0, lh), Offset(lw, h - lh), t, const Color(0xFFD4E8D0), 'Kitchen');
    double rw = w - lw;
    double rh = h * 0.5;
    _roomWalls(o + Offset(lw, 0), Offset(rw, rh), t, const Color(0xFFFFE0B2), 'Bed 1');
    _roomWalls(o + Offset(lw, rh), Offset(rw, h - rh), t, const Color(0xFFE1BEE7), 'Bed 2');
    _roomWalls(o + Offset(lw + rw - rw * 0.4, rh + (h - rh) * 0.45), Offset(rw * 0.4, (h - rh) * 0.55), t, const Color(0xFFC5DFF0), 'Bath');
    _placeFurniture('Sofa', o + Offset(lw * 0.3, lh * 0.3));
    _placeFurniture('Table', o + Offset(lw * 0.5, lh * 0.5));
    _placeFurniture('Bed', o + Offset(lw + rw * 0.4, rh * 0.4));
    _placeFurniture('Bed', o + Offset(lw + rw * 0.4, rh + (h - rh) * 0.4));
  }

  void _add3BHK(Offset o, double w, double h) {
    double t = 12;
    double th = h * 0.55;
    double lw = w * 0.55;
    _roomWalls(o, Offset(lw, th), t, const Color(0xFFE8D5B7), 'Living');
    double rw = w - lw;
    _roomWalls(o + Offset(lw, 0), Offset(rw, th), t, const Color(0xFFFFE0B2), 'Bed 1');
    double bh = h - th;
    double kw = lw * 0.5;
    _roomWalls(o + Offset(0, th), Offset(kw, bh), t, const Color(0xFFD4E8D0), 'Kitchen');
    double bw = lw - kw;
    _roomWalls(o + Offset(kw, th), Offset(bw, bh), t, const Color(0xFFE1BEE7), 'Bed 2');
    double btw = rw;
    _roomWalls(o + Offset(lw + rw - btw, th + bh * 0.45), Offset(btw, bh * 0.55), t, const Color(0xFFC5DFF0), 'Bath');
    _placeFurniture('Sofa', o + Offset(lw * 0.3, th * 0.3));
    _placeFurniture('Table', o + Offset(lw * 0.5, th * 0.5));
    _placeFurniture('Bed', o + Offset(lw + rw * 0.4, th * 0.4));
    _placeFurniture('Bed', o + Offset(kw + bw * 0.4, th + bh * 0.4));
    _placeFurniture('Desk', o + Offset(kw + bw * 0.3, th + bh * 0.6));
  }

  void _roomWalls(Offset pos, Offset size, double t, Color color, String label) {
    double x = pos.dx, y = pos.dy, w = size.dx, h = size.dy;
    Color wc = const Color(0xFF2D3436);
    walls.add(WallModel(start: Offset(x, y), end: Offset(x + w, y), thickness: t, color: wc));
    walls.add(WallModel(start: Offset(x + w, y), end: Offset(x + w, y + h), thickness: t, color: wc));
    walls.add(WallModel(start: Offset(x + w, y + h), end: Offset(x, y + h), thickness: t, color: wc));
    walls.add(WallModel(start: Offset(x, y + h), end: Offset(x, y), thickness: t, color: wc));
    rooms.add(RoomData(rect: Rect.fromLTWH(x, y, w, h), color: color, label: label));
  }

  void _placeFurniture(String type, Offset pos) {
    _furnitureId++;
    Color c;
    double w, h;
    switch (type) {
      case 'Sofa': c = const Color(0xFF78909C); w = 90; h = 45; break;
      case 'Bed': c = const Color(0xFF64B5F6); w = 70; h = 85; break;
      case 'Table': c = const Color(0xFFA1887F); w = 60; h = 40; break;
      case 'Chair': c = const Color(0xFFFFB74D); w = 30; h = 30; break;
      case 'Wardrobe': c = const Color(0xFF8D6E63); w = 50; h = 65; break;
      case 'Desk': c = const Color(0xFF7986CB); w = 55; h = 30; break;
      default: c = const Color(0xFFFF9800); w = 50; h = 50;
    }
    furniture.add(FurnitureModel(
      id: 'auto_$_furnitureId', type: type, position: pos,
      width: w, height: h, color: c,
    ));
  }

  void startDrawingWall(Offset start) {
    isDrawingWall = true;
    tempWall = WallModel(start: _snap(start), end: _snap(start));
    notifyListeners();
  }

  void updateDrawingWall(Offset current) {
    if (tempWall != null) {
      tempWall!.end = _snap(current);
      notifyListeners();
    }
  }

  void endDrawingWall() {
    if (tempWall != null && (tempWall!.start - tempWall!.end).distance > 5) {
      _saveSnapshot();
      walls.add(tempWall!);
    }
    isDrawingWall = false;
    tempWall = null;
    notifyListeners();
  }

  void addFurniture(String type, {Offset? position, String styleName = '', double width = 60, double height = 60, Color color = const Color(0xFFFF9800)}) {
    _saveSnapshot();
    furniture.add(FurnitureModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type, position: position ?? const Offset(150, 150),
      styleName: styleName, width: width, height: height, color: color,
    ));
    notifyListeners();
  }

  void rotateSelectedFurniture(double angle) {
    if (selectedObject is FurnitureModel) {
      _saveSnapshot();
      (selectedObject as FurnitureModel).rotation += angle;
      notifyListeners();
    }
  }

  Offset _snap(Offset point) {
    if (!snapToGrid) return point;

    // Snap to existing wall endpoints for seamless connection
    Offset snapped = Offset(
      (point.dx / gridSize).round() * gridSize,
      (point.dy / gridSize).round() * gridSize,
    );

    // Check nearby wall endpoints
    for (var w in walls) {
      if ((w.start - point).distance < 15) return w.start;
      if ((w.end - point).distance < 15) return w.end;
    }
    return snapped;
  }

  void selectObject(Offset localPosition) {
    selectedObject = null;
    selectedRoomIndex = null;

    // Check furniture
    for (var f in furniture.reversed) {
      final rect = Rect.fromCenter(center: f.position, width: f.width + 10, height: f.height + 10);
      if (rect.contains(localPosition)) { selectedObject = f; break; }
    }
    // Check walls
    if (selectedObject == null) {
      for (var w in walls.reversed) {
        final d = _distanceToSegment(localPosition, w.start, w.end);
        if (d.distance < w.thickness + 10) { selectedObject = w; break; }
      }
    }
    // Check rooms
    if (selectedObject == null) {
      for (int i = rooms.length - 1; i >= 0; i--) {
        if (rooms[i].rect.contains(localPosition)) {
          selectedRoomIndex = i;
          break;
        }
      }
    }
    notifyListeners();
  }

  String selectedDoorDesign = 'Wooden';
  Color selectedDoorColor = const Color(0xFF8B5E3C);
  String selectedWindowDesign = 'Casement';
  Color selectedWindowColor = const Color(0xFF81D4FA);
  double selectedDoorWidth = 36.0;
  double selectedWindowWidth = 40.0;

  void setDoorDesign(String name, Color color, double width) {
    selectedDoorDesign = name; selectedDoorColor = color; selectedDoorWidth = width;
  }

  void setWindowDesign(String name, Color color, double width) {
    selectedWindowDesign = name; selectedWindowColor = color; selectedWindowWidth = width;
  }

  void addOpening(OpeningType type, Offset position) {
    WallModel? nearestWall;
    double minDist = double.infinity, tVal = 0.5;
    for (var wall in walls) {
      final d = _distanceToSegment(position, wall.start, wall.end);
      if (d.distance < minDist && d.distance < 25) { minDist = d.distance; nearestWall = wall; tVal = d.t; }
    }
    if (nearestWall != null) {
      _saveSnapshot();
      if (type == OpeningType.door) {
        nearestWall.openings = List.from(nearestWall.openings)..add(OpeningModel(
          type: type, position: tVal,
          designName: selectedDoorDesign, designColor: selectedDoorColor,
          width: selectedDoorWidth,
        ));
      } else {
        nearestWall.openings = List.from(nearestWall.openings)..add(OpeningModel(
          type: type, position: tVal,
          designName: selectedWindowDesign, designColor: selectedWindowColor,
          width: selectedWindowWidth,
        ));
      }
      notifyListeners();
    }
  }

  ({double distance, double t}) _distanceToSegment(Offset p, Offset a, Offset b) {
    final l2 = (a - b).distanceSquared;
    if (l2 == 0) return (distance: (p - a).distance, t: 0.0);
    var t = ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2;
    t = t.clamp(0.0, 1.0);
    return (distance: (p - (a + (b - a) * t)).distance, t: t);
  }

  void moveSelected(Offset delta) {
    if (selectedObject is FurnitureModel) {
      (selectedObject as FurnitureModel).position += delta;
      notifyListeners();
    }
  }

  void deleteSelected() {
    if (selectedObject == null) return;
    _saveSnapshot();
    walls.removeWhere((w) => w == selectedObject);
    furniture.removeWhere((f) => f == selectedObject);
    selectedObject = null;
    notifyListeners();
  }

  void applyTextureToSelected(Color color) {
    if (selectedObject is WallModel) {
      _saveSnapshot();
      (selectedObject as WallModel).color = color;
      notifyListeners();
    }
  }
}

class _CanvasSnapshot {
  final List<WallModel> walls;
  final List<FurnitureModel> furniture;
  final List<RoomData> rooms;
  _CanvasSnapshot({required this.walls, required this.furniture, required this.rooms});
}
