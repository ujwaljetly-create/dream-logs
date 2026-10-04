import 'package:flutter/material.dart';

class DreamColors {
  static const night = Color(0xFF070B1D);
  static const surface = Color(0xFF11162D);
  static const surface2 = Color(0xFF191D3A);
  static const violet = Color(0xFF9B6CFF);
  static const pink = Color(0xFFF29CFF);
  static const blue = Color(0xFF69C9FF);
  static const text = Color(0xFFF8F6FF);
  static const muted = Color(0xFFAAA8C2);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: DreamColors.night,
        colorScheme: const ColorScheme.dark(
          primary: DreamColors.violet,
          secondary: DreamColors.pink,
          surface: DreamColors.surface,
        ),
        useMaterial3: true,
        fontFamily: 'Georgia',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -.8),
          headlineMedium: TextStyle(fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(fontFamily: 'Arial'),
          bodyMedium: TextStyle(fontFamily: 'Arial'),
          labelLarge: TextStyle(fontFamily: 'Arial', fontWeight: FontWeight.w700),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: DreamColors.surface,
          hintStyle: const TextStyle(color: DreamColors.muted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      );
}
