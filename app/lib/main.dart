import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/quick_calculator/quick_calculator_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/price_ladder/price_ladder_screen.dart';
import 'screens/what_if/what_if_screen.dart';
import 'screens/reverse_mode/reverse_mode_screen.dart';
import 'screens/share/share_screen.dart';
import 'screens/saved_strategies/saved_strategies_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  runApp(
    const ProviderScope(
      child: GridSurvivalApp(),
    ),
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
