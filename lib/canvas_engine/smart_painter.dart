import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/home_design_models.dart';

class SmartPainter extends CustomPainter {
  final List<WallModel> walls;
  final List<FurnitureModel> furniture;
  final WallModel? tempWall;
  final dynamic selectedObject;
  final double gridSize;
  final List<RoomData> rooms;
  final int? selectedRoomIndex;

  SmartPainter({
    required this.walls,
    required this.furniture,
    this.tempWall,
    this.selectedObject,
    this.gridSize = 50.0,
    this.rooms = const [],
    this.selectedRoomIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawFloor(canvas, size);
    _drawRooms(canvas);
    _drawMeasurements(canvas);
    _drawWalls(canvas);
    _drawFurniture(canvas);
    if (tempWall != null) _drawTempWall(canvas);
  }

  void _drawFloor(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF5F0E8);
    canvas.drawRect(const Offset(0, 0) & Size(size.width, size.height), bgPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFFE8E0D0).withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    for (double x = 0; x <= size.width; x += gridSize * 2) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += gridSize * 2) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Sub-grid
    final subPaint = Paint()
      ..color = const Color(0xFFE8E0D0).withValues(alpha: 0.25)
      ..strokeWidth = 0.3;
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), subPaint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), subPaint);
    }

    // Origin marker
    final originPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(50, 50), 20, originPaint);
  }

  void _drawRooms(Canvas canvas) {
    for (int i = 0; i < rooms.length; i++) {
      final room = rooms[i];
      final isSelected = selectedRoomIndex == i;

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            room.color.withValues(alpha: isSelected ? 0.4 : 0.2),
            room.color.withValues(alpha: isSelected ? 0.25 : 0.12),
          ],
        ).createShader(room.rect);
      canvas.drawRect(room.rect, paint);

      if (isSelected) {
        final glowPaint = Paint()
          ..color = Colors.blue.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        final r = RRect.fromRectAndRadius(room.rect, const Radius.circular(4));
        canvas.drawRRect(r, glowPaint);
      }

      final center = room.rect.center;
      final tp = TextPainter(
        text: TextSpan(
          text: room.label,
          style: TextStyle(
            color: room.color.withValues(alpha: isSelected ? 1.0 : 0.65),
            fontSize: isSelected ? 15 : 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawMeasurements(Canvas canvas) {
    for (var room in rooms) {
      final w = (room.rect.width / 10).round();
      final h = (room.rect.height / 10).round();
      final label = '$w\' × $h\'';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: room.color.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      final pos = room.rect.center + const Offset(0, 16);
      tp.paint(canvas, pos - Offset(tp.width / 2, 0));
    }
  }

  void _drawWalls(Canvas canvas) {
    for (var wall in walls) {
      final isSel = selectedObject == wall;

      // Shadow
      if (!isSel) {
        final shadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.06)
          ..strokeWidth = wall.thickness + 4
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(wall.start + const Offset(2, 2), wall.end + const Offset(2, 2), shadowPaint);
      }

      // Main wall
      final paint = Paint()
        ..color = isSel ? Colors.blue : wall.color
        ..strokeWidth = wall.thickness
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(wall.start, wall.end, paint);

      if (isSel) {
        final selPaint = Paint()
          ..color = Colors.blue.withValues(alpha: 0.3)
          ..strokeWidth = wall.thickness + 6
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(wall.start, wall.end, selPaint);
        canvas.drawLine(wall.start, wall.end, paint);
      }

      _drawOpenings(canvas, wall);
    }
  }

  void _drawOpenings(Canvas canvas, WallModel wall) {
    if (wall.openings.isEmpty) return;

    for (var op in wall.openings) {
      final pos = wall.start + (wall.end - wall.start) * op.position;
      final angle = (wall.end - wall.start).direction;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle);

      final bw = op.width;
      final bt = wall.thickness;

      if (op.type == OpeningType.door) {
        // Gap in wall
        final gapPaint = Paint()..color = const Color(0xFFF5F0E8);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: bw, height: bt + 2), gapPaint);

        // Door leaf
        final doorPaint = Paint()
          ..color = op.designColor
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(bw * 0.25, 0), width: bw * 0.45, height: bt - 2),
            const Radius.circular(2),
          ),
          doorPaint,
        );
        // Door frame
        final framePaint = Paint()
          ..color = op.designColor.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(bw * 0.25, 0), width: bw * 0.45, height: bt - 2),
            const Radius.circular(2),
          ),
          framePaint,
        );
        // Swing
        final swingPaint = Paint()
          ..color = op.designColor.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: bw * 0.45),
          0, -1.4, false, swingPaint,
        );
        // Handle
        canvas.drawCircle(Offset(bw * 0.2, 0), 2, Paint()..color = Colors.white);
      } else {
        // Window gap
        final gapPaint = Paint()..color = const Color(0xFFE3F2FD);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: bw, height: bt + 2), gapPaint);

        // Window frame
        final framePaint = Paint()
          ..color = op.designColor
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: bw, height: bt - 1),
            const Radius.circular(3),
          ),
          framePaint,
        );
        // Glass
        final glassPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromCenter(center: Offset(-bw * 0.2, 0), width: bw * 0.32, height: bt - 5),
          glassPaint,
        );
        canvas.drawRect(
          Rect.fromCenter(center: Offset(bw * 0.2, 0), width: bw * 0.32, height: bt - 5),
          glassPaint,
        );
        // Divider
        final divPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..strokeWidth = 1;
        canvas.drawLine(Offset(0, -(bt - 5) / 2), Offset(0, (bt - 5) / 2), divPaint);
      }

      canvas.restore();
    }
  }

  void _drawTempWall(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.35)
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tempWall!.start, tempWall!.end, paint);

    final len = (tempWall!.start - tempWall!.end).distance / 10;
    if (len > 0.5) {
      final center = (tempWall!.start + tempWall!.end) / 2;
      // Background pill for text
      final bgP = Paint()..color = Colors.blue.withValues(alpha: 0.15);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: center + const Offset(0, -20), width: 50, height: 18), const Radius.circular(9)),
        bgP,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${len.toStringAsFixed(0)}ft',
          style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, center + const Offset(0, -20) - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawFurniture(Canvas canvas) {
    for (var f in furniture) {
      final isSel = selectedObject == f;

      canvas.save();
      canvas.translate(f.position.dx, f.position.dy);
      canvas.rotate(f.rotation);

      final rect = Rect.fromCenter(center: Offset.zero, width: f.width, height: f.height);

      // Shadow when selected
      if (isSel) {
        final shadowPaint = Paint()
          ..color = Colors.blue.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawRRect(RRect.fromRectAndRadius(rect.translate(0, 3), const Radius.circular(8)), shadowPaint);
      }

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      final paint = Paint()
        ..color = (isSel ? Colors.blue : f.color).withValues(alpha: 0.55)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = isSel ? Colors.blue : f.color.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRRect(rrect, paint);
      canvas.drawRRect(rrect, borderPaint);

      _drawFurnitureIcon(canvas, f.type, f.width, f.height);

      if (isSel) {
        final hlPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset.zero, 4, hlPaint);
      }

      canvas.restore();
    }
  }

  void _drawFurnitureIcon(Canvas canvas, String type, double w, double h) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    switch (type) {
      case 'Sofa':
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(-w * 0.18, 0), width: w * 0.3, height: h * 0.45), const Radius.circular(4)), paint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.18, 0), width: w * 0.3, height: h * 0.45), const Radius.circular(4)), paint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, -h * 0.25), width: w * 0.7, height: h * 0.15), const Radius.circular(3)), paint);
      case 'Bed':
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, -h * 0.2), width: w * 0.55, height: h * 0.22), const Radius.circular(4)), paint);
      case 'Table':
        canvas.drawCircle(Offset.zero, math.min(w, h) * 0.18, paint);
      case 'Chair':
        canvas.drawCircle(Offset.zero, math.min(w, h) * 0.15, paint);
      case 'Wardrobe':
        canvas.drawRect(Rect.fromCenter(center: Offset(-w * 0.18, 0), width: w * 0.3, height: h * 0.65), paint);
        canvas.drawRect(Rect.fromCenter(center: Offset(w * 0.18, 0), width: w * 0.3, height: h * 0.65), paint);
      case 'Desk':
        final lp = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..strokeWidth = 2;
        canvas.drawLine(Offset(-w * 0.35, 0), Offset(w * 0.35, 0), lp);
        canvas.drawLine(Offset(-w * 0.35, -h * 0.25), Offset(-w * 0.35, h * 0.25), lp);
        canvas.drawLine(Offset(w * 0.35, -h * 0.25), Offset(w * 0.35, h * 0.25), lp);
      default:
        canvas.drawCircle(Offset.zero, 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SmartPainter oldDelegate) {
    return oldDelegate.walls != walls ||
        oldDelegate.furniture != furniture ||
        oldDelegate.tempWall != tempWall ||
        oldDelegate.selectedObject != selectedObject ||
        oldDelegate.rooms != rooms ||
        oldDelegate.selectedRoomIndex != selectedRoomIndex;
  }
}
