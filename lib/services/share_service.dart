import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Enhanced sharing service that shares news with thumbnail image.
class ShareService {
  /// Share news article with image thumbnail for viral growth.
  /// Falls back to text-only share if image download fails.
  static Future<void> shareNewsWithImage({
    required String title,
    required String slug,
    String? imageUrl,
  }) async {
    final newsUrl = 'https://indiainformations.com/news/$slug';
    final text = '$title\n\nRead more: $newsUrl\n\nDownload India Informations App for latest news & tools!';

    // Try to download and share with image
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/share_image.jpg');
          await file.writeAsBytes(bytes);

          await Share.shareXFiles(
            [XFile(file.path)],
            text: text,
            subject: title,
          );
          return;
        }
      } catch (_) {
        // Fall through to text-only share
      }
    }

    // Fallback: text-only share
    await Share.share(text, subject: title);
  }
}
