import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';

Future<void> shareBytesAsFile(Uint8List bytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$filename';
  final f = File(path);
  await f.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(path)], subject: filename);
}

Widget toolSectionCard(BuildContext context, {required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFDBE6F8)),
      boxShadow: [
        BoxShadow(
          color: AppColors.brandNavy.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

String extForFormat(String key) {
  switch (key) {
    case 'png':
      return 'png';
    case 'jpg':
    default:
      return 'jpg';
  }
}
