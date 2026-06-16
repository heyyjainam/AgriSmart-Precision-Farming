import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2E7D32); // Emerald Green
  static const Color secondaryColor = Color(0xFF81C784); // Light Green
  static const Color backgroundColor = Color(0xFFF1F8E9); // Off white/green tint
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1B5E20);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color earthyBrown = Color(0xFF795548);
  static const Color warningColor = Color(0xFFFFA000);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        background: backgroundColor,
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // Glassmorphism Box Decoration
  static BoxDecoration get glassDecoration {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.05),
          blurRadius: 20,
          spreadRadius: 1,
        ),
      ],
    );
  }
}
