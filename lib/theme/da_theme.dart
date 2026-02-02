import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';

class DATheme {
  static ThemeData get themeData {
    return ThemeData(
      scaffoldBackgroundColor: DAColors.lightGrey,
      textTheme: GoogleFonts.poppinsTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: DAColors.primaryGreen,
        primary: DAColors.primaryGreen,
        secondary: DAColors.orange,
        surface: DAColors.white,
        error: DAColors.red,
      ),
      useMaterial3: true,

  
      appBarTheme: AppBarTheme(
        backgroundColor: DAColors.primaryGreen,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: DAColors.white,
        ),
        iconTheme: const IconThemeData(color: DAColors.white),
      ),

      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DAColors.primaryGreen,
          foregroundColor: DAColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

    
      inputDecorationTheme: InputDecorationTheme(
        fillColor: DAColors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DAColors.primaryGreen, width: 2),
        ),
      ),

  
      cardTheme: CardThemeData(
        color: DAColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }
}