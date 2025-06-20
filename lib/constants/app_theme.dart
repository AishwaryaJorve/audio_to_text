import 'package:flutter/material.dart';

class AppTheme {
  // Add color constants
  static const Color avatarBackgroundLight = Color(0xFFFFB6C1);
  static const Color avatarBackgroundDark = Color(0xFFFF4081);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.light(
      primary: Colors.blue,
      secondary: const Color.fromARGB(255, 186, 71, 90).withOpacity(0.7),
      surface: Colors.white,
      background: Colors.grey[50]!,
      error: Colors.red[700]!,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.black87,
      ),
    ),
    dividerColor: Colors.grey[300],
    iconTheme: IconThemeData(
      color: Colors.grey[700],
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blue[700],
    scaffoldBackgroundColor: const Color(0xFF23272F),
    colorScheme: ColorScheme.dark(
      primary: Colors.blue[700]!,
      secondary: const Color.fromARGB(255, 207, 46, 107).withOpacity(0.7),
      surface: const Color(0xFF2C313C),
      background: const Color(0xFF23272F),
      error: Colors.red[300]!,
      onBackground: Colors.white,
      onSurface: Colors.white,
      onSecondary: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF2C313C),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[800]!),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.white70,
      ),
    ),
    dividerColor: Colors.grey[800],
    iconTheme: const IconThemeData(
      color: Colors.white70,
    ),
  );
}