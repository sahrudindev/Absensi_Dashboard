import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/app_config.dart';
import 'screens/dashboard_screen.dart';

/// Main Application Entry Point
/// 
/// Attendance Dashboard with Material 3 design and Riverpod state management.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  runApp(
    const ProviderScope(
      child: AttendanceApp(),
    ),
  );
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      
      // Material 3 Theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(AppConfig.primaryColorValue),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      
      // Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(AppConfig.primaryColorValue),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      
      // Use system theme preference
      themeMode: ThemeMode.system,
      
      home: const DashboardScreen(),
    );
  }
}
