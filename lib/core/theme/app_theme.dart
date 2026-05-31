import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Color Palette (Tailwind CSS Dark Theme)
  static const Color slate950 = Color(0xFF020617); // Main Background
  static const Color slate900 = Color(0xFF0F172A); // Card Background
  static const Color slate850 = Color(0xFF161E31); // Darker Accent Card
  static const Color slate800 = Color(0xFF1E293B); // Borders & Dividers
  static const Color slate700 = Color(0xFF334155); 
  static const Color slate500 = Color(0xFF64748B); 
  static const Color slate400 = Color(0xFF94A3B8); // Subtext
  static const Color slate300 = Color(0xFFCBD5E1); // Neutral Text
  static const Color slate100 = Color(0xFFF1F5F9); // Light Text

  // Accent Colors
  static const Color indigo600 = Color(0xFF4F46E5); // Primary Action
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color purple600 = Color(0xFF9333EA); // Secondary Accent
  
  // Financial Accents
  static const Color emerald400 = Color(0xFF34D399); // Income Text
  static const Color emerald950 = Color(0x33022C22); // Income Bg (Opacity)
  static const Color emeraldBorder = Color(0x4010B981); // Income Border
  
  static const Color rose400 = Color(0xFFF43F5E); // Expense Text
  static const Color rose950 = Color(0x334C0519); // Expense Bg (Opacity)
  static const Color roseBorder = Color(0x40F43F5E); // Expense Border

  // ThemeData Definition
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: slate950,
      primaryColor: indigo600,
      
      // Card Theme
      cardTheme: const CardThemeData(
        color: slate900,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: slate800, width: 1),
        ),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: slate100,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: slate100,
        ),
        titleLarge: GoogleFonts.kanit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: slate100,
        ),
        bodyLarge: GoogleFonts.kanit(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: slate300,
        ),
        bodyMedium: GoogleFonts.kanit(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: slate300,
        ),
        labelLarge: GoogleFonts.kanit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: slate100,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: slate400,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate900.withOpacity(0.45),
        hintStyle: GoogleFonts.kanit(color: slate700, fontSize: 14),
        labelStyle: GoogleFonts.kanit(color: slate400, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: slate800),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: slate800),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: indigo500, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: rose400),
        ),
      ),

      // Button Theme
      buttonTheme: const ButtonThemeData(
        buttonColor: indigo600,
        textTheme: ButtonTextTheme.primary,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: slate800,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

// Glassmorphism Widget Utility
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color color;
  final Color borderColor;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 12.0,
    this.opacity = 0.3,
    this.color = AppTheme.slate900,
    this.borderColor = AppTheme.slate800,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color.withOpacity(opacity),
              borderRadius: borderRadius,
              border: Border.all(
                color: borderColor.withOpacity(0.8),
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
