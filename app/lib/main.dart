import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'config/app_config.dart';
import 'screens/quick_calculator/quick_calculator_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/price_ladder/price_ladder_screen.dart';
import 'screens/what_if/what_if_screen.dart';
import 'screens/reverse_mode/reverse_mode_screen.dart';
import 'screens/share/share_screen.dart';
import 'screens/saved_strategies/saved_strategies_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Sentry for error tracking
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://6ab18f7926270c94bfa159b590f0c293@o4505474077753344.ingest.us.sentry.io/4511981740359680';
      options.tracesSampleRate = 0.2; // 20% performance tracing
      options.debug = false;
    },
    appRunner: () async {
      // Initialize Hive for persistence
      await Hive.initFlutter();

      // Initialize AdMob SDK
      unawaited(MobileAds.instance.initialize());

      // Set test device IDs if in test mode
      if (AppConfig.testAds) {
        MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            testDeviceIds: [], // Emulators/simulators auto-detected
          ),
        );
      }

      // Lock to portrait for mobile
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      runApp(
        const ProviderScope(
          child: GridSurvivalApp(),
        ),
      );
    },
  );
}

class GridSurvivalApp extends StatelessWidget {
  const GridSurvivalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grid Survival Simulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A5F),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A5F),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.system,

      // Named routes for deep linking
      initialRoute: '/',
      routes: {
        '/': (context) => const QuickCalculatorScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/price-ladder': (context) => const PriceLadderScreen(),
        '/what-if': (context) => const WhatIfScreen(),
        '/reverse': (context) => const ReverseModeScreen(),
        '/share': (context) => const ShareScreen(),
        '/saved': (context) => const SavedStrategiesScreen(),
      },

      // Handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const QuickCalculatorScreen(),
        );
      },
    );
  }
}
