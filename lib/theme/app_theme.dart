import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryGreen = Color(0xFF5CFBAC);
  static const Color darkBackground = Color(0xFF121212);
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color borderGreen = Color(0xFF5CFBAC);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color errorRed = Color(0xFFFF5252);

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF5CFBAC), Color(0xFF4AE89B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textWhite,
    letterSpacing: 0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textWhite,
    letterSpacing: 0.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: textGrey,
    letterSpacing: 0.2,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: textGrey,
  );

  // Input Decoration Theme
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1E1E1E),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2E2E2E), width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2E2E2E), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryGreen, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: errorRed, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: errorRed, width: 2),
    ),
    labelStyle: const TextStyle(color: textGrey),
    hintStyle: const TextStyle(color: Color(0xFF616161)),
    prefixIconColor: textGrey,
    suffixIconColor: textGrey,
  );

  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: darkBackground,
      cardColor: cardBackground,
      inputDecorationTheme: inputDecorationTheme,
      textTheme: const TextTheme(
        headlineLarge: headingLarge,
        headlineMedium: headingMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
      ),
      iconTheme: const IconThemeData(color: textGrey),
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: primaryGreen,
        surface: cardBackground,
        error: errorRed,
      ),
    );
  }
}