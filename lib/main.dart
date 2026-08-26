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

  // Initialize ads (ATT will be requested after app renders)
  await MobileAds.instance.initialize();

  // Error Boundary — suppress known third-party package issues
  FlutterError.onError = (details) {
    final msg = details.exceptionAsString();
    // Suppress glass_kit shadow errors and overflow (non-critical visual issues)
    if (msg.contains('shadow blur radius') ||
        msg.contains('RenderFlex overflowed') ||
        msg.contains('painting.dart') ||
        msg.contains('optimized out')) {
      return; // Silently ignore
    }
    FlutterError.presentError(details);
  };

  // Replace red error screen with a clean grey placeholder in debug mode
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const SizedBox.shrink();
  };

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
  bool _showOnboarding = false;
  bool _checkingOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
    // Request ATT after app is fully rendered (Apple requirement)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestATT();
    });
  }

  Future<void> _requestATT() async {
    // Wait for app to be fully visible
    await Future.delayed(const Duration(seconds: 2));
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
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
      title: 'India Informations',
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
