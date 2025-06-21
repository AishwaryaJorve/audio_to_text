import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// Enum to represent different theme modes
enum AppThemeMode {
  system,
  light,
  dark
}

// Theme provider to manage app theme state
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  // Default to system theme
  ThemeModeNotifier() : super(AppThemeMode.system);

  // Method to change theme mode
  void setThemeMode(AppThemeMode mode) {
    state = mode;
  }

  // Convert AppThemeMode to ThemeMode
  ThemeMode get themeMode {
    switch (state) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
} 