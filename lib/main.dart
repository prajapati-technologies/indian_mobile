import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import 'package:indian_mobile/app_shell.dart';
import 'package:indian_mobile/screens/onboarding_page.dart';
import 'package:indian_mobile/theme/app_theme.dart';
import 'package:indian_mobile/providers/local_explorer_provider.dart';
import 'package:indian_mobile/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Limit image cache to reduce memory usage
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 200;

  // Request ATT permission BEFORE initializing ads
  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status == TrackingStatus.notDetermined) {
    await Future.delayed(const Duration(milliseconds: 500));
    await AppTrackingTransparency.requestTrackingAuthorization();
  }

  await MobileAds.instance.initialize();

  // Error Boundary — catch all unhandled Flutter errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exceptionAsString()}');
  };

  // Catch async errors that escape the Flutter framework
  runZonedGuarded(
    () {
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LocalExplorerProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const IndianInfoApp(),
        ),
      );
    },
    (error, stackTrace) {
      debugPrint('Unhandled Error: $error\n$stackTrace');
    },
  );
}

class IndianInfoApp extends StatefulWidget {
  const IndianInfoApp({super.key});

  @override
  State<IndianInfoApp> createState() => _IndianInfoAppState();
}

class _IndianInfoAppState extends State<IndianInfoApp> {
  bool _showOnboarding = false;
  bool _checkingOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final shouldShow = await OnboardingPage.shouldShow();
    setState(() {
      _showOnboarding = shouldShow;
      _checkingOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    if (_checkingOnboarding) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildIndianInformationTheme(),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

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
      home: _showOnboarding
          ? OnboardingPage(onComplete: () => setState(() => _showOnboarding = false))
          : const AppShell(),
    );
  }
}
