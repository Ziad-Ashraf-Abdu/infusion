// main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const InfusionPumpApp());
}

class InfusionPumpApp extends StatefulWidget {
  const InfusionPumpApp({Key? key}) : super(key: key);

  @override
  State<InfusionPumpApp> createState() => _InfusionPumpAppState();
}

class _InfusionPumpAppState extends State<InfusionPumpApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MaterialApp(
      title: 'Infusion Pump Monitor',
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light, textTheme),
      darkTheme: _buildTheme(Brightness.dark, textTheme),
      home: HomeScreen(
        themeMode: _themeMode,
        onThemeChanged: _changeTheme,
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildTheme(Brightness brightness, TextTheme textTheme) {
    bool isLight = brightness == Brightness.light;

    // Define base colors
    const primaryColor = Color(0xFF5C95FF); // Friendly, soft blue
    final lightBackgroundColor = const Color(0xFFE0E5EC);
    final darkBackgroundColor = const Color(0xFF2E2E2E);
    final backgroundColor = isLight ? lightBackgroundColor : darkBackgroundColor;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        background: backgroundColor,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(textTheme).apply(
        bodyColor: isLight ? Colors.grey[800] : Colors.white70,
        displayColor: isLight ? Colors.grey[900] : Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: isLight ? Colors.black87 : Colors.white,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isLight ? Colors.grey[800] : Colors.white,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}