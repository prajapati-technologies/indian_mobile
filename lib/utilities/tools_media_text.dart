import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_theme.dart';
import 'tool_shared.dart';

Future<Uint8List> _bytesFromPath(String path) async {
  final d = await io.File(path).readAsBytes();
  return Uint8List.fromList(d);
}

class ImageCompressorToolBody extends StatefulWidget {
  const ImageCompressorToolBody({super.key});

  @override
  State<ImageCompressorToolBody> createState() => _ImageCompressorToolBodyState();
}

class _ImageCompressorToolBodyState extends State<ImageCompressorToolBody> {
  double _q = 0.7;
  String _status = 'Select an image.';
  Uint8List? _preview;

  Future<void> _pickAndCompress() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (r == null || r.files.isEmpty) {
      return;
    }
    final f = r.files.single;
    final raw = f.bytes ?? (f.path != null ? await _bytesFromPath(f.path!) : null);
    if (raw == null) {
      setState(() => _status = 'Could not read the file.');
      return;
    }
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      setState(() => _status = 'Could not decode the image.');
      return;
    }
    final q = (_q * 100).round().clamp(10, 100);
    final jpg = img.encodeJpg(decoded, quality: q);
    setState(() {
      _preview = Uint8List.fromList(jpg);
      _status =
          'Original ~${(raw.length / 1024).toStringAsFixed(1)} KB → Compressed ~${(jpg.length / 1024).toStringAsFixed(1)} KB';
    });
  }

  Future<void> _share() async {
    final p = _preview;
    if (p == null) {
      return;
    }
    await shareBytesAsFile(p, 'compressed.jpg');
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
              Text('Quality: ${_q.toStringAsFixed(1)}', style: Theme.of(context).textTheme.titleSmall),
              Slider(
                value: _q,
                min: 0.1,
                max: 1,
                divisions: 9,
                onChanged: (v) => setState(() => _q = v),
              ),
              FilledButton.icon(
                onPressed: _pickAndCompress,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Select image · Compress'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _preview == null ? null : _share,
                icon: const Icon(Icons.share),
                label: const Text('Share compressed'),
              ),
              const SizedBox(height: 8),
              Text(_status, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              if (_preview != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_preview!, fit: BoxFit.contain),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ImageResizeToolBody extends StatefulWidget {
  const ImageResizeToolBody({super.key});

  @override
  State<ImageResizeToolBody> createState() => _ImageResizeToolBodyState();
}

class _ImageResizeToolBodyState extends State<ImageResizeToolBody> {
  final _wCtrl = TextEditingController();
  final _hCtrl = TextEditingController();
  String _format = 'jpg';
  String _status = 'Select an image.';
  Uint8List? _out;

  @override
  void dispose() {
    _wCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (r == null || r.files.isEmpty) {
      return;
    }
    final f = r.files.single;
    final raw = f.bytes ?? (f.path != null ? await _bytesFromPath(f.path!) : null);
    if (raw == null) {
      setState(() => _status = 'Could not read the file.');
      return;
    }
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      setState(() => _status = 'Decode failed.');
      return;
    }
    var tw = int.tryParse(_wCtrl.text.trim()) ?? 0;
    var th = int.tryParse(_hCtrl.text.trim()) ?? 0;
    if (tw <= 0 && th <= 0) {
      tw = decoded.width;
      th = decoded.height;
    } else if (tw <= 0) {
      tw = (decoded.width * th / decoded.height).round();
    } else if (th <= 0) {
      th = (decoded.height * tw / decoded.width).round();
    }
    final resized = img.copyResize(decoded, width: tw, height: th);
    late List<int> encoded;
    if (_format == 'png') {
      encoded = img.encodePng(resized);
    } else {
      encoded = img.encodeJpg(resized, quality: 90);
    }
    setState(() {
      _out = Uint8List.fromList(encoded);
      _status =
          'Ready: ${tw}x$th · ${(encoded.length / 1024).toStringAsFixed(1)} KB — tap Share below.';
    });
  }

  Future<void> _shareResult() async {
    final o = _out;
    if (o == null) {
      return;
    }
    final ext = _format == 'png' ? 'png' : 'jpg';
    await shareBytesAsFile(o, 'converted.$ext');
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _wCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Width (px)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _hCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Height (px)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _format,
                decoration: const InputDecoration(
                  labelText: 'Format',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'jpg', child: Text('JPG')),
                  DropdownMenuItem(value: 'png', child: Text('PNG')),
                ],
                onChanged: (v) => setState(() => _format = v ?? 'jpg'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _run,
                icon: const Icon(Icons.aspect_ratio),
                label: const Text('Resize & Convert'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _out == null ? null : _shareResult,
                icon: const Icon(Icons.share),
                label: const Text('Share file'),
              ),
              const SizedBox(height: 8),
              Text(_status, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class WordCountToolBody extends StatefulWidget {
  const WordCountToolBody({super.key});

  @override
  State<WordCountToolBody> createState() => _WordCountToolBodyState();
}

class _WordCountToolBodyState extends State<WordCountToolBody> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Map<String, int> _stats(String t) {
    final words = t.trim().isEmpty ? 0 : RegExp(r'\S+').allMatches(t.trim()).length;
    final chars = t.length;
    final noSpace = t.replaceAll(RegExp(r'\s'), '').length;
    final lines = t.isEmpty ? 0 : t.split(RegExp(r'\r\n|\r|\n')).length;
    return {'words': words, 'chars': chars, 'ns': noSpace, 'lines': lines};
  }

  void _case(String mode) {
    final t = _ctrl.text;
    if (mode == 'upper') {
      _ctrl.text = t.toUpperCase();
    } else if (mode == 'lower') {
      _ctrl.text = t.toLowerCase();
    } else if (mode == 'title') {
      _ctrl.text = t.split(RegExp(r'\s+')).map((w) {
        if (w.isEmpty) {
          return w;
        }
        return w[0].toUpperCase() + w.substring(1).toLowerCase();
      }).join(' ');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = _stats(_ctrl.text);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        toolSectionCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _ctrl,
                onChanged: (_) => setState(() {}),
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Type or paste text here',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(onPressed: () => _case('upper'), child: const Text('UPPER')),
                  OutlinedButton(onPressed: () => _case('lower'), child: const Text('lower')),
                  OutlinedButton(onPressed: () => _case('title'), child: const Text('Title')),
                  TextButton(onPressed: () => setState(() => _ctrl.clear()), child: const Text('Clear')),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Words: ${s['words']} · Chars: ${s['chars']} · No-space: ${s['ns']} · Lines: ${s['lines']}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.brandNavy),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class OcrToolBody extends StatefulWidget {
  const OcrToolBody({super.key});

  @override
  State<OcrToolBody> createState() => _OcrToolBodyState();
}

class _OcrToolBodyState extends State<OcrToolBody> {
  bool _busy = false;
  String _out = 'Select an image.';

  Future<void> _run() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.image);
    if (r == null || r.files.isEmpty) {
      return;
    }
    final path = r.files.single.path;
    if (path == null) {
      setState(() => _out = 'Path not available — choose again.');
      return;
    }
    setState(() {
      _busy = true;
      _out = 'Running OCR…';
    });
    final input = InputImage.fromFilePath(path);
    final rec = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final res = await rec.processImage(input);
      setState(() => _out = res.text.trim().isEmpty ? 'No text found.' : res.text);
    } finally {
      await rec.close();
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
              FilledButton.icon(
                onPressed: _busy ? null : _run,
                icon: const Icon(Icons.document_scanner_outlined),
                label: Text(_busy ? 'Please wait…' : 'Select image · Extract text'),
              ),
              const SizedBox(height: 12),
              SelectableText(_out, style: const TextStyle(height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}

class QrGeneratorToolBody extends StatefulWidget {
  const QrGeneratorToolBody({super.key});

  @override
  State<QrGeneratorToolBody> createState() => _QrGeneratorToolBodyState();
}

class _QrGeneratorToolBodyState extends State<QrGeneratorToolBody> {
  final _ctrl = TextEditingController();
  String _data = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
              TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  labelText: 'Text or URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => setState(() => _data = _ctrl.text.trim()),
                child: const Text('Generate QR'),
              ),
              const SizedBox(height: 16),
              if (_data.isNotEmpty)
                Center(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: QrImageView(
                      data: _data,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class BarcodeGeneratorToolBody extends StatefulWidget {
  const BarcodeGeneratorToolBody({super.key});

  @override
  State<BarcodeGeneratorToolBody> createState() => _BarcodeGeneratorToolBodyState();
}

class _BarcodeGeneratorToolBodyState extends State<BarcodeGeneratorToolBody> {
  final _ctrl = TextEditingController();
  String _val = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
              TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  labelText: 'Barcode value',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => setState(() => _val = _ctrl.text.trim()),
                child: const Text('Generate Barcode'),
              ),
              const SizedBox(height: 16),
              if (_val.isNotEmpty)
                Center(
                  child: BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: _val,
                    width: 280,
                    height: 80,
                    drawText: true,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class PasswordGeneratorToolBody extends StatefulWidget {
  const PasswordGeneratorToolBody({super.key});

  @override
  State<PasswordGeneratorToolBody> createState() => _PasswordGeneratorToolBodyState();
}

class _PasswordGeneratorToolBodyState extends State<PasswordGeneratorToolBody> {
  final _lenCtrl = TextEditingController(text: '12');
  String _out = '';

  final _rand = Random.secure();

  String _gen(int len) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#\$%';
    final b = StringBuffer();
    for (var i = 0; i < len; i++) {
      b.write(chars[_rand.nextInt(chars.length)]);
    }
    return b.toString();
  }

  @override
  void dispose() {
    _lenCtrl.dispose();
    super.dispose();
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
              TextField(
                controller: _lenCtrl,
                decoration: const InputDecoration(
                  labelText: 'Length (6–50)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  final n = int.tryParse(_lenCtrl.text.trim()) ?? 12;
                  final len = n.clamp(6, 50);
                  setState(() => _out = _gen(len));
                },
                child: const Text('Generate Password'),
              ),
              const SizedBox(height: 12),
              SelectableText(_out, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}
