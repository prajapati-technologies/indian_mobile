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
import '../../models/design_catalog.dart';
import 'three_d_preview_screen.dart';
import 'ai_interior_screen.dart';
import 'create_project_screen.dart';

class ProjectEditorScreen extends StatefulWidget {
  final String? projectId;
  const ProjectEditorScreen({super.key, this.projectId});
  @override
  State<ProjectEditorScreen> createState() => _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends State<ProjectEditorScreen> {
  int _selectedToolIndex = -1;
  final _canvasKey = GlobalKey();
  final _transformCtrl = TransformationController();
  bool _placingFurniture = false;
  String? _pendingFurnitureType;
  String _pendingFurnitureStyle = '';
  double _pendingFurnitureW = 60;
  double _pendingFurnitureH = 60;
  Color _pendingFurnitureColor = Colors.orange;
  String _hintText = '';

  Offset _toCanvas(Offset p) => _transformCtrl.toScene(p);

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<CanvasProvider>(context, listen: false);
      if (p.canvasWidth > 0) {
        _transformCtrl.value = Matrix4.identity()..translate(-30, -30);
      }
      setState(() => _hintText = 'Select a tool below to start designing');
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _hintText = '');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CanvasProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Row(children: [
          const Text('Design Editor', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
          if (provider.plotWidthFt > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Text('${provider.plotWidthFt.toInt()}x${provider.plotHeightFt.toInt()}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ),
          ],
        ]),
        actions: [
          IconButton(icon: Icon(Icons.undo, color: provider.canUndo ? Colors.black54 : Colors.grey.shade300), onPressed: provider.canUndo ? () => provider.undo() : null),
          IconButton(icon: Icon(Icons.redo, color: provider.canRedo ? Colors.black54 : Colors.grey.shade300), onPressed: provider.canRedo ? () => provider.redo() : null),
          IconButton(icon: const Icon(Icons.auto_awesome, color: Colors.purple), tooltip: 'AI Design', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIInteriorScreen()))),
          IconButton(icon: const Icon(Icons.view_in_ar, color: Colors.blue), tooltip: '3D View', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ThreeDPreviewScreen(walls: provider.walls, furniture: provider.furniture)))),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onSelected: (v) {
              if (v == 'regen') _regenerateLayout(provider);
              if (v == 'export') _exportAsPng(provider);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'regen', child: ListTile(leading: Icon(Icons.refresh, size: 20), title: Text('Regenerate', style: TextStyle(fontSize: 14)))),
              const PopupMenuItem(value: 'export', child: ListTile(leading: Icon(Icons.image, size: 20), title: Text('Export PNG', style: TextStyle(fontSize: 14)))),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Canvas
          GestureDetector(
            behavior: _placingFurniture ? HitTestBehavior.translucent : HitTestBehavior.deferToChild,
            onPanStart: (details) {
              if (_placingFurniture) return;
              final c = _toCanvas(details.localPosition);
              if (_selectedToolIndex == 0) { provider.startDrawingWall(c); return; }
              provider.selectObject(c);
            },
            onPanUpdate: (details) {
              if (_placingFurniture) return;
              final c = _toCanvas(details.localPosition);
              if (_selectedToolIndex == 0) { provider.updateDrawingWall(c); return; }
              if (provider.selectedObject != null) provider.moveSelected(details.delta);
            },
            onPanEnd: (_) {
              if (_placingFurniture) return;
              if (_selectedToolIndex == 0) provider.endDrawingWall();
            },
            onTapDown: (details) {
              final c = _toCanvas(details.localPosition);

              // Furniture placement mode
              if (_placingFurniture && _pendingFurnitureType != null) {
                provider.addFurniture(_pendingFurnitureType!,
                  position: c,
                  styleName: _pendingFurnitureStyle,
                  width: _pendingFurnitureW,
                  height: _pendingFurnitureH,
                  color: _pendingFurnitureColor,
                );
                setState(() { _placingFurniture = false; _pendingFurnitureType = null; _hintText = ''; });
                return;
              }

              if (_selectedToolIndex == 1) { provider.addOpening(OpeningType.door, c); return; }
              if (_selectedToolIndex == 2) { provider.addOpening(OpeningType.window, c); return; }
              if (_selectedToolIndex == -1) provider.selectObject(c);
            },
            child: RepaintBoundary(
              key: _canvasKey,
              child: InteractiveViewer(
                transformationController: _transformCtrl,
                minScale: 0.2,
                maxScale: 4.0,
                constrained: false,
                child: SizedBox(
                  width: provider.canvasWidth + 200,
                  height: provider.canvasHeight + 200,
                  child: CustomPaint(
                    size: Size(provider.canvasWidth + 200, provider.canvasHeight + 200),
                    painter: SmartPainter(
                      walls: provider.walls,
                      furniture: provider.furniture,
                      tempWall: provider.tempWall,
                      selectedObject: provider.selectedObject,
                      rooms: provider.rooms,
                      gridSize: provider.gridSize,
                      selectedRoomIndex: provider.selectedRoomIndex,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Hint text
          if (_hintText.isNotEmpty)
            Positioned(top: 16, left: 0, right: 0, child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_hintText, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
            )),

          // Placement mode indicator
          if (_placingFurniture)
            Positioned(top: 16, right: 16, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.touch_app, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text('Tap canvas to place $_pendingFurnitureType', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ]),
            )),

          // Selected object / Room popup
          if (provider.selectedObject != null)
            Positioned(top: 80, left: 12, child: _objectPopup(provider)),
          if (provider.selectedRoomIndex != null && provider.selectedObject == null)
            Positioned(top: 80, left: 12, child: _roomPopup(provider)),

          // Bottom toolbar
          Positioned(bottom: 20, left: 12, right: 12, child: _toolbar(provider)),
        ],
      ),
    );
  }

  void _regenerateLayout(CanvasProvider provider) {
    if (provider.plotWidthFt <= 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CreateProjectScreen()));
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Regenerate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () { Navigator.pop(ctx); provider.initializePlot(provider.plotWidthFt, provider.plotHeightFt); },
            icon: const Icon(Icons.refresh),
            label: Text('Auto Layout (${provider.plotWidthFt.toInt()}x${provider.plotHeightFt.toInt()} ft)'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () { Navigator.pop(ctx); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CreateProjectScreen())); },
            icon: const Icon(Icons.add),
            label: const Text('New Project'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
        ]),
      ),
    );
  }

  Widget _toolbar(CanvasProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolBtn(0, Icons.edit_note, 'Wall', Colors.indigo, provider),
          _toolBtn(1, Icons.sensor_door_outlined, 'Door', Colors.brown, provider),
          _toolBtn(2, Icons.window_outlined, 'Window', Colors.blue, provider),
          _toolBtn(3, Icons.chair_outlined, 'Furniture', Colors.orange, provider),
          _toolBtn(4, Icons.format_paint, 'Paint', Colors.teal, provider),
          _toolBtn(5, Icons.refresh, 'Regen', Colors.grey.shade600, provider),
        ],
      ),
    );
  }

  Widget _toolBtn(int index, IconData icon, String label, Color color, CanvasProvider provider) {
    bool sel = _selectedToolIndex == index;
    bool isRegen = index == 5;

    return GestureDetector(
      onTap: isRegen
        ? () => _regenerateLayout(provider)
        : () {
            setState(() {
              _selectedToolIndex = sel ? -1 : index;
              _placingFurniture = false;
              _hintText = sel ? '' : _hintForTool(index);
            });
            if (index == 1 && _selectedToolIndex == 1) _showDoorDesigns(provider);
            if (index == 2 && _selectedToolIndex == 2) _showWindowDesigns(provider);
            if (index == 3 && _selectedToolIndex == 3) _showFurnitureLibrary(provider);
            if (index == 4 && _selectedToolIndex == 4) _showTextureSelector(provider);
          },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: sel ? 14 : 10, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: sel ? color : Colors.grey.shade600, size: 22),
          if (sel) ...[
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ]),
      ),
    );
  }

  String _hintForTool(int index) {
    switch (index) {
      case 0: return 'Drag on canvas to draw walls';
      case 1: return 'Pick a door style → tap wall to place';
      case 2: return 'Pick a window style → tap wall to place';
      case 3: return 'Pick furniture style → tap canvas to place';
      case 4: return 'Select a wall → pick a color';
      default: return '';
    }
  }

  // ---- POPUPS ----
  Widget _objectPopup(CanvasProvider provider) {
    final obj = provider.selectedObject;
    if (obj is WallModel) {
      final dist = (obj.start - obj.end).distance / 10;
      return _popCard([
        Row(children: [
          Icon(Icons.edit_note, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text('Wall  ${dist.toInt()}ft', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _btn(Icons.delete_outline, Colors.red, () => provider.deleteSelected()),
          const Spacer(),
          _btn(Icons.check, Colors.blue, () => provider.selectObject(const Offset(-9999, -9999)), filled: true),
        ]),
      ]);
    }
    if (obj is FurnitureModel) {
      return _popCard([
        Row(children: [
          _furnIcon(obj.type, 18, obj.color),
          const SizedBox(width: 6),
          Expanded(child: Text(obj.styleName.isNotEmpty ? obj.styleName : obj.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _btn(Icons.rotate_left, Colors.blue, () => provider.rotateSelectedFurniture(-1.57)),
          _btn(Icons.rotate_right, Colors.blue, () => provider.rotateSelectedFurniture(1.57)),
          _btn(Icons.delete_outline, Colors.red, () => provider.deleteSelected()),
          _btn(Icons.check, Colors.blue, () => provider.selectObject(const Offset(-9999, -9999)), filled: true),
        ]),
      ]);
    }
    return const SizedBox.shrink();
  }

  Widget _roomPopup(CanvasProvider provider) {
    final room = provider.rooms[provider.selectedRoomIndex!];
    final w = (room.rect.width / 10).toInt();
    final h = (room.rect.height / 10).toInt();
    return _popCard([
      Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: room.color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(room.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
      const SizedBox(height: 4),
      Text('${w}ft × ${h}ft', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      const SizedBox(height: 8),
      Row(children: [
        _btn(Icons.check, Colors.blue, () => provider.selectObject(const Offset(-9999, -9999)), filled: true),
      ]),
    ]);
  }

  Widget _popCard(List<Widget> children) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }

  Widget _btn(IconData icon, Color color, VoidCallback onTap, {bool filled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _furnIcon(String type, double size, Color color) {
    IconData icon;
    switch (type) {
      case 'Sofa': icon = Icons.weekend; break;
      case 'Bed': icon = Icons.bed; break;
      case 'Table': icon = Icons.table_restaurant; break;
      case 'Chair': icon = Icons.chair; break;
      case 'Wardrobe': icon = Icons.shelves; break;
      case 'Desk': icon = Icons.desk; break;
      default: icon = Icons.chair;
    }
    return Icon(icon, size: size, color: color);
  }

  // ---- DESIGN PICKERS ----
  void _showDoorDesigns(CanvasProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Choose Door', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10,
            children: DesignCatalog.doors.map((d) => GestureDetector(
              onTap: () {
                provider.setDoorDesign(d.name, d.color, d.width);
                Navigator.pop(ctx);
                setState(() => _hintText = 'Tap a wall to place ${d.name} door');
                Future.delayed(const Duration(seconds: 3), () { if (mounted && _hintText.contains('door')) setState(() => _hintText = ''); });
              },
              child: Container(
                width: 88, padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: d.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: d.color.withValues(alpha: 0.3)),
                ),
                child: Column(children: [
                  Icon(d.icon, color: d.color, size: 28),
                  const SizedBox(height: 4),
                  Text(d.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: d.color)),
                ]),
              ),
            )).toList(),
          ),
        ]),
      ),
    );
  }

  void _showWindowDesigns(CanvasProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Choose Window', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10,
            children: DesignCatalog.windows.map((w) => GestureDetector(
              onTap: () {
                provider.setWindowDesign(w.name, w.color, w.width);
                Navigator.pop(ctx);
                setState(() => _hintText = 'Tap a wall to place ${w.name} window');
                Future.delayed(const Duration(seconds: 3), () { if (mounted && _hintText.contains('window')) setState(() => _hintText = ''); });
              },
              child: Container(
                width: 88, padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: w.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: w.color.withValues(alpha: 0.3)),
                ),
                child: Column(children: [
                  Icon(w.icon, color: w.color, size: 28),
                  const SizedBox(height: 4),
                  Text(w.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: w.color)),
                ]),
              ),
            )).toList(),
          ),
        ]),
      ),
    );
  }

  void _showFurnitureLibrary(CanvasProvider provider) {
    var cats = DesignCatalog.furnitureCategories.entries.toList();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Furniture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: ListView(scrollDirection: Axis.horizontal,
              children: cats.map((cat) => GestureDetector(
                onTap: () => _showFurnitureStyles(ctx, provider, cat.key, cat.value),
                child: Container(
                  width: 78, margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: cat.value.first.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cat.value.first.color.withValues(alpha: 0.2)),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(cat.value.first.icon, color: cat.value.first.color, size: 26),
                    const SizedBox(height: 4),
                    Text(cat.key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cat.value.first.color)),
                  ]),
                ),
              )).toList(),
            ),
          ),
        ]),
      ),
    );
  }

  void _showFurnitureStyles(BuildContext parentCtx, CanvasProvider provider, String category, List<FurnitureDesign> styles) {
    Navigator.pop(parentCtx);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$category Styles', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10,
            children: styles.map((s) => GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _placingFurniture = true;
                  _pendingFurnitureType = category;
                  _pendingFurnitureStyle = s.name;
                  _pendingFurnitureW = s.width;
                  _pendingFurnitureH = s.height;
                  _pendingFurnitureColor = s.color;
                  _hintText = 'Tap on canvas to place $category';
                  _selectedToolIndex = -1;
                });
                Future.delayed(const Duration(seconds: 4), () { if (mounted && _hintText.contains('place $category')) setState(() => _hintText = ''); });
              },
              child: Container(
                width: 98, padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: s.color.withValues(alpha: 0.3)),
                ),
                child: Column(children: [
                  Icon(s.icon, color: s.color, size: 26),
                  const SizedBox(height: 4),
                  Text(s.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: s.color)),
                  Text('${s.width.toInt()}x${s.height.toInt()}', style: TextStyle(fontSize: 9, color: s.color.withValues(alpha: 0.5))),
                ]),
              ),
            )).toList(),
          ),
        ]),
      ),
    );
  }

  void _showTextureSelector(CanvasProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Wall Color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: DesignCatalog.textures.map((t) => GestureDetector(
            onTap: () { provider.applyTextureToSelected(t.color); Navigator.pop(ctx); },
            child: Column(children: [
              Container(width: 52, height: 52,
                decoration: BoxDecoration(color: t.color, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.borderColor, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)]),
                child: Icon(t.icon, color: t.borderColor.withValues(alpha: 0.35), size: 22),
              ),
              const SizedBox(height: 4),
              Text(t.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
            ]),
          )).toList()),
        ]),
      ),
    );
  }

  // ---- EXPORT ----
  Future<void> _exportAsPng(CanvasProvider provider) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendering...'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
      );
      final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/home_design.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      if (mounted) await Share.shareXFiles([XFile(file.path)], text: 'My Home Design');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }
}
