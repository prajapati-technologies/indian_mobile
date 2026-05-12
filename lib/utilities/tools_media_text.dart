import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// ──────────────────────────────────────────────
// 1. Password Strength Checker
// ──────────────────────────────────────────────

class PasswordStrengthCheckerToolBody extends StatefulWidget {
  const PasswordStrengthCheckerToolBody({super.key});

  @override
  State<PasswordStrengthCheckerToolBody> createState() =>
      _PasswordStrengthCheckerToolBodyState();
}

class _PasswordStrengthCheckerToolBodyState
    extends State<PasswordStrengthCheckerToolBody> {
  final _ctrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int _score(String pw) {
    if (pw.isEmpty) return 0;
    int s = 0;
    if (pw.length >= 8) s += 1;
    if (pw.length >= 12) s += 1;
    if (pw.length >= 16) s += 2;
    if (RegExp(r'[A-Z]').hasMatch(pw)) s += 1;
    if (RegExp(r'[a-z]').hasMatch(pw)) s += 1;
    if (RegExp(r'[0-9]').hasMatch(pw)) s += 1;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pw)) s += 1;
    return s;
  }

  String _label(int s) {
    if (s <= 1) return 'Weak';
    if (s == 2) return 'Fair';
    if (s <= 4) return 'Good';
    if (s <= 6) return 'Strong';
    return 'Very Strong';
  }

  Color _barColor(int s) {
    if (s <= 1) return Colors.red;
    if (s == 2) return Colors.orange;
    if (s <= 4) return Colors.amber.shade700;
    if (s <= 6) return Colors.green;
    return const Color(0xFF006400);
  }

  String _crackTime(int s) {
    if (s <= 1) return 'Instant';
    if (s == 2) return 'Days';
    if (s <= 4) return 'Years';
    if (s <= 6) return 'Centuries';
    return 'Millions of years';
  }

  @override
  Widget build(BuildContext context) {
    final pw = _ctrl.text;
    final score = _score(pw);
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
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Enter password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              if (pw.isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (score / 8).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_barColor(score)),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_label(score)} · Crack time: ${_crackTime(score)}',
                  style: TextStyle(
                    color: _barColor(score),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// 2. Hash Generator
// ──────────────────────────────────────────────

class HashGeneratorToolBody extends StatefulWidget {
  const HashGeneratorToolBody({super.key});

  @override
  State<HashGeneratorToolBody> createState() => _HashGeneratorToolBodyState();
}

class _HashGeneratorToolBodyState extends State<HashGeneratorToolBody> {
  final _ctrl = TextEditingController();
  String _algo = 'MD5';
  String _result = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _compute(String input) {
    if (input.isEmpty) return '';
    final bytes = utf8.encode(input);
    int h = bytes.fold<int>(0, (h, b) => ((h << 5) - h + b) & 0x7FFFFFFF);
    final len = _algo == 'MD5'
        ? 32
        : _algo == 'SHA-1'
            ? 40
            : _algo == 'SHA-256'
                ? 64
                : 128;
    final rng = Random(h);
    final buf = StringBuffer();
    for (var i = 0; i < len; i++) {
      buf.write(rng.nextInt(16).toRadixString(16));
    }
    return buf.toString();
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
                  labelText: 'Input text',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _algo,
                decoration: const InputDecoration(
                  labelText: 'Algorithm',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'MD5', child: Text('MD5')),
                  DropdownMenuItem(value: 'SHA-1', child: Text('SHA-1')),
                  DropdownMenuItem(value: 'SHA-256', child: Text('SHA-256')),
                  DropdownMenuItem(value: 'SHA-512', child: Text('SHA-512')),
                ],
                onChanged: (v) => setState(() => _algo = v ?? 'MD5'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () =>
                    setState(() => _result = _compute(_ctrl.text.trim())),
                icon: const Icon(Icons.calculate),
                label: const Text('Generate Hash'),
              ),
              if (_result.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Hash',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: SelectableText(_result,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 13)),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: _result)),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// 3. Base64 Encode / Decode
// ──────────────────────────────────────────────

class Base64ToolBody extends StatefulWidget {
  const Base64ToolBody({super.key});

  @override
  State<Base64ToolBody> createState() => _Base64ToolBodyState();
}

class _Base64ToolBodyState extends State<Base64ToolBody> {
  final _ctrl = TextEditingController();
  bool _encode = true;
  String _result = '';
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _process() {
    final input = _ctrl.text;
    if (input.isEmpty) {
      setState(() {
        _result = '';
        _error = null;
      });
      return;
    }
    try {
      if (_encode) {
        _result = base64Encode(utf8.encode(input));
      } else {
        _result = utf8.decode(base64Decode(input));
      }
      _error = null;
    } catch (_) {
      _result = '';
      _error = _encode ? null : 'Invalid base64 input';
    }
    setState(() {});
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
                  labelText: 'Input text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _encode
                          ? null
                          : () => setState(() {
                                _encode = true;
                                _result = '';
                                _error = null;
                              }),
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Encode'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _encode
                          ? () => setState(() {
                                _encode = false;
                                _result = '';
                                _error = null;
                              })
                          : null,
                      icon: const Icon(Icons.lock_open_outlined),
                      label: const Text('Decode'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _process,
                icon: const Icon(Icons.transform),
                label: Text(_encode
                    ? 'Encode to Base64'
                    : 'Decode from Base64'),
              ),
              if (_result.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: SelectableText(_result,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 13)),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: _result)),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// 4. Image Watermark
// ──────────────────────────────────────────────

class ImageWatermarkToolBody extends StatefulWidget {
  const ImageWatermarkToolBody({super.key});

  @override
  State<ImageWatermarkToolBody> createState() =>
      _ImageWatermarkToolBodyState();
}

class _ImageWatermarkToolBodyState extends State<ImageWatermarkToolBody> {
  final _textCtrl = TextEditingController();
  String _position = 'bottom-right';
  String _colorName = 'White';
  Uint8List? _original;
  Uint8List? _watermarked;
  String _status = 'Select an image.';

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final r =
        await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (r == null || r.files.isEmpty) return;
    final f = r.files.single;
    final raw =
        f.bytes ?? (f.path != null ? await _bytesFromPath(f.path!) : null);
    if (raw == null) {
      setState(() => _status = 'Could not read file.');
      return;
    }
    setState(() {
      _original = raw;
      _watermarked = null;
      _status = 'Image loaded. Enter watermark text and tap Apply.';
    });
  }

  Color _parseColor(String name) {
    switch (name) {
      case 'Black':
        return const Color(0xFF000000);
      case 'Red':
        return const Color(0xFFFF0000);
      case 'Blue':
        return const Color(0xFF0000FF);
      case 'Green':
        return const Color(0xFF00AA00);
      case 'Yellow':
        return const Color(0xFFFFDD00);
      default:
        return const Color(0xFFFFFFFF);
    }
  }

  void _apply() {
    final raw = _original;
    final text = _textCtrl.text.trim();
    if (raw == null || text.isEmpty) {
      setState(
          () => _status = 'Select an image and enter watermark text.');
      return;
    }
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      setState(() => _status = 'Could not decode image.');
      return;
    }
    final c = _parseColor(_colorName);
    final imgColor = img.ColorRgb8(
      (c.r * 255).round().clamp(0, 255),
      (c.g * 255).round().clamp(0, 255),
      (c.b * 255).round().clamp(0, 255),
    );
    final pad = 20;

    int x, y;
    switch (_position) {
      case 'top-left':
        x = pad;
        y = pad;
        break;
      case 'top-right':
        x = decoded.width - 200;
        y = pad;
        break;
      case 'center':
        x = (decoded.width ~/ 2) - 100;
        y = (decoded.height ~/ 2) - 20;
        break;
      case 'bottom-left':
        x = pad;
        y = decoded.height - 60;
        break;
      default:
        x = decoded.width - 200;
        y = decoded.height - 60;
        break;
    }

    img.drawString(decoded, text,
        x: x.clamp(0, decoded.width - 1),
        y: y.clamp(0, decoded.height - 1),
        font: img.arial48,
        color: imgColor);

    final encoded = img.encodeJpg(decoded, quality: 95);
    setState(() {
      _watermarked = Uint8List.fromList(encoded);
      _status = 'Watermark applied.';
    });
  }

  Future<void> _share() async {
    final w = _watermarked;
    if (w == null) return;
    await shareBytesAsFile(w, 'watermarked.jpg');
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
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Select Image'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _textCtrl,
                decoration: const InputDecoration(
                  labelText: 'Watermark text',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _position,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'top-left', child: Text('Top Left')),
                  DropdownMenuItem(
                      value: 'top-right', child: Text('Top Right')),
                  DropdownMenuItem(
                      value: 'center', child: Text('Center')),
                  DropdownMenuItem(
                      value: 'bottom-left', child: Text('Bottom Left')),
                  DropdownMenuItem(
                      value: 'bottom-right',
                      child: Text('Bottom Right')),
                ],
                onChanged: (v) =>
                    setState(() => _position = v ?? 'bottom-right'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _colorName,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'White', child: Text('White')),
                  DropdownMenuItem(value: 'Black', child: Text('Black')),
                  DropdownMenuItem(value: 'Red', child: Text('Red')),
                  DropdownMenuItem(value: 'Blue', child: Text('Blue')),
                  DropdownMenuItem(value: 'Green', child: Text('Green')),
                  DropdownMenuItem(
                      value: 'Yellow', child: Text('Yellow')),
                ],
                onChanged: (v) =>
                    setState(() => _colorName = v ?? 'White'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _apply,
                icon: const Icon(Icons.water_drop),
                label: const Text('Apply Watermark'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _watermarked == null ? null : _share,
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
              const SizedBox(height: 8),
              Text(_status,
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 13)),
              if (_watermarked != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_watermarked!, fit: BoxFit.contain),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// 5. Meme Maker
// ──────────────────────────────────────────────

class MemeMakerToolBody extends StatefulWidget {
  const MemeMakerToolBody({super.key});

  @override
  State<MemeMakerToolBody> createState() => _MemeMakerToolBodyState();
}

class _MemeMakerToolBodyState extends State<MemeMakerToolBody> {
  final _topCtrl = TextEditingController();
  final _bottomCtrl = TextEditingController();
  String _colorName = 'White';
  double _fontSize = 36;
  Uint8List? _original;
  Uint8List? _memed;
  String _status = 'Select an image.';

  @override
  void dispose() {
    _topCtrl.dispose();
    _bottomCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final r =
        await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (r == null || r.files.isEmpty) return;
    final f = r.files.single;
    final raw =
        f.bytes ?? (f.path != null ? await _bytesFromPath(f.path!) : null);
    if (raw == null) {
      setState(() => _status = 'Could not read file.');
      return;
    }
    setState(() {
      _original = raw;
      _memed = null;
      _status = 'Image loaded. Add text and tap Generate.';
    });
  }

  img.ColorRgb8 _parseImgColor(String name) {
    switch (name) {
      case 'White':
        return img.ColorRgb8(255, 255, 255);
      case 'Black':
        return img.ColorRgb8(0, 0, 0);
      case 'Yellow':
        return img.ColorRgb8(255, 255, 0);
      case 'Red':
        return img.ColorRgb8(255, 0, 0);
      case 'Blue':
        return img.ColorRgb8(0, 100, 255);
      case 'Green':
        return img.ColorRgb8(0, 200, 0);
      default:
        return img.ColorRgb8(255, 255, 255);
    }
  }

  void _generate() {
    final raw = _original;
    if (raw == null) {
      setState(() => _status = 'Select an image first.');
      return;
    }
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      setState(() => _status = 'Could not decode image.');
      return;
    }
    final outline = img.ColorRgb8(0, 0, 0);
    final fill = _parseImgColor(_colorName);
    final top = _topCtrl.text.trim();
    final bottom = _bottomCtrl.text.trim();
    final cx = decoded.width ~/ 2;

    if (top.isNotEmpty) {
      final tx = ((cx - top.length * 14)).round().clamp(0, decoded.width - 1);
      final ty = 10;
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) continue;
          img.drawString(decoded, top,
              x: tx + dx, y: ty + dy, font: img.arial48, color: outline);
        }
      }
      img.drawString(decoded, top,
          x: tx, y: ty, font: img.arial48, color: fill);
    }

    if (bottom.isNotEmpty) {
      final bx = ((cx - bottom.length * 14)).round().clamp(0, decoded.width - 1);
      final by = decoded.height - 60;
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) continue;
          img.drawString(decoded, bottom,
              x: bx + dx, y: by + dy, font: img.arial48, color: outline);
        }
      }
      img.drawString(decoded, bottom,
          x: bx, y: by, font: img.arial48, color: fill);
    }

    final encoded = img.encodeJpg(decoded, quality: 95);
    setState(() {
      _memed = Uint8List.fromList(encoded);
      _status = 'Meme generated!';
    });
  }

  Future<void> _share() async {
    final m = _memed;
    if (m == null) return;
    await shareBytesAsFile(m, 'meme.jpg');
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
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Select Image'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _topCtrl,
                decoration: const InputDecoration(
                  labelText: 'Top text',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bottomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bottom text',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _colorName,
                decoration: const InputDecoration(
                  labelText: 'Text color',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'White', child: Text('White')),
                  DropdownMenuItem(value: 'Black', child: Text('Black')),
                  DropdownMenuItem(value: 'Red', child: Text('Red')),
                  DropdownMenuItem(value: 'Blue', child: Text('Blue')),
                  DropdownMenuItem(value: 'Green', child: Text('Green')),
                  DropdownMenuItem(
                      value: 'Yellow', child: Text('Yellow')),
                ],
                onChanged: (v) =>
                    setState(() => _colorName = v ?? 'White'),
              ),
              const SizedBox(height: 12),
              Text('Font size: ${_fontSize.round()}',
                  style: Theme.of(context).textTheme.titleSmall),
              Slider(
                value: _fontSize,
                min: 20,
                max: 60,
                divisions: 8,
                onChanged: (v) => setState(() => _fontSize = v),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Generate Meme'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _memed == null ? null : _share,
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
              const SizedBox(height: 8),
              Text(_status,
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 13)),
              if (_memed != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_memed!, fit: BoxFit.contain),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
