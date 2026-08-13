import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import 'package:indian_mobile/app_shell.dart';
import 'package:indian_mobile/theme/app_theme.dart';
import 'package:indian_mobile/providers/local_explorer_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    return MaterialApp(
      title: 'Indian Information',
      debugShowCheckedModeBanner: false,
      theme: buildIndianInformationTheme(),
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
