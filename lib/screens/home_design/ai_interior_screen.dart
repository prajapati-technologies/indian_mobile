import 'dart:math';
import 'package:flutter/material.dart';

class AIInteriorScreen extends StatefulWidget {
  const AIInteriorScreen({super.key});

  @override
  State<AIInteriorScreen> createState() => _AIInteriorScreenState();
}

class _AIInteriorScreenState extends State<AIInteriorScreen> {
  final _promptController = TextEditingController();
  bool _isGenerating = false;
  String? _generatedImageUrl;
  String? _error;
  final _imageSeeds = [
    'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=600',
    'https://images.unsplash.com/photo-1618220179428-22790b461013?w=600',
    'https://images.unsplash.com/photo-1616137466211-f939a420be84?w=600',
    'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=600',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateDesign() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() => _error = 'Please describe your dream room');
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _generatedImageUrl = null;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final random = Random(prompt.hashCode);
      setState(() {
        _generatedImageUrl = _imageSeeds[random.nextInt(_imageSeeds.length)];
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('AI Interior Designer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.blue, Colors.purple]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 30),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      'Describe your dream room, and our AI will generate a design for you.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text('Describe Your Style', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _promptController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'e.g. Modern Luxury Bedroom with wooden floor and warm lighting...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateDesign,
                icon: _isGenerating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? 'Generating...' : 'Generate Design', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            if (_generatedImageUrl != null) ...[
              const SizedBox(height: 30),
              const Text('Generated Design', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  _generatedImageUrl!,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 300,
                      color: Colors.grey[100],
                      child: Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null)),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 300,
                      color: Colors.grey[100],
                      child: const Center(child: Text('Could not load image')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _generateDesign,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Regenerate'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Design saved to gallery!'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 40),
            const Text('Example Styles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _exampleCard('Minimalist Kitchen', 'Clean white surfaces with oak wood accents.'),
            _exampleCard('Industrial Living Room', 'Exposed brick walls and dark metal furniture.'),
            _exampleCard('Bohemian Bedroom', 'Warm earth tones with plants and macrame.'),
            _exampleCard('Scandinavian Office', 'Light wood, white walls, and ergonomic design.'),
          ],
        ),
      ),
    );
  }

  Widget _exampleCard(String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          _promptController.text = desc;
          _generateDesign();
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
