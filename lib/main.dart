import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import 'package:indian_mobile/app_shell.dart';
import 'package:indian_mobile/theme/app_theme.dart';
import 'package:indian_mobile/providers/local_explorer_provider.dart';
import 'package:indian_mobile/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Limit image cache to reduce memory usage
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100MB max
  PaintingBinding.instance.imageCache.maximumSize = 200; // Max 200 images in memory

  // Request ATT permission BEFORE initializing ads
  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status == TrackingStatus.notDetermined) {
    // Small delay required by Apple (app must be fully rendered first)
    await Future.delayed(const Duration(milliseconds: 500));
    await AppTrackingTransparency.requestTrackingAuthorization();
  }

  await MobileAds.instance.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocalExplorerProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const IndianInfoApp(),
    ),
  );
}

class IndianInfoApp extends StatefulWidget {
  const IndianInfoApp({super.key});

  @override
  State<IndianInfoApp> createState() => _IndianInfoAppState();
}

class _IndianInfoAppState extends State<IndianInfoApp> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Indian Information',
      debugShowCheckedModeBanner: false,
      theme: buildIndianInformationTheme(),
      darkTheme: buildIndianInformationDarkTheme(),
      themeMode: themeProvider.mode,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppShell(),
    );
  }
}
