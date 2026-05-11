import 'package:flutter/material.dart';
import '../models/home_design_models.dart';

class CanvasProvider extends ChangeNotifier {
  List<WallModel> walls = [];
  List<FurnitureModel> furniture = [];

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
    ));
    if (_undoStack.length > _maxUndoSteps) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void undo() {
    if (_undoStack.isEmpty) return;
    final snapshot = _undoStack.removeLast();
    _redoStack.add(_CanvasSnapshot(
      walls: List.from(walls), furniture: List.from(furniture),
    ));
    walls = snapshot.walls;
    furniture = snapshot.furniture;
    selectedObject = null;
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final snapshot = _redoStack.removeLast();
    _undoStack.add(_CanvasSnapshot(
      walls: List.from(walls), furniture: List.from(furniture),
    ));
    walls = snapshot.walls;
    furniture = snapshot.furniture;
    selectedObject = null;
    notifyListeners();
  }

  void addWall(Offset start, Offset end) {
    _saveSnapshot();
    walls.add(WallModel(start: _snap(start), end: _snap(end)));
    notifyListeners();
  }

  void initializePlot(double width, double height) {
    walls.clear();
    furniture.clear();
    _undoStack.clear();
    _redoStack.clear();
    selectedObject = null;

    double w = width * 10;
    double h = height * 10;
    Offset startPos = const Offset(50, 50);

    walls.add(WallModel(start: startPos, end: startPos + Offset(w, 0)));
    walls.add(WallModel(start: startPos + Offset(w, 0), end: startPos + Offset(w, h)));
    walls.add(WallModel(start: startPos + Offset(w, h), end: startPos + Offset(0, h)));
    walls.add(WallModel(start: startPos + Offset(0, h), end: startPos));

    notifyListeners();
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
      final f = selectedObject as FurnitureModel;
      f.rotation += angle;
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
      if (rect.contains(localPosition)) {
        selectedObject = f;
        break;
      }
    }
    if (selectedObject == null) {
      for (var w in walls.reversed) {
        final d = _distanceToSegment(localPosition, w.start, w.end);
        if (d.distance < w.thickness + 10) {
          selectedObject = w;
          break;
        }
      }
    }
    notifyListeners();
  }

  void addOpening(OpeningType type, Offset position) {
    WallModel? nearestWall;
    double minDistance = double.infinity;
    double tValue = 0.5;

    for (var wall in walls) {
      final d = _distanceToSegment(position, wall.start, wall.end);
      if (d.distance < minDistance && d.distance < 20) {
        minDistance = d.distance;
        nearestWall = wall;
        tValue = d.t;
      }
    }

    if (nearestWall != null) {
      _saveSnapshot();
      nearestWall.openings = List.from(nearestWall.openings)
        ..add(OpeningModel(type: type, position: tValue));
      notifyListeners();
    }
  }

  ({double distance, double t}) _distanceToSegment(Offset p, Offset a, Offset b) {
    final l2 = (a - b).distanceSquared;
    if (l2 == 0) return (distance: (p - a).distance, t: 0.0);
    var t = ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2;
    t = t.clamp(0.0, 1.0);
    final projection = a + (b - a) * t;
    return (distance: (p - projection).distance, t: t);
  }

  void moveSelected(Offset delta) {
    if (selectedObject is FurnitureModel) {
      final f = selectedObject as FurnitureModel;
      f.position += delta;
      notifyListeners();
    }
  }

  void deleteSelected() {
    if (selectedObject == null) return;
    _saveSnapshot();
    if (selectedObject is WallModel) {
      walls.removeWhere((w) => w == selectedObject);
    }
    if (selectedObject is FurnitureModel) {
      furniture.removeWhere((f) => f == selectedObject);
    }
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

  _CanvasSnapshot({required this.walls, required this.furniture});
}
