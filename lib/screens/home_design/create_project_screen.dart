import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'project_editor_screen.dart';
import '../../providers/canvas_provider.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _nameController = TextEditingController(text: 'My Dream Home');
  final _widthController = TextEditingController(text: '40');
  final _heightController = TextEditingController(text: '60');
  int _floors = 1;
  bool _isCreating = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Project', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ),
            _label('Project Name'),
            const SizedBox(height: 8),
            _input(_nameController, 'e.g. My Dream Home'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Width (ft)'),
                      const SizedBox(height: 8),
                      _input(_widthController, '40', keyboardType: TextInputType.number),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Height (ft)'),
                      const SizedBox(height: 8),
                      _input(_heightController, '60', keyboardType: TextInputType.number),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _label('Floors'),
            const SizedBox(height: 12),
            Row(
              children: [
                _floorBtn(1),
                _floorBtn(2),
                _floorBtn(3),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createProject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3436),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: _isCreating
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Create Project', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createProject() {
    final name = _nameController.text.trim();
    final widthText = _widthController.text.trim();
    final heightText = _heightController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter a project name');
      return;
    }
    final width = double.tryParse(widthText);
    final height = double.tryParse(heightText);
    if (width == null || width <= 0) {
      setState(() => _error = 'Please enter a valid width');
      return;
    }
    if (height == null || height <= 0) {
      setState(() => _error = 'Please enter a valid height');
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });

    Provider.of<CanvasProvider>(context, listen: false).initializePlot(width, height);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProjectEditorScreen()));
      }
    });
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87));

  Widget _input(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF0F2F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _floorBtn(int count) {
    bool active = _floors == count;
    return GestureDetector(
      onTap: () => setState(() => _floors = count),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 60,
        height: 50,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2D3436) : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text('$count', style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
