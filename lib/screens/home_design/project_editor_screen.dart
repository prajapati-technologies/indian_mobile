import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/canvas_provider.dart';
import '../../canvas_engine/smart_painter.dart';
import '../../models/home_design_models.dart';
import 'three_d_preview_screen.dart';
import 'ai_interior_screen.dart';

class ProjectEditorScreen extends StatefulWidget {
  final String? projectId;

  const ProjectEditorScreen({super.key, this.projectId});

  @override
  State<ProjectEditorScreen> createState() => _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends State<ProjectEditorScreen> {
  int _selectedToolIndex = -1;
  final GlobalKey _canvasKey = GlobalKey();
  final TransformationController _transformCtrl = TransformationController();

  Offset _toCanvas(Offset screenPos) => _transformCtrl.toScene(screenPos);

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CanvasProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('Design Editor', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.undo, color: provider.canUndo ? Colors.black54 : Colors.grey.shade300),
            onPressed: provider.canUndo ? () => provider.undo() : null,
          ),
          IconButton(
            icon: Icon(Icons.redo, color: provider.canRedo ? Colors.black54 : Colors.grey.shade300),
            onPressed: provider.canRedo ? () => provider.redo() : null,
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.purple),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIInteriorScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.view_in_ar, color: Colors.blue),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ThreeDPreviewScreen(walls: provider.walls, furniture: provider.furniture))),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onSelected: (value) {
              if (value == 'save') _saveProject(provider);
              if (value == 'export_png') _exportAsPng(provider);
              if (value == 'export_pdf') _exportAsPdf();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'save', child: ListTile(leading: Icon(Icons.save), title: Text('Save'))),
              const PopupMenuItem(value: 'export_png', child: ListTile(leading: Icon(Icons.image), title: Text('Export PNG'))),
              const PopupMenuItem(value: 'export_pdf', child: ListTile(leading: Icon(Icons.picture_as_pdf), title: Text('Export PDF'))),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) {
              final c = _toCanvas(details.localPosition);
              if (_selectedToolIndex == 0) { provider.startDrawingWall(c); return; }
              if (_selectedToolIndex == 3 && provider.selectedObject != null) return;
              final hit = _hitTestObject(provider, c);
              if (hit == null) provider.selectObject(c);
            },
            onPanUpdate: (details) {
              final c = _toCanvas(details.localPosition);
              if (_selectedToolIndex == 0) { provider.updateDrawingWall(c); return; }
              if (provider.selectedObject != null) provider.moveSelected(details.delta);
            },
            onPanEnd: (details) {
              if (_selectedToolIndex == 0) provider.endDrawingWall();
            },
            onTapDown: (details) {
              final c = _toCanvas(details.localPosition);
              if (_selectedToolIndex == 1) { provider.addOpening(OpeningType.door, c); return; }
              if (_selectedToolIndex == 2) { provider.addOpening(OpeningType.window, c); return; }
              if (_selectedToolIndex == -1) { provider.selectObject(c); }
            },
            child: RepaintBoundary(
              key: _canvasKey,
              child: InteractiveViewer(
                transformationController: _transformCtrl,
                minScale: 0.3,
                maxScale: 5.0,
                constrained: false,
                child: SizedBox(
                  width: 5000,
                  height: 5000,
                  child: CustomPaint(
                    size: const Size(5000, 5000),
                    painter: SmartPainter(
                      walls: provider.walls,
                      furniture: provider.furniture,
                      tempWall: provider.tempWall,
                      selectedObject: provider.selectedObject,
                      rooms: provider.rooms,
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (provider.selectedObject != null)
            Positioned(top: 100, left: 20, child: _objectEditPopup(provider)),

          Positioned(bottom: 30, left: 20, right: 20, child: _buildToolBar(provider)),
        ],
      ),
    );
  }

  Widget _buildToolBar(CanvasProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _toolItem(0, Icons.edit_note, 'Wall', provider),
          _toolItem(1, Icons.sensor_door_outlined, 'Door', provider),
          _toolItem(2, Icons.window_outlined, 'Window', provider),
          _toolItem(3, Icons.chair_outlined, 'Furniture', provider),
          _toolItem(4, Icons.texture, 'Texture', provider),
          _toolDeselectItem(),
        ],
      ),
    );
  }

  dynamic _hitTestObject(CanvasProvider provider, Offset position) {
    for (var f in provider.furniture.reversed) {
      final rect = Rect.fromCenter(center: f.position, width: f.width + 10, height: f.height + 10);
      if (rect.contains(position)) return f;
    }
    return null;
  }

  Widget _toolItem(int index, IconData icon, String label, CanvasProvider provider) {
    bool isSelected = _selectedToolIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedToolIndex = index);
        if (index == 3) _showFurnitureLibrary(provider);
        if (index == 4) _showTextureSelector(provider);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey.shade600, size: 26),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey.shade600,
              fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }

  Widget _toolDeselectItem() {
    return GestureDetector(
      onTap: () => setState(() => _selectedToolIndex = -1),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.close, color: Colors.red, size: 22),
      ),
    );
  }

  void _showFurnitureLibrary(CanvasProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Furniture', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _furnitureItem('Sofa', Icons.weekend, () => provider.addFurniture('Sofa', position: _randomPos())),
                  _furnitureItem('Bed', Icons.bed, () => provider.addFurniture('Bed', position: _randomPos())),
                  _furnitureItem('Table', Icons.table_restaurant, () => provider.addFurniture('Table', position: _randomPos())),
                  _furnitureItem('Chair', Icons.chair, () => provider.addFurniture('Chair', position: _randomPos())),
                  _furnitureItem('Wardrobe', Icons.shelves, () => provider.addFurniture('Wardrobe', position: _randomPos())),
                  _furnitureItem('Desk', Icons.desk, () => provider.addFurniture('Desk', position: _randomPos())),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Offset _randomPos() {
    final t = DateTime.now().microsecondsSinceEpoch;
    return Offset(200.0 + (t % 300).toDouble(), 200.0 + ((t >> 10) % 300).toDouble());
  }

  Widget _furnitureItem(String name, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { onTap(); Navigator.pop(context); },
      child: Container(
        width: 80, margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blue, size: 30),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _objectEditPopup(CanvasProvider provider) {
    final obj = provider.selectedObject;
    if (obj is WallModel) {
      final dist = (obj.start - obj.end).distance / 10;
      return Container(
        width: 220, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Wall', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 16),
          _propRow('Length', '${dist.toStringAsFixed(1)}ft'),
          _propRow('Thickness', '${obj.thickness.toStringAsFixed(0)}px'),
          const SizedBox(height: 12),
          Row(children: [
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => provider.deleteSelected()),
            const Spacer(),
            ElevatedButton(onPressed: () => provider.selectObject(const Offset(-9999, -9999)), child: const Text('Done')),
          ]),
        ]),
      );
    }
    if (obj is FurnitureModel) {
      return Container(
        width: 240, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(obj.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            IconButton(icon: const Icon(Icons.rotate_left, color: Colors.blue), tooltip: 'Rotate Left', onPressed: () => provider.rotateSelectedFurniture(-0.785)),
            IconButton(icon: const Icon(Icons.rotate_right, color: Colors.blue), tooltip: 'Rotate Right', onPressed: () => provider.rotateSelectedFurniture(0.785)),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => provider.deleteSelected()),
          ]),
          const SizedBox(height: 8),
          Center(child: ElevatedButton(onPressed: () => provider.selectObject(const Offset(-9999, -9999)), child: const Text('Done'))),
        ]),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _propRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }

  void _showTextureSelector(CanvasProvider provider) {
    final colors = [
      ('White', Colors.white, Colors.grey.shade300),
      ('Brick', const Color(0xFFB5651D), Colors.brown),
      ('Wood', const Color(0xFF8B5E3C), Colors.brown.shade400),
      ('Marble', Colors.grey.shade300, Colors.grey),
      ('Navy', const Color(0xFF1E3A5F), Colors.blue.shade900),
      ('Beige', const Color(0xFFF5F0E1), Colors.brown.shade100),
      ('Green', const Color(0xFF4A7C59), Colors.green.shade700),
      ('Slate', const Color(0xFF708090), Colors.blueGrey),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Select Wall Texture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Wrap(spacing: 16, runSpacing: 16, children: colors.map((c) => GestureDetector(
            onTap: () { provider.applyTextureToSelected(c.$2); Navigator.pop(context); },
            child: Column(children: [
              Container(width: 56, height: 56,
                decoration: BoxDecoration(color: c.$2, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.$3, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
              ),
              const SizedBox(height: 6),
              Text(c.$1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            ]),
          )).toList()),
        ]),
      ),
    );
  }

  void _saveProject(CanvasProvider provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Project saved!'), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _exportAsPng(CanvasProvider provider) async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/design_export.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], text: 'My Home Design');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _exportAsPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF export coming soon'), behavior: SnackBarBehavior.floating),
    );
  }
}
