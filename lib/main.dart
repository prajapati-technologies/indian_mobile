import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'package:indian_mobile/app_shell.dart';
import 'package:indian_mobile/theme/app_theme.dart';
import 'package:indian_mobile/providers/canvas_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CanvasProvider()),
      ],
      child: const IndianInfoApp(),
    ),
  );
}

class IndianInfoApp extends StatelessWidget {
  const IndianInfoApp({super.key});

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
