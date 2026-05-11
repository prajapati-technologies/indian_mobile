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
