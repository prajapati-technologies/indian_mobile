import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import 'tools_media_text.dart';
import 'tools_pdf.dart';

/// Opens a utility in-app (no website URL / WebView).
class UtilityToolPage extends StatefulWidget {
  const UtilityToolPage({
    super.key,
    required this.toolKey,
    required this.title,
  });

  final String toolKey;
  final String title;

  @override
  State<UtilityToolPage> createState() => _UtilityToolPageState();
}

class _UtilityToolPageState extends State<UtilityToolPage> {
  // AdMob State
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  void _loadAds() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: _body(),
          ),
          if (_isBannerLoaded && _bannerAd != null)
            Container(
              color: Colors.white,
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (widget.toolKey) {
      case 'pdf-word':
        return const PdfWordToolBody();
      case 'pdf-merge-split':
        return const PdfMergeSplitToolBody();
      case 'image-compressor':
        return const ImageCompressorToolBody();
      case 'image-resize-convert':
        return const ImageResizeToolBody();
      case 'word-count-case':
        return const WordCountToolBody();
      case 'image-ocr':
        return const OcrToolBody();
      case 'qr-generator':
        return const QrGeneratorToolBody();
      case 'barcode-generator':
        return const BarcodeGeneratorToolBody();
      case 'password-generator':
        return const PasswordGeneratorToolBody();
      default:
        return const Center(
          child: Text('Unknown tool'),
        );
    }
  }
}
