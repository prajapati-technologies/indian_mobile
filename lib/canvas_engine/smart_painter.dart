import 'package:flutter/material.dart';
import '../models/home_design_models.dart';

class SmartPainter extends CustomPainter {
  final List<WallModel> walls;
  final List<FurnitureModel> furniture;
  final WallModel? tempWall;
  final dynamic selectedObject;
  final double gridSize;
  final List<RoomData> rooms;

  SmartPainter({
    required this.walls,
    required this.furniture,
    this.tempWall,
    this.selectedObject,
    this.gridSize = 25.0,
    this.rooms = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawRooms(canvas);
    _drawGrid(canvas, size);
    _drawWalls(canvas);
    _drawFurniture(canvas);
    if (tempWall != null) _drawTempWall(canvas);
  }

  void _drawRooms(Canvas canvas) {
    for (var room in rooms) {
      final paint = Paint()
        ..color = room.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRect(room.rect, paint);

      final center = room.rect.center;
      final tp = TextPainter(
        text: TextSpan(
          text: room.label,
          style: TextStyle(
            color: room.color.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawWalls(Canvas canvas) {
    for (var wall in walls) {
      final isSelected = selectedObject == wall;
      final paint = Paint()
        ..color = isSelected ? Colors.blue : wall.color
        ..strokeWidth = wall.thickness
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(wall.start, wall.end, paint);

      _drawOpenings(canvas, wall);
      _drawMeasurement(canvas, wall);
    }
  }

  void _drawOpenings(Canvas canvas, WallModel wall) {
    for (var op in wall.openings) {
      final pos = wall.start + (wall.end - wall.start) * op.position;
      final angle = (wall.end - wall.start).direction;

      final paint = Paint()
        ..color = op.type == OpeningType.door ? Colors.brown : Colors.lightBlueAccent
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle);

      if (op.type == OpeningType.door) {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: op.width, height: wall.thickness + 2), paint);
        final swingPaint = Paint()..color = Colors.brown..style = PaintingStyle.stroke..strokeWidth = 1;
        canvas.drawArc(Rect.fromCircle(center: Offset(-op.width/2, 0), radius: op.width), 0, -1.5, false, swingPaint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: op.width, height: wall.thickness - 2), paint);
      }

      canvas.restore();
    }
  }

  void _drawTempWall(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.5)
      ..strokeWidth = 15.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tempWall!.start, tempWall!.end, paint);
  }

  void _drawFurniture(Canvas canvas) {
    for (var f in furniture) {
      final isSelected = selectedObject == f;
      final paint = Paint()
        ..color = (isSelected ? Colors.blue : Colors.orange).withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = isSelected ? Colors.blue : Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.save();
      canvas.translate(f.position.dx, f.position.dy);
      canvas.rotate(f.rotation);

      final rect = Rect.fromCenter(center: Offset.zero, width: f.width, height: f.height);
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);

      _drawText(canvas, f.type.toUpperCase(), Offset.zero);

      canvas.restore();
    }
  }

  void _drawMeasurement(Canvas canvas, WallModel wall) {
    final dist = (wall.start - wall.end).distance / 10;
    final center = Offset((wall.start.dx + wall.end.dx) / 2, (wall.start.dy + wall.end.dy) / 2);
    _drawText(canvas, "${dist.toStringAsFixed(0)}ft", center + const Offset(0, -15));
  }

  void _drawText(Canvas canvas, String text, Offset position) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, position - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant SmartPainter oldDelegate) => true;
}
