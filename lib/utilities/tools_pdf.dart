import 'dart:io' as io;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../theme/app_theme.dart';
import 'tool_shared.dart';

Future<Uint8List> _bytesFromPlatformFile(PlatformFile f) async {
  if (f.bytes != null) {
    return f.bytes!;
  }
  final p = f.path;
  if (p == null) {
    throw StateError('File path not available.');
  }
  final raw = await io.File(p).readAsBytes();
  return Uint8List.fromList(raw);
}

/// Matches web stub — picks file + mode.
class PdfWordToolBody extends StatefulWidget {
  const PdfWordToolBody({super.key});

  @override
  State<PdfWordToolBody> createState() => _PdfWordToolBodyState();
}

class _PdfWordToolBodyState extends State<PdfWordToolBody> {
  String _mode = 'pdf-to-word';
  String _status = 'Choose a file and tap Convert.';

  Future<void> _pickAndStub() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (r == null || r.files.isEmpty) {
      return;
    }
    final name = r.files.single.name;
    final label = _mode.replaceAll('-', ' ');
    setState(
      () => _status = '"$name" selected for $label. (Preview utility — same as website)',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        toolSectionCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _mode,
                decoration: const InputDecoration(
                  labelText: 'Direction',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pdf-to-word', child: Text('PDF to Word')),
                  DropdownMenuItem(value: 'word-to-pdf', child: Text('Word to PDF')),
                ],
                onChanged: (v) => setState(() => _mode = v ?? _mode),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _pickAndStub,
                icon: const Icon(Icons.folder_open),
                label: const Text('Choose file · Convert'),
              ),
              const SizedBox(height: 12),
              Text(
                _status,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PdfMergeSplitToolBody extends StatefulWidget {
  const PdfMergeSplitToolBody({super.key});

  @override
  State<PdfMergeSplitToolBody> createState() => _PdfMergeSplitToolBodyState();
}

class _PdfMergeSplitToolBodyState extends State<PdfMergeSplitToolBody> {
  String _mode = 'merge';
  final _rangeCtrl = TextEditingController();
  bool _busy = false;
  String _message = 'Select PDFs and tap Run.';

  @override
  void dispose() {
    _rangeCtrl.dispose();
    super.dispose();
  }

  Future<Uint8List> _mergePdfs(List<Uint8List> inputs) async {
    final merged = PdfDocument();
    try {
      for (final raw in inputs) {
        final src = PdfDocument(inputBytes: raw);
        try {
          final count = src.pages.count;
          for (var i = 0; i < count; i++) {
            final srcPage = src.pages[i];
            final template = srcPage.createTemplate();
            final dest = merged.pages.add();
            dest.graphics.drawPdfTemplate(
              template,
              Offset.zero,
              srcPage.getClientSize(),
            );
          }
        } finally {
          src.dispose();
        }
      }
      final saved = await merged.save();
      return Uint8List.fromList(saved);
    } finally {
      merged.dispose();
    }
  }

  Future<Uint8List> _splitPdf(Uint8List bytes, int start, int end) async {
    final src = PdfDocument(inputBytes: bytes);
    try {
      final total = src.pages.count;
      if (start < 1 || end > total || start > end) {
        throw StateError('Invalid range. This PDF has $total pages.');
      }
      final out = PdfDocument();
      try {
        for (var i = start - 1; i <= end - 1; i++) {
          final srcPage = src.pages[i];
          final template = srcPage.createTemplate();
          final dest = out.pages.add();
          dest.graphics.drawPdfTemplate(
            template,
            Offset.zero,
            srcPage.getClientSize(),
          );
        }
        final saved = await out.save();
        return Uint8List.fromList(saved);
      } finally {
        out.dispose();
      }
    } finally {
      src.dispose();
    }
  }

  Future<void> _run() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _message = 'Processing…';
    });
    try {
      if (_mode == 'merge') {
        final r = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          allowMultiple: true,
        );
        if (r == null || r.files.isEmpty) {
          setState(() => _message = 'Select at least one PDF.');
          return;
        }
        final buffers = <Uint8List>[];
        for (final f in r.files) {
          buffers.add(await _bytesFromPlatformFile(f));
        }
        final out = await _mergePdfs(buffers);
        await shareBytesAsFile(out, 'merged.pdf');
        setState(() => _message = 'Merged ${buffers.length} PDFs. The share sheet should open.');
      } else {
        final r = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          allowMultiple: false,
        );
        if (r == null || r.files.isEmpty) {
          setState(() => _message = 'Select one PDF.');
          return;
        }
        final bytes = await _bytesFromPlatformFile(r.files.single);
        final re = RegExp(r'^(\d+)\s*-\s*(\d+)$');
        final m = re.firstMatch(_rangeCtrl.text.trim());
        if (m == null) {
          setState(() => _message = 'Enter a range like 1-3.');
          return;
        }
        final start = int.parse(m.group(1)!);
        final end = int.parse(m.group(2)!);
        final out = await _splitPdf(bytes, start, end);
        await shareBytesAsFile(out, 'split-pages-$start-$end.pdf');
        setState(() => _message = 'Pages $start–$end ready. The share sheet should open.');
      }
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        toolSectionCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _mode,
                decoration: const InputDecoration(
                  labelText: 'Mode',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'merge', child: Text('Merge PDFs')),
                  DropdownMenuItem(value: 'split', child: Text('Split PDF')),
                ],
                onChanged: _busy ? null : (v) => setState(() => _mode = v ?? _mode),
              ),
              if (_mode == 'split') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _rangeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Page range (e.g. 1-3)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy ? null : _run,
                icon: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_busy ? 'Please wait…' : 'Run PDF Tool'),
              ),
              const SizedBox(height: 12),
              Text(
                _message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ImageToPdfToolBody extends StatefulWidget {
  const ImageToPdfToolBody({super.key});

  @override
  State<ImageToPdfToolBody> createState() => _ImageToPdfToolBodyState();
}

class _ImageToPdfToolBodyState extends State<ImageToPdfToolBody> {
  List<PlatformFile>? _selectedFiles;
  String _pageSize = 'A4';
  bool _landscape = false;
  bool _busy = false;
  String _message = 'Select images and tap Convert.';

  static const Map<String, double> _pageW = {
    'A4': 595.28, 'Letter': 612, 'Legal': 612,
  };
  static const Map<String, double> _pageH = {
    'A4': 841.89, 'Letter': 792, 'Legal': 1008,
  };

  Future<void> _pickImages() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (r == null || r.files.isEmpty) return;
    setState(() {
      _selectedFiles = r.files;
      _message = '${r.files.length} image(s) selected.';
    });
  }

  Future<void> _convert() async {
    if (_busy || _selectedFiles == null || _selectedFiles!.isEmpty) return;
    setState(() { _busy = true; _message = 'Creating PDF…'; });
    try {
      final doc = PdfDocument();
      final pw = _landscape ? _pageH[_pageSize]! : _pageW[_pageSize]!;
      final ph = _landscape ? _pageW[_pageSize]! : _pageH[_pageSize]!;
      const margin = 20.0;
      final maxW = pw - margin * 2;
      final maxH = ph - margin * 2;

      for (final f in _selectedFiles!) {
        final bytes = await _bytesFromPlatformFile(f);
        final bitmap = PdfBitmap(bytes);
        final scale = (maxW / bitmap.width).clamp(0.0, maxH / bitmap.height);
        final drawW = bitmap.width * scale;
        final drawH = bitmap.height * scale;
        final page = doc.pages.add();
        page.graphics.drawImage(
          bitmap,
          Rect.fromLTWH((pw - drawW) / 2, (ph - drawH) / 2, drawW, drawH),
        );
      }

      final saved = await doc.save();
      doc.dispose();
      await shareBytesAsFile(Uint8List.fromList(saved), 'images.pdf');
      setState(() => _message = 'PDF created. Share sheet should open.');
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        toolSectionCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.image),
                label: const Text('Pick Images'),
              ),
              if (_selectedFiles != null && _selectedFiles!.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedFiles!.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final f = _selectedFiles![i];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: f.bytes != null
                            ? Image.memory(f.bytes!, width: 80, height: 80, fit: BoxFit.cover)
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
                              ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _pageSize,
                decoration: const InputDecoration(
                  labelText: 'Page Size',
                  border: OutlineInputBorder(),
                ),
                items: ['A4', 'Letter', 'Legal']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _pageSize = v ?? _pageSize),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Landscape'),
                  const Spacer(),
                  Switch(
                    value: _landscape,
                    onChanged: (v) => setState(() => _landscape = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy ? null : _convert,
                icon: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_busy ? 'Please wait…' : 'Convert to PDF'),
              ),
              const SizedBox(height: 12),
              Text(
                _message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PdfWatermarkToolBody extends StatefulWidget {
  const PdfWatermarkToolBody({super.key});

  @override
  State<PdfWatermarkToolBody> createState() => _PdfWatermarkToolBodyState();
}

class _PdfWatermarkToolBodyState extends State<PdfWatermarkToolBody> {
  PlatformFile? _file;
  final _textCtrl = TextEditingController();
  double _opacity = 0.3;
  double _rotation = 45;
  String _color = 'Red';
  bool _busy = false;
  String _message = 'Select a PDF and configure watermark.';

  static final Map<String, PdfColor> _colors = {
    'Red': PdfColor(255, 0, 0),
    'Blue': PdfColor(0, 0, 255),
    'Black': PdfColor(0, 0, 0),
    'Gray': PdfColor(128, 128, 128),
  };

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (r == null || r.files.isEmpty) return;
    setState(() {
      _file = r.files.single;
      _message = '${_file!.name} selected.';
    });
  }

  Future<void> _apply() async {
    if (_busy || _file == null) return;
    if (_textCtrl.text.trim().isEmpty) {
      setState(() => _message = 'Enter watermark text.');
      return;
    }
    setState(() { _busy = true; _message = 'Applying watermark…'; });
    try {
      final bytes = await _bytesFromPlatformFile(_file!);
      final doc = PdfDocument(inputBytes: bytes);
      final font = PdfStandardFont(PdfFontFamily.helvetica, 60);
      final brush = PdfSolidBrush(_colors[_color]!);
      final text = _textCtrl.text.trim();

      for (var i = 0; i < doc.pages.count; i++) {
        final page = doc.pages[i];
        final size = page.getClientSize();
        final g = page.graphics;
        g.save();
        g.translateTransform(size.width / 2, size.height / 2);
        g.rotateTransform(_rotation);
        g.setTransparency(_opacity);
        g.drawString(
          text,
          font,
          brush: brush,
          bounds: const Rect.fromLTWH(-500, -30, 1000, 60),
        );
        g.restore();
      }

      final saved = await doc.save();
      doc.dispose();
      await shareBytesAsFile(Uint8List.fromList(saved), 'watermarked.pdf');
      setState(() => _message = 'Watermark applied. Share sheet should open.');
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        toolSectionCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: _pickPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(_file != null ? _file!.name : 'Choose PDF'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textCtrl,
                decoration: const InputDecoration(
                  labelText: 'Watermark Text',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text('Opacity: ${_opacity.toStringAsFixed(1)}'),
              Slider(
                value: _opacity,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                onChanged: (v) => setState(() => _opacity = v),
              ),
              const SizedBox(height: 8),
              Text('Rotation: ${_rotation.round()}°'),
              Slider(
                value: _rotation,
                min: 0,
                max: 360,
                divisions: 36,
                onChanged: (v) => setState(() => _rotation = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _color,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                ),
                items: _colors.keys
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _color = v ?? _color),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy ? null : _apply,
                icon: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.water_drop),
                label: Text(_busy ? 'Please wait…' : 'Apply Watermark'),
              ),
              const SizedBox(height: 12),
              Text(
                _message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PdfPasswordToolBody extends StatefulWidget {
  const PdfPasswordToolBody({super.key});

  @override
  State<PdfPasswordToolBody> createState() => _PdfPasswordToolBodyState();
}

class _PdfPasswordToolBodyState extends State<PdfPasswordToolBody> {
  PlatformFile? _file;
  final _ownerCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  bool _busy = false;
  String _message = 'Select a PDF and set passwords.';

  @override
  void dispose() {
    _ownerCtrl.dispose();
    _userCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (r == null || r.files.isEmpty) return;
    setState(() {
      _file = r.files.single;
      _message = '${_file!.name} selected.';
    });
  }

  Future<void> _protect() async {
    if (_busy || _file == null) return;
    if (_ownerCtrl.text.isEmpty) {
      setState(() => _message = 'Owner password is required.');
      return;
    }
    setState(() { _busy = true; _message = 'Protecting PDF…'; });
    try {
      final bytes = await _bytesFromPlatformFile(_file!);
      final doc = PdfDocument(inputBytes: bytes);
      doc.security.ownerPassword = _ownerCtrl.text;
      if (_userCtrl.text.isNotEmpty) {
        doc.security.userPassword = _userCtrl.text;
      }

      final saved = await doc.save();
      doc.dispose();
      await shareBytesAsFile(Uint8List.fromList(saved), 'protected.pdf');
      setState(() => _message = 'Password applied. Share sheet should open.');
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        toolSectionCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: _pickPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(_file != null ? _file!.name : 'Choose PDF'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ownerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Owner Password (required)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _userCtrl,
                decoration: const InputDecoration(
                  labelText: 'User Password (optional)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy ? null : _protect,
                icon: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.lock_outline),
                label: Text(_busy ? 'Please wait…' : 'Protect PDF'),
              ),
              const SizedBox(height: 12),
              Text(
                _message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
