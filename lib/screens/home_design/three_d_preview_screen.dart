import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart' as cube;
import 'package:vector_math/vector_math_64.dart' as vec;
import '../../models/home_design_models.dart';

class ThreeDPreviewScreen extends StatefulWidget {
  final List<WallModel> walls;
  final List<FurnitureModel> furniture;

  const ThreeDPreviewScreen({
    super.key,
    required this.walls,
    required this.furniture,
  });

  @override
  State<ThreeDPreviewScreen> createState() => _ThreeDPreviewScreenState();
}

class _ThreeDPreviewScreenState extends State<ThreeDPreviewScreen> {
  cube.Scene? _scene;

  void _onSceneCreated(cube.Scene scene) {
    _scene = scene;
    scene.light.position.setFrom(vec.Vector3(0, 15, 20));
    scene.camera.position.setFrom(vec.Vector3(0, 8, 25));
    scene.camera.target.setFrom(vec.Vector3(0, 0, 0));

    _buildWalls(scene);
    _buildFurniture(scene);
  }

  void _buildWalls(cube.Scene scene) {
    final dynamic world = scene.world;

    for (var wall in widget.walls) {
      final length = (wall.start - wall.end).distance / 20;
      final center = (wall.start + wall.end) / 2;
      final angle = (wall.end - wall.start).direction;

      final wallObj = cube.Object(
        position: vec.Vector3(
          (center.dx - 200) / 20,
          1.25,
          (center.dy - 200) / 20,
        ),
        rotation: vec.Vector3(0, -angle * 57.2958, 0),
        scale: vec.Vector3(length, 2.5, 0.15),
        mesh: _createColoredMesh(
          Color.lerp(wall.color, Colors.white, 0.3) ?? Colors.grey,
        ),
      );
      world.add(wallObj);
    }
  }

  void _buildFurniture(cube.Scene scene) {
    final dynamic world = scene.world;

    for (var f in widget.furniture) {
      final color = _furnitureColor(f.type);
      final scale = _furnitureScale(f.type);

      final obj = cube.Object(
        position: vec.Vector3(
          (f.position.dx - 200) / 20,
          0.4,
          (f.position.dy - 200) / 20,
        ),
        rotation: vec.Vector3(0, f.rotation * 57.2958, 0),
        scale: vec.Vector3(scale, 0.8, scale * 0.8),
        mesh: _createColoredMesh(color),
      );
      world.add(obj);
    }
  }

  cube.Mesh _createColoredMesh(Color color) {
    final mesh = cube.Mesh(
      vertices: [
        vec.Vector3(-0.5, -0.5, 0.5), vec.Vector3(0.5, -0.5, 0.5),
        vec.Vector3(0.5, 0.5, 0.5), vec.Vector3(-0.5, 0.5, 0.5),
        vec.Vector3(-0.5, -0.5, -0.5), vec.Vector3(0.5, -0.5, -0.5),
        vec.Vector3(0.5, 0.5, -0.5), vec.Vector3(-0.5, 0.5, -0.5),
      ],
      indices: [
        cube.Polygon(0, 1, 2), cube.Polygon(0, 2, 3),
        cube.Polygon(1, 5, 6), cube.Polygon(1, 6, 2),
        cube.Polygon(5, 4, 7), cube.Polygon(5, 7, 6),
        cube.Polygon(4, 0, 3), cube.Polygon(4, 3, 7),
        cube.Polygon(3, 2, 6), cube.Polygon(3, 6, 7),
        cube.Polygon(4, 5, 1), cube.Polygon(4, 1, 0),
      ],
    );
    for (var i = 0; i < 8; i++) {
      mesh.colors.add(color);
    }
    return mesh;
  }

  Color _furnitureColor(String type) {
    switch (type.toLowerCase()) {
      case 'sofa': return Colors.teal.shade400;
      case 'bed': return Colors.blue.shade300;
      case 'table': return Colors.brown.shade400;
      case 'chair': return Colors.orange.shade300;
      case 'wardrobe': return Colors.brown.shade600;
      case 'desk': return Colors.indigo.shade300;
      default: return Colors.grey;
    }
  }

  double _furnitureScale(String type) {
    switch (type.toLowerCase()) {
      case 'sofa': return 1.5;
      case 'bed': return 1.8;
      case 'table': return 1.2;
      case 'chair': return 0.6;
      case 'wardrobe': return 0.8;
      case 'desk': return 1.2;
      default: return 1.0;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_scene == null) return;
    _scene!.camera.trackBall(
      vec.Vector2(-details.delta.dx, -details.delta.dy),
      vec.Vector2(0, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('3D Visualization', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.white70),
            onPressed: () {
              if (_scene == null) return;
              _scene!.camera.position.setFrom(vec.Vector3(0, 8, 25));
              _scene!.camera.target.setFrom(vec.Vector3(0, 0, 0));
            },
          ),
        ],
      ),
      body: GestureDetector(
        onPanUpdate: _onPanUpdate,
        child: cube.Cube(onSceneCreated: _onSceneCreated),
      ),
    );
  }
}
