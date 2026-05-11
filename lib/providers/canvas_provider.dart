import 'dart:math';
import 'package:flutter/material.dart';
import '../models/home_design_models.dart';

class CanvasProvider extends ChangeNotifier {
  List<WallModel> walls = [];
  List<FurnitureModel> furniture = [];
  List<RoomData> rooms = [];

  dynamic selectedObject;

  bool isDrawingWall = false;
  WallModel? tempWall;

  double scale = 1.0;
  Offset offset = Offset.zero;
  double gridSize = 25.0;
  bool snapToGrid = true;

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
    _redoStack.add(_CanvasSnapshot(walls: List.from(walls), furniture: List.from(furniture), rooms: List.from(rooms)));
    walls = s.walls; furniture = s.furniture; rooms = s.rooms;
    selectedObject = null;
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final s = _redoStack.removeLast();
    _undoStack.add(_CanvasSnapshot(walls: List.from(walls), furniture: List.from(furniture), rooms: List.from(rooms)));
    walls = s.walls; furniture = s.furniture; rooms = s.rooms;
    selectedObject = null;
    notifyListeners();
  }

  void addWall(Offset start, Offset end) {
    _saveSnapshot();
    walls.add(WallModel(start: _snap(start), end: _snap(end)));
    notifyListeners();
  }

  void initializePlot(double widthFeet, double heightFeet) {
    walls.clear();
    furniture.clear();
    rooms.clear();
    _undoStack.clear();
    _redoStack.clear();
    selectedObject = null;

    double ppf = 10.0;
    double w = widthFeet * ppf;
    double h = heightFeet * ppf;
    Offset o = const Offset(50, 50);

    // Boundary
    walls.add(WallModel(start: o, end: o + Offset(w, 0)));
    walls.add(WallModel(start: o + Offset(w, 0), end: o + Offset(w, h)));
    walls.add(WallModel(start: o + Offset(w, h), end: o + Offset(0, h)));
    walls.add(WallModel(start: o + Offset(0, h), end: o));

    _autoGenerateLayout(widthFeet, heightFeet, o, ppf);
    notifyListeners();
  }

  void _autoGenerateLayout(double wFt, double hFt, Offset o, double ppf) {
    if (wFt < 15 || hFt < 15) return;

    double w = wFt * ppf;
    double h = hFt * ppf;

    // Determine layout type
    double area = wFt * hFt;
    int numRooms;
    if (area <= 600) numRooms = 1;       // 1BHK
    else if (area <= 1000) numRooms = 2; // 2BHK
    else numRooms = 3;                    // 3BHK

    double margin = 10 * ppf;
    double usableW = w - 2 * margin;
    double usableH = h - 2 * margin;

    Random rng = Random(wFt.toInt() * 1000 + hFt.toInt());

    if (numRooms == 1) {
      _add1BHK(o + Offset(margin, margin), usableW, usableH, rng);
    } else if (numRooms == 2) {
      _add2BHK(o + Offset(margin, margin), usableW, usableH, rng);
    } else {
      _add3BHK(o + Offset(margin, margin), usableW, usableH, rng);
    }
  }

  void _add1BHK(Offset o, double w, double h, Random rng) {
    double wallT = 12;
    // Living+Bedroom - 50% area
    double livingW = w * 0.55;
    double livingH = h;
    _roomWalls(o, Offset(livingW, livingH), wallT, const Color(0xFFE8D5B7), 'Living Room');
    // Kitchen
    double kitW = w - livingW;
    double kitH = h * 0.5;
    _roomWalls(o + Offset(livingW, 0), Offset(kitW, kitH), wallT, const Color(0xFFD4E8D0), 'Kitchen');
    // Bathroom
    double bathH = h - kitH;
    _roomWalls(o + Offset(livingW, kitH), Offset(kitW, bathH), wallT, const Color(0xFFC5DFF0), 'Bathroom');

    _placeFurniture('Sofa', o + Offset(livingW * 0.25, livingH * 0.3));
    _placeFurniture('Table', o + Offset(livingW * 0.5, livingH * 0.6));
    _placeFurniture('Bed', o + Offset(livingW * 0.3, livingH * 0.8));
    _placeFurniture('Chair', o + Offset(livingW * 0.7, livingH * 0.5));
  }

  void _add2BHK(Offset o, double w, double h, Random rng) {
    double wallT = 12;
    double leftW = w * 0.5;

    // Left column: Living Room (top) + Kitchen (bottom)
    double livingH = h * 0.6;
    _roomWalls(o, Offset(leftW, livingH), wallT, const Color(0xFFE8D5B7), 'Living Room');
    double kitH = h - livingH;
    _roomWalls(o + Offset(0, livingH), Offset(leftW, kitH), wallT, const Color(0xFFD4E8D0), 'Kitchen');

    // Right column: Bedroom1 (top) + Bedroom2 (bottom)
    double br1H = h * 0.5;
    double rightW = w - leftW;
    _roomWalls(o + Offset(leftW, 0), Offset(rightW, br1H), wallT, const Color(0xFFFFE0B2), 'Bedroom 1');
    double br2H = h - br1H;
    _roomWalls(o + Offset(leftW, br1H), Offset(rightW, br2H), wallT, const Color(0xFFE1BEE7), 'Bedroom 2');

    // Bathroom (small, inside)
    double bathW = rightW * 0.4;
    double bathH2 = br2H * 0.5;
    _roomWalls(o + Offset(leftW + rightW - bathW, br1H + br2H - bathH2), Offset(bathW, bathH2), wallT, const Color(0xFFC5DFF0), 'Bathroom');

    _placeFurniture('Sofa', o + Offset(leftW * 0.3, livingH * 0.3));
    _placeFurniture('Table', o + Offset(leftW * 0.5, livingH * 0.5));
    _placeFurniture('Bed', o + Offset(leftW + rightW * 0.4, br1H * 0.4));
    _placeFurniture('Bed', o + Offset(leftW + rightW * 0.4, br1H + br2H * 0.4));
    _placeFurniture('Chair', o + Offset(leftW * 0.7, livingH * 0.7));
    _placeFurniture('Wardrobe', o + Offset(leftW + rightW * 0.2, br1H * 0.2));
  }

  void _add3BHK(Offset o, double w, double h, Random rng) {
    double wallT = 12;
    // Top row: Living Room (big, left) + Bedroom 1 (right)
    double topH = h * 0.55;
    double leftW = w * 0.55;

    _roomWalls(o, Offset(leftW, topH), wallT, const Color(0xFFE8D5B7), 'Living Room');
    double br1W = w - leftW;
    _roomWalls(o + Offset(leftW, 0), Offset(br1W, topH), wallT, const Color(0xFFFFE0B2), 'Bedroom 1');

    // Bottom row: Kitchen (left), Bedroom 2 (mid), Bathroom (right)
    double botH = h - topH;
    double kitW = leftW * 0.5;
    _roomWalls(o + Offset(0, topH), Offset(kitW, botH), wallT, const Color(0xFFD4E8D0), 'Kitchen');
    double br2W = leftW - kitW;
    _roomWalls(o + Offset(kitW, topH), Offset(br2W, botH), wallT, const Color(0xFFE1BEE7), 'Bedroom 2');
    double bathW = br1W;
    double bathH2 = botH * 0.55;
    _roomWalls(o + Offset(leftW + br1W - bathW, topH + botH - bathH2), Offset(bathW, bathH2), wallT, const Color(0xFFC5DFF0), 'Bathroom');

    _placeFurniture('Sofa', o + Offset(leftW * 0.3, topH * 0.3));
    _placeFurniture('Table', o + Offset(leftW * 0.5, topH * 0.5));
    _placeFurniture('Bed', o + Offset(leftW + br1W * 0.4, topH * 0.4));
    _placeFurniture('Bed', o + Offset(kitW + br2W * 0.4, topH + botH * 0.4));
    _placeFurniture('Chair', o + Offset(leftW * 0.7, topH * 0.7));
    _placeFurniture('Wardrobe', o + Offset(leftW + br1W * 0.15, topH * 0.2));
    _placeFurniture('Desk', o + Offset(kitW + br2W * 0.3, topH + botH * 0.5));
  }

  void _roomWalls(Offset pos, Offset size, double t, Color color, String label) {
    double x = pos.dx, y = pos.dy, w = size.dx, h = size.dy;
    Color wallColor = const Color(0xFF2D3436);

    // Skip walls that overlap with boundary or existing walls
    walls.add(WallModel(start: Offset(x, y), end: Offset(x + w, y), thickness: t, color: wallColor));
    walls.add(WallModel(start: Offset(x + w, y), end: Offset(x + w, y + h), thickness: t, color: wallColor));
    walls.add(WallModel(start: Offset(x + w, y + h), end: Offset(x, y + h), thickness: t, color: wallColor));
    walls.add(WallModel(start: Offset(x, y + h), end: Offset(x, y), thickness: t, color: wallColor));

    rooms.add(RoomData(rect: Rect.fromLTWH(x, y, w, h), color: color, label: label));
  }

  int _furnitureId = 0;
  void _placeFurniture(String type, Offset pos) {
    _furnitureId++;
    furniture.add(FurnitureModel(
      id: 'auto_$_furnitureId',
      type: type, position: pos,
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

  void addFurniture(String type, {Offset? position}) {
    _saveSnapshot();
    furniture.add(FurnitureModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      position: position ?? const Offset(150, 150),
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
    return Offset(
      (point.dx / gridSize).round() * gridSize,
      (point.dy / gridSize).round() * gridSize,
    );
  }

  void selectObject(Offset localPosition) {
    selectedObject = null;
    for (var f in furniture.reversed) {
      final rect = Rect.fromCenter(center: f.position, width: f.width + 10, height: f.height + 10);
      if (rect.contains(localPosition)) { selectedObject = f; break; }
    }
    if (selectedObject == null) {
      for (var w in walls.reversed) {
        final d = _distanceToSegment(localPosition, w.start, w.end);
        if (d.distance < w.thickness + 10) { selectedObject = w; break; }
      }
    }
    notifyListeners();
  }

  void addOpening(OpeningType type, Offset position) {
    WallModel? nearestWall;
    double minDist = double.infinity, tVal = 0.5;
    for (var wall in walls) {
      final d = _distanceToSegment(position, wall.start, wall.end);
      if (d.distance < minDist && d.distance < 20) { minDist = d.distance; nearestWall = wall; tVal = d.t; }
    }
    if (nearestWall != null) {
      _saveSnapshot();
      nearestWall.openings = List.from(nearestWall.openings)..add(OpeningModel(type: type, position: tVal));
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
